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

    // MARK: - Day 20 完善：根据 POI 类型生成随机掉落物品

    /// 根据 POI 类型生成 1-3 件随机物品
    /// - Parameter poiType: POI 类型
    /// - Returns: 生成的物品数组
    func generateLoot(for poiType: POIType) -> [BackpackItem] {
        // 根据 POI 类型定义可能掉落的物品池
        let lootTable: [POIType: [(itemId: String, name: String, category: ItemCategory, weight: Double, icon: String)]] = [
            .supermarket: [
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
                ("food_002", "压缩饼干", .food, 0.2, "rectangle.compress.vertical")
            ],
            .hospital: [
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill")
            ],
            .pharmacy: [
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill")
            ],
            .gasStation: [
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill")
            ],
            .factory: [
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
                ("material_002", "废金属", .material, 2.0, "cube.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link")
            ],
            .warehouse: [
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link")
            ],
            .school: [
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("material_004", "布料", .material, 0.5, "square.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill")
            ]
        ]

        // 获取该类型的掉落池，默认使用超市
        let pool = lootTable[poiType] ?? lootTable[.supermarket]!

        // 随机生成 1-3 件物品
        let itemCount = Int.random(in: 1...3)
        var generatedItems: [BackpackItem] = []

        for _ in 0..<itemCount {
            let randomIndex = Int.random(in: 0..<pool.count)
            let template = pool[randomIndex]
            let quantity = Int.random(in: 1...3)

            // 随机品质
            let qualities: [ItemQuality] = [.poor, .normal, .good, .excellent]
            let quality = qualities.randomElement()

            let item = BackpackItem(
                id: UUID().uuidString,
                itemId: template.itemId,
                name: template.name,
                category: template.category,
                quantity: quantity,
                weight: template.weight,
                quality: quality,
                icon: template.icon
            )
            generatedItems.append(item)
        }

        print("🎲 生成掉落物品：\(generatedItems.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
        return generatedItems
    }
}
