import Foundation
import CoreLocation
import Combine
import Supabase

@MainActor
class WalkingRewardManager: ObservableObject {
    static let shared = WalkingRewardManager()

    // MARK: - Published Properties

    @Published var totalWalkingDistance: Double = 0.0  // 总行走距离（米）
    @Published var unlockedTiers: Set<Int> = []        // 已解锁的等级
    @Published var recentReward: WalkingRewardTier?    // 最近获得的奖励
    @Published var showRewardNotification = false      // 显示奖励通知

    // MARK: - Constants

    private let maxSpeed: Double = 30.0  // 30 km/h = 8.33 m/s
    private let maxSpeedMPS: Double = 8.33  // 米/秒
    private let supabase = supabaseClient

    // MARK: - Private Properties

    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?
    private var rewardRecords: [WalkingRewardRecord] = []

    // ✅ Day 20+21：每 10 秒采样一次的真实位移累加
    private var lastSampleTime: Date?
    private var lastSampleLocation: CLLocation?
    private let sampleInterval: TimeInterval = 10.0  // 10秒采样间隔

    // ✅ 连续超速检测
    private var speedingStartTime: Date?
    private let maxSpeedingDuration: TimeInterval = 10.0  // 10秒
    private var isSpeedViolationActive = false

    private init() {
        LogDebug("🚀 [奖励系统] WalkingRewardManager 初始化开始")
        loadProgress()

        // ✅ 修复：延迟 Supabase 调用，等待用户登录后再同步
        // 不在 init 中直接调用网络请求，避免阻塞主线程
        LogInfo("✅ [奖励系统] WalkingRewardManager 初始化完成（本地数据）")
        LogDebug("📊 [奖励系统] 当前累计距离: \(String(format: "%.2f", totalWalkingDistance))m")
        LogDebug("🏆 [奖励系统] 已解锁等级: \(unlockedTiers.count) 个")
    }

    /// ✅ 新增：登录后调用此方法同步云端数据
    func syncWithSupabaseIfNeeded() {
        Task { @MainActor in
            await loadTodayProgressFromSupabase()
        }
    }

    // MARK: - Distance Tracking

    /// 更新行走距离（由 LocationManager 调用）
    /// ✅ Day 20+21：实现每 10 秒采样一次的真实位移累加机制
    func updateDistance(newLocation: CLLocation) {
        let now = Date()

        // ✅ GPS 异常点过滤：丢弃精度差的点
        if newLocation.horizontalAccuracy > 50 {
            return
        }

        // 首次定位，初始化采样点
        guard let sampleLoc = lastSampleLocation, let sampleTime = lastSampleTime else {
            LogDebug("⚪️ [奖励系统] 首次定位，初始化采样点")
            lastSampleLocation = newLocation
            lastSampleTime = now
            lastLocation = newLocation
            lastUpdateTime = now
            return
        }

        // 检查是否超过 10 秒采样间隔
        let timeSinceLastSample = now.timeIntervalSince(sampleTime)
        guard timeSinceLastSample >= sampleInterval else {
            // 未到 10 秒，仅更新当前位置（用于速度检测）
            lastLocation = newLocation
            lastUpdateTime = now
            return
        }

        // ✅ 到达 10 秒采样点，开始计算真实位移
        LogDebug("⏰ [奖励系统] 到达 10 秒采样点，开始计算真实位移")
        LogDebug("📍 [奖励系统] 采样起点: (\(sampleLoc.coordinate.latitude), \(sampleLoc.coordinate.longitude))")
        LogDebug("📍 [奖励系统] 采样终点: (\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
        // 计算采样周期内的真实位移距离
        let distanceMoved = newLocation.distance(from: sampleLoc)

        // ✅ GPS 跳点过滤：采样周期内位移超过 200m 视为异常
        if distanceMoved > 200 {
            LogWarning("⚠️ [奖励系统] GPS 跳点！位移 \(String(format: "%.1f", distanceMoved))m，丢弃并重置采样点")
            lastSampleLocation = newLocation
            lastSampleTime = now
            lastLocation = newLocation
            lastUpdateTime = now
            return
        }

        // 计算平均速度
        let averageSpeed = distanceMoved / timeSinceLastSample  // 米/秒
        let averageSpeedKmH = averageSpeed * 3.6  // 转换为 km/h

        LogDebug("🚶 [奖励系统] 采样位移: \(String(format: "%.2f", distanceMoved))m")
        LogDebug("🚶 [奖励系统] 平均速度: \(String(format: "%.1f", averageSpeedKmH)) km/h")
        // ✅ 速度检测：30 km/h 限制
        if averageSpeed > maxSpeedMPS {
            if speedingStartTime == nil {
                speedingStartTime = now
                LogWarning("⚠️ [奖励系统] 检测到超速，开始计时（速度: \(String(format: "%.1f", averageSpeedKmH)) km/h）")
            } else {
                let speedingDuration = now.timeIntervalSince(speedingStartTime!)
                if speedingDuration >= maxSpeedingDuration {
                    if !isSpeedViolationActive {
                        isSpeedViolationActive = true
                        LogDebug("🛑 [奖励系统] 连续超速 \(Int(maxSpeedingDuration)) 秒，停止距离累计")
                        LogDebug("🛑 [奖励系统] 当前速度: \(String(format: "%.1f", averageSpeedKmH)) km/h（限制: 30 km/h）")
                    }
                    // 更新采样点但不累加距离
                    lastSampleLocation = newLocation
                    lastSampleTime = now
                    lastLocation = newLocation
                    lastUpdateTime = now
                    return
                }
                LogWarning("⚠️ [奖励系统] 超速持续 \(String(format: "%.1f", speedingDuration)) 秒")
            }
            // 更新采样点但不累加距离
            lastSampleLocation = newLocation
            lastSampleTime = now
            lastLocation = newLocation
            lastUpdateTime = now
            return
        } else {
            // 恢复正常速度，重置超速计时
            if speedingStartTime != nil {
                LogInfo("✅ [奖励系统] 速度恢复正常，重置超速计时")
            }
            speedingStartTime = nil
            isSpeedViolationActive = false
        }

        // 距离过滤：忽略小于 3 米的移动
        guard distanceMoved >= 3.0 else {
            LogDebug("⏭️ [奖励系统] 10 秒位移太小(< 3m)，忽略: \(String(format: "%.2f", distanceMoved))m")
            // 更新采样点
            lastSampleLocation = newLocation
            lastSampleTime = now
            lastLocation = newLocation
            lastUpdateTime = now
            return
        }

        LogInfo("✅ [奖励系统] 距离检查通过！准备累加: \(String(format: "%.2f", distanceMoved))m")
        // ✅ 累加距离
        let previousDistance = totalWalkingDistance
        totalWalkingDistance += distanceMoved

        LogDebug("🎉🎉🎉 [奖励系统] 累计距离更新！")
        LogDebug("📊 [奖励系统] 之前: \(String(format: "%.2f", previousDistance))m")
        LogDebug("📊 [奖励系统] 现在: \(String(format: "%.2f", totalWalkingDistance))m")
        LogDebug("📊 [奖励系统] 新增: \(String(format: "%.2f", distanceMoved))m")
        LogDebug("🏆 [奖励系统] 已解锁等级数: \(unlockedTiers.count)")
        // 检查是否解锁新等级
        checkAndUnlockTiers(from: previousDistance, to: totalWalkingDistance)

        // 保存进度
        saveProgress()

        // 更新采样点
        lastSampleLocation = newLocation
        lastSampleTime = now
        lastLocation = newLocation
        lastUpdateTime = now
    }

    // MARK: - Testing & Simulation

    /// 🧪 模拟行走（仅用于测试）
    @available(*, deprecated, message: "仅用于测试，生产环境请使用真实 GPS 位移")
    func simulateWalking(distance: Double) {
        let oldDistance = totalWalkingDistance
        totalWalkingDistance += distance
        LogDebug("🧪 [测试] 模拟行走 +\(Int(distance))m，当前总距离：\(Int(totalWalkingDistance))m")
        // 触发奖励检查
        checkAndUnlockTiers(from: oldDistance, to: totalWalkingDistance)

        // 保存进度
        saveProgress()
    }

    // MARK: - Reward System

    /// 检查并解锁新等级
    private func checkAndUnlockTiers(from oldDistance: Double, to newDistance: Double) {
        for tier in WalkingRewardTier.allCases {
            let tierDistance = tier.distance

            // 检查是否跨越了这个等级的阈值
            if oldDistance < tierDistance && newDistance >= tierDistance {
                unlockTier(tier)
            }
        }
    }

    /// 解锁等级并发放奖励
    private func unlockTier(_ tier: WalkingRewardTier) {
        // 防止重复解锁
        guard !unlockedTiers.contains(tier.rawValue) else { return }

        LogDebug("🎉 [WalkingReward] 解锁等级: \(tier.displayName) (\(Int(tier.distance))m)")
        unlockedTiers.insert(tier.rawValue)
        recentReward = tier
        showRewardNotification = true

        // 发放奖励到背包
        let rewards = tier.rewards
        ExplorationManager.shared.addItems(items: rewards)

        // 记录奖励
        let record = WalkingRewardRecord(
            tier: tier.rawValue,
            distance: tier.distance,
            timestamp: Date(),
            itemsReceived: rewards.map { $0.itemId }
        )
        rewardRecords.append(record)

        LogDebug("🎁 [WalkingReward] 发放奖励: \(rewards.map { $0.name }.joined(separator: ", "))")
        // ✅ Day 21：同步到 Supabase
        Task {
            await saveRewardToSupabase(tier: tier)
        }
    }

    // MARK: - Reset & Save

    /// 重置每日进度
    func resetDailyProgress() {
        LogDebug("🔄 [WalkingReward] 重置每日进度")
        totalWalkingDistance = 0.0
        unlockedTiers.removeAll()
        rewardRecords.removeAll()
        saveProgress()
    }

    /// 保存进度到 UserDefaults
    private func saveProgress() {
        UserDefaults.standard.set(totalWalkingDistance, forKey: "WalkingReward_TotalDistance")
        UserDefaults.standard.set(Array(unlockedTiers), forKey: "WalkingReward_UnlockedTiers")

        if let encoded = try? JSONEncoder().encode(rewardRecords) {
            UserDefaults.standard.set(encoded, forKey: "WalkingReward_Records")
        }
    }

    /// 加载进度
    private func loadProgress() {
        totalWalkingDistance = UserDefaults.standard.double(forKey: "WalkingReward_TotalDistance")

        if let tiers = UserDefaults.standard.array(forKey: "WalkingReward_UnlockedTiers") as? [Int] {
            unlockedTiers = Set(tiers)
        }

        if let data = UserDefaults.standard.data(forKey: "WalkingReward_Records"),
           let records = try? JSONDecoder().decode([WalkingRewardRecord].self, from: data) {
            rewardRecords = records
        }

        LogDebug("📂 [WalkingReward] 加载进度: \(Int(totalWalkingDistance))m, 已解锁: \(unlockedTiers.count) 个等级")
    }

    // MARK: - Supabase Sync

    /// 保存奖励记录到 Supabase
    @MainActor
    private func saveRewardToSupabase(tier: WalkingRewardTier) async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            struct WalkingRewardRecord: Encodable {
                let user_id: String
                let tier: Int
                let distance_meters: Double
                let items_received: [String]
            }

            let record = WalkingRewardRecord(
                user_id: userId,
                tier: tier.rawValue,
                distance_meters: tier.distance,
                items_received: tier.rewards.map { $0.itemId }
            )

            try await supabase
                .from("walking_rewards")
                .insert(record)
                .execute()

            LogDebug("☁️ [Supabase] 奖励记录已存入云端：\(tier.displayName)")
        } catch {
            LogError("❌ [Supabase] 存储失败：\(error.localizedDescription)")
        }
    }

    /// 从 Supabase 加载今日进度
    @MainActor
    private func loadTodayProgressFromSupabase() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            // 获取今日已解锁的等级
            struct RewardRow: Decodable {
                let tier: Int
            }

            // 获取今日开始时间（UTC 时区）
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let isoFormatter = ISO8601DateFormatter()
            let todayString = isoFormatter.string(from: today)

            let response: [RewardRow] = try await supabase
                .from("walking_rewards")
                .select("tier")
                .eq("user_id", value: userId)
                .gte("unlocked_at", value: todayString)
                .execute()
                .value

            // 更新已解锁等级
            let cloudTiers = Set(response.map { $0.tier })
            if !cloudTiers.isEmpty {
                unlockedTiers = cloudTiers
                LogDebug("☁️ [Supabase] 从云端加载今日解锁等级: \(unlockedTiers.count) 个")
            } else {
                LogDebug("☁️ [Supabase] 今日尚未解锁任何等级")
            }
        } catch {
            LogError("❌ [Supabase] 加载进度失败：\(error.localizedDescription)，使用本地数据")
            // 出错时继续使用 UserDefaults 数据
        }
    }

    // MARK: - Public Getters

    /// 获取下一个等级
    var nextTier: WalkingRewardTier? {
        return WalkingRewardTier.allCases.first { tier in
            !unlockedTiers.contains(tier.rawValue)
        }
    }

    /// 获取下一个等级还需要的距离
    var distanceToNextTier: Double {
        guard let next = nextTier else { return 0 }
        return max(0, next.distance - totalWalkingDistance)
    }
}
