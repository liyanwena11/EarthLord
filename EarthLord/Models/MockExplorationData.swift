//
//  MockExplorationData.swift
//  EarthLord
//
//  探索模块的测试假数据
//  包含POI兴趣点、背包物品、物品定义表、探索结果等测试数据
//

import Foundation
import CoreLocation

// MARK: - 数据模型定义

/// POI兴趣点状态
enum POIStatus: String {
    case undiscovered = "未发现"  // 未发现
    case discovered = "已发现"     // 已发现
    case looted = "已搜空"         // 已被搜空
}

/// POI兴趣点类型
enum POIType: String {
    case supermarket = "超市"
    case hospital = "医院"
    case gasStation = "加油站"
    case pharmacy = "药店"
    case factory = "工厂"
    case warehouse = "仓库"
    case school = "学校"
}

/// 兴趣点数据模型
struct POIPoint: Identifiable {
    let id: String
    let name: String              // 名称
    let type: POIType            // 类型
    let coordinate: CLLocationCoordinate2D  // 坐标
    var status: POIStatus        // 状态
    var hasResources: Bool       // 是否有物资
    let dangerLevel: Int         // 危险等级 (1-5)
    let description: String      // 描述
    var distance: Double?        // 距离玩家的距离（米）
}

/// 物品品质
enum ItemQuality: String {
    case poor = "破损"
    case normal = "普通"
    case good = "良好"
    case excellent = "优秀"
}

/// 物品类型
enum ItemCategory: String {
    case water = "水"
    case food = "食物"
    case medical = "医疗"
    case material = "材料"
    case tool = "工具"
}

/// 物品稀有度
enum ItemRarity: String {
    case common = "常见"
    case uncommon = "罕见"
    case rare = "稀有"
    case epic = "史诗"
}

/// 背包物品
struct BackpackItem: Identifiable {
    let id: String
    let itemId: String           // 物品ID
    let name: String             // 中文名称
    let category: ItemCategory   // 分类
    var quantity: Int            // 数量
    let weight: Double           // 单个重量（kg）
    let quality: ItemQuality?    // 品质（部分物品没有品质）
    let icon: String             // 图标名称

    /// 总重量
    var totalWeight: Double {
        return weight * Double(quantity)
    }
}

/// 物品定义
struct ItemDefinition: Identifiable {
    let id: String
    let name: String             // 中文名称
    let category: ItemCategory   // 分类
    let weight: Double           // 重量（kg）
    let volume: Double           // 体积（立方米）
    let rarity: ItemRarity       // 稀有度
    let hasQuality: Bool         // 是否有品质属性
    let description: String      // 描述
    let stackable: Bool          // 是否可堆叠
}

/// 探索结果
struct ExplorationResult {
    let walkDistance: Double         // 本次行走距离（米）
    let totalWalkDistance: Double    // 累计行走距离（米）
    let walkRanking: Int             // 行走距离排名

    let exploredArea: Double         // 本次探索面积（平方米）
    let totalExploredArea: Double    // 累计探索面积（平方米）
    let areaRanking: Int             // 探索面积排名

    let duration: TimeInterval       // 探索时长（秒）
    let itemsFound: [BackpackItem]   // 获得的物品
    let poisDiscovered: Int          // 发现的POI数量
    let experienceGained: Int        // 获得的经验值
}

// MARK: - 测试假数据

/// Mock探索数据管理器
struct MockExplorationData {

    // MARK: - 1. POI列表（5个不同状态的兴趣点）

    static let mockPOIs: [POIPoint] = [
        // 废弃超市：已发现，有物资
        POIPoint(
            id: "poi_001",
            name: "废弃超市",
            type: .supermarket,
            coordinate: CLLocationCoordinate2D(latitude: 30.6586, longitude: 104.0647),
            status: .discovered,
            hasResources: true,
            dangerLevel: 2,
            description: "一家大型连锁超市的废墟，货架倒塌，但仍有部分物资可搜刮",
            distance: 150
        ),

        // 医院废墟：已发现，已被搜空
        POIPoint(
            id: "poi_002",
            name: "医院废墟",
            type: .hospital,
            coordinate: CLLocationCoordinate2D(latitude: 30.6595, longitude: 104.0655),
            status: .looted,
            hasResources: false,
            dangerLevel: 4,
            description: "市中心医院的残骸，医疗物资已被洗劫一空，有感染者出没的痕迹",
            distance: 320
        ),

        // 加油站：未发现
        POIPoint(
            id: "poi_003",
            name: "加油站",
            type: .gasStation,
            coordinate: CLLocationCoordinate2D(latitude: 30.6600, longitude: 104.0660),
            status: .undiscovered,
            hasResources: true,
            dangerLevel: 3,
            description: "一座中型加油站，可能还有燃料和便利店物资",
            distance: nil  // 未发现，距离未知
        ),

        // 药店废墟：已发现，有物资
        POIPoint(
            id: "poi_004",
            name: "药店废墟",
            type: .pharmacy,
            coordinate: CLLocationCoordinate2D(latitude: 30.6578, longitude: 104.0642),
            status: .discovered,
            hasResources: true,
            dangerLevel: 2,
            description: "一家小型药店，门窗破损，但后仓可能还有药品",
            distance: 280
        ),

        // 工厂废墟：未发现
        POIPoint(
            id: "poi_005",
            name: "工厂废墟",
            type: .factory,
            coordinate: CLLocationCoordinate2D(latitude: 30.6610, longitude: 104.0670),
            status: .undiscovered,
            hasResources: true,
            dangerLevel: 5,
            description: "一座大型机械制造厂，可能有工具和原材料，但危险程度未知",
            distance: nil  // 未发现，距离未知
        )
    ]

    // MARK: - 2. 背包物品（6-8种不同类型）

    static let mockBackpackItems: [BackpackItem] = [
        // 水类：矿泉水
        BackpackItem(
            id: "item_001",
            itemId: "water_001",
            name: "矿泉水",
            category: .water,
            quantity: 8,
            weight: 0.5,
            quality: nil,  // 水没有品质
            icon: "drop.fill"
        ),

        // 食物：罐头食品
        BackpackItem(
            id: "item_002",
            itemId: "food_001",
            name: "罐头食品",
            category: .food,
            quantity: 12,
            weight: 0.3,
            quality: .good,
            icon: "square.stack.3d.up.fill"
        ),

        // 医疗：绷带
        BackpackItem(
            id: "item_003",
            itemId: "medical_001",
            name: "绷带",
            category: .medical,
            quantity: 5,
            weight: 0.05,
            quality: .normal,
            icon: "cross.case.fill"
        ),

        // 医疗：药品
        BackpackItem(
            id: "item_004",
            itemId: "medical_002",
            name: "止痛药",
            category: .medical,
            quantity: 15,
            weight: 0.02,
            quality: .excellent,
            icon: "pills.fill"
        ),

        // 材料：木材
        BackpackItem(
            id: "item_005",
            itemId: "material_001",
            name: "木材",
            category: .material,
            quantity: 20,
            weight: 1.5,
            quality: .normal,
            icon: "rectangle.stack.fill"
        ),

        // 材料：废金属
        BackpackItem(
            id: "item_006",
            itemId: "material_002",
            name: "废金属",
            category: .material,
            quantity: 8,
            weight: 2.0,
            quality: .poor,
            icon: "cube.fill"
        ),

        // 工具：手电筒
        BackpackItem(
            id: "item_007",
            itemId: "tool_001",
            name: "手电筒",
            category: .tool,
            quantity: 2,
            weight: 0.3,
            quality: .good,
            icon: "flashlight.on.fill"
        ),

        // 工具：绳子
        BackpackItem(
            id: "item_008",
            itemId: "tool_002",
            name: "绳子",
            category: .tool,
            quantity: 3,
            weight: 0.8,
            quality: .normal,
            icon: "link"
        )
    ]

    /// 计算背包总重量
    static var totalBackpackWeight: Double {
        mockBackpackItems.reduce(0) { $0 + $1.totalWeight }
    }

    // MARK: - 3. 物品定义表

    static let itemDefinitions: [ItemDefinition] = [
        // 水类
        ItemDefinition(
            id: "water_001",
            name: "矿泉水",
            category: .water,
            weight: 0.5,
            volume: 0.0005,
            rarity: .common,
            hasQuality: false,
            description: "500ml瓶装矿泉水，生存必需品",
            stackable: true
        ),

        // 食物类
        ItemDefinition(
            id: "food_001",
            name: "罐头食品",
            category: .food,
            weight: 0.3,
            volume: 0.0003,
            rarity: .common,
            hasQuality: true,
            description: "密封罐头，保质期长，提供基础营养",
            stackable: true
        ),

        ItemDefinition(
            id: "food_002",
            name: "压缩饼干",
            category: .food,
            weight: 0.2,
            volume: 0.0002,
            rarity: .uncommon,
            hasQuality: true,
            description: "高能量压缩食品，便于携带",
            stackable: true
        ),

        // 医疗类
        ItemDefinition(
            id: "medical_001",
            name: "绷带",
            category: .medical,
            weight: 0.05,
            volume: 0.00005,
            rarity: .common,
            hasQuality: true,
            description: "医用绷带，可以简单包扎伤口",
            stackable: true
        ),

        ItemDefinition(
            id: "medical_002",
            name: "止痛药",
            category: .medical,
            weight: 0.02,
            volume: 0.00002,
            rarity: .uncommon,
            hasQuality: true,
            description: "非处方止痛药，缓解疼痛",
            stackable: true
        ),

        ItemDefinition(
            id: "medical_003",
            name: "抗生素",
            category: .medical,
            weight: 0.03,
            volume: 0.00003,
            rarity: .rare,
            hasQuality: true,
            description: "处方药，治疗感染必备",
            stackable: true
        ),

        // 材料类
        ItemDefinition(
            id: "material_001",
            name: "木材",
            category: .material,
            weight: 1.5,
            volume: 0.002,
            rarity: .common,
            hasQuality: true,
            description: "建筑用木材，可用于建造和修复",
            stackable: true
        ),

        ItemDefinition(
            id: "material_002",
            name: "废金属",
            category: .material,
            weight: 2.0,
            volume: 0.001,
            rarity: .common,
            hasQuality: true,
            description: "废旧金属，可用于制作工具",
            stackable: true
        ),

        ItemDefinition(
            id: "material_003",
            name: "布料",
            category: .material,
            weight: 0.5,
            volume: 0.001,
            rarity: .common,
            hasQuality: true,
            description: "各类布料，可用于制作防具",
            stackable: true
        ),

        // 工具类
        ItemDefinition(
            id: "tool_001",
            name: "手电筒",
            category: .tool,
            weight: 0.3,
            volume: 0.0003,
            rarity: .uncommon,
            hasQuality: true,
            description: "LED手电筒，夜间探索必备",
            stackable: false
        ),

        ItemDefinition(
            id: "tool_002",
            name: "绳子",
            category: .tool,
            weight: 0.8,
            volume: 0.001,
            rarity: .common,
            hasQuality: true,
            description: "10米长的尼龙绳，多用途工具",
            stackable: false
        ),

        ItemDefinition(
            id: "tool_003",
            name: "工具箱",
            category: .tool,
            weight: 3.0,
            volume: 0.01,
            rarity: .rare,
            hasQuality: true,
            description: "包含各种维修工具的工具箱",
            stackable: false
        )
    ]

    // MARK: - 4. 探索结果示例

    static let mockExplorationResult = ExplorationResult(
        // 行走距离：本次2500米，累计15000米，排名42
        walkDistance: 2500,
        totalWalkDistance: 15000,
        walkRanking: 42,

        // 探索面积：本次5万平方米，累计25万平方米，排名38
        exploredArea: 50000,
        totalExploredArea: 250000,
        areaRanking: 38,

        // 探索时长：30分钟
        duration: 1800,  // 30分钟 = 1800秒

        // 获得物品：木材x5、矿泉水x3、罐头x2
        itemsFound: [
            BackpackItem(
                id: "found_001",
                itemId: "material_001",
                name: "木材",
                category: .material,
                quantity: 5,
                weight: 1.5,
                quality: .normal,
                icon: "rectangle.stack.fill"
            ),
            BackpackItem(
                id: "found_002",
                itemId: "water_001",
                name: "矿泉水",
                category: .water,
                quantity: 3,
                weight: 0.5,
                quality: nil,
                icon: "drop.fill"
            ),
            BackpackItem(
                id: "found_003",
                itemId: "food_001",
                name: "罐头食品",
                category: .food,
                quantity: 2,
                weight: 0.3,
                quality: .good,
                icon: "square.stack.3d.up.fill"
            )
        ],

        // 发现的POI数量
        poisDiscovered: 2,

        // 获得的经验值
        experienceGained: 350
    )

    // MARK: - 辅助方法

    /// 根据ID获取物品定义
    static func getItemDefinition(by id: String) -> ItemDefinition? {
        return itemDefinitions.first { $0.id == id }
    }

    /// 根据分类筛选物品
    static func getItems(by category: ItemCategory) -> [BackpackItem] {
        return mockBackpackItems.filter { $0.category == category }
    }

    /// 根据状态筛选POI
    static func getPOIs(by status: POIStatus) -> [POIPoint] {
        return mockPOIs.filter { $0.status == status }
    }

    /// 格式化距离显示
    static func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance else {
            return "未知"
        }
        if distance < 1000 {
            return String(format: "%.0f米", distance)
        } else {
            return String(format: "%.1f公里", distance / 1000)
        }
    }

    /// 格式化面积显示
    static func formatArea(_ area: Double) -> String {
        if area < 10000 {
            return String(format: "%.0f平方米", area)
        } else {
            return String(format: "%.1f万平方米", area / 10000)
        }
    }

    /// 格式化时长显示
    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - 示例用法

extension MockExplorationData {

    /// 获取探索统计摘要
    static var explorationSummary: String {
        let result = mockExplorationResult
        return """
        【探索统计】
        ━━━━━━━━━━━━━━━━
        📍 行走距离
        本次：\(formatDistance(result.walkDistance))
        累计：\(formatDistance(result.totalWalkDistance))
        排名：第 \(result.walkRanking) 名

        🗺️ 探索面积
        本次：\(formatArea(result.exploredArea))
        累计：\(formatArea(result.totalExploredArea))
        排名：第 \(result.areaRanking) 名

        ⏱️ 探索时长：\(formatDuration(result.duration))
        📦 发现POI：\(result.poisDiscovered) 个
        ⭐ 获得经验：\(result.experienceGained) 点

        【获得物品】
        """
    }

    /// 获取背包摘要
    static var backpackSummary: String {
        var summary = """
        【背包物品】
        总重量：\(String(format: "%.2f", totalBackpackWeight)) kg
        ━━━━━━━━━━━━━━━━
        """

        for item in mockBackpackItems {
            let qualityText = item.quality?.rawValue ?? ""
            summary += "\n\(item.name) x\(item.quantity) \(qualityText)"
        }

        return summary
    }
}
