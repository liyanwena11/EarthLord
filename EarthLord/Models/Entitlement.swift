import Foundation

// MARK: - Entitlement (权益)

/// 用户权益记录 - 记录用户获得的具体权益
struct Entitlement: Codable, Identifiable {
    let id: String
    
    // 基础信息
    let entitlementID: String           // 权益 ID
    let userID: String                  // 用户 ID
    let productID: String               // 对应的产品 ID
    let tier: UserTier                  // 权益等级
    let subscriptionType: SubscriptionType
    
    // 时间信息
    let activatedAt: Date               // 激活时间
    let expiresAt: Date?                // 过期时间 (nil = 永不过期)
    
    // 权益数据 (缓存)
    let buildSpeedBonus: Double
    let productionSpeedBonus: Double
    let resourceOutputBonus: Double
    let backpackCapacityBonus: Int
    let shopDiscountPercentage: Double
    let defenseBonus: Double
    
    // 特殊权益标记
    let hasVIPBadge: Bool
    let hasWeeklyChallenge: Bool
    let hasMonthlyChallenge: Bool
    let hasMonthlyLootBox: Bool
    let hasUnlimitedQueues: Bool
    let has24hSupport: Bool
    let teleportDailyLimit: Int
    let monthlySupplyVoucher: Int
    
    // MARK: - Computed Properties
    
    /// 是否已过期
    var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false  // 永不过期
        }
        return Date() > expiresAt
    }
    
    /// 剩余时长 (天数)
    var remainingDays: Int {
        guard let expiresAt = expiresAt else {
            return Int.max  // 永不过期 = 无限
        }
        
        let interval = expiresAt.timeIntervalSince(Date())
        if interval <= 0 {
            return 0
        }
        return Int(ceil(interval / 86400))  // 转换为天数
    }
    
    /// 是否活跃 (未过期)
    var isActive: Bool {
        !isExpired
    }
    
    /// 权益强度级别 (用于多个权益时选择最强的)
    var powerLevel: Int {
        tier.powerLevel
    }
    
    /// 创建 Entitlement 从 TierBenefit
    static func from(
        tier: UserTier,
        benefit: TierBenefit,
        productID: String,
        subscriptionType: SubscriptionType,
        userID: String,
        durationDays: Int? = nil
    ) -> Entitlement {
        let expiresAt: Date?
        
        switch subscriptionType {
        case .consumable:
            expiresAt = nil  // 消耗品不过期
        case .nonRenewable, .autoRenewable, .trial:
            let days = durationDays ?? 30
            expiresAt = Calendar.current.date(byAdding: .day, value: days, to: Date())
        }
        
        return Entitlement(
            id: UUID().uuidString,
            entitlementID: UUID().uuidString,
            userID: userID,
            productID: productID,
            tier: tier,
            subscriptionType: subscriptionType,
            activatedAt: Date(),
            expiresAt: expiresAt,
            buildSpeedBonus: benefit.buildSpeedBonus,
            productionSpeedBonus: benefit.productionSpeedBonus,
            resourceOutputBonus: benefit.resourceOutputBonus,
            backpackCapacityBonus: benefit.backpackCapacityBonus,
            shopDiscountPercentage: benefit.shopDiscountPercentage,
            defenseBonus: benefit.defenseBonus,
            hasVIPBadge: benefit.hasVIPBadge,
            hasWeeklyChallenge: benefit.hasWeeklyChallenge,
            hasMonthlyChallenge: benefit.hasMonthlyChallenge,
            hasMonthlyLootBox: benefit.hasMonthlyLootBox,
            hasUnlimitedQueues: benefit.hasUnlimitedQueues,
            has24hSupport: benefit.has24hSupport,
            teleportDailyLimit: benefit.teleportDailyLimit,
            monthlySupplyVoucher: benefit.monthlySupplyVoucher
        )
    }
}

// MARK: - 16 Products Complete Definition (16 个完整产品定义)

/// 所有 16 个 IAP 产品的完整定义库
struct All16Products {
    // MARK: - Group 1: Consumable Products (4 个消耗品)
    
    /// 消耗品集合 - 一次性购买, 不自动续费
    static let consumables: [IAPProduct] = [
        IAPProduct(
            id: "com.earthlord.supply.survivor",
            displayName: "生存者补给",
            tier: .free,
            type: .consumable,
            priceInYuan: 6,
            durationDays: nil,
            duration: nil
        ),
        IAPProduct(
            id: "com.earthlord.supply.explorer",
            displayName: "探险家补给",
            tier: .free,
            type: .consumable,
            priceInYuan: 18,
            durationDays: nil,
            duration: nil
        ),
        IAPProduct(
            id: "com.earthlord.supply.lord",
            displayName: "领主补给",
            tier: .free,
            type: .consumable,
            priceInYuan: 30,
            durationDays: nil,
            duration: nil
        ),
        IAPProduct(
            id: "com.earthlord.supply.overlord",
            displayName: "霸主补给",
            tier: .free,
            type: .consumable,
            priceInYuan: 68,
            durationDays: nil,
            duration: nil
        ),
    ]
    
    // MARK: - Group 2: Tier 1 - Support (Explorer Pass, 3 个)

    static let tier1Products: [IAPProduct] = [
        IAPProduct(
            id: "com.earthlord.support.1m",
            displayName: "Explorer Pass Monthly",
            tier: .support,
            type: .nonRenewable,
            priceInYuan: 35,
            durationDays: 30,
            duration: .oneMonth
        ),
        IAPProduct(
            id: "com.earthlord.support.3m",
            displayName: "Explorer Pass Quarterly",
            tier: .support,
            type: .nonRenewable,
            priceInYuan: 88,
            durationDays: 90,
            duration: .threeMonths
        ),
        IAPProduct(
            id: "com.earthlord.support.1y",
            displayName: "Explorer Pass Yearly",
            tier: .support,
            type: .nonRenewable,
            priceInYuan: 280,
            durationDays: 365,
            duration: .oneYear
        ),
    ]

    // MARK: - Group 3: Tier 2 - Lordship (Lord Pass, 3 个)

    static let tier2Products: [IAPProduct] = [
        IAPProduct(
            id: "com.earthlord.lordship.1m",
            displayName: "Lord Pass Monthly",
            tier: .lordship,
            type: .nonRenewable,
            priceInYuan: 70,
            durationDays: 30,
            duration: .oneMonth
        ),
        IAPProduct(
            id: "com.earthlord.lordship.3m",
            displayName: "Lord Pass Quarterly",
            tier: .lordship,
            type: .nonRenewable,
            priceInYuan: 168,
            durationDays: 90,
            duration: .threeMonths
        ),
        IAPProduct(
            id: "com.earthlord.lordship.1y",
            displayName: "Lord Pass Yearly",
            tier: .lordship,
            type: .nonRenewable,
            priceInYuan: 560,
            durationDays: 365,
            duration: .oneYear
        ),
    ]
    
    // MARK: - Group 4: Tier 3 - Empire (帝国统治, 3 个)
    
    static let tier3Products: [IAPProduct] = [
        IAPProduct(
            id: "com.earthlord.empire.1m",
            displayName: "帝国统治 30 天",
            tier: .empire,
            type: .nonRenewable,
            priceInYuan: 38,
            durationDays: 30,
            duration: .oneMonth
        ),
        IAPProduct(
            id: "com.earthlord.empire.3m",
            displayName: "帝国统治 90 天",
            tier: .empire,
            type: .nonRenewable,
            priceInYuan: 88,
            durationDays: 90,
            duration: .threeMonths
        ),
        IAPProduct(
            id: "com.earthlord.empire.1y",
            displayName: "帝国统治年卡",
            tier: .empire,
            type: .nonRenewable,
            priceInYuan: 298,
            durationDays: 365,
            duration: .oneYear
        ),
    ]
    
    // MARK: - Group 5: VIP - Auto Renewable (VIP 续期, 3 个)
    
    static let vipProducts: [IAPProduct] = [
        IAPProduct(
            id: "com.earthlord.vip.monthly",
            displayName: "VIP 月会员",
            tier: .vip,
            type: .autoRenewable,
            priceInYuan: 12,
            durationDays: 30,
            duration: .oneMonth
        ),
        IAPProduct(
            id: "com.earthlord.vip.quarterly",
            displayName: "VIP 季会员",
            tier: .vip,
            type: .autoRenewable,
            priceInYuan: 28,
            durationDays: 90,
            duration: .threeMonths
        ),
        IAPProduct(
            id: "com.earthlord.vip.annual",
            displayName: "VIP 年会员",
            tier: .vip,
            type: .autoRenewable,
            priceInYuan: 88,
            durationDays: 365,
            duration: .oneYear
        ),
    ]
    
    // MARK: - All Products (所有 16 个产品)
    
    /// 所有 16 个产品集合
    static var all: [IAPProduct] {
        consumables + tier1Products + tier2Products + tier3Products + vipProducts
    }
    
    /// 按产品 ID 快速查找
    static func product(for productID: String) -> IAPProduct? {
        all.first { $0.id == productID }
    }
    
    /// 按 Tier 过滤产品
    static func products(for tier: UserTier) -> [IAPProduct] {
        all.filter { $0.tier == tier }
    }
    
    /// 按类型过滤产品
    static func products(for type: SubscriptionType) -> [IAPProduct] {
        all.filter { $0.type == type }
    }
    
    /// 获取产品对应的益处
    static func benefit(for productID: String) -> TierBenefit? {
        guard let product = product(for: productID) else {
            return nil
        }
        
        switch product.tier {
        case .free:
            return TierBenefitConfig.tier0
        case .support:
            return TierBenefitConfig.tier1
        case .lordship:
            return TierBenefitConfig.tier2
        case .empire:
            return TierBenefitConfig.tier3
        case .vip:
            return TierBenefitConfig.tierVIP
        }
    }
    
    // MARK: - Product Statistics
    
    /// 16 个产品统计信息
    static var statistics: String {
        """
        EarthLord 16 产品统计:
        ├─ 消耗品: \(consumables.count) 个 (¥\(consumables.map { $0.priceInYuan }.reduce(0, +)))
        ├─ Tier 1: \(tier1Products.count) 个 (¥\(tier1Products.map { $0.priceInYuan }.reduce(0, +)))
        ├─ Tier 2: \(tier2Products.count) 个 (¥\(tier2Products.map { $0.priceInYuan }.reduce(0, +)))
        ├─ Tier 3: \(tier3Products.count) 个 (¥\(tier3Products.map { $0.priceInYuan }.reduce(0, +)))
        └─ VIP: \(vipProducts.count) 个 (¥\(vipProducts.map { $0.priceInYuan }.reduce(0, +))/月)
        
        总计: \(all.count) 个产品
        """
    }
}

// MARK: - Product Lookup Extensions

extension String {
    /// 快速查找产品
    func toIAPProduct() -> IAPProduct? {
        All16Products.product(for: self)
    }
    
    /// 快速查找权益
    func toTierBenefit() -> TierBenefit? {
        All16Products.benefit(for: self)
    }
}
