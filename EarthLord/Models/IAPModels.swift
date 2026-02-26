import Foundation
import StoreKit

// MARK: - Extended Product Identifiers (16 个产品完整定义)

enum IAPProductID: String, CaseIterable {
    // MARK: Consumables (消耗品, 4 个)
    case survivorPack = "com.earthlord.supply.survivor"
    case explorerPack = "com.earthlord.supply.explorer"
    case lordPack = "com.earthlord.supply.lord"
    case overlordPack = "com.earthlord.supply.overlord"
    
    // MARK: Tier 1 - Support (快速支援, 3 个)
    case support1m = "com.earthlord.support.1m"
    case support3m = "com.earthlord.support.3m"
    case support1y = "com.earthlord.support.1y"
    
    // MARK: Tier 2 - Lordship (领主权益, 3 个)
    case lordship1m = "com.earthlord.lordship.1m"
    case lordship3m = "com.earthlord.lordship.3m"
    case lordship1y = "com.earthlord.lordship.1y"
    
    // MARK: Tier 3 - Empire (帝国统治, 3 个)
    case empire1m = "com.earthlord.empire.1m"
    case empire3m = "com.earthlord.empire.3m"
    case empire1y = "com.earthlord.empire.1y"
    
    // MARK: VIP - Auto Renewable (VIP 续期, 3 个)
    case vipMonthly = "com.earthlord.vip.monthly"
    case vipQuarterly = "com.earthlord.vip.quarterly"
    case vipAnnual = "com.earthlord.vip.annual"
    
    var displayName: String {
        switch self {
        // Consumables
        case .survivorPack:
            return "生存者补给"
        case .explorerPack:
            return "探险家补给"
        case .lordPack:
            return "领主补给"
        case .overlordPack:
            return "霸主补给"
        // Tier 1
        case .support1m:
            return "快速支援 30 天"
        case .support3m:
            return "快速支援 90 天"
        case .support1y:
            return "快速支援年卡"
        // Tier 2
        case .lordship1m:
            return "领主权益 30 天"
        case .lordship3m:
            return "领主权益 90 天"
        case .lordship1y:
            return "领主权益年卡"
        // Tier 3
        case .empire1m:
            return "帝国统治 30 天"
        case .empire3m:
            return "帝国统治 90 天"
        case .empire1y:
            return "帝国统治年卡"
        // VIP
        case .vipMonthly:
            return "VIP 月会员"
        case .vipQuarterly:
            return "VIP 季会员"
        case .vipAnnual:
            return "VIP 年会员"
        }
    }
    
    var priceTier: String {
        switch self {
        case .survivorPack: return "¥6"
        case .explorerPack: return "¥18"
        case .lordPack: return "¥30"
        case .overlordPack: return "¥68"
        case .support1m: return "¥8"
        case .support3m: return "¥18"
        case .support1y: return "¥58"
        case .lordship1m: return "¥18"
        case .lordship3m: return "¥38"
        case .lordship1y: return "¥128"
        case .empire1m: return "¥38"
        case .empire3m: return "¥88"
        case .empire1y: return "¥298"
        case .vipMonthly: return "¥12/月"
        case .vipQuarterly: return "¥28/季"
        case .vipAnnual: return "¥88/年"
        }
    }
    
    /// 获取对应的 Tier
    var tier: UserTier {
        switch self {
        case .survivorPack, .explorerPack, .lordPack, .overlordPack:
            return .free
        case .support1m, .support3m, .support1y:
            return .support
        case .lordship1m, .lordship3m, .lordship1y:
            return .lordship
        case .empire1m, .empire3m, .empire1y:
            return .empire
        case .vipMonthly, .vipQuarterly, .vipAnnual:
            return .vip
        }
    }
    
    /// 获取对应的产品类型
    var subscriptionType: SubscriptionType {
        switch self {
        case .survivorPack, .explorerPack, .lordPack, .overlordPack:
            return .consumable
        case .support1m, .support3m, .support1y, .lordship1m, .lordship3m, .lordship1y, .empire1m, .empire3m, .empire1y:
            return .nonRenewable
        case .vipMonthly, .vipQuarterly, .vipAnnual:
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
    let isPlaceholder: Bool // ✅ 新增：标记是否为占位产品

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

    // ✅ 新增：占位商品不可购买
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
