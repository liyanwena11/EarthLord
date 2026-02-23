//
//  Emblem.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  领地徽章数据模型
//

import Foundation
import SwiftUI

// MARK: - Emblem

struct Emblem: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: EmblemCategory
    let rarity: EmblemRarity
    let bonus: EmblemBonus
    let requirement: EmblemRequirement
    let isUnlocked: Bool

    var displayColor: Color {
        rarity.color
    }
}

// MARK: - EmblemCategory

enum EmblemCategory: String, Codable, CaseIterable {
    case achievement = "achievement" // 成就解锁
    case territory = "territory"     // 领地等级解锁
    case building = "building"       // 建筑相关
    case resource = "resource"       // 资源相关
    case special = "special"         // 特殊徽章

    var displayName: String {
        switch self {
        case .achievement: return "成就徽章"
        case .territory: return "领地徽章"
        case .building: return "建筑徽章"
        case .resource: return "资源徽章"
        case .special: return "特殊徽章"
        }
    }
}

// MARK: - EmblemRarity

enum EmblemRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"

    var displayName: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        }
    }

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    var bonusMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.1
        case .epic: return 1.2
        case .legendary: return 1.3
        }
    }
}

// MARK: - EmblemBonus

struct EmblemBonus: Codable {
    let resourceProduction: Double? // 资源生产加成 (百分比)
    let buildingSpeed: Double?      // 建造速度加成
    let tradeDiscount: Double?      // 交易折扣
    let exploration: Double?        // 探索奖励加成
    let description: String

    var formattedDescription: String {
        var parts: [String] = []
        if let prod = resourceProduction {
            parts.append("资源生产+\(Int(prod * 100))%")
        }
        if let speed = buildingSpeed {
            parts.append("建造速度+\(Int(speed * 100))%")
        }
        if let discount = tradeDiscount {
            parts.append("交易折扣-\(Int(discount * 100))%")
        }
        if let explore = exploration {
            parts.append("探索奖励+\(Int(explore * 100))%")
        }
        return parts.isEmpty ? description : parts.joined(separator: ", ")
    }
}

// MARK: - EmblemRequirement

enum EmblemRequirement: Codable {
    case none
    case territoryLevel(level: Int)
    case buildingCount(count: Int)
    case achievement(achievementId: String)
    case custom(type: String, target: Int)

    var isMet: Bool {
        // TODO: 实现实际检查逻辑
        switch self {
        case .none: return true
        default: return false
        }
    }

    var displayText: String {
        switch self {
        case .none: return "无条件"
        case .territoryLevel(let level): return "领地达到 \(level) 级"
        case .buildingCount(let count): return "建造 \(count) 个建筑"
        case .achievement(let id): return "解锁成就: \(id)"
        case .custom(let type, let target): return "\(type): \(target)"
        }
    }
}

// MARK: - Predefined Emblems

extension Emblem {
    static let allEmblems: [Emblem] = [
        // 成就徽章
        Emblem(
            id: "first_build",
            name: "第一块砖",
            description: "建造你的第一个建筑",
            icon: "house.fill",
            category: .achievement,
            rarity: .common,
            bonus: EmblemBonus(resourceProduction: nil, buildingSpeed: 0.05, tradeDiscount: nil, exploration: nil, description: "建造速度+5%"),
            requirement: .achievement(achievementId: "first_build"),
            isUnlocked: false
        ),
        Emblem(
            id: "master_builder",
            name: "建筑大师",
            description: "建造10个建筑",
            icon: "building.columns.fill",
            category: .achievement,
            rarity: .rare,
            bonus: EmblemBonus(resourceProduction: nil, buildingSpeed: 0.1, tradeDiscount: nil, exploration: nil, description: "建造速度+10%"),
            requirement: .buildingCount(count: 10),
            isUnlocked: false
        ),

        // 领地徽章
        Emblem(
            id: "lord",
            name: "领主",
            description: "拥有1个领地",
            icon: "flag.fill",
            category: .territory,
            rarity: .common,
            bonus: EmblemBonus(resourceProduction: 0.05, buildingSpeed: nil, tradeDiscount: nil, exploration: nil, description: "资源生产+5%"),
            requirement: .territoryLevel(level: 1),
            isUnlocked: false
        ),
        Emblem(
            id: "duke",
            name: "公爵",
            description: "领地达到3级",
            icon: "crown.fill",
            category: .territory,
            rarity: .epic,
            bonus: EmblemBonus(resourceProduction: 0.15, buildingSpeed: nil, tradeDiscount: nil, exploration: nil, description: "资源生产+15%"),
            requirement: .territoryLevel(level: 3),
            isUnlocked: false
        ),

        // 资源徽章
        Emblem(
            id: "harvest_badge",
            name: "丰收徽章",
            description: "累计生产10000单位资源",
            icon: "leaf.fill",
            category: .resource,
            rarity: .rare,
            bonus: EmblemBonus(resourceProduction: 0.1, buildingSpeed: nil, tradeDiscount: nil, exploration: nil, description: "资源生产+10%"),
            requirement: .custom(type: "累计资源生产", target: 10000),
            isUnlocked: false
        ),

        // 特殊徽章
        Emblem(
            id: "pioneer",
            name: "开拓者",
            description: "创建首个世界玩家",
            icon: "star.fill",
            category: .special,
            rarity: .legendary,
            bonus: EmblemBonus(resourceProduction: 0.2, buildingSpeed: 0.1, tradeDiscount: 0.05, exploration: 0.1, description: "全属性加成"),
            requirement: .none,
            isUnlocked: false
        )
    ]
}

// MARK: - TerritoryEmblem

struct TerritoryEmblem: Codable {
    let territoryId: String
    let emblemId: String
    let equippedAt: Date

    var emblem: Emblem? {
        Emblem.allEmblems.first { $0.id == emblemId }
    }
}
