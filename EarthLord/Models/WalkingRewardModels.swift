import Foundation

/// 行走奖励等级
enum WalkingRewardTier: Int, CaseIterable {
    case tier1 = 200    // 200米
    case tier2 = 500    // 500米
    case tier3 = 1000   // 1000米
    case tier4 = 2000   // 2000米
    case tier5 = 3000   // 3000米

    var distance: Double {
        return Double(self.rawValue)
    }

    var displayName: String {
        switch self {
        case .tier1: return "初级探索者"
        case .tier2: return "资深探索者"
        case .tier3: return "精英探索者"
        case .tier4: return "传奇探索者"
        case .tier5: return "传说探索者"
        }
    }

    /// 奖励物品池
    var rewards: [BackpackItem] {
        switch self {
        case .tier1:
            return [
                BackpackItem(id: UUID().uuidString, itemId: "water_001",
                           name: "矿泉水", category: .water, quantity: 1,
                           weight: 0.5, quality: .normal, icon: "drop.fill")
            ]
        case .tier2:
            return [
                BackpackItem(id: UUID().uuidString, itemId: "food_001",
                           name: "罐头食品", category: .food, quantity: 1,
                           weight: 0.3, quality: .normal, icon: "square.stack.3d.up.fill"),
                BackpackItem(id: UUID().uuidString, itemId: "water_001",
                           name: "矿泉水", category: .water, quantity: 1,
                           weight: 0.5, quality: .normal, icon: "drop.fill")
            ]
        case .tier3:
            return [
                BackpackItem(id: UUID().uuidString, itemId: "medical_001",
                           name: "绷带", category: .medical, quantity: 2,
                           weight: 0.05, quality: .good, icon: "cross.case.fill"),
                BackpackItem(id: UUID().uuidString, itemId: "food_002",
                           name: "压缩饼干", category: .food, quantity: 2,
                           weight: 0.2, quality: .good, icon: "rectangle.compress.vertical")
            ]
        case .tier4:
            return [
                BackpackItem(id: UUID().uuidString, itemId: "medical_002",
                           name: "止痛药", category: .medical, quantity: 3,
                           weight: 0.02, quality: .excellent, icon: "pills.fill"),
                BackpackItem(id: UUID().uuidString, itemId: "tool_001",
                           name: "多功能工具", category: .tool, quantity: 1,
                           weight: 0.3, quality: .excellent, icon: "wrench.and.screwdriver.fill")
            ]
        case .tier5:
            return [
                BackpackItem(id: UUID().uuidString, itemId: "medical_003",
                           name: "抗生素", category: .medical, quantity: 5,
                           weight: 0.03, quality: .excellent, icon: "syringe.fill"),
                BackpackItem(id: UUID().uuidString, itemId: "material_003",
                           name: "燃料罐", category: .material, quantity: 2,
                           weight: 2.0, quality: .excellent, icon: "fuelpump.fill")
            ]
        }
    }
}

/// 行走奖励记录
struct WalkingRewardRecord: Codable {
    let tier: Int                 // 等级
    let distance: Double          // 解锁距离
    let timestamp: Date          // 解锁时间
    let itemsReceived: [String]  // 获得的物品ID列表
}
