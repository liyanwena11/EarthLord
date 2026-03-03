import Foundation
import SwiftUI

// MARK: - Subscription Period (订阅周期)

/// 订阅周期：月付或年付
enum SubscriptionPeriod: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .monthly:
            return "月付"
        case .yearly:
            return "年付"
        }
    }

    var shortName: String {
        switch self {
        case .monthly:
            return "月"
        case .yearly:
            return "年"
        }
    }
}

// MARK: - Subscription Product Group (订阅产品组)

/// 订阅产品组 - 新的4产品订阅系统
/// 每个产品���包含月付、年付、试用三种选项
struct SubscriptionProductGroup: Identifiable {
    let id: String                     // 产品组 ID
    let displayName: String             // 显示名称
    let displayNameShort: String        // 简短名称
    let tier: UserTier                  // 对应的 Tier
    let icon: String                    // 图标 emoji
    let iconColor: Color                // 图标颜色
    let description: String             // 产品描述

    // 产品 ID
    let monthlyProductID: String        // 月付产品 ID
    let yearlyProductID: String         // 年付产品 ID
    let trialProductID: String?         // 试用产品 ID (可选)

    // 价格信息 (人民币 - 元)
    let monthlyPrice: Int               // 月付价格
    let yearlyPrice: Int                // 年付价格
    let trialDays: Int?                 // 试用天数

    // 权益信息
    let benefits: SubscriptionBenefits  // 权益详情

    /// 是否有试用选项
    var hasTrial: Bool {
        trialProductID != nil
    }

    /// 年付节省金额
    var yearlySavings: Int {
        monthlyPrice * 12 - yearlyPrice
    }

    /// 年付折扣百分比
    var yearlyDiscountPercentage: Int {
        guard monthlyPrice > 0 else { return 0 }
        let fullPrice = monthlyPrice * 12
        return Int((Double(fullPrice - yearlyPrice) / Double(fullPrice)) * 100)
    }

    /// 获取所有产品 ID
    var allProductIDs: [String] {
        var ids = [monthlyProductID, yearlyProductID]
        if let trialID = trialProductID {
            ids.append(trialID)
        }
        return ids
    }
}

// MARK: - Subscription Benefits (订阅权益)

/// 订阅权益详情 - 用于展示6项核心权益
struct SubscriptionBenefits {
    // 6项核心权益
    let buildSpeedBonus: String         // 建造加速
    let productionSpeedBonus: String    // 生产加速
    let resourceBonus: String           // 资源加成
    let backpackCapacity: String        // 背包容量
    let shopDiscount: String            // 商店折扣
    let specialFeatures: [String]       // 特殊功能列表

    /// 创建权益详情
    static func from(tierBenefit: TierBenefit) -> SubscriptionBenefits {
        let buildSpeed = tierBenefit.buildSpeedBonus > 0
            ? "+\(Int(tierBenefit.buildSpeedBonus * 100))%"
            : "无"
        let productionSpeed = tierBenefit.productionSpeedBonus > 0
            ? "+\(Int(tierBenefit.productionSpeedBonus * 100))%"
            : "无"
        let resource = tierBenefit.resourceOutputBonus > 0
            ? "+\(Int(tierBenefit.resourceOutputBonus * 100))%"
            : "无"
        let backpack = tierBenefit.backpackCapacityBonus > 0
            ? "+\(tierBenefit.backpackCapacityBonus)kg"
            : "无"
        let discount = tierBenefit.shopDiscountPercentage > 0
            ? "\(Int(tierBenefit.shopDiscountPercentage))% OFF"
            : "无"

        var features: [String] = []
        if tierBenefit.hasVIPBadge { features.append("VIP名牌") }
        if tierBenefit.hasWeeklyChallenge { features.append("每周挑战") }
        if tierBenefit.hasMonthlyChallenge { features.append("每月挑战") }
        if tierBenefit.hasMonthlyLootBox { features.append("每月宝箱") }
        if tierBenefit.hasUnlimitedQueues { features.append("无限队列") }
        if tierBenefit.has24hSupport { features.append("24h客服") }
        if tierBenefit.tradeFeeDiscount > 0 {
            features.append("交易费-\(Int(tierBenefit.tradeFeeDiscount * 100))%")
        }

        return SubscriptionBenefits(
            buildSpeedBonus: buildSpeed,
            productionSpeedBonus: productionSpeed,
            resourceBonus: resource,
            backpackCapacity: backpack,
            shopDiscount: discount,
            specialFeatures: features
        )
    }
}

// MARK: - Subscription Product Groups (4个产品组定义)

/// 4个订阅产品组的完整定义
enum SubscriptionProductGroups {
    // MARK: - Free Tier (免费版)

    static let freePass = SubscriptionProductGroup(
        id: "free_pass",
        displayName: "免费版",
        displayNameShort: "免费",
        tier: .free,
        icon: "⭕",
        iconColor: .gray,
        description: "基础游戏体验",
        monthlyProductID: "free.pass.month",
        yearlyProductID: "free.pass.year",
        trialProductID: nil,
        monthlyPrice: 0,
        yearlyPrice: 0,
        trialDays: nil,
        benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier0)
    )

    // MARK: - Explorer Pass (探索者通行证)

    static let explorerPass = SubscriptionProductGroup(
        id: "explorer_pass",
        displayName: "探索者通行证",
        displayNameShort: "探索者",
        tier: .support,
        icon: "🔵",
        iconColor: .blue,
        description: "适合新手玩家，快速起步",
        monthlyProductID: "com.liyanwen.EarthLord.explorer.monthly",
        yearlyProductID: "com.liyanwen.EarthLord.explorer.yearly",
        trialProductID: nil,
        monthlyPrice: 12,
        yearlyPrice: 88,
        trialDays: 7,
        benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier1)
    )

    // MARK: - Lord Pass (领主通行证) - 推荐

    static let lordPass = SubscriptionProductGroup(
        id: "lord_pass",
        displayName: "领主通行证",
        displayNameShort: "领主",
        tier: .lordship,
        icon: "🟣",
        iconColor: .purple,
        description: "中级玩家首选，全面加成",
        monthlyProductID: "com.liyanwen.EarthLord.lord.monthly",
        yearlyProductID: "com.liyanwen.EarthLord.lord.yearly",
        trialProductID: nil,
        monthlyPrice: 28,
        yearlyPrice: 168,
        trialDays: 7,
        benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier2)
    )

    // MARK: - Apocalypse Pass (末日通行证)

    static let apocalypsePass = SubscriptionProductGroup(
        id: "apocalypse_pass",
        displayName: "末日通行证",
        displayNameShort: "末日",
        tier: .empire,
        icon: "🔴",
        iconColor: .red,
        description: "高级玩家专享，最强权益",
        monthlyProductID: "com.earthlord.sub.apocalypse.monthly",
        yearlyProductID: "com.earthlord.sub.apocalypse.yearly",
        trialProductID: "com.earthlord.sub.apocalypse.trial",
        monthlyPrice: 50,
        yearlyPrice: 328,
        trialDays: 7,
        benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier3)
    )

    // MARK: - VIP Pass (VIP会员)

    static let vipPass = SubscriptionProductGroup(
        id: "vip_pass",
        displayName: "VIP会员",
        displayNameShort: "VIP",
        tier: .vip,
        icon: "⭐",
        iconColor: Color(red: 1.0, green: 0.84, blue: 0),
        description: "持续订阅尊享，交易费折扣",
        monthlyProductID: "vip.pass.month",
        yearlyProductID: "vip.pass.year",
        trialProductID: "vip.trial",
        monthlyPrice: 12,
        yearlyPrice: 88,
        trialDays: 7,
        benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tierVIP)
    )

    // MARK: - All Products (所有产品组)

    /// 所有产品组 (只保留: Free, Explorer, Lord)
    static var all: [SubscriptionProductGroup] {
        [freePass, explorerPass, lordPass]
    }

    /// 可购买的订阅产品组 (不含免费版)
    static var purchasable: [SubscriptionProductGroup] {
        [explorerPass, lordPass]
    }

    /// 按产品 ID 查找产品组
    static func group(for productID: String) -> SubscriptionProductGroup? {
        all.first { group in
            group.allProductIDs.contains(productID)
        }
    }

    /// 按 Tier 查找产品组
    static func group(for tier: UserTier) -> SubscriptionProductGroup? {
        all.first { $0.tier == tier }
    }

    /// 获取所有产品 ID
    static var allProductIDs: [String] {
        all.flatMap { $0.allProductIDs }
    }

    /// 获取所有试用产品 ID
    static var allTrialProductIDs: [String] {
        all.compactMap { $0.trialProductID }
    }

    /// 获取所有订阅产品 ID (不包括试用)
    static var allSubscriptionProductIDs: [String] {
        all.flatMap { [$0.monthlyProductID, $0.yearlyProductID] }
    }
}

// MARK: - Product Type Extension (产品类型扩展)

extension SubscriptionProductGroup {
    /// 获取产品类型
    enum ProductType {
        case monthly
        case yearly
        case trial
    }

    /// 根据 ID 判断产品类型
    func getProductType(for productID: String) -> ProductType? {
        if productID == monthlyProductID {
            return .monthly
        } else if productID == yearlyProductID {
            return .yearly
        } else if productID == trialProductID {
            return .trial
        }
        return nil
    }

    /// 获取产品显示名称
    func getProductDisplayName(for productID: String) -> String? {
        guard let type = getProductType(for: productID) else {
            return nil
        }

        switch type {
        case .monthly:
            return "\(displayNameShort) 月付"
        case .yearly:
            return "\(displayNameShort) 年付"
        case .trial:
            return "\(displayNameShort) 试用"
        }
    }

    /// 获取产品价格
    func getProductPrice(for productID: String) -> Int? {
        guard let type = getProductType(for: productID) else {
            return nil
        }

        switch type {
        case .monthly:
            return monthlyPrice
        case .yearly:
            return yearlyPrice
        case .trial:
            return 0
        }
    }

    /// 获取产品时长 (天数)
    func getProductDuration(for productID: String) -> Int? {
        guard let type = getProductType(for: productID) else {
            return nil
        }

        switch type {
        case .monthly:
            return 30
        case .yearly:
            return 365
        case .trial:
            return trialDays
        }
    }

    /// 是否为试用产品
    func isTrialProduct(_ productID: String) -> Bool {
        productID == trialProductID
    }

    /// 是否为订阅产品 (非试用)
    func isSubscriptionProduct(_ productID: String) -> Bool {
        productID == monthlyProductID || productID == yearlyProductID
    }
}

// MARK: - App Store Connect Configuration Helper

/// App Store Connect 配置助手
/// 用于生成 App Store Connect 的产品配置清单
enum AppStoreConnectConfig {
    static var configurationList: String {
        """
        # App Store Connect 产品配置清单 - 末日通行证系统

        ## 订阅组配置 (2个付费订阅组)

        ### 1. 探索者通行证 (Explorer Pass)
        - 产品 ID: com.earthlord.sub.explorer.monthly
        - 类型: 自动续费订阅
        - 价格: ¥12/月 ($1.99)

        - 产品 ID: com.earthlord.sub.explorer.yearly
        - 类型: 自动续费订阅
        - 价格: ¥88/年 ($11.99) - 省39%

        - 产品 ID: com.earthlord.sub.explorer.trial
        - 类型: 免费试用
        - 试用时长: 7天

        ### 2. 领主通行证 (Lord Pass) - 推荐
        - 产品 ID: com.earthlord.sub.lord.monthly
        - 类型: 自动续费订阅
        - 价格: ¥28/月 ($4.49)

        - 产品 ID: com.earthlord.sub.lord.yearly
        - 类型: 自动续费订阅
        - 价格: ¥188/年 ($26.99) - 省44%

        - 产品 ID: com.earthlord.sub.lord.trial
        - 类型: 免费试用
        - 试用时长: 7天

        ---
        总计: 2个订阅组, 6个产品 + 1个免费版
        """
    }
}
