import Foundation
import SwiftUI

// MARK: - User Tier Definition (用户等级定义)

/// 用户 Tier 等级 - 核心枚举定义
/// Tier 0: 免费用户 (无权益)
/// Tier 1: 快速支援 (基础权益)
/// Tier 2: 领主权益 (中级权益)
/// Tier 3: 帝国统治 (高级权益)
/// Tier 4: VIP 会员 (持续订阅)
enum UserTier: Int, Codable, Hashable {
    case free = 0           // 免费用户
    case support = 1        // 快速支援
    case lordship = 2       // 领主权益
    case empire = 3         // 帝国统治
    case vip = 4            // VIP 会员
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .free:
            return "基础用户"
        case .support:
            return "快速支援"
        case .lordship:
            return "领主权益"
        case .empire:
            return "帝国统治"
        case .vip:
            return "VIP会员"
        }
    }
    
    var displayNameShort: String {
        switch self {
        case .free:
            return "免费"
        case .support:
            return "Tier 1"
        case .lordship:
            return "Tier 2"
        case .empire:
            return "Tier 3"
        case .vip:
            return "VIP"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .free:
            return .gray
        case .support:
            return .blue
        case .lordship:
            return .purple
        case .empire:
            return .red
        case .vip:
            return Color(red: 1.0, green: 0.84, blue: 0)  // 金色
        }
    }
    
    var badgeEmoji: String {
        switch self {
        case .free:
            return "⭕"
        case .support:
            return "🔵"
        case .lordship:
            return "🟣"
        case .empire:
            return "🔴"
        case .vip:
            return "⭐"
        }
    }
    
    // MARK: - Tier Properties
    
    /// 权益等级 (用于权益比较, 数值越高权益越多)
    var powerLevel: Int {
        self.rawValue
    }
    
    /// 是否为付费用户
    var isPaidTier: Bool {
        self != .free
    }
    
    /// 是否有续费 (仅 VIP)
    var isAutoRenewable: Bool {
        self == .vip
    }
    
    /// 获取下一个 Tier
    var nextTier: UserTier? {
        switch self {
        case .free:
            return .support
        case .support:
            return .lordship
        case .lordship:
            return .empire
        case .empire:
            return .vip
        case .vip:
            return nil
        }
    }
    
    /// 获取上一个 Tier
    var previousTier: UserTier? {
        switch self {
        case .free:
            return nil
        case .support:
            return .free
        case .lordship:
            return .support
        case .empire:
            return .lordship
        case .vip:
            return .empire
        }
    }
}

// MARK: - Trial Status (试用状态)

/// 试用状态枚举 - 用于跟踪用户试用状态
enum TrialStatus: String, Codable {
    case notStarted           // 未开始试用
    case active               // 试用进行中
    case expired              // 试用已过期
    case converted            // 已转正 (试用期间购买正式订阅)
    case cancelled            // 试用已取消

    var displayName: String {
        switch self {
        case .notStarted:
            return "未开始"
        case .active:
            return "试用中"
        case .expired:
            return "已过期"
        case .converted:
            return "已转正"
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

    var isUsed: Bool {
        switch self {
        case .converted, .expired, .cancelled:
            return true
        case .notStarted, .active:
            return false
        }
    }
}

// MARK: - Subscription Type

/// 订阅产品类型
enum SubscriptionType: String, Codable {
    case consumable              // 消耗性 (一次性购买)
    case nonRenewable           // 非续期 (购买后不自动续费)
    case autoRenewable          // 自动续期 (自动续费)
    case trial                  // 试用 (新增)

    var displayName: String {
        switch self {
        case .consumable:
            return "消耗性物品"
        case .nonRenewable:
            return "限时权益"
        case .autoRenewable:
            return "持续订阅"
        case .trial:
            return "免费试用"
        }
    }
}

// MARK: - Entitlement Expiration Type

/// 权益过期类型
enum EntitlementExpirationType {
    case noExpiration           // 不过期 (消耗性物品)
    case expiresAfterDays(Int)  // N 天后过期 (非续期)
    case autoRenews             // 自动续费 (VIP)
    
    var durationDays: Int? {
        switch self {
        case .noExpiration:
            return nil
        case .expiresAfterDays(let days):
            return days
        case .autoRenews:
            return 30  // 默认 30 天续费周期
        }
    }
}

// MARK: - Product Duration

/// 产品时长选项
enum ProductDuration: Int, Codable {
    case oneMonth = 30
    case threeMonths = 90
    case oneYear = 365
    
    var displayName: String {
        switch self {
        case .oneMonth:
            return "30天"
        case .threeMonths:
            return "90天"
        case .oneYear:
            return "365天"
        }
    }
    
    var displayNameShort: String {
        switch self {
        case .oneMonth:
            return "1月"
        case .threeMonths:
            return "3月"
        case .oneYear:
            return "1年"
        }
    }
}

// MARK: - IAP Product Definition

/// IAP 产品完整定义
struct IAPProduct: Identifiable, Codable {
    let id: String              // 产品 ID (com.earthlord.*)
    let displayName: String     // 显示名称
    let tier: UserTier          // 关联的 Tier 等级
    let type: SubscriptionType  // 产品类型
    let priceInYuan: Int        // 价格 (单位: 元)
    let durationDays: Int?      // 时长 (天), nil = 一次性 (消耗品)
    let duration: ProductDuration?  // 如果是时长产品
    
    // 可计算属性
    var displayPrice: String {
        "\(priceInYuan)元"
    }
    
    var isConsumable: Bool {
        type == .consumable
    }
    
    var isSubscription: Bool {
        type == .nonRenewable || type == .autoRenewable
    }
}

// MARK: - Tier 权益预设 (定义每个 Tier 的权益数据)

struct TierBenefitConfig {
    // MARK: - Tier 0: Free (无权益)
    static let tier0 = TierBenefit(
        tier: .free,
        buildSpeedBonus: 0,
        productionSpeedBonus: 0,
        resourceOutputBonus: 0,
        backpackCapacityBonus: 0,
        shopDiscountPercentage: 0,
        defenseBonus: 0,
        tradeFeeDiscount: 0,
        hasVIPBadge: false,
        hasWeeklyChallenge: false,
        hasMonthlyChallenge: false,
        hasMonthlyLootBox: false,
        hasUnlimitedQueues: false,
        has24hSupport: false,
        teleportDailyLimit: 0,
        monthlySupplyVoucher: 0
    )
    
    // MARK: - Tier 1: Support (快速支援)
    static let tier1 = TierBenefit(
        tier: .support,
        buildSpeedBonus: 0.20,           // 建造时间 -20%
        productionSpeedBonus: 0.15,      // 生产时间 -15%
        resourceOutputBonus: 0,           // 资源产出 +0%
        backpackCapacityBonus: 25,        // 背包容量 +25kg
        shopDiscountPercentage: 10,       // 商店折扣 10%
        defenseBonus: 0,                  // 防御加成 0%
        tradeFeeDiscount: 0,
        hasVIPBadge: false,
        hasWeeklyChallenge: false,
        hasMonthlyChallenge: false,
        hasMonthlyLootBox: false,
        hasUnlimitedQueues: false,
        has24hSupport: false,
        teleportDailyLimit: 3,            // 每日传送 3 次
        monthlySupplyVoucher: 0
    )
    
    // MARK: - Tier 2: Lordship (领主权益)
    static let tier2 = TierBenefit(
        tier: .lordship,
        buildSpeedBonus: 0.40,            // 建造时间 -40%
        productionSpeedBonus: 0.30,       // 生产时间 -30%
        resourceOutputBonus: 0.20,        // 资源产出 +20%
        backpackCapacityBonus: 50,        // 背包容量 +50kg
        shopDiscountPercentage: 20,       // 商店折扣 20%
        defenseBonus: 0,
        tradeFeeDiscount: 0,
        hasVIPBadge: true,
        hasWeeklyChallenge: true,
        hasMonthlyChallenge: false,
        hasMonthlyLootBox: false,
        hasUnlimitedQueues: false,
        has24hSupport: false,
        teleportDailyLimit: 3,
        monthlySupplyVoucher: 0
    )
    
    // MARK: - Tier 3: Empire (帝国统治)
    static let tier3 = TierBenefit(
        tier: .empire,
        buildSpeedBonus: 0.60,            // 建造时间 -60%
        productionSpeedBonus: 0.50,       // 生产时间 -50%
        resourceOutputBonus: 0.40,        // 资源产出 +40%
        backpackCapacityBonus: 100,       // 背包容量 +100kg
        shopDiscountPercentage: 20,       // 商店折扣 20%
        defenseBonus: 0.15,               // 防御加成 +15%
        tradeFeeDiscount: 0,
        hasVIPBadge: true,
        hasWeeklyChallenge: true,
        hasMonthlyChallenge: true,
        hasMonthlyLootBox: true,
        hasUnlimitedQueues: true,
        has24hSupport: true,
        teleportDailyLimit: 3,
        monthlySupplyVoucher: 50
    )
    
    // MARK: - Tier 4: VIP (VIP 会员)
    // VIP = Tier 1 权益 + VIP 续费机制 + 20% 交易手续费折扣
    static let tierVIP = TierBenefit(
        tier: .vip,
        buildSpeedBonus: 0.20,
        productionSpeedBonus: 0.15,
        resourceOutputBonus: 0,
        backpackCapacityBonus: 25,
        shopDiscountPercentage: 10,
        defenseBonus: 0,
        tradeFeeDiscount: 0.20,           // VIP: 交易手续费 -20%
        hasVIPBadge: true,
        hasWeeklyChallenge: false,
        hasMonthlyChallenge: false,
        hasMonthlyLootBox: true,          // VIP 独有: 月度物资箱
        hasUnlimitedQueues: false,
        has24hSupport: false,
        teleportDailyLimit: 3,
        monthlySupplyVoucher: 0
    )
}

// MARK: - Tier Benefit Model

/// Tier 权益完整定义
struct TierBenefit: Codable {
    let tier: UserTier
    
    // 游戏权益
    let buildSpeedBonus: Double          // 建造速度加成 (%)
    let productionSpeedBonus: Double     // 生产速度加成 (%)
    let resourceOutputBonus: Double      // 资源产出加成 (%)
    let backpackCapacityBonus: Int       // 背包容量加成 (kg)
    let shopDiscountPercentage: Double   // 店铺折扣 (%)
    let defenseBonus: Double             // 防御加成 (%)
    let tradeFeeDiscount: Double         // 交易手续费折扣 (%) - Day 9 新增
    
    // 特殊权益
    let hasVIPBadge: Bool                // VIP 名牌
    let hasWeeklyChallenge: Bool         // 每周挑战
    let hasMonthlyChallenge: Bool        // 每月挑战
    let hasMonthlyLootBox: Bool          // 每月物资箱
    let hasUnlimitedQueues: Bool         // 无限队列
    let has24hSupport: Bool              // 24/7 客服
    let teleportDailyLimit: Int          // 每日传送限制
    let monthlySupplyVoucher: Int        // 月度补给券 (¥)
    
    // 便利属性
    var displayName: String {
        return tier.displayName
    }
    
    var powerLevel: Int {
        return tier.powerLevel
    }
    
    // MARK: - Multiplier Conversions (用于游戏系统)
    
    /// 建筑加速倍数 (>1.0 表示加速)
    var buildSpeedMultiplier: Double {
        guard buildSpeedBonus > 0 else { return 1.0 }
        return 1.0 / (1.0 - buildSpeedBonus)
    }
    
    /// 生产加速倍数 (>1.0 表示加速)
    var productionSpeedMultiplier: Double {
        guard productionSpeedBonus > 0 else { return 1.0 }
        return 1.0 / (1.0 - productionSpeedBonus)
    }
    
    /// 背包容量加成 (kg)
    var inventoryCapacityBonus: Int {
        return backpackCapacityBonus
    }
    
    // MARK: - Static Methods
    
    /// 根据 Tier 类型获取对应权益
    static func getBenefit(for tier: UserTier) -> TierBenefit? {
        switch tier {
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
    
    /// 根据 Tier ID 字符串获取对应权益
    static func getBenefit(for tierId: String) -> TierBenefit? {
        // 支持多种 ID 格式
        switch tierId.lowercased() {
        case "free", "0":
            return TierBenefitConfig.tier0
        case "support", "tier1", "1":
            return TierBenefitConfig.tier1
        case "lordship", "tier2", "2":
            return TierBenefitConfig.tier2
        case "empire", "tier3", "3":
            return TierBenefitConfig.tier3
        case "vip", "4":
            return TierBenefitConfig.tierVIP
        default:
            return nil
        }
    }
}
