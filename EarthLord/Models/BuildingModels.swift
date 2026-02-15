//
//  BuildingModels.swift
//  EarthLord
//
//  建筑系统数据模型
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - BuildingCategory

enum BuildingCategory: String, Codable, CaseIterable {
    case all = "all"
    case survival = "survival"
    case storage = "storage"
    case production = "production"
    case energy = "energy"

    var displayName: String {
        switch self {
        case .all: return "全部"
        case .survival: return "生存"
        case .storage: return "储存"
        case .production: return "生产"
        case .energy: return "能源"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .survival: return "flame.fill"
        case .storage: return "archivebox.fill"
        case .production: return "hammer.fill"
        case .energy: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .survival: return .orange
        case .storage: return .brown
        case .production: return .green
        case .energy: return .yellow
        }
    }
}

// MARK: - BuildingStatus

enum BuildingStatus: String, Codable {
    case constructing = "constructing"
    case active = "active"
    case upgrading = "upgrading"
    case damaged = "damaged"
    case inactive = "inactive"

    var displayName: String {
        switch self {
        case .constructing: return "建造中"
        case .active: return "运行中"
        case .upgrading: return "升级中"
        case .damaged: return "已损坏"
        case .inactive: return "已停用"
        }
    }

    var color: Color {
        switch self {
        case .constructing: return .orange
        case .active: return .green
        case .upgrading: return .blue
        case .damaged: return .red
        case .inactive: return .gray
        }
    }
}

// MARK: - BuildingTemplate

struct BuildingTemplate: Codable, Identifiable {
    let id: UUID
    let templateId: String
    let name: String
    let category: BuildingCategory
    let tier: Int
    let description: String
    let icon: String
    let requiredResources: [String: Int]
    let buildTimeSeconds: Int
    let maxPerTerritory: Int
    let maxLevel: Int

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name, category, tier, description, icon
        case requiredResources = "required_resources"
        case buildTimeSeconds = "build_time_seconds"
        case maxPerTerritory = "max_per_territory"
        case maxLevel = "max_level"
    }

    /// 格式化建造时间
    var formattedBuildTime: String {
        if buildTimeSeconds < 60 {
            return "\(buildTimeSeconds)秒"
        } else if buildTimeSeconds < 3600 {
            let minutes = buildTimeSeconds / 60
            let seconds = buildTimeSeconds % 60
            return seconds > 0 ? "\(minutes)分\(seconds)秒" : "\(minutes)分钟"
        } else {
            let hours = buildTimeSeconds / 3600
            let minutes = (buildTimeSeconds % 3600) / 60
            return minutes > 0 ? "\(hours)小时\(minutes)分" : "\(hours)小时"
        }
    }
}

// MARK: - PlayerBuilding

struct PlayerBuilding: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let territoryId: String
    let templateId: String
    let buildingName: String
    var status: BuildingStatus
    var level: Int
    let locationLat: Double?
    let locationLon: Double?
    let buildStartedAt: Date
    var buildCompletedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case territoryId = "territory_id"
        case templateId = "template_id"
        case buildingName = "building_name"
        case status, level
        case locationLat = "location_lat"
        case locationLon = "location_lon"
        case buildStartedAt = "build_started_at"
        case buildCompletedAt = "build_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// 将存储的经纬度转换为地图坐标（如果存在）
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = locationLat, let lon = locationLon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var isConstructionComplete: Bool {
        guard let completedAt = buildCompletedAt else { return false }
        return completedAt <= Date()
    }

    var remainingBuildTime: TimeInterval? {
        guard status == .constructing || status == .upgrading,
              let completedAt = buildCompletedAt else { return nil }
        let remaining = completedAt.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }

    var formattedRemainingTime: String {
        guard let remaining = remainingBuildTime else { return "" }
        if remaining <= 0 { return "即将完成" }
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

    var constructionProgress: Double {
        guard status == .constructing, let completedAt = buildCompletedAt else { return 1.0 }
        let totalTime = completedAt.timeIntervalSince(buildStartedAt)
        let elapsed = Date().timeIntervalSince(buildStartedAt)
        if totalTime <= 0 { return 1.0 }
        return min(max(elapsed / totalTime, 0.0), 1.0)
    }

    /// 建造进度（0.0 ~ 1.0），用于进度环显示
    var buildProgress: Double {
        guard status == .constructing || status == .upgrading,
              let completedAt = buildCompletedAt else { return 0 }
        let total = completedAt.timeIntervalSince(buildStartedAt)
        let elapsed = Date().timeIntervalSince(buildStartedAt)
        return min(1.0, max(0, elapsed / total))
    }
}

// MARK: - BuildingError

enum BuildingError: LocalizedError {
    case insufficientResources([String: Int])
    case maxBuildingsReached(Int)
    case templateNotFound
    case invalidStatus
    case maxLevelReached
    case databaseError(Error)
    case notConfigured
    case buildingNotFound

    var errorDescription: String? {
        switch self {
        case .insufficientResources(let missing):
            let list = missing.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "资源不足，还需要: \(list)"
        case .maxBuildingsReached(let limit):
            return "该建筑已达上限（最多 \(limit) 个）"
        case .templateNotFound: return "建筑模板不存在"
        case .invalidStatus: return "建筑状态无效"
        case .maxLevelReached: return "建筑已达最高等级"
        case .databaseError(let e): return "数据库错误: \(e.localizedDescription)"
        case .notConfigured: return "建筑管理器未配置"
        case .buildingNotFound: return "建筑不存在"
        }
    }
}

// MARK: - Database Models

struct NewPlayerBuilding: Encodable {
    let user_id: UUID
    let territory_id: String
    let template_id: String
    let building_name: String
    let status: String
    let level: Int
    let location_lat: Double?
    let location_lon: Double?
    let build_started_at: Date
    let build_completed_at: Date?
}

struct BuildingStatusUpdate: Encodable {
    let status: String
    let updated_at: Date
}

struct BuildingLevelUpdate: Encodable {
    let level: Int
    let updated_at: Date
}
