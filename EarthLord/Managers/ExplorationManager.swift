import Foundation
import Combine

class ExplorationManager: ObservableObject {
    static let shared = ExplorationManager()
    
    // 背包物品
    @Published var backpackItems: [BackpackItem] = []
    // 当前总重量
    @Published var totalWeight: Double = 0
    // 最大容量
    @Published var maxCapacity: Double = 100.0
    
    private init() {
        // 初始化数据
        self.backpackItems = MockExplorationData.mockBackpackItems
        updateWeight()
    }
    
    // 核心方法：刷新重量
    func updateWeight() {
        self.totalWeight = backpackItems.reduce(0) { $0 + ($1.weight * Double($1.quantity)) }
        print("📝 系统：背包重量已更新为 \(self.totalWeight) kg")
    }
    
    // 核心方法：使用物品
    func useItem(item: BackpackItem) {
        if let index = backpackItems.firstIndex(where: { $0.id == item.id }) {
            if backpackItems[index].quantity > 1 {
                backpackItems[index].quantity -= 1
            } else {
                backpackItems.remove(at: index)
            }
            // 使用后立即重新计算重量，触发界面刷新
            updateWeight()
        }
    }

    // MARK: - Day 20: 添加物品到背包

    /// 将探索获得的物品添加到背包
    /// - Parameter items: 要添加的物品列表
    /// - Returns: 成功添加的物品数量
    @discardableResult
    func addItems(items: [BackpackItem]) -> Int {
        var addedCount = 0

        for newItem in items {
            // 检查背包中是否已有相同物品（通过 itemId 判断）
            if let index = backpackItems.firstIndex(where: { $0.itemId == newItem.itemId }) {
                // 相同物品：增加数量
                backpackItems[index].quantity += newItem.quantity
                print("📦 合并物品：\(newItem.name) +\(newItem.quantity)，现有 \(backpackItems[index].quantity)")
            } else {
                // 新物品：直接添加（生成新 ID 避免冲突）
                var itemToAdd = newItem
                itemToAdd = BackpackItem(
                    id: UUID().uuidString,
                    itemId: newItem.itemId,
                    name: newItem.name,
                    category: newItem.category,
                    quantity: newItem.quantity,
                    weight: newItem.weight,
                    quality: newItem.quality,
                    icon: newItem.icon
                )
                backpackItems.append(itemToAdd)
                print("📦 新增物品：\(newItem.name) x\(newItem.quantity)")
            }
            addedCount += newItem.quantity
        }

        // 更新总重量
        updateWeight()
        print("🎒 背包更新完成，共添加 \(addedCount) 件物品，当前 \(backpackItems.count) 种物品")

        return addedCount
    }

    /// 清空背包（测试用）
    func clearBackpack() {
        backpackItems.removeAll()
        updateWeight()
        print("🗑️ 背包已清空")
    }
}
