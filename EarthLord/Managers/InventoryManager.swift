//
//  InventoryManager.swift
//  EarthLord
//
//  背包管理器 - 单例模式
//

import Foundation
import Supabase
import Combine

// MARK: - DB Models

struct DBInventoryItem: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let item_id: String
    var quantity: Int
    let quality: String?
    let obtained_at: Date?
}

struct DBItemDefinition: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let rarity: String
    let weight: Double?
    let icon: String?
}

struct InventoryDisplayItem: Identifiable {
    let id: UUID
    let itemId: String
    let name: String
    let description: String
    let category: String
    let rarity: String
    let weight: Double
    let icon: String
    var quantity: Int
    let quality: String?
    let obtainedAt: Date?

    var categoryDisplayName: String {
        switch category {
        case "water": return "水类"
        case "food": return "食物"
        case "medical": return "医疗"
        case "material": return "材料"
        case "tool": return "工具"
        default: return category
        }
    }

    var rarityDisplayName: String {
        switch rarity {
        case "common": return "普通"
        case "rare": return "稀有"
        case "epic": return "史诗"
        default: return rarity
        }
    }
}

// MARK: - InventoryManager

class InventoryManager: ObservableObject {

    static let shared = InventoryManager()

    @Published var items: [InventoryDisplayItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var itemDefinitions: [String: DBItemDefinition] = [:]

    private let supabase = supabaseClient

    var totalItemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    let maxCapacity = 100
    var capacityPercentage: Double { Double(totalItemCount) / Double(maxCapacity) }

    private init() {
        print("🎒 [背包] InventoryManager 初始化完成")
    }

    // MARK: - Aggregated Resources

    /// 将当前背包中的物资按 `itemId` 聚合为资源字典，方便建造/消耗逻辑使用
    /// - Returns: 形如 ["wood": 80, "stone": 40] 的资源映射
    func aggregatedResources() -> [String: Int] {
        var result: [String: Int] = [:]
        for item in items {
            result[item.itemId, default: 0] += item.quantity
        }
        return result
    }

    // MARK: - Load

    func loadItemDefinitions() async throws {
        let definitions: [DBItemDefinition] = try await supabase
            .from("item_definitions")
            .select()
            .execute()
            .value

        await MainActor.run {
            self.itemDefinitions = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
        }
        print("✅ [背包] 物品定义加载完成，共 \(definitions.count) 种")
    }

    func loadInventory() async {
        let userId = await MainActor.run { AuthManager.shared.currentUser?.id.uuidString }
        guard let userId else {
            await MainActor.run { self.errorMessage = "请先登录" }
            return
        }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        do {
            if itemDefinitions.isEmpty { try await loadItemDefinitions() }

            let inventoryItems: [DBInventoryItem] = try await supabase
                .from("inventory_items")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            var displayItems: [InventoryDisplayItem] = []
            for item in inventoryItems {
                if let def = itemDefinitions[item.item_id] {
                    displayItems.append(InventoryDisplayItem(
                        id: item.id,
                        itemId: item.item_id,
                        name: def.name,
                        description: def.description ?? "",
                        category: def.category,
                        rarity: def.rarity,
                        weight: def.weight ?? 0,
                        icon: def.icon ?? "questionmark",
                        quantity: item.quantity,
                        quality: item.quality,
                        obtainedAt: item.obtained_at
                    ))
                }
            }

            await MainActor.run { self.items = displayItems; self.isLoading = false }
            print("✅ [背包] 背包加载完成，共 \(displayItems.count) 种")
        } catch {
            print("❌ [背包] 加载失败: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false; self.errorMessage = "加载背包失败" }
        }
    }

    // MARK: - Item Operations

    func addItem(itemId: String, quantity: Int = 1) async throws {
        let userId = await MainActor.run { AuthManager.shared.currentUser?.id }
        guard let userId else {
            throw NSError(domain: "InventoryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }

        if let existingIndex = items.firstIndex(where: { $0.itemId == itemId }) {
            let newQty = items[existingIndex].quantity + quantity
            struct QuantityUpdate: Encodable { let quantity: Int }
            try await supabase
                .from("inventory_items")
                .update(QuantityUpdate(quantity: newQty))
                .eq("id", value: items[existingIndex].id.uuidString)
                .execute()
            await MainActor.run { self.items[existingIndex].quantity = newQty }
        } else {
            struct NewItem: Encodable { let user_id: UUID; let item_id: String; let quantity: Int }
            try await supabase
                .from("inventory_items")
                .insert(NewItem(user_id: userId, item_id: itemId, quantity: quantity))
                .execute()
            await loadInventory()
        }
    }

    func removeItem(itemId: String, quantity: Int = 1) async throws {
        guard let existingIndex = items.firstIndex(where: { $0.itemId == itemId }) else {
            throw NSError(domain: "InventoryManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "物品不存在"])
        }
        let existingItem = items[existingIndex]
        let newQty = existingItem.quantity - quantity

        if newQty <= 0 {
            try await supabase.from("inventory_items").delete().eq("id", value: existingItem.id.uuidString).execute()
            await MainActor.run { self.items.remove(at: existingIndex) }
        } else {
            struct QuantityUpdate: Encodable { let quantity: Int }
            try await supabase
                .from("inventory_items")
                .update(QuantityUpdate(quantity: newQty))
                .eq("id", value: existingItem.id.uuidString)
                .execute()
            await MainActor.run { self.items[existingIndex].quantity = newQty }
        }
    }

    // MARK: - Debug / Test

    #if DEBUG
    /// 添加测试资源（用于测试建造系统）
    func addTestResources() async {
        let testResources: [(id: String, qty: Int)] = [
            ("wood", 200),
            ("stone", 150),
            ("metal", 100),
            ("glass", 50)
        ]
        for res in testResources {
            do {
                try await addItem(itemId: res.id, quantity: res.qty)
                print("🧪 [测试] 添加资源: \(res.id) x\(res.qty)")
            } catch {
                print("❌ [测试] 添加 \(res.id) 失败: \(error.localizedDescription)")
            }
        }
        await loadInventory()
    }

    /// 清空所有背包物品
    func clearAllItems() async {
        let userId = await MainActor.run { AuthManager.shared.currentUser?.id.uuidString }
        guard let userId else { return }
        do {
            try await supabase
                .from("inventory_items")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            await MainActor.run { self.items = [] }
            print("🧹 [测试] 背包已清空")
        } catch {
            print("❌ [测试] 清空失败: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - Filter

    func filterByCategory(_ category: String?) -> [InventoryDisplayItem] {
        guard let category = category else { return items }
        return items.filter { $0.category == category }
    }

    func searchByName(_ query: String) -> [InventoryDisplayItem] {
        query.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func filter(category: String?, searchText: String) -> [InventoryDisplayItem] {
        var result = items
        if let c = category { result = result.filter { $0.category == c } }
        if !searchText.isEmpty { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return result
    }
}
