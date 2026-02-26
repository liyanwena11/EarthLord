import Foundation
import Combine
import SwiftUI

// MARK: - Trial State (试用状态)

/// 试用状态枚举
enum TrialState: Equatable, Codable {
    case notStarted           // 未开始
    case active               // 进行中
    case expired              // 已过期
    case used                 // 已使用 (已转正)
    case cancelled            // 已取消

    var displayName: String {
        switch self {
        case .notStarted:
            return "未开始"
        case .active:
            return "试用中"
        case .expired:
            return "已过期"
        case .used:
            return "已使用"
        case .cancelled:
            return "已取消"
        }
    }

    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }

    var canStartTrial: Bool {
        if case .notStarted = self {
            return true
        }
        return false
    }
}

// MARK: - Trial Record (试用记录)

/// 单个产品的试用记录
struct TrialRecord: Codable {
    let productGroupID: String           // 产品组 ID
    let trialProductID: String           // 试用产品 ID
    var state: TrialState                // 试用状态
    let startedAt: Date                  // 开始时间
    var expiresAt: Date                  // 过期时间
    var convertedAt: Date?               // 转正时间 (如果已转正)
    var cancelledAt: Date?               // 取消时间 (如果已取消)

    /// 剩余天数
    var remainingDays: Int {
        guard state == .active else {
            return 0
        }

        let interval = expiresAt.timeIntervalSince(Date())
        if interval <= 0 {
            return 0
        }
        return Int(ceil(interval / 86400))
    }

    /// 是否已过期
    var isExpired: Bool {
        state == .active && Date() > expiresAt
    }

    /// 试用时长 (天数)
    var trialDays: Int {
        let interval = expiresAt.timeIntervalSince(startedAt)
        return Int(ceil(interval / 86400))
    }
}

// MARK: - TrialManager (试用管理器)

/// TrialManager - 试用流程管理
/// 核心职责:
/// 1. 管理用户试用状态 (每用户每产品仅一次)
/// 2. 监控试用过期和转正
/// 3. 与 TierManager 集成处理试用权益
/// 4. 持久化试用状态
@MainActor
final class TrialManager: ObservableObject {
    static let shared = TrialManager()

    // MARK: - Published Properties

    @Published var trialRecords: [String: TrialRecord] = [:]  // [productGroupID: TrialRecord]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userDefaultsKey = "TrialManager_records"
    private let tierManager = TierManager.shared
    private var expirationCheckTimer: Timer?
    private var saveCancellable: AnyCancellable?

    // MARK: - Init

    private init() {
        loadTrialState()
        startExpirationMonitoring()
        setupAutoSave()

        print("✅ TrialManager 初始化完成")
    }

    deinit {
        expirationCheckTimer?.invalidate()
    }

    // MARK: - Public Methods - Trial Eligibility (试用资格)

    /// 检查是否可以开始试用
    /// - Parameter productGroupID: 产品组 ID
    /// - Returns: 是否可以试用
    func canStartTrial(for productGroupID: String) -> Bool {
        guard let record = trialRecords[productGroupID] else {
            // 没有记录，可以试用
            return true
        }

        return record.state.canStartTrial
    }

    /// 检查是否可以开始试用 (通过产品 ID)
    /// - Parameter productID: 产品 ID
    /// - Returns: 是否可以试用
    func canStartTrialForProduct(_ productID: String) -> Bool {
        guard let group = SubscriptionProductGroups.group(for: productID),
              group.isTrialProduct(productID) else {
            return false
        }
        return canStartTrial(for: group.id)
    }

    /// 获取试用剩余天数
    /// - Parameter productGroupID: 产品组 ID
    /// - Returns: 剩余天数 (如果未试用或已过期返回 0)
    func getTrialRemainingDays(for productGroupID: String) -> Int {
        guard let record = trialRecords[productGroupID],
              record.state == .active else {
            return 0
        }
        return record.remainingDays
    }

    /// 获取试用状态
    /// - Parameter productGroupID: 产品组 ID
    /// - Returns: 试用状态
    func getTrialState(for productGroupID: String) -> TrialState {
        return trialRecords[productGroupID]?.state ?? .notStarted
    }

    /// 获取试用记录
    /// - Parameter productGroupID: 产品组 ID
    /// - Returns: 试用记录
    func getTrialRecord(for productGroupID: String) -> TrialRecord? {
        return trialRecords[productGroupID]
    }

    // MARK: - Public Methods - Trial Management (试用管理)

    /// 开始试用
    /// - Parameters:
    ///   - productID: 试用产品 ID
    ///   - trialDays: 试用天数
    /// - Returns: 是否成功开始试用
    func startTrial(for productID: String, trialDays: Int = 7) async -> Bool {
        guard let group = SubscriptionProductGroups.group(for: productID),
              let trialProductID = group.trialProductID else {
            errorMessage = "无效的试用产品"
            return false
        }

        guard canStartTrial(for: group.id) else {
            errorMessage = "您已试用过此产品，无法再次试用"
            return false
        }

        print("🎉 [Trial] 开始试用: \(group.displayName)")

        // 创建试用记录
        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .day, value: trialDays, to: now) ?? now

        let record = TrialRecord(
            productGroupID: group.id,
            trialProductID: trialProductID,
            state: .active,
            startedAt: now,
            expiresAt: expiresAt,
            convertedAt: nil,
            cancelledAt: nil
        )

        trialRecords[group.id] = record

        // 保存状态
        saveTrialState()

        // 通知 TierManager 升级 Tier
        await tierManager.handleTrialStart(
            productGroupID: group.id,
            tier: group.tier,
            expiresAt: expiresAt
        )

        // 调度过期处理
        scheduleTrialExpiration(for: group.id, at: expiresAt)

        print("✅ [Trial] 试用开始成功，过期时间: \(expiresAt)")
        return true
    }

    /// 取消试用
    /// - Parameter productGroupID: 产品组 ID
    /// - Returns: 是否成功取消
    func cancelTrial(for productGroupID: String) async -> Bool {
        guard var record = trialRecords[productGroupID],
              record.state == .active else {
            errorMessage = "没有进行中的试用"
            return false
        }

        print("🚫 [Trial] 取消试用: \(productGroupID)")

        record.state = .cancelled
        record.cancelledAt = Date()
        trialRecords[productGroupID] = record

        saveTrialState()

        // 通知 TierManager 降级 Tier
        await tierManager.handleTrialCancellation(productGroupID: productGroupID)

        print("✅ [Trial] 试用已取消")
        return true
    }

    /// 试用转正 (用户在试用期间购买正式订阅)
    /// - Parameters:
    ///   - productGroupID: 产品组 ID
    ///   - purchasedProductID: 购买的产品 ID
    /// - Returns: 是否成功转正
    func convertTrial(
        for productGroupID: String,
        purchasedProductID: String
    ) async -> Bool {
        guard var record = trialRecords[productGroupID],
              record.state == .active else {
            // 没有进行中的试用，不处理
            return false
        }

        print("💎 [Trial] 试用转正: \(productGroupID)")

        record.state = .used
        record.convertedAt = Date()
        trialRecords[productGroupID] = record

        saveTrialState()

        print("✅ [Trial] 试用已转正")
        return true
    }

    /// 处理试用过期
    /// - Parameter productGroupID: 产品组 ID
    func handleTrialExpiration(_ productGroupID: String) async {
        guard var record = trialRecords[productGroupID],
              record.state == .active else {
            return
        }

        print("⏰ [Trial] 试用过期: \(productGroupID)")

        record.state = .expired
        trialRecords[productGroupID] = record

        saveTrialState()

        // 通知 TierManager 降级 Tier
        await tierManager.handleTrialExpiration(productGroupID: productGroupID)

        // 发送过期通知
        NotificationCenter.default.post(
            name: NSNotification.Name("TrialExpired"),
            object: productGroupID
        )

        print("✅ [Trial] 试用过期处理完成")
    }

    // MARK: - Private Methods - Persistence (持久化)

    /// 加载试用状态
    private func loadTrialState() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let records = try? JSONDecoder().decode([String: TrialRecord].self, from: data) else {
            print("📂 [Trial] 没有找到试用记录")
            return
        }

        trialRecords = records
        print("📂 [Trial] 加载了 \(records.count) 条试用记录")

        // 检查是否有已过期但未处理的试用
        for (productGroupID, record) in records {
            if record.isExpired {
                Task {
                    await handleTrialExpiration(productGroupID)
                }
            }
        }
    }

    /// 保存试用状态
    private func saveTrialState() {
        guard let data = try? JSONEncoder().encode(trialRecords) else {
            print("❌ [Trial] 保存试用记录失败")
            return
        }

        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        print("💾 [Trial] 试用记录已保存")
    }

    /// 设置自动保存
    private func setupAutoSave() {
        saveCancellable = $trialRecords
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveTrialState()
            }
    }

    // MARK: - Private Methods - Expiration Monitoring (过期监控)

    /// 启动过期监控
    private func startExpirationMonitoring() {
        // 每60秒检查一次
        expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkTrialExpirations()
            }
        }

        print("⏰ [Trial] 试用过期监控已启动")
    }

    /// 检查试用过期
    private func checkTrialExpirations() async {
        let now = Date()

        for (productGroupID, record) in trialRecords {
            guard record.state == .active else {
                continue
            }

            if now > record.expiresAt {
                await handleTrialExpiration(productGroupID)
            }
        }
    }

    /// 调度单次过期检查
    private func scheduleTrialExpiration(for productGroupID: String, at expiresAt: Date) {
        let interval = expiresAt.timeIntervalSinceNow

        guard interval > 0 else {
            // 已经过期，立即处理
            Task {
                await handleTrialExpiration(productGroupID)
            }
            return
        }

        // 调度在过期时间执行
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            Task { [weak self] in
                await self?.handleTrialExpiration(productGroupID)
            }
        }

        print("📅 [Trial] 已调度过期检查: \(productGroupID), \(interval)s 后执行")
    }

    // MARK: - Public Methods - Reset (重置)

    /// 重置所有试用记录 (用于测试)
    func resetAllTrials() {
        print("🔄 [Trial] 重置所有试用记录")

        trialRecords.removeAll()
        saveTrialState()

        print("✅ [Trial] 试用记录已重置")
    }

    /// 重置特定产品的试用记录 (用于测试)
    /// - Parameter productGroupID: 产品组 ID
    func resetTrial(for productGroupID: String) {
        print("🔄 [Trial] 重置试用记录: \(productGroupID)")

        trialRecords.removeValue(forKey: productGroupID)
        saveTrialState()

        print("✅ [Trial] 试用记录已重置")
    }

    // MARK: - Public Methods - Debug (调试)

    /// 打印调试信息
    func printDebugInfo() {
        print("📊 [Trial] ===== TrialManager 调试信息 =====")
        print("📊 [Trial] 试用记录数: \(trialRecords.count)")

        for (productGroupID, record) in trialRecords {
            print("📊 [Trial] - \(productGroupID):")
            print("    状态: \(record.state.displayName)")
            print("    开始时间: \(record.startedAt)")
            print("    过期时间: \(record.expiresAt)")
            print("    剩余天数: \(record.remainingDays)")
        }

        print("📊 [Trial] ===== 调试信息结束 =====")
    }

    /// 获取所有活跃的试用
    /// - Returns: 活跃的试用记录数组
    func getActiveTrials() -> [TrialRecord] {
        return trialRecords.values.filter { $0.state == .active }
    }

    /// 是否有进行中的试用
    /// - Returns: 是否有活跃试用
    var hasActiveTrial: Bool {
        trialRecords.values.contains { $0.state == .active }
    }
}

// MARK: - TrialState Extension (试用状态扩展)

extension TrialState {
    /// 是否已使用过
    var isUsed: Bool {
        switch self {
        case .used, .expired, .cancelled:
            return true
        case .notStarted, .active:
            return false
        }
    }

    /// 是否可以再次试用
    var canRetry: Bool {
        switch self {
        case .expired, .cancelled:
            return false  // 过期或取消后不能再次试用
        case .notStarted:
            return true
        case .active, .used:
            return false
        }
    }
}
