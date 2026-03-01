//
//  LeaderboardModels.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就排行榜系统数据模型
//

import Foundation
import SwiftUI

// MARK: - LeaderboardEntry

struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let totalPoints: Int
    let totalAchievements: Int
    let completionRate: Double
    let rankingPosition: Int
    let lastUpdatedAt: Date

    var isCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case userId = "user_id"
        case totalPoints = "total_points"
        case totalAchievements = "total_achievements"
        case completionRate = "completion_rate"
        case rankingPosition = "ranking_position"
        case lastUpdatedAt = "last_updated_at"
    }

    var completionPercentage: Int {
        return Int(completionRate * 100)
    }

    var rankDisplay: String {
        switch rankingPosition {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "#\(rankingPosition)"
        }
    }

    var rankColor: Color {
        switch rankingPosition {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        default:
            return ApocalypseTheme.textSecondary
        }
    }
}

// MARK: - CategoryLeaderboardEntry

struct CategoryLeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let category: AchievementCategory
    let categoryPoints: Int
    let categoryAchievements: Int
    let rankingPosition: Int
    let lastUpdatedAt: Date

    var isCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, username, category
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case userId = "user_id"
        case categoryPoints = "category_points"
        case categoryAchievements = "category_achievements"
        case rankingPosition = "ranking_position"
        case lastUpdatedAt = "last_updated_at"
    }
}

// MARK: - SpeedRecord

struct SpeedRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let milestoneType: LeaderboardMilestoneType
    let daysTaken: Int
    let achievedAt: Date
    let ranking: Int

    var isCurrentUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, username, ranking
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case userId = "user_id"
        case milestoneType = "milestone_type"
        case daysTaken = "days_taken"
        case achievedAt = "achieved_at"
    }
}

enum LeaderboardMilestoneType: String, Codable {
    case first10 = "first_10"
    case first50 = "first_50"
    case first100 = "first_100"
    case allAchievements = "all_achievements"

    var displayName: String {
        switch self {
        case .first10:
            return "10成就里程碑"
        case .first50:
            return "50成就里程碑"
        case .first100:
            return "100成就里程碑"
        case .allAchievements:
            return "全成就里程碑"
        }
    }

    var icon: String {
        switch self {
        case .first10:
            return "10.circle.fill"
        case .first50:
            return "50.circle.fill"
        case .first100:
            return "100.circle.fill"
        case .allAchievements:
            return "star.circle.fill"
        }
    }
}

// MARK: - LeaderboardReward

struct LeaderboardReward: Codable, Identifiable {
    let id: UUID
    let rankMin: Int
    let rankMax: Int
    let rewardType: RewardType
    let rewardData: RewardData
    let seasonId: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case rankMin = "rank_min"
        case rankMax = "rank_max"
        case rewardType = "reward_type"
        case rewardData = "reward_data"
        case seasonId = "season_id"
        case isActive = "is_active"
    }

    var rankRangeDisplay: String {
        if rankMin == rankMax {
            return "#\(rankMin)"
        }
        return "#\(rankMin)-#\(rankMax)"
    }
}

enum RewardType: String, Codable {
    case resources
    case items
    case emblem
    case title
    case bonus
}

struct RewardData: Codable {
    let id: String?
    let name: String?
    let description: String?
    let text: String?
    let resources: [String: Int]?
}

// MARK: - LeaderboardSeason

struct LeaderboardSeason: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }

    var daysRemaining: Int? {
        guard isActive else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    var isSeasonEnded: Bool {
        return Date() > endDate
    }

    var seasonProgress: Double? {
        guard isActive && !isSeasonEnded else { return nil }
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1)
    }
}

// MARK: - UserLeaderboardStats

struct UserLeaderboardStats: Codable {
    let userId: UUID
    let totalPoints: Int
    let totalAchievements: Int
    let completionRate: Double
    let rankingPosition: Int?
    let categoryStats: [CategoryStats]
    let speedRecords: [SpeedRecord]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalPoints = "total_points"
        case totalAchievements = "total_achievements"
        case completionRate = "completion_rate"
        case rankingPosition = "ranking_position"
        case categoryStats = "category_stats"
        case speedRecords = "speed_records"
    }
}

struct CategoryStats: Codable, Identifiable {
    let category: AchievementCategory
    let points: Int
    let achievements: Int
    let ranking: Int?

    var id: String {
        return category.rawValue
    }
}

// MARK: - LeaderboardType

enum LeaderboardTab: String, CaseIterable {
    case points = "points"
    case achievements = "achievements"
    case completion = "completion"
    case category = "category"
    case speed = "speed"

    var displayName: String {
        switch self {
        case .points:
            return "积分榜"
        case .achievements:
            return "数量榜"
        case .completion:
            return "完成度"
        case .category:
            return "分类榜"
        case .speed:
            return "速度榜"
        }
    }

    var icon: String {
        switch self {
        case .points:
            return "star.fill"
        case .achievements:
            return "trophy.fill"
        case .completion:
            return "percent"
        case .category:
            return "square.grid.2x2"
        case .speed:
            return "bolt.fill"
        }
    }
}

// MARK: - LeaderboardFilter

enum LeaderboardTimeFilter: String, CaseIterable {
    case all = "all"
    case week = "week"
    case month = "month"
    case season = "season"

    var displayName: String {
        switch self {
        case .all:
            return "全部时间"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .season:
            return "本赛季"
        }
    }
}
