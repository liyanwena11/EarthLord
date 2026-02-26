//
//  LeaderboardManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就排行榜管理器
//

import Foundation
import Supabase

@MainActor
class LeaderboardManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient
    private let authManager = AuthManager.shared

    // MARK: - Fetch Leaderboard

    /// 获取成就积分排行榜
    func fetchPointsLeaderboard(limit: Int = 100, offset: Int = 0) async throws -> [LeaderboardEntry] {
        isLoading = true
        defer { isLoading = false }

        // 从数据库视图获取数据
        let response: [LeaderboardEntry] = try await supabase
            .from("v_leaderboard_with_user")
            .select()
            .order("total_points", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// 获取成就数量排行榜
    func fetchAchievementsLeaderboard(limit: Int = 100, offset: Int = 0) async throws -> [LeaderboardEntry] {
        isLoading = true
        defer { isLoading = false }

        let response: [LeaderboardEntry] = try await supabase
            .from("v_leaderboard_with_user")
            .select()
            .order("total_achievements", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// 获取完成度排行榜
    func fetchCompletionLeaderboard(limit: Int = 100, offset: Int = 0) async throws -> [LeaderboardEntry] {
        isLoading = true
        defer { isLoading = false }

        let response: [LeaderboardEntry] = try await supabase
            .from("v_leaderboard_with_user")
            .select()
            .order("completion_rate", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// 获取分类排行榜
    func fetchCategoryLeaderboard(category: AchievementCategory, limit: Int = 100, offset: Int = 0) async throws -> [CategoryLeaderboardEntry] {
        isLoading = true
        defer { isLoading = false }

        let response: [CategoryLeaderboardEntry] = try await supabase
            .from("v_category_leaderboard_with_user")
            .select()
            .eq("category", value: category.rawValue)
            .order("category_points", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return response
    }

    /// 获取速度排行榜
    func fetchSpeedLeaderboard(milestone: MilestoneType, limit: Int = 100) async throws -> [SpeedRecord] {
        isLoading = true
        defer { isLoading = false }

        let response: [SpeedRecord] = try await supabase
            .from("v_speed_leaderboard")
            .select()
            .eq("milestone_type", value: milestone.rawValue)
            .order("days_taken", ascending: true)
            .limit(limit)
            .execute()
            .value

        return response
    }

    // MARK: - Fetch User Stats

    /// 获取用户排行榜统计
    func fetchUserLeaderboardStats(userId: UUID) async throws -> UserLeaderboardStats {
        isLoading = true
        defer { isLoading = false }

        // 获取总榜数据
        let mainData: [LeaderboardEntry] = try await supabase
            .from("achievement_leaderboard")
            .select("*, profiles(username, display_name, avatar_url)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let mainEntry = mainData.first

        // 获取分类榜数据
        let categoryData: [CategoryLeaderboardEntry] = try await supabase
            .from("category_leaderboard")
            .select("*, profiles(username, display_name, avatar_url)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let categoryStats = categoryData.map { data in
            CategoryStats(
                category: data.category,
                points: data.categoryPoints,
                achievements: data.categoryAchievements,
                ranking: data.rankingPosition
            )
        }

        // 获取速度记录
        let speedData: [SpeedRecord] = try await supabase
            .from("achievement_speed_records")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return UserLeaderboardStats(
            userId: userId,
            totalPoints: mainEntry?.totalPoints ?? 0,
            totalAchievements: mainEntry?.totalAchievements ?? 0,
            completionRate: mainEntry?.completionRate ?? 0,
            rankingPosition: mainEntry?.rankingPosition,
            categoryStats: categoryStats,
            speedRecords: speedData.isEmpty ? nil : speedData
        )
    }

    /// 获取用户当前排名
    func fetchCurrentUserRanking() async throws -> Int? {
        guard let userId = authManager.currentUser?.id else {
            return nil
        }

        let response: [LeaderboardEntry] = try await supabase
            .from("achievement_leaderboard")
            .select("ranking_position")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return response.first?.rankingPosition
    }

    // MARK: - Fetch Rewards

    /// 获取排行榜奖励列表
    func fetchLeaderboardRewards(seasonId: String? = nil) async throws -> [LeaderboardReward] {
        isLoading = true
        defer { isLoading = false }

        var query = supabase
            .from("leaderboard_rewards")
            .select()

        if let seasonId = seasonId {
            query = query.eq("season_id", value: seasonId)
        }

        let response: [LeaderboardReward] = try await query
            .eq("is_active", value: true)
            .order("rank_min", ascending: true)
            .execute()
            .value

        return response
    }

    /// 获取当前赛季信息
    func fetchCurrentSeason() async throws -> LeaderboardSeason? {
        isLoading = true
        defer { isLoading = false }

        let response: [LeaderboardSeason] = try await supabase
            .from("leaderboard_seasons")
            .select()
            .eq("is_active", value: true)
            .lte("start_date", value: Date())
            .gte("end_date", value: Date())
            .order("start_date", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Manual Update

    /// 手动更新用户排行榜数据（测试用）
    func updateUserLeaderboard() async throws {
        guard let userId = authManager.currentUser?.id else {
            throw LeaderboardError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // 调用数据库函数
        try await supabase.rpc(
            "update_user_achievement_leaderboard",
            params: ["p_user_id": userId.uuidString]
        ).execute()
    }

    /// 手动重新计算所有排名（管理员功能）
    func recalculateAllRankings() async throws {
        isLoading = true
        defer { isLoading = false }

        try await supabase.rpc("recalculate_leaderboard_rankings").execute()
    }

    // MARK: - Around Me

    /// 获取用户附近的排名（前后各5名）
    func fetchAroundMe() async throws -> (before: [LeaderboardEntry], current: LeaderboardEntry?, after: [LeaderboardEntry]) {
        guard let userId = authManager.currentUser?.id else {
            throw LeaderboardError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // 先获取用户排名
        let userEntries: [LeaderboardEntry] = try await supabase
            .from("achievement_leaderboard")
            .select("*, profiles(username, display_name, avatar_url)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        guard let currentUser = userEntries.first else {
            return ([], nil, [])
        }

        let currentRank = currentUser.rankingPosition
        let rankMin = max(1, currentRank - 5)
        let rankMax = currentRank + 5

        // 获取排名范围内的数据
        let nearbyEntries: [LeaderboardEntry] = try await supabase
            .from("v_leaderboard_with_user")
            .select()
            .gte("ranking_position", value: rankMin)
            .lte("ranking_position", value: rankMax)
            .order("ranking_position", ascending: true)
            .execute()
            .value

        // 分离前后数据
        if let currentIndex = nearbyEntries.firstIndex(where: { $0.userId == userId }) {
            let before = Array(nearbyEntries.prefix(upTo: currentIndex))
            let current = nearbyEntries[currentIndex]
            let after = Array(nearbyEntries.dropFirst(currentIndex + 1))
            return (before, current, after)
        }

        return ([], currentUser, [])
    }
}

// MARK: - LeaderboardError

enum LeaderboardError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case leaderboardNotAvailable
    case invalidSeason

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "未登录"
        case .userNotFound:
            return "用户不存在"
        case .leaderboardNotAvailable:
            return "排行榜暂不可用"
        case .invalidSeason:
            return "无效的赛季"
        }
    }
}

// MARK: - Preview Data

extension LeaderboardEntry {
    static func sampleData() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "survivor_pro",
                displayName: "荒原幸存者",
                avatarUrl: nil,
                totalPoints: 3500,
                totalAchievements: 85,
                completionRate: 0.85,
                rankingPosition: 1,
                lastUpdatedAt: Date()
            ),
            LeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "builder_king",
                displayName: "建筑之王",
                avatarUrl: nil,
                totalPoints: 3200,
                totalAchievements: 78,
                completionRate: 0.78,
                rankingPosition: 2,
                lastUpdatedAt: Date()
            ),
            LeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "explorer_007",
                displayName: "探索专家",
                avatarUrl: nil,
                totalPoints: 2800,
                totalAchievements: 70,
                completionRate: 0.70,
                rankingPosition: 3,
                lastUpdatedAt: Date()
            ),
            LeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "trader_master",
                displayName: "贸易大师",
                avatarUrl: nil,
                totalPoints: 2500,
                totalAchievements: 62,
                completionRate: 0.62,
                rankingPosition: 4,
                lastUpdatedAt: Date()
            ),
            LeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "resource_lord",
                displayName: "资源领主",
                avatarUrl: nil,
                totalPoints: 2200,
                totalAchievements: 55,
                completionRate: 0.55,
                rankingPosition: 5,
                lastUpdatedAt: Date()
            )
        ]
    }
}

extension CategoryLeaderboardEntry {
    static func sampleData(category: AchievementCategory) -> [CategoryLeaderboardEntry] {
        return [
            CategoryLeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "building_expert",
                displayName: "建筑专家",
                avatarUrl: nil,
                category: category,
                categoryPoints: 800,
                categoryAchievements: 20,
                rankingPosition: 1,
                lastUpdatedAt: Date()
            ),
            CategoryLeaderboardEntry(
                id: UUID(),
                userId: UUID(),
                username: "constructor",
                displayName: "建造者",
                avatarUrl: nil,
                category: category,
                categoryPoints: 650,
                categoryAchievements: 17,
                rankingPosition: 2,
                lastUpdatedAt: Date()
            )
        ]
    }
}

extension SpeedRecord {
    static func sampleData(milestone: MilestoneType) -> [SpeedRecord] {
        return [
            SpeedRecord(
                id: UUID(),
                userId: UUID(),
                username: "speed_demon",
                displayName: "速度恶魔",
                avatarUrl: nil,
                milestoneType: milestone,
                daysTaken: 7,
                achievedAt: Date().addingTimeInterval(-604800),
                ranking: 1
            ),
            SpeedRecord(
                id: UUID(),
                userId: UUID(),
                username: "fast_learner",
                displayName: "快速学习者",
                avatarUrl: nil,
                milestoneType: milestone,
                daysTaken: 10,
                achievedAt: Date().addingTimeInterval(-864000),
                ranking: 2
            )
        ]
    }
}
