import Foundation
import StoreKit
import SwiftUI

// MARK: - Supply Pack Product IDs

enum SupplyPackID: String, CaseIterable {
    case survivor  = "com.liyanwen.EarthLord.supply.survivor"   // ¥6
    case explorer  = "com.liyanwen.EarthLord.supply.explorer"   // ¥18
    case lord      = "com.liyanwen.EarthLord.supply.lord"        // ¥38
    case overlord  = "com.liyanwen.EarthLord.supply.overlord"   // ¥68

    var displayName: String {
        switch self {
        case .survivor: return "幸存者补给包"
        case .explorer: return "探险家补给包"
        case .lord:     return "领主补给包"
        case .overlord: return "霸主补给包"
        }
    }

    var subtitle: String {
        switch self {
        case .survivor: return "新手必备，解决燃眉之急"
        case .explorer: return "中坚玩家，性价比之选"
        case .lord:     return "核心玩家，快速���展"
        case .overlord: return "重度玩家，一步到位"
        }
    }

    var detailedDescription: String {
        switch self {
        case .survivor:
            return "包含基础生存物资，帮助新手度过初期困难。含饮用水、食物和基础建筑材料。"
        case .explorer:
            return "均衡发展的补给包，适合中期玩家。包含丰富的资源和少量稀有物品。"
        case .lord:
            return "快速发展所需的全套物资，含电子元件等稀有材料，加速基地建设。"
        case .overlord:
            return "顶级玩家豪华礼包，包含卫星模块等史诗物品，体验终极游戏乐趣。"
        }
    }

    var recommendedFor: String {
        switch self {
        case .survivor: return "适合新手玩家"
        case .explorer: return "适合中期玩家"
        case .lord: return "适合高级玩家"
        case .overlord: return "适合顶级玩家"
        }
    }

    var iconName: String {
        switch self {
        case .survivor: return "leaf.fill"
        case .explorer: return "safari.fill"
        case .lord:     return "building.columns.fill"
        case .overlord: return "crown.fill"
        }
    }

    /// 补给包标价（人民币，估值对比使用）
    var listPriceYuan: Double {
        switch self {
        case .survivor: return 6
        case .explorer: return 18
        case .lord: return 38
        case .overlord: return 68
        }
    }

    /// 固定物资 + 随机物资内容
    var contents: [PackItem] {
        switch self {
        case .survivor:
            return [
                PackItem(itemId: "water",       quantity: 10, rarity: "common",  guaranteed: true),
                PackItem(itemId: "canned_food", quantity: 5,  rarity: "common",  guaranteed: true),
                PackItem(itemId: "wood",         quantity: 30, rarity: "common",  guaranteed: true),
                PackItem(itemId: "stone",        quantity: 20, rarity: "common",  guaranteed: true),
                PackItem(itemId: "bandage",      quantity: 3,  rarity: "common",  guaranteed: false, dropRate: 0.5),
            ]
        case .explorer:
            return [
                PackItem(itemId: "water",        quantity: 25, rarity: "common",  guaranteed: true),
                PackItem(itemId: "canned_food",  quantity: 15, rarity: "common",  guaranteed: true),
                PackItem(itemId: "wood",         quantity: 80, rarity: "common",  guaranteed: true),
                PackItem(itemId: "stone",        quantity: 60, rarity: "common",  guaranteed: true),
                PackItem(itemId: "metal",        quantity: 30, rarity: "common",  guaranteed: true),
                PackItem(itemId: "cloth",        quantity: 15, rarity: "common",  guaranteed: true),
                PackItem(itemId: "first_aid_kit",quantity: 2,  rarity: "rare",    guaranteed: false, dropRate: 0.6),
            ]
        case .lord:
            return [
                PackItem(itemId: "water",          quantity: 50, rarity: "common",  guaranteed: true),
                PackItem(itemId: "canned_food",     quantity: 30, rarity: "common",  guaranteed: true),
                PackItem(itemId: "wood",            quantity: 150, rarity: "common",  guaranteed: true),
                PackItem(itemId: "stone",           quantity: 100, rarity: "common",  guaranteed: true),
                PackItem(itemId: "metal",           quantity: 80,  rarity: "common",  guaranteed: true),
                PackItem(itemId: "glass",           quantity: 30, rarity: "common",  guaranteed: true),
                PackItem(itemId: "electronic_part", quantity: 10, rarity: "rare",    guaranteed: true),
                PackItem(itemId: "mechanical_part", quantity: 5,   rarity: "rare",    guaranteed: false, dropRate: 0.7),
                PackItem(itemId: "solar_panel",     quantity: 1,   rarity: "epic",    guaranteed: false, dropRate: 0.3),
            ]
        case .overlord:
            return [
                PackItem(itemId: "water",           quantity: 100, rarity: "common",     guaranteed: true),
                PackItem(itemId: "canned_food",      quantity: 60,  rarity: "common",     guaranteed: true),
                PackItem(itemId: "wood",             quantity: 300, rarity: "common",     guaranteed: true),
                PackItem(itemId: "stone",            quantity: 200, rarity: "common",     guaranteed: true),
                PackItem(itemId: "metal",            quantity: 150, rarity: "common",     guaranteed: true),
                PackItem(itemId: "glass",            quantity: 60,  rarity: "common",     guaranteed: true),
                PackItem(itemId: "electronic_part",  quantity: 30, rarity: "rare",       guaranteed: true),
                PackItem(itemId: "mechanical_part",  quantity: 15, rarity: "rare",       guaranteed: true),
                PackItem(itemId: "satellite_module", quantity: 1,   rarity: "epic",       guaranteed: true),
                PackItem(itemId: "solar_panel",      quantity: 2,   rarity: "epic",       guaranteed: false, dropRate: 0.8),
                PackItem(itemId: "ancient_tech",     quantity: 1,   rarity: "legendary",  guaranteed: false, dropRate: 0.2),
            ]
        }
    }

    /// 根据掉落率计算实际获得的物资
    func resolveItems() -> [PackItem] {
        contents.compactMap { item in
            if item.guaranteed { return item }
            return Double.random(in: 0...1) <= item.dropRate ? item : nil
        }
    }

    /// 必得物资保底价值
    var guaranteedValueYuan: Double {
        contents
            .filter(\.guaranteed)
            .reduce(0) { $0 + $1.totalValueYuan }
    }

    /// 随机物资期望价值
    var randomExpectedValueYuan: Double {
        contents
            .filter { !$0.guaranteed }
            .reduce(0) { $0 + $1.expectedValueYuan }
    }

    /// 总期望价值 = 保底 + 随机期望
    var totalExpectedValueYuan: Double {
        guaranteedValueYuan + randomExpectedValueYuan
    }

    /// 名义总价值（按随机项100%掉落计算）
    var nominalTotalValueYuan: Double {
        contents.reduce(0) { $0 + $1.totalValueYuan }
    }

    /// 期望价值相对售价的倍率（用于“性价比”展示）
    var valueRatio: Double {
        guard listPriceYuan > 0 else { return 0 }
        return totalExpectedValueYuan / listPriceYuan
    }
}

// MARK: - Pack Item Model

struct PackItem: Identifiable {
    let id = UUID()
    let itemId: String
    let quantity: Int
    let rarity: String         // "common" / "rare" / "epic" / "legendary"
    let guaranteed: Bool
    var dropRate: Double = 1.0

    var rarityColor: String {
        switch rarity {
        case "rare":      return "blue"
        case "epic":      return "purple"
        case "legendary": return "gold"
        default:          return "white"
        }
    }

    var displayName: String {
        // Maps itemId to display name; InventoryManager definitions are the source of truth at runtime
        let names: [String: String] = [
            "water":            "饮用水",
            "canned_food":      "罐头食品",
            "wood":             "木材",
            "stone":            "石头",
            "metal":            "废金属",
            "glass":            "玻璃",
            "cloth":            "布料",
            "bandage":          "绷带",
            "first_aid_kit":    "急救包",
            "electronic_part":  "电子元件",
            "mechanical_part":  "机械组件",
            "solar_panel":      "太阳能电板",
            "satellite_module": "卫星模块",
            "ancient_tech":     "古代科技残骸",
        ]
        return names[itemId] ?? itemId
    }

    /// 单件估值（人民币），用于商城“内容价值”展示
    var unitValueYuan: Double {
        let unitValues: [String: Double] = [
            "water": 0.6,
            "canned_food": 1.4,
            "wood": 0.5,
            "stone": 0.4,
            "metal": 1.2,
            "glass": 1.0,
            "cloth": 1.1,
            "bandage": 4.0,
            "first_aid_kit": 12.0,
            "electronic_part": 10.0,
            "mechanical_part": 14.0,
            "solar_panel": 120.0,
            "satellite_module": 260.0,
            "ancient_tech": 520.0
        ]

        if let value = unitValues[itemId] {
            return value
        }

        // 兜底：未知物品按稀有度给估值
        switch rarity {
        case "rare": return 8
        case "epic": return 25
        case "legendary": return 88
        default: return 1
        }
    }

    /// 该条目满额价值（不考虑掉率）
    var totalValueYuan: Double {
        unitValueYuan * Double(quantity)
    }

    /// 该条目期望价值（随机项按掉率折算）
    var expectedValueYuan: Double {
        guaranteed ? totalValueYuan : (totalValueYuan * dropRate)
    }
}

// MARK: - StoreManager

@MainActor
class StoreManager: ObservableObject {

    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var isPurchasing: Bool = false
    @Published var purchaseError: String?

    /// 购买成功后解析出的物资 -> 触发开箱动画
    @Published var lastPurchasedItems: [PackItem] = []
    @Published var showOpeningAnimation: Bool = false

    private let iapManager = IAPManager.shared

    private init() {
        // 延迟加载产品，避免在初始化时阻塞
    }

    // MARK: - Load Products

    func loadProducts() async {
        LogDebug("🔄 [商城] 开始加载产品...")
        await iapManager.loadProducts()

        // 检查加载结果
        if iapManager.availableProducts.isEmpty {
            LogWarning("⚠️ [商城] 警告：未加载到任何产品！")
            LogWarning("⚠️ [商城] 可能原因：")
            LogDebug("  1. App Store Connect 未配置产品")
            LogDebug("  2. 沙盒账号未登录")
            LogDebug("  3. Product ID 不匹配")
            LogWarning("⚠️ [商城] 预期的 Product IDs:")
            for packID in SupplyPackID.allCases {
                LogDebug("  - \(packID.rawValue)")
            }
        } else {
            LogInfo("✅ [商城] IAPManager 加载了 \(iapManager.availableProducts.count) 个产品")
            for storeProduct in iapManager.availableProducts {
                LogDebug("  - \(storeProduct.id): \(storeProduct.displayName)")
            }
        }

        // Convert StoreProduct to Product for compatibility
        products = iapManager.availableProducts.map { $0 }

        // ✅ 修复：如果仍然为空，添加日志
        if products.isEmpty {
            LogWarning("⚠️ [商城] 最终产品列表为空，UI 将显示空状态")
        }

        LogDebug("📊 [商城] StoreManager 产品总数: \(products.count)")
    }

    // ✅ 修复：创建虚拟产品用于 UI 显示（当 StoreKit 不可用时）
    private func createVirtualProducts() -> [Product] {
        // 注意：无法创建真实的 StoreKit Product 对象
        // UI 应该使用 displayProducts 属性来获取模拟数据
        LogDebug("🔧 [商城] 无法创建虚拟 StoreKit Product，返回空数组")
        return []
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        // Find Product from IAPManager
        if let storeProduct = iapManager.availableProducts.first(where: { $0.id == product.id }) {
            let success = await iapManager.purchase(storeProduct)

            if success {
                // 购买成功 - 物品会自动发送到Mailbox
                // 显示成功提示
                showOpeningAnimation = true

                // 获取产品信息用于日志
                if let productInfo = iapManager.getProductInfo(for: storeProduct.id) {
                    LogInfo("✅ [商城] 购买成功: \(productInfo.displayName)")
                    // 成功消息已通过 MailboxManager 发送到邮箱
                }
            } else {
                purchaseError = "购买失败"
                LogError("❌ [商城] 购买失败")
            }
        } else {
            purchaseError = "商品不存在"
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        let success = await iapManager.restorePurchases()
        if !success {
            purchaseError = "恢复购买失败"
        }
    }

    // MARK: - Helpers

    /// 根据 productID 找到对应的 SupplyPackID
    func supplyPack(for product: Product) -> SupplyPackID? {
        SupplyPackID(rawValue: product.id)
    }

    /// 格式化价格显示
    func formattedPrice(_ product: Product) -> String {
        product.displayPrice
    }

    // MARK: - ✅ 新增：支持 SupplyStationView

    var displayProducts: [SupplyProductData] {
        // 如果 StoreKit 加载了真实产品，使用真实产品
        if !iapManager.availableProducts.isEmpty {
            return iapManager.availableProducts.map { storeProduct in
                let packID = SupplyPackID(rawValue: storeProduct.id) ?? .survivor
                return SupplyProductData(
                    id: storeProduct.id,
                    name: packID.displayName,
                    description: packID.subtitle,
                    price: storeProduct.displayPrice,
                    iconName: getIconName(for: packID),
                    rarity: getRarity(for: packID),
                    previewItems: packID.contents.map { "\($0.displayName) x\($0.quantity)" }
                )
            }
        }

        // 否则返回模拟数据（用于开发/测试）
        return SupplyPackID.allCases.map { packID in
            SupplyProductData(
                id: packID.rawValue,
                name: packID.displayName,
                description: packID.subtitle,
                price: getPrice(for: packID),
                iconName: getIconName(for: packID),
                rarity: getRarity(for: packID),
                previewItems: packID.contents.map { "\($0.displayName) x\($0.quantity)" }
            )
        }
    }

    private func getPrice(for packID: SupplyPackID) -> String {
        switch packID {
        case .survivor: return "¥6"
        case .explorer: return "¥18"
        case .lord: return "¥38"
        case .overlord: return "¥68"
        }
    }

    private func getIconName(for packID: SupplyPackID) -> String {
        switch packID {
        case .survivor: return "leaf.fill"
        case .explorer: return "compass.fill"
        case .lord: return "castle.fill"
        case .overlord: return "crown.fill"
        }
    }

    private func getRarity(for packID: SupplyPackID) -> SupplyRarity {
        switch packID {
        case .survivor: return .common
        case .explorer: return .good
        case .lord: return .excellent
        case .overlord: return .legendary
        }
    }

    func purchaseProduct(_ product: SupplyProductData) async -> Bool {
        // 查找对应的 Product
        guard let realProduct = products.first(where: { $0.id == product.id }) else {
            LogWarning("⚠️ [商城] 未找到产品: \(product.id)")
            return false
        }

        await purchase(realProduct)
        return purchaseError == nil
    }
}

// MARK: - StoreError

enum StoreError: Error {
    case failedVerification
}
