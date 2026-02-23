//
//  TaskModels.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  任务与成就系统数据模型
//

import Foundation
import SwiftUI

// MARK: - DailyTask

struct DailyTask: Codable, Identifiable {
    let id: String
    let type: DailyTaskType
    let title: String
    let description: String
    let target: Int
    let current: Int
    let reward: TaskReward
    let isCompleted: Bool
    var isClaimed: Bool
    let expiresAt: Date
    let createdAt: Date

    var progress: Double {
        return min(Double(current) / Double(target), 1.0)
    }

    var formattedProgress: String {
        return "\(current)/\(target)"
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var remainingTime: TimeInterval {
        return max(expiresAt.timeIntervalSince(Date()), 0)
    }
}

// MARK: - DailyTaskType

enum DailyTaskType: String, Codable, CaseIterable {
    case production = "production"
    case building = "building"
    case upgrade = "upgrade"
    case collection = "collection"
    case exploration = "exploration"
    case trade = "trade"

    var displayName: String {
        switch self {
        case .production: return "生产任务"
        case .building: return "建造任务"
        case .upgrade: return "升级任务"
        case .collection: return "收集任务"
        case .exploration: return "探索任务"
        case .trade: return "交易任务"
        }
    }

    var icon: String {
        switch self {
        case .production: return "gearshape.2.fill"
        case .building: return "hammer.fill"
        case .upgrade: return "arrow.up.circle.fill"
        case .collection: return "square.and.arrow.down.fill"
        case .exploration: return "mappin.circle.fill"
        case .trade: return "arrow.left.arrow.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .production: return .green
        case .building: return .orange
        case .upgrade: return .blue
        case .collection: return .purple
        case .exploration: return .teal
        case .trade: return .yellow
        }
    }
}

// MARK: - TaskReward

struct TaskReward: Codable {
    let experience: Int
    let resources: [String: Int] // resourceId -> amount
    let items: [String] // itemIds

    var totalRewards: Int {
        return experience + resources.values.reduce(0, +) + items.count
    }
}

// MARK: - Achievement

struct Achievement: Codable, Identifiable {
    let id: String
    let category: AchievementCategory
    let title: String
    let description: String
    let icon: String
    let requirement: AchievementRequirement
    let reward: AchievementReward
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: Double // 0.0 ~ 1.0

    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

// MARK: - AchievementCategory

enum AchievementCategory: String, Codable, CaseIterable {
    case building = "building"
    case resource = "resource"
    case territory = "territory"
    case exploration = "exploration"
    case trade = "trade"
    case social = "social"

    var color: Color {
        switch self {
        case .building: return .orange
        case .resource: return .green
        case .territory: return .purple
        case .exploration: return .teal
        case .trade: return .yellow
        case .social: return .blue
        }
    }

    var displayName: String {
        switch self {
        case .building: return "建筑成就"
        case .resource: return "资源成就"
        case .territory: return "领地成就"
        case .exploration: return "探索成就"
        case .trade: return "交易成就"
        case .social: return "社交成就"
        }
    }

    var icon: String {
        switch self {
        case .building: return "building.columns.fill"
        case .resource: return "cube.fill"
        case .territory: return "flag.fill"
        case .exploration: return "safari.fill"
        case .trade: return "banknote.fill"
        case .social: return "person.2.fill"
        }
    }
}

// MARK: - AchievementRequirement

enum AchievementRequirement: Codable {
    case buildCount(buildingType: String, count: Int)
    case resourceCollected(resourceId: String, amount: Int)
    case territoryLevel(level: Int)
    case territoryCount(count: Int)
    case poiScavenged(count: Int)
    case tradeCompleted(count: Int)
    case custom(type: String, target: Int, current: Int)

    var displayText: String {
        switch self {
        case .buildCount(let type, let count):
            return "建造 \(type) x\(count)"
        case .resourceCollected(let id, let amount):
            return "收集 \(id) x\(amount)"
        case .territoryLevel(let level):
            return "领地达到 \(level) 级"
        case .territoryCount(let count):
            return "拥有 \(count) 个领地"
        case .poiScavenged(let count):
            return "搜刮 \(count) 个POI"
        case .tradeCompleted(let count):
            return "完成 \(count) 次交易"
        case .custom(let type, let target, let current):
            return "\(type): \(current)/\(target)"
        }
    }
}

// MARK: - AchievementReward

struct AchievementReward: Codable {
    let emblemId: String? // 解锁的徽章ID
    let bonusResources: [String: Int] // 资源加成
    let title: String? // 获得称号
    let experience: Int
}

// MARK: - TaskError

enum TaskError: LocalizedError {
    case taskNotFound
    case taskNotCompleted
    case taskAlreadyClaimed
    case taskExpired
    case databaseError(Error)

    var errorDescription: String? {
        switch self {
        case .taskNotFound: return "任务不存在"
        case .taskNotCompleted: return "任务未完成"
        case .taskAlreadyClaimed: return "奖励已领取"
        case .taskExpired: return "任务已过期"
        case .databaseError(let e): return "数据库错误: \(e.localizedDescription)"
        }
    }
}

// MARK: - Database Models

struct NewDailyTask: Encodable {
    let user_id: String
    let type: String
    let title: String
    let description: String
    let target: Int
    let current: Int
    let reward: TaskReward
    let is_completed: Bool
    let is_claimed: Bool
    let expires_at: Date
}

struct DailyTaskProgressUpdate: Encodable {
    var current: Int
    var is_completed: Bool
    let updated_at: Date
}

struct DailyTaskClaimUpdate: Encodable {
    var is_claimed: Bool
    var claimed_at: Date
}
