//
//  ResourceLocalization.swift
//  EarthLord
//
//  资源名称本地化
//

import Foundation

enum ResourceID: String, CaseIterable {
    // 基础资源
    case wood = "wood"
    case stone = "stone"
    case iron = "iron"
    case ironOre = "iron_ore"
    case copper = "copper"
    case copperOre = "copper_ore"
    case coal = "coal"
    case steel = "steel"
    case steelIngot = "steel_ingot"
    case gold = "gold"

    // 建筑材料
    case cement = "cement"
    case glass = "glass"
    case brick = "brick"
    case clay = "clay"

    // 生存物资
    case water = "water"
    case food = "food"
    case meat = "meat"
    case vegetable = "vegetable"
    case fruit = "fruit"
    case bread = "bread"
    case cannedFood = "canned_food"

    // 医疗物资
    case medicine = "medicine"
    case bandage = "bandage"
    case antibiotic = "antibiotic"

    // 工具和材料
    case metal = "metal"
    case plastic = "plastic"
    case rubber = "rubber"
    case cloth = "cloth"
    case leather = "leather"
    case rope = "rope"

    // 电子和科技
    case electronics = "electronics"
    case circuit = "circuit"
    case battery = "battery"
    case wire = "wire"

    // 其他
    case fuel = "fuel"
    case oil = "oil"
    case scrap = "scrap"

    var localizedName: String {
        return String(localized: String.LocalizationValue(self.rawValue))
    }

    var icon: String {
        switch self {
        case .wood: return "star.fill"
        case .stone: return "circle.fill"
        case .iron, .ironOre, .steel, .steelIngot: return "diamond.fill"
        case .copper, .copperOre, .gold: return "circle.fill"
        case .coal: return "circle.fill"
        case .water: return "drop.fill"
        case .food, .meat, .bread: return "circle.fill"
        case .medicine: return "cross.fill"
        case .metal: return "diamond.fill"
        case .glass: return "circle.fill"
        default: return "square.fill"
        }
    }
}

// 领地相关
enum TerritoryLocalization {
    static let unnamedTerritory = String(localized: String.LocalizationValue("未命名领地"))
    static let myTerritories = String(localized: String.LocalizationValue("我的领地"))
    static let territoryDetail = String(localized: String.LocalizationValue("领地详情"))
}

// 辅助函数：通过资源ID获取本地化名称
func getResourceName(_ resourceId: String) -> String {
    // 如果资源ID已经在xcstrings中，直接使用
    return String(localized: String.LocalizationValue(resourceId))
}
