import Foundation
import StoreKit
import SwiftUI

// MARK: - IAPManager

@MainActor
class IAPManager: ObservableObject {

    static let shared = IAPManager()

    @Published var products: [StoreProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress: Bool = false

    private var productIdentifiers: Set<String>
    private var updates: Task<Void, Never>? = nil

    private init() {
        self.productIdentifiers = Set(IAPProductID.allCases.map { $0.rawValue })
        startProductUpdates()
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - StoreKit Setup

    private func startProductUpdates() {
        updates = Task {
            for await _ in StoreKit.Transaction.updates {
                await loadProducts()
            }
        }
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        LogDebug("📦 [IAP] 开始加载产品...")
        LogDebug("📦 [IAP] 产品标识符: \(productIdentifiers)")

        do {
            let storeProducts = try await StoreKit.Product.products(for: productIdentifiers)

            LogDebug("📦 [IAP] StoreKit 返回产品数量: \(storeProducts.count)")

            // ✅ 修复：检查返回的产品是否为空
            if storeProducts.isEmpty {
                LogWarning("⚠️ [IAP] StoreKit 返回空产品列表")
                LogWarning("⚠️ [IAP] 可能原因：")
                LogDebug("  1. App Store Connect 未配置产品")
                LogDebug("  2. 沙盒账号未登录")
                LogDebug("  3. Bundle ID 不匹配")

                // ✅ 返回空列表，UI 将使用 displayProducts 的模拟数据
                products = []
                errorMessage = "商店暂时不可用"
                return
            }

            // Create SupplyPack models for each product
            var storeKitProducts: [StoreProduct] = []

            for product in storeProducts {
                LogDebug("📦 [IAP] 找到产品: \(product.displayName), ID: \(product.id)")
                if let supplyPack = createSupplyPack(for: product) {
                    storeKitProducts.append(StoreProduct(product: product, supplyPack: supplyPack))
                    LogDebug("📦 [IAP] 创建物资包: \(supplyPack.name)")
                } else {
                    storeKitProducts.append(StoreProduct(product: product))
                    LogDebug("📦 [IAP] 创建通用产品: \(product.displayName)")
                }
            }

            products = storeKitProducts
            errorMessage = nil // 清除错误信息
            LogInfo("📦 [IAP] 加载产品成功: \(products.count) 个")

        } catch {
            // ✅ 修复：捕获错误时返回空列表，UI 使用 displayProducts
            LogError("❌ [IAP] 加载产品失败: \(error.localizedDescription)")
            LogWarning("⚠️ [IAP] UI 将使用模拟数据显示")

            // 返回空列表，StoreManager.displayProducts 会提供模拟数据
            products = []
            errorMessage = "商店连接失败"
        }
    }

    private func createSupplyPack(for product: Product) -> SupplyPack? {
        guard let productID = IAPProductID(rawValue: product.id) else { return nil }

        switch productID {
        case .survivorPack:
            return SupplyPack(
                id: product.id,
                name: "生存者补给包",
                description: "基础生存物资，适合新手幸存者",
                price: product.displayPrice,
                productId: product.id,
                rarity: "common",
                items: [
                    PackItem(itemId: "water", quantity: 10, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 5, rarity: "common", guaranteed: true),
                    PackItem(itemId: "bandage", quantity: 2, rarity: "common", guaranteed: true)
                ],
                guaranteedItems: [
                    PackItem(itemId: "water", quantity: 10, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 5, rarity: "common", guaranteed: true),
                    PackItem(itemId: "bandage", quantity: 2, rarity: "common", guaranteed: true)
                ]
            )
        case .explorerPack:
            return SupplyPack(
                id: product.id,
                name: "探索者物资包",
                description: "丰富的探索装备，助你开拓新领地",
                price: product.displayPrice,
                productId: product.id,
                rarity: "rare",
                items: [
                    PackItem(itemId: "water", quantity: 15, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 15, rarity: "common", guaranteed: true),
                    PackItem(itemId: "bandage", quantity: 5, rarity: "common", guaranteed: true),
                    PackItem(itemId: "flashlight", quantity: 1, rarity: "rare", guaranteed: true)
                ],
                guaranteedItems: [
                    PackItem(itemId: "water", quantity: 15, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 15, rarity: "common", guaranteed: true),
                    PackItem(itemId: "bandage", quantity: 5, rarity: "common", guaranteed: true),
                    PackItem(itemId: "flashlight", quantity: 1, rarity: "rare", guaranteed: true)
                ]
            )
        case .lordPack:
            return SupplyPack(
                id: product.id,
                name: "领主物资包",
                description: "高级资源套装，建立你的末日帝国",
                price: product.displayPrice,
                productId: product.id,
                rarity: "epic",
                items: [
                    PackItem(itemId: "water", quantity: 30, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 30, rarity: "common", guaranteed: true),
                    PackItem(itemId: "medical_kit", quantity: 3, rarity: "rare", guaranteed: true),
                    PackItem(itemId: "wood", quantity: 20, rarity: "common", guaranteed: true)
                ],
                guaranteedItems: [
                    PackItem(itemId: "water", quantity: 30, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 30, rarity: "common", guaranteed: true),
                    PackItem(itemId: "medical_kit", quantity: 3, rarity: "rare", guaranteed: true),
                    PackItem(itemId: "wood", quantity: 20, rarity: "common", guaranteed: true)
                ]
            )
        case .overlordPack:
            return SupplyPack(
                id: product.id,
                name: "末日霸主包",
                description: "终极物资包，包含所有类型的资源",
                price: product.displayPrice,
                productId: product.id,
                rarity: "legendary",
                items: [
                    PackItem(itemId: "water", quantity: 80, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 80, rarity: "common", guaranteed: true),
                    PackItem(itemId: "medical_kit", quantity: 10, rarity: "rare", guaranteed: true),
                    PackItem(itemId: "wood", quantity: 50, rarity: "common", guaranteed: true),
                    PackItem(itemId: "stone", quantity: 40, rarity: "common", guaranteed: true),
                    PackItem(itemId: "metal", quantity: 30, rarity: "rare", guaranteed: true)
                ],
                guaranteedItems: [
                    PackItem(itemId: "water", quantity: 80, rarity: "common", guaranteed: true),
                    PackItem(itemId: "canned_food", quantity: 80, rarity: "common", guaranteed: true),
                    PackItem(itemId: "medical_kit", quantity: 10, rarity: "rare", guaranteed: true),
                    PackItem(itemId: "wood", quantity: 50, rarity: "common", guaranteed: true),
                    PackItem(itemId: "stone", quantity: 40, rarity: "common", guaranteed: true),
                    PackItem(itemId: "metal", quantity: 30, rarity: "rare", guaranteed: true)
                ]
            )
        }
    }

    // MARK: - Purchases

    func purchase(_ product: StoreProduct) async -> PurchaseResult {
        guard !purchaseInProgress else {
            return .failed(IAPError.purchaseFailed)
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Handle successful purchase
                    await handlePurchase(transaction, for: product)
                    await transaction.finish()
                    return .success(product.product)
                case .unverified(_, let error):
                    LogError("❌ [IAP] 交易验证失败: \(error)")
                    return .failed(error)
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            default:
                return .failed(IAPError.purchaseFailed)
            }
        } catch {
            LogError("❌ [IAP] 购买失败: \(error)")
            return .failed(error)
        }
    }

    private func handlePurchase(_ transaction: StoreKit.Transaction, for product: StoreProduct) async {
        LogInfo("✅ [IAP] 购买成功: \(product.displayName)")
        // Add items to mailbox
        if let supplyPack = product.supplyPack {
            let mailboxManager = MailboxManager.shared

            do {
                // Combine guaranteed and random items
                var allItems = supplyPack.guaranteedItems

                // Add random items if applicable
                let randomItems = supplyPack.items.filter { !$0.guaranteed }
                if !randomItems.isEmpty {
                    // For simplicity, just add all random items for now
                    allItems.append(contentsOf: randomItems)
                }

                try await mailboxManager.addItems(allItems, productID: product.id, transactionID: String(transaction.id))
                LogDebug("📬 [IAP] 物资已添加到邮箱: \(allItems.count) 个物品")
            } catch {
                LogError("❌ [IAP] 添加到邮箱失败: \(error)")
            }
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            for await result in StoreKit.Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    // Handle restored purchase
                    LogDebug("🔄 [IAP] 恢复购买: \(transaction.productID)")
                    await transaction.finish()
                case .unverified(_, let error):
                    LogError("❌ [IAP] 恢复购买验证失败: \(error)")
                }
            }
            return true
        } catch {
            errorMessage = "恢复购买失败"
            LogError("❌ [IAP] 恢复购买失败: \(error)")
            return false
        }
    }

    // MARK: - Helpers

    func getProduct(for productId: String) -> StoreProduct? {
        return products.first { $0.id == productId }
    }

    var hasProducts: Bool {
        !products.isEmpty
    }
}
