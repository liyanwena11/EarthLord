//
//  ProductionModels.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  资源生产系统数据模型
//

import Foundation
import SwiftUI

// MARK: - ProductionJob

struct ProductionJob: Codable, Identifiable {
    let id: String
    let buildingId: String
    let territoryId: String
    let resourceId: String
    let resourceName: String
    let amount: Int
    let startTime: Date
    let completionTime: Date
    var isCollected: Bool
    let buildingName: String

    enum CodingKeys: String, CodingKey {
        case id
        case buildingId = "building_id"
        case territoryId = "territory_id"
        case resourceId = "resource_id"
        case resourceName = "resource_name"
        case amount
        case startTime = "start_time"
        case completionTime = "completion_time"
        case isCollected = "is_collected"
        case buildingName = "building_name"
    }

    var isCompleted: Bool {
        return Date() >= completionTime
    }

    var progress: Double {
        let total = completionTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(max(elapsed / total, 0.0), 1.0)
    }

    var remainingTime: TimeInterval {
        let remaining = completionTime.timeIntervalSince(Date())
        return max(remaining, 0)
    }

    var formattedRemainingTime: String {
        let remaining = remainingTime
        if remaining <= 0 { return "已完成" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - ProductionTemplate

struct ProductionTemplate: Codable {
    let buildingTemplateId: String
    let resourceId: String
    let resourceName: String
    let resourceIcon: String
    let baseAmount: Int
    let productionTimeMinutes: Int
    let requiredBuildingLevel: Int

    var formattedProductionTime: String {
        if productionTimeMinutes < 60 {
            return "\(productionTimeMinutes)分钟"
        } else {
            let hours = productionTimeMinutes / 60
            let minutes = productionTimeMinutes % 60
            return minutes > 0 ? "\(hours)小时\(minutes)分" : "\(hours)小时"
        }
    }
}

// MARK: - ProductionError

enum ProductionError: LocalizedError {
    case buildingNotFound
    case buildingNotActive
    case buildingLevelTooLow(required: Int)
    case productionAlreadyActive
    case databaseError(Error)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .buildingNotFound: return "建筑不存在"
        case .buildingNotActive: return "建筑未激活或正在建造/升级"
        case .buildingLevelTooLow(let level): return "建筑等级不足，需要 \(level) 级"
        case .productionAlreadyActive: return "该建筑已有生产任务进行中"
        case .databaseError(let e): return "数据库错误: \(e.localizedDescription)"
        case .notConfigured: return "生产系统未配置"
        }
    }
}

// MARK: - Database Models

struct NewProductionJob: Encodable {
    let building_id: String
    let territory_id: String
    let resource_id: String
    let resource_name: String
    let amount: Int
    let start_time: Date
    let completion_time: Date
    let is_collected: Bool
    let building_name: String
}

struct ProductionJobUpdate: Encodable {
    let is_collected: Bool
    let collected_at: Date
}
