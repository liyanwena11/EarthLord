import Foundation
import StoreKit

// MARK: - Product Identifiers

enum IAPProductID: String, CaseIterable {
    case survivorPack = "com.earthlord.supply.survivor"
    case explorerPack = "com.earthlord.supply.explorer"
    case lordPack = "com.earthlord.supply.lord"
    case overlordPack = "com.earthlord.supply.overlord"
    
    var displayName: String {
        switch self {
        case .survivorPack:
            return "生存者补给包"
        case .explorerPack:
            return "探索者物资包"
        case .lordPack:
            return "领主物资包"
        case .overlordPack:
            return "末日霸主包"
        }
    }
    
    var priceTier: String {
        switch self {
        case .survivorPack:
            return "¥6"
        case .explorerPack:
            return "¥18"
        case .lordPack:
            return "¥30"
        case .overlordPack:
            return "¥68"
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
