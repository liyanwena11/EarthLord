import Foundation
import StoreKit

// MARK: - Product Identifiers (8 个产品 - 与 App Store Connect 一致)

enum IAPProductID: String, CaseIterable {
    // MARK: 消耗型产品 - App内购买项目 (4 个)
    case survivorPack = "com.liyanwen.EarthLord.supply.survivor"      // ¥6
    case explorerPack = "com.liyanwen.EarthLord.supply.explorer"      // ¥18
    case lordPack = "com.liyanwen.EarthLord.supply.lord"              // ¥38
    case overlordPack = "com.liyanwen.EarthLord.supply.overlord"      // ¥68

    // MARK: 订阅产品 - 探索者通行证 (2 个)
    case explorerMonthly = "com.liyanwen.EarthLord.explorer.monthly"  // ¥12/月
    case explorerYearly = "com.liyanwen.EarthLord.explorer.yearly"    // ¥88/年

    // MARK: 订阅产品 - 领主通行证 (2 个)
    case lordMonthly = "com.liyanwen.EarthLord.lord.monthly"          // ¥28/月
    case lordYearly = "com.liyanwen.EarthLord.lord.yearly"            // ¥168/年

    var displayName: String {
        switch self {
        // 消耗型产品
        case .survivorPack:
            return "幸存者补给包"
        case .explorerPack:
            return "探险家补给包"
        case .lordPack:
            return "领主补给包"
        case .overlordPack:
            return "霸主补给包"
        // 订阅产品 - 探索者
        case .explorerMonthly:
            return "探索者通行证月付"
        case .explorerYearly:
            return "探索者通行证年付"
        // 订阅产品 - 领主
        case .lordMonthly:
            return "领主通行证月付"
        case .lordYearly:
            return "领主通行证年付"
        }
    }

    var priceTier: String {
        switch self {
        case .survivorPack: return "¥6"
        case .explorerPack: return "¥18"
        case .lordPack: return "¥38"
        case .overlordPack: return "¥68"
        case .explorerMonthly: return "¥12/月"
        case .explorerYearly: return "¥88/年"
        case .lordMonthly: return "¥28/月"
        case .lordYearly: return "¥168/年"
        }
    }

    /// 获取对应的 Tier
    var tier: UserTier {
        switch self {
        case .survivorPack, .explorerPack, .lordPack, .overlordPack:
            return .free
        case .explorerMonthly, .explorerYearly:
            return .support
        case .lordMonthly, .lordYearly:
            return .lordship
        }
    }

    /// 获取对应的产品类型
    var subscriptionType: SubscriptionType {
        switch self {
        case .survivorPack, .explorerPack, .lordPack, .overlordPack:
            return .consumable
        case .explorerMonthly, .explorerYearly, .lordMonthly, .lordYearly:
            return .autoRenewable
        }
    }
}

// MARK: - Supply Pack Models

struct SupplyPack: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: String
    let productId: String
    let rarity: String
    let items: [PackItem]
    let guaranteedItems: [PackItem]

    var isPremium: Bool {
        rarity == "epic" || rarity == "legendary"
    }
}

// MARK: - StoreKit Product Wrapper

struct StoreProduct: Identifiable {
    let id: String
    let product: Product
    let supplyPack: SupplyPack?
    let isPlaceholder: Bool

    init(product: Product, supplyPack: SupplyPack? = nil, isPlaceholder: Bool = false) {
        self.id = product.id
        self.product = product
        self.supplyPack = supplyPack
        self.isPlaceholder = isPlaceholder
    }

    var displayName: String {
        supplyPack?.name ?? product.displayName
    }

    var price: String {
        return "\(product.displayPrice)"
    }

    var availableForPurchase: Bool {
        return !isPlaceholder
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success(Product)
    case pending
    case cancelled
    case failed(Error)
}

// MARK: - IAP Error

enum IAPError: Error, LocalizedError {
    case productNotAvailable
    case purchaseFailed
    case restoreFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return "商品不可用"
        case .purchaseFailed:
            return "购买失败"
        case .restoreFailed:
            return "恢复购买失败"
        case .notAuthenticated:
            return "用户未登录"
        }
    }
}
