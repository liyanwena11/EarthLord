import Foundation
import SwiftUI

// MARK: - TierManager (等级管理器)

/// TierManager - 管理用户 Tier 等级和权益应用
/// 核心职责:
/// 1. 加载用户当前 Tier
/// 2. 管理权益激活/过期
/// 3. 应用权益到游戏系统
/// 4. 处理升级/降级逻辑
@MainActor
final class TierManager: ObservableObject {
    static let shared = TierManager()
    
    // MARK: - Published Properties
    
    @Published var currentTier: UserTier = .free
    @Published var tierExpiration: Date?
    @Published var activeEntitlements: [Entitlement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var expirationCheckTimer: Timer?
    private var currentUserID: String = "temp-user-id"  // 将从 AuthManager 获取
    
    // MARK: - Init
    
    private init() {
        // 私有初始化，仅能通过 shared 访问
    }
    
    // MARK: - Public Methods
    
    /// 初始化：加载用户 Tier 信息
    func initialize(userID: String = "temp-user-id") async {
        self.currentUserID = userID
        
        await loadUserTier()
        await checkTierExpiration()
        startExpirationWatcher()
        
        print("✅ TierManager 初始化完成, 当前 Tier: \(currentTier.displayName)")
    }
    
    /// 加载用户当前 Tier (从数据库/本地缓存)
    private func loadUserTier() async {
        isLoading = true
        
        // TODO: 实际实现时从 Supabase 加载
        // 现在使用本地默认值
        
        // 模拟从数据库加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
    
    /// 应用权益到游戏系统
    /// 从当前活跃权益中提取最高等级权益，应用到各游戏系统
    func applyActiveEntitlements() {
        // 获取最高等级的有效权益
        let effectiveEntitlements = activeEntitlements.filter { $0.isActive }
        
        guard let maxEntitlement = effectiveEntitlements.max(by: {
            $0.powerLevel < $1.powerLevel
        }) else {
            // 无有效权益，应用默认值
            applyDefaultBenefits()
            return
        }
        
        // 应用到各游戏系统
        applyBenefitsToGameSystems(maxEntitlement)
        
        print("✅ 权益已应用: \(maxEntitlement.tier.displayName)")
    }
    
    // MARK: - Trial Support (试用支持)

    /// 处理试用开始
    /// - Parameters:
    ///   - productGroupID: 产品组 ID
    ///   - tier: 试用等级
    ///   - expiresAt: 过期时间
    func handleTrialStart(
        productGroupID: String,
        tier: UserTier,
        expiresAt: Date
    ) async {
        print("🎉 [Trial] 试用开始: \(productGroupID), Tier: \(tier.displayName)")

        // 获取对应的权益配置
        guard let benefit = TierBenefit.getBenefit(for: tier) else {
            errorMessage = "无法找到试用权益配置"
            return
        }

        // 创建试用权益记录
        let trialEntitlement = Entitlement.from(
            tier: tier,
            benefit: benefit,
            productID: productGroupID + "_trial",
            subscriptionType: .trial,
            userID: currentUserID,
            durationDays: Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 7
        )

        // 更新 Tier
        let oldTier = currentTier
        if tier.powerLevel > oldTier.powerLevel {
            await handleTierUpgrade(from: oldTier, to: tier, newEntitlement: trialEntitlement)
        }

        // 设置过期时间
        tierExpiration = expiresAt

        // 添加到活跃权益
        activeEntitlements.append(trialEntitlement)

        // 应用权益
        applyActiveEntitlements()

        print("✅ [Trial] 试用权益已激活")
    }

    /// 处理试用取消
    /// - Parameter productGroupID: 产品组 ID
    func handleTrialCancellation(productGroupID: String) async {
        print("🚫 [Trial] 试用取消: \(productGroupID)")

        // 移除试用权益
        activeEntitlements.removeAll { $0.productID.contains(productGroupID) }

        // 重新计算当前 Tier
        await recalculateCurrentTier()

        print("✅ [Trial] 试用已取消，当前 Tier: \(currentTier.displayName)")
    }

    /// 处理试用过期
    /// - Parameter productGroupID: 产品组 ID
    func handleTrialExpiration(productGroupID: String) async {
        print("⏰ [Trial] 试用过期: \(productGroupID)")

        // 移除过期的试用权益
        activeEntitlements.removeAll {
            $0.productID.contains(productGroupID) && $0.isExpired
        }

        // 重新计算当前 Tier
        await recalculateCurrentTier()

        print("✅ [Trial] 试用过期处理完成，当前 Tier: \(currentTier.displayName)")
    }

    /// 重新计算当前 Tier
    private func recalculateCurrentTier() async {
        // 获取最高等级的有效权益
        let validEntitlements = activeEntitlements.filter { $0.isActive }

        if let maxEntitlement = validEntitlements.max(by: { $0.powerLevel < $1.powerLevel }) {
            // 更新为最高等级
            if maxEntitlement.tier != currentTier {
                let oldTier = currentTier
                currentTier = maxEntitlement.tier
                tierExpiration = maxEntitlement.expiresAt

                // 发送通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("TierUpdated"),
                    object: ["from": oldTier, "to": currentTier]
                )
            } else {
                tierExpiration = maxEntitlement.expiresAt
            }
        } else {
            // 无有效权益，降级到 Free
            if currentTier != .free {
                let previousTier = currentTier
                currentTier = .free
                tierExpiration = nil

                // 发送通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("TierDowngraded"),
                    object: previousTier
                )
            }
        }

        // 应用权益
        applyActiveEntitlements()
    }

    // MARK: - New Subscription System Handler

    /// 处理新的订阅系统购买
    private func handleNewSubscriptionPurchase(productID: String, group: SubscriptionProductGroup, userID: String) async {
        print("🎉 [订阅] 新系统购买: \(group.displayName) - \(productID)")

        // 获取权益配置
        guard let benefit = TierBenefit.getBenefit(for: group.tier) else {
            errorMessage = "无法找到权益配置"
            return
        }

        // 确定订阅类型和时长
        let subType: SubscriptionType
        let durationDays: Int

        if group.isTrialProduct(productID) {
            subType = .trial
            durationDays = group.trialDays ?? 7
        } else if group.isSubscriptionProduct(productID) {
            subType = .autoRenewable
            // 月付或年付
            if productID.contains("month") {
                durationDays = 30
            } else {
                durationDays = 365
            }
        } else {
            subType = .nonRenewable
            durationDays = 30
        }

        // 创建权益记录
        let entitlement = Entitlement.from(
            tier: group.tier,
            benefit: benefit,
            productID: productID,
            subscriptionType: subType,
            userID: userID,
            durationDays: durationDays
        )

        // 更新 Tier
        await updateTierWithNewEntitlement(entitlement)

        print("✅ [订阅] \(group.displayName) 权益已激活")
    }

    // MARK: - Auto-renewal Monitoring (自动续费监控)

    /// 检查自动续费状态
    /// 提前3天和1天发送续费提醒
    func checkAutoRenewalStatus() async {
        guard let expiration = tierExpiration else {
            return
        }

        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0

        // 提前3天提醒
        if daysRemaining == 3 {
            await sendRenewalReminder(days: 3)
        }
        // 提前1天提醒
        else if daysRemaining == 1 {
            await sendRenewalReminder(days: 1)
        }
    }

    /// 发送续费提醒
    /// - Parameter days: 剩余天数
    private func sendRenewalReminder(days: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "订阅即将到期"
        content.body = "您的 \(currentTier.displayName) 订阅将在 \(days) 天后到期。及时续费以继续享受权益！"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "renewal_reminder_\(days)_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)

        print("📬 [Renewal] 已发送续费提醒，剩余 \(days) 天")
    }

    /// 处理户购买产品后的 Tier 更新
    /// - Parameters:
    ///   - productID: 购买的产品 ID
    ///   - userID: 用户 ID
    func handlePurchase(productID: String, userID: String = "") async {
        let id = userID.isEmpty ? currentUserID : userID

        // 首先尝试从新的订阅产品组中查找
        if let group = SubscriptionProductGroups.group(for: productID) {
            await handleNewSubscriptionPurchase(productID: productID, group: group, userID: id)
            return
        }

        // 查找产品和对应的权益 (旧系统)
        guard let product = All16Products.product(for: productID),
              let benefit = All16Products.benefit(for: productID) else {
            errorMessage = "产品或权益不存在"
            return
        }
        
        // 创建新权益记录
        let newEntitlement = Entitlement.from(
            tier: product.tier,
            benefit: benefit,
            productID: productID,
            subscriptionType: product.type,
            userID: id,
            durationDays: product.durationDays
        )
        
        // 处理逻辑
        switch product.type {
        case .consumable:
            // 消耗品：不改变 Tier，直接添加到库存
            print("✅ 消耗品购买: \(product.displayName)")
            // 触发库存增加事件
            NotificationCenter.default.post(
                name: NSNotification.Name("ConsumableItemPurchased"),
                object: productID
            )

        case .nonRenewable, .autoRenewable, .trial:
            // 权益产品：更新 Tier 和激活权益
            await updateTierWithNewEntitlement(newEntitlement)
        }
    }
    
    /// 更新 Tier 和权益
    private func updateTierWithNewEntitlement(_ newEntitlement: Entitlement) async {
        // 检查是否需要升级或降级
        let oldTier = currentTier
        let newTier = newEntitlement.tier
        
        if newTier.powerLevel > oldTier.powerLevel {
            // 升级
            await handleTierUpgrade(from: oldTier, to: newTier, newEntitlement: newEntitlement)
        } else if newTier.powerLevel < oldTier.powerLevel {
            // 降级 (通常不会，除非用户取消订阅)
            // 这种情况由 checkTierExpiration 处理
        } else {
            // 同级延长
            await handleTierExtend(newEntitlement)
        }
        
        // 添加到活跃权益
        activeEntitlements.append(newEntitlement)
        
        // 应用权益
        applyActiveEntitlements()
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("TierUpdated"),
            object: ["from": oldTier, "to": newTier]
        )
    }
    
    /// 处理 Tier 升级
    /// 升级时两个选项：
    /// A. 延长不丧失：老权益时间 + 新权益时间
    /// B. 立即替换：仅保持新权益
    private func handleTierUpgrade(
        from oldTier: UserTier,
        to newTier: UserTier,
        newEntitlement: Entitlement
    ) async {
        // 方案 A (推荐)：延长不丧失
        // 新权益从老权益过期后激活
        
        if let oldExpiration = tierExpiration, oldExpiration > Date() {
            // 保留老权益的过期时间，新权益在其后激活
            print("📈 升级权益: \(oldTier.displayName) → \(newTier.displayName)")
            print("💡 继续享受 \(oldTier.displayName) 直到 \(oldExpiration.formatted())")
        }
        
        // 更新主 Tier 为最高级别
        currentTier = newTier
        
        // 如果新的过期时间更晚，更新过期时间
        if let newExpiration = newEntitlement.expiresAt,
           let oldExpiration = tierExpiration {
            if newExpiration > oldExpiration {
                tierExpiration = newExpiration
            }
        } else if tierExpiration == nil {
            tierExpiration = newEntitlement.expiresAt
        }
    }
    
    /// 处理 Tier 延长 (同一 Tier 但延长时长)
    private func handleTierExtend(_ newEntitlement: Entitlement) async {
        // 取最晚的过期时间
        if let newExpiration = newEntitlement.expiresAt {
            if let oldExpiration = tierExpiration {
                if newExpiration > oldExpiration {
                    tierExpiration = newExpiration
                    print("🔄 权益已延长至: \(newExpiration.formatted())")
                }
            } else {
                tierExpiration = newExpiration
            }
        }
    }
    
    /// 检查 Tier 是否过期，并处理降级
    private func checkTierExpiration() async {
        guard let expiration = tierExpiration else {
            return  // 无过期时间 = 永不过期
        }
        
        if Date() > expiration && currentTier != .free {
            // 权益已过期，降级到 Tier 0
            await handleTierDowngrade()
        }
    }
    
    /// 处理权益过期降级
    private func handleTierDowngrade() async {
        let previousTier = currentTier
        
        currentTier = .free
        tierExpiration = nil
        activeEntitlements.removeAll { !$0.isExpired }
        
        print("⬇️ 权益已过期，从 \(previousTier.displayName) 降级到免费用户")
        
        // 应用默认权益
        applyDefaultBenefits()
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("TierDowngraded"),
            object: previousTier
        )
        
        // 发送推送通知给用户
        await sendExpirationNotification(previousTier)
    }
    
    // MARK: - Apply Benefits to Game Systems (应用权益到游戏系统)
    
    /// 应用权益参数到游戏各个系统
    private func applyBenefitsToGameSystems(_ entitlement: Entitlement) {
        // 获取对应的 Tier 权益配置
        guard let tierBenefit = TierBenefit.getBenefit(for: entitlement.tier) else {
            LogError("❌ [权益] 无法找到 Tier 的权益配置")
            return
        }

        // 应用到建筑系统
        BuildingManager.shared.applyBuildingBenefit(tierBenefit)

        // 应用到生产系统
        ProductionManager.shared.applyProductionBenefit(tierBenefit)

        // 应用到背包系统
        InventoryManager.shared.applyInventoryBenefit(tierBenefit)
        
        // 应用到领地系统
        TerritoryManager.shared.applyTerritoryBenefit(tierBenefit)

        LogInfo("✅ [权益] 已应用 Tier \(entitlement.tier.displayNameShort) 权益到所有系统")
    }

    /// 应用默认权益 (Tier 0)
    private func applyDefaultBenefits() {
        // 重置所有权益加成为默认值
        BuildingManager.shared.resetBuildingBenefit()
        ProductionManager.shared.resetProductionBenefit()
        InventoryManager.shared.resetInventoryBenefit()
        TerritoryManager.shared.resetTerritoryBenefit()
        
        LogInfo("✅ [权益] 已重置所有系统为默认权益")
    }
    
    // MARK: - Monitoring (监听和定期检查)
    
    /// 启动过期监听��时器
    /// 每 120 秒检查一次权益是否过期和续费状态
    private func startExpirationWatcher() {
        expirationCheckTimer?.invalidate()

        expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkTierExpiration()
                await self?.checkAutoRenewalStatus()
            }
        }
    }
    
    /// 停止监听
    func stopExpirationWatcher() {
        expirationCheckTimer?.invalidate()
        expirationCheckTimer = nil
    }
    
    // MARK: - Notifications (消息通知)
    
    /// 发送权益过期通知
    private func sendExpirationNotification(_ tier: UserTier) async {
        let content = UNMutableNotificationContent()
        content.title = "权益已过期"
        content.body = "\(tier.displayName)权益已过期。升级新权益继续享受加成！"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Debug Methods
    
    /// 获取 Tier 系统状态摘要
    func getStatus() -> String {
        """
        === Tier 系统状态 ===
        当前 Tier: \(currentTier.displayName)
        过期时间: \(tierExpiration?.formatted() ?? "永不过期")
        活跃权益数: \(activeEntitlements.filter { $0.isActive }.count)
        剩余天数: \(tierExpiration.map { Int(max(0, $0.timeIntervalSinceNow / 86400)) } ?? 999)
        """
    }
    
    deinit {
        // 不能在deinit中直接调用main actor方法
        // Timer会自动清理，无需手动停止
        expirationCheckTimer?.invalidate()
        expirationCheckTimer = nil
    }
}

// MARK: - Placeholder System Managers (占位符系统管理器)
// 这些需要在实际 Xcode 项目中与真实系统集成

@MainActor
class BuildingSystemManager {
    static let shared = BuildingSystemManager()
    func applyBuildSpeedBonus(_ bonus: Double) {}
}

@MainActor
class ProductionSystemManager {
    static let shared = ProductionSystemManager()
    func applyProductionSpeedBonus(_ bonus: Double) {}
    func applyResourceOutputBonus(_ bonus: Double) {}
}

@MainActor
class BackpackSystemManager {
    static let shared = BackpackSystemManager()
    func addCapacityBonus(_ bonus: Int) {}
}

@MainActor
class ShopSystemManager {
    static let shared = ShopSystemManager()
    func applyDiscount(_ discount: Double) {}
}

@MainActor
class DefenseSystemManager {
    static let shared = DefenseSystemManager()
    func applyDefenseBonus(_ bonus: Double) {}
}

@MainActor
class QueueSystemManager {
    static let shared = QueueSystemManager()
    func enableUnlimitedQueues() {}
}
