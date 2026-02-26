import Foundation
import StoreKit
import SwiftUI

// MARK: - IAPManager (优化版 - 支持 16 产品 + Tier 系统)

/// IAPManager - StoreKit 2 集成 + 16 产品完整管理
/// 核心职责:
/// 1. 加载 App Store 产品信息
/// 2. 处理用户购买流程
/// 3. 验证交易
/// 4. 追踪已购买产品
/// 5. 与 TierManager 集成
@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    // MARK: - Published Properties
    
    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress = false
    
    // MARK: - Private Properties
    
    private var productIdentifiers: Set<String>
    private var transactionUpdates: Task<Void, Never>?
    private let tierManager = TierManager.shared
    
    // MARK: - Init
    
    private init() {
        // 获取所有 16 个产品 ID + 新的订阅产品 ID
        var allProducts = All16Products.all.map { $0.id }
        allProducts.append(contentsOf: SubscriptionProductGroups.allProductIDs)

        // 添加新的末日通行证产品 ID
        let apocalypseProductIDs = [
            "com.earthlord.sub.explorer.monthly",
            "com.earthlord.sub.explorer.yearly",
            "com.earthlord.sub.explorer.trial",
            "com.earthlord.sub.lord.monthly",
            "com.earthlord.sub.lord.yearly",
            "com.earthlord.sub.lord.trial",
            "com.earthlord.sub.apocalypse.monthly",
            "com.earthlord.sub.apocalypse.yearly",
            "com.earthlord.sub.apocalypse.trial"
        ]
        allProducts.append(contentsOf: apocalypseProductIDs)

        self.productIdentifiers = Set(allProducts)

        // 启动交易更新监听
        startTransactionUpdates()

        print("✅ IAPManager 初始化完成，监听 \(productIdentifiers.count) 个产品")
    }
    
    deinit {
        transactionUpdates?.cancel()
    }
    
    // MARK: - Initialization
    
    /// 初始化：加载产品 + 恢复购买历史
    func initialize() async {
        print("🔄 IAPManager 初始化开始...")
        
        await loadProducts()
        await loadPurchasedProducts()
        
        print("✅ IAPManager 初始化完成")
    }
    
    // MARK: - Product Loading (产品加载)
    
    /// 从 App Store 加载产品信息
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        print("📦 [IAP] 开始加载 \(productIdentifiers.count) 个产品...")
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            
            print("✅ [IAP] 从 App Store 加载产品: \(products.count) 个")
            
            // 按照 All16Products.all 的顺序排序
            let sortedProducts = products.sorted { p1, p2 in
                let order1 = All16Products.all.firstIndex { $0.id == p1.id } ?? Int.max
                let order2 = All16Products.all.firstIndex { $0.id == p2.id } ?? Int.max
                return order1 < order2
            }
            
            availableProducts = sortedProducts
            errorMessage = nil
            
            // 打印产品信息
            for product in sortedProducts {
                print("  - \(product.displayName): \(product.displayPrice)")
            }
            
        } catch {
            print("❌ [IAP] 加载产品失败: \(error.localizedDescription)")
            errorMessage = "商店暂时不可用，请稍后重试"
            availableProducts = []
        }
    }
    
    // MARK: - Purchase History (购买历史)
    
    /// 加载已购买产品
    /// 从 StoreKit 恢复用户已购买的产品列表 (用于赠礼和订阅)
    private func loadPurchasedProducts() async {
        print("🔄 [IAP] 开始加载已购买产品...")

        var purchased = Set<String>()

        for await entitlement in StoreKit.Transaction.currentEntitlements {
            switch entitlement {
            case .verified(let transaction):
                purchased.insert(transaction.productID)
                print("  ✓ 已购买: \(transaction.productID)")

            case .unverified(let transaction, let error):
                print("  ⚠️ 未验证的交易: \(transaction.productID), 错误: \(error)")
            }
        }

        purchasedProductIDs = purchased
        print("✅ [IAP] 已购买产品数: \(purchased.count)")
    }
    
    // MARK: - Purchase Flow (购买流程)
    
    /// 购买产品
    /// - Parameter product: StoreKit Product 对象
    /// - Returns: 购买结果 (成功/失败/取消/待处理)
    func purchase(_ product: Product) async -> Bool {
        guard !purchaseInProgress else {
            print("⚠️ [IAP] 购买正在进行中，请稍候")
            return false
        }
        
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        print("🛒 [IAP] 开始购买: \(product.displayName)...")
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 处理购买成功
                return await handlePurchaseVerification(verification, productID: product.id)
                
            case .userCancelled:
                print("👤 [IAP] 用户取消购买")
                return false
                
            case .pending:
                print("⏳ [IAP] 购买待处理 (可能需要家长同意或其他确认)")
                errorMessage = "购买待处理，请在设置中确认"
                return false
                
            @unknown default:
                print("❌ [IAP] 未知购买结果")
                errorMessage = "购买失败"
                return false
            }
        } catch {
            print("❌ [IAP] 购买异常: \(error.localizedDescription)")
            errorMessage = "购买失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 验证和处理购买
    private func handlePurchaseVerification(
        _ verification: VerificationResult<StoreKit.Transaction>,
        productID: String
    ) async -> Bool {
        switch verification {
        case .verified(let transaction):
            // 交易验证成功
            print("✅ [IAP] 交易验证成功")

            // 更新已购买列表
            purchasedProductIDs.insert(productID)

            // 签收交易 (告诉 App Store 已处理)
            await transaction.finish()
            print("✅ [IAP] 交易已签收")

            // 检查是否为试用产品
            if let group = SubscriptionProductGroups.group(for: productID),
               group.isTrialProduct(productID) {
                // 处理试用购买 - 通知 TrialManager
                print("🎉 [IAP] 试用产品购买: \(productID)")
                // TrialManager 会通知 TierManager
            } else {
                // 与 TierManager 集成：更新用户 Tier
                await tierManager.handlePurchase(productID: productID)
            }

            // 发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("IAPPurchaseCompleted"),
                object: productID
            )

            return true

        case .unverified(_, let error):
            // 交易验证失败 - 不要完成交易，等待重试
            print("❌ [IAP] 交易验证失败: \(error.localizedDescription)")
            errorMessage = "交易验证失败，请重试"
            return false
        }
    }
    
    // MARK: - Transaction Updates (交易监听)
    
    /// 启动交易更新监听
    /// 监听后台 App Store 事件 (续费、取消、恢复等)
    private func startTransactionUpdates() {
        transactionUpdates = Task {
            print("🔄 [IAP] 启动交易监听...")
            
            for await update in Transaction.updates {
                print("📲 [IAP] 收到交易更新...")
                
                switch update {
                case .verified(let transaction):
                    print("✅ [IAP] 验证的交易: \(transaction.productID)")
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                    
                    // 更新 Tier (可能是续费或恢复)
                    await tierManager.handlePurchase(productID: transaction.productID)
                    
                case .unverified(let transaction, let error):
                    print("⚠️ [IAP] 未验证的交易: \(transaction.productID), 错误: \(error.localizedDescription)")
                    // 未验证的交易不立即处理，等待验证
                }
            }
        }
    }
    
    // MARK: - Query Methods (查询方法)
    
    /// 根据产品 ID 获取 Product
    /// - Parameter productID: 产品 ID
    /// - Returns: 对应的 Product 或 nil
    func getProduct(for productID: String) -> Product? {
        return availableProducts.first { $0.id == productID }
    }
    
    /// 检查是否有特定产品已购买
    /// - Parameter productID: 产品 ID
    /// - Returns: 是否已购买
    func hasProduct(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    /// 获取产品的 IAPProduct 信息
    /// - Parameter productID: 产品 ID
    /// - Returns: IAPProduct 结构体或 nil
    func getProductInfo(for productID: String) -> IAPProduct? {
        return All16Products.all.first { $0.id == productID }
    }
    
    /// 获取产品的价格字符串
    /// - Parameter product: Product 对象
    /// - Returns: 格式化的价格字符串 (e.g., "¥6.00" or "Free")
    func getPriceString(_ product: Product) -> String {
        if product.price == 0 {
            return "免费"
        }
        // StoreKit 2 使用 Decimal 类型
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatStyle.locale.currency?.identifier ?? "CNY"
        formatter.locale = product.priceFormatStyle.locale
        return formatter.string(from: product.price as NSDecimalNumber) ?? product.displayPrice
    }
    
    /// 获取所有已购买的产品 ID
    /// - Returns: 包含所有已购买产品 ID 的数组
    func getAllPurchasedProductIDs() -> [String] {
        return Array(purchasedProductIDs)
    }
    
    /// 检查是否有任何产品可用
    /// - Returns: 是否有加载的产品
    var hasAvailableProducts: Bool {
        return !availableProducts.isEmpty
    }
    
    // MARK: - Restore Purchases (恢复购买)
    
    /// 恢复之前的购买
    /// 通常用于用户切换设备或重新安装应用后恢复购买
    /// - Returns: 恢复是否成功
    func restorePurchases() async -> Bool {
        print("🔄 [IAP] 开始恢复购买...")

        isLoading = true
        defer { isLoading = false }

        // 清空当前购买ID，重新加载
        purchasedProductIDs.removeAll()
        await loadPurchasedProducts()

        print("✅ [IAP] 购买恢复完成，已恢复 \(purchasedProductIDs.count) 个购买")

        // 对每个恢复的购买，更新 Tier
        for productID in purchasedProductIDs {
            await tierManager.handlePurchase(productID: productID)
        }

        return true
    }

    // MARK: - Helpers (辅助方法)
    
    /// 清除所有缓存和状态
    /// 用于测试或重置应用状态
    func resetManager() {
        print("🔄 [IAP] 重置 IAPManager...")
        
        availableProducts.removeAll()
        purchasedProductIDs.removeAll()
        isLoading = false
        errorMessage = nil
        purchaseInProgress = false
        
        // 停止现有的交易更新任务
        transactionUpdates?.cancel()
        transactionUpdates = nil
        
        print("✅ [IAP] IAPManager 已重置")
    }
    
    /// 获取所有可用产品按 Tier 分类
    /// - Returns: [UserTier: [Product]] 字典
    func getProductsByTier() -> [UserTier: [Product]] {
        var tierProducts: [UserTier: [Product]] = [:]

        let allTiers: [UserTier] = [.free, .support, .lordship, .empire, .vip]
        for tier in allTiers {
            tierProducts[tier] = availableProducts.filter { product in
                if let iapProduct = All16Products.all.first(where: { $0.id == product.id }) {
                    return iapProduct.tier == tier
                }
                return false
            }
        }

        return tierProducts
    }

    /// 获取所有可用产品按类型分类
    /// - Returns: [SubscriptionType: [Product]] 字典
    func getProductsByType() -> [SubscriptionType: [Product]] {
        var typeProducts: [SubscriptionType: [Product]] = [:]

        for subscriptionType in [SubscriptionType.consumable, .nonRenewable, .autoRenewable] {
            typeProducts[subscriptionType] = availableProducts.filter { product in
                if let iapProduct = All16Products.all.first(where: { $0.id == product.id }) {
                    return iapProduct.type == subscriptionType
                }
                return false
            }
        }

        return typeProducts
    }
    
    /// 打印调试信息
    func printDebugInfo() {
        print("📊 [IAP] ===== IAPManager 调试信息 =====")
        print("📊 [IAP] 可用产品数: \(availableProducts.count)")
        print("📊 [IAP] 已购买产品数: \(purchasedProductIDs.count)")
        print("📊 [IAP] 已购买产品 ID: \(purchasedProductIDs)")
        print("📊 [IAP] 加载中: \(isLoading)")
        print("📊 [IAP] 购买中: \(purchaseInProgress)")
        if let error = errorMessage {
            print("📊 [IAP] 错误: \(error)")
        }
        print("📊 [IAP] ===== 调试信息结束 =====")
    }
}
