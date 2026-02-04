//
//  ExplorationModels.swift
//  EarthLord
//
//  探索模块的数据模型定义
//  包含POI兴趣点、背包物品、物品定义等核心数据结构
//

import Foundation
import CoreLocation

// MARK: - POI 相关模型

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
    var lastLootedTime: Date?    // ✅ Day 22：上次搜刮时间（用于 24 小时冷却）

    // MARK: - Day 22：24 小时冷却逻辑

    /// 冷却时间（24小时）
    static let cooldownDuration: TimeInterval = 24 * 60 * 60  // 24小时

    /// 是否可搜刮（未搜刮过 或 已过冷却期）
    var isLootable: Bool {
        guard let lastLooted = lastLootedTime else {
            return true  // 从未搜刮过
        }
        let timeSinceLooted = Date().timeIntervalSince(lastLooted)
        return timeSinceLooted >= POIPoint.cooldownDuration
    }

    /// 剩余冷却时间（秒）
    var remainingCooldown: TimeInterval {
        guard let lastLooted = lastLootedTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastLooted)
        return max(0, POIPoint.cooldownDuration - elapsed)
    }

    /// 剩余冷却时间的格式化字符串
    var cooldownString: String {
        let remaining = remainingCooldown
        if remaining <= 0 { return "可搜刮" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟后刷新"
        } else {
            return "\(minutes)分钟后刷新"
        }
    }

    /// 根据 POI 类型返回对应的 SF Symbol 图标名
    var iconName: String {
        switch type {
        case .supermarket:
            return "cart.fill"
        case .hospital:
            return "cross.case.fill"
        case .gasStation:
            return "fuelpump.fill"
        case .pharmacy:
            return "pills.fill"
        case .factory:
            return "building.2.fill"
        case .warehouse:
            return "shippingbox.fill"
        case .school:
            return "book.fill"
        }
    }

    /// 根据 POI 类型返回对应的颜色
    var typeColor: (red: Double, green: Double, blue: Double) {
        switch type {
        case .supermarket:
            return (0.2, 0.7, 0.3)   // 绿色
        case .hospital:
            return (0.9, 0.2, 0.2)   // 红色
        case .gasStation:
            return (0.9, 0.6, 0.1)   // 橙色
        case .pharmacy:
            return (0.3, 0.7, 0.9)   // 蓝色
        case .factory:
            return (0.5, 0.5, 0.5)   // 灰色
        case .warehouse:
            return (0.6, 0.4, 0.2)   // 棕色
        case .school:
            return (0.6, 0.3, 0.7)   // 紫色
        }
    }
}

// MARK: - 物品相关模型

/// 物品品质
enum ItemQuality: String, Codable {
    case poor = "破损"
    case normal = "普通"
    case good = "良好"
    case excellent = "优秀"
}

/// 物品类型
enum ItemCategory: String, Codable {
    case water = "水"
    case food = "食物"
    case medical = "医疗"
    case material = "材料"
    case tool = "工具"
}

/// 物品稀有度
enum ItemRarity: String, Codable {
    case common = "常见"
    case uncommon = "罕见"
    case rare = "稀有"
    case epic = "史诗"
}

/// 背包物品
struct BackpackItem: Identifiable, Codable {
    let id: String
    let itemId: String           // 物品ID
    let name: String             // 中文名称
    let category: ItemCategory   // 分类
    var quantity: Int            // 数量
    let weight: Double           // 单个重量（kg）
    let quality: ItemQuality?    // 品质（部分物品没有品质）
    let icon: String             // 图标名称
    var backstory: String?       // AI 生成的背景故事
    var isAIGenerated: Bool = false  // 是否为 AI 生成
    var itemRarity: POIRarity?   // 物品稀有度（AI 掉落用）

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

// MARK: - 探索结果模型

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
