//
//  AchievementManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就系统管理器
//

import Foundation
import Supabase
import SwiftUI

@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var achievements: [Achievement] = []
    @Published var userAchievements: [UserAchievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient
    private let authManager = AuthManager.shared

    private init() {}

    // MARK: - Fetch Data

    /// 获取所有成就定义
    func fetchAllAchievements() async throws {
        isLoading = true
        defer { isLoading = false }

        let response: [AchievementDefinition] = try await supabase
            .from("achievements")
            .select()
            .eq("is_active", value: true)
            .order("category", ascending: true)
            .order("points", ascending: false)
            .execute()
            .value

        await MainActor.run {
            self.achievements = response.map { def in
                Achievement(
                    id: def.id,
                    category: AchievementCategory(rawValue: def.category) ?? .building,
                    title: def.title,
                    description: def.description,
                    icon: def.icon,
                    requirement: parseRequirement(def.requirement),
                    reward: AchievementReward(
                        emblemId: def.rewardEmblemId,
                        bonusResources: def.rewardResources ?? [:],
                        title: def.rewardTitle,
                        experience: def.rewardExperience
                    ),
                    isUnlocked: false,
                    unlockedAt: nil,
                    progress: 0.0
                )
            }
        }
    }

    /// 获取用户成就进度
    func fetchUserAchievements() async throws {
        guard let userId = authManager.currentUser?.id else {
            throw AchievementError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // 获取用户的成就进度
        let response: [UserAchievementData] = try await supabase
            .from("user_achievements")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        await MainActor.run {
            self.userAchievements = response.map { data in
                UserAchievement(
                    id: data.id,
                    userId: data.userId,
                    achievementId: data.achievementId,
                    progress: data.progress,
                    isUnlocked: data.isUnlocked,
                    unlockedAt: data.unlockedAt
                )
            }

            // 更新成就列表中的解锁状态和进度
            updateAchievementProgress()
        }
    }

    /// 刷新所有数据
    func refreshData() async {
        do {
            try await fetchAllAchievements()
            try await fetchUserAchievements()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("加载成就数据失败: \(error)")
        }
    }

    // MARK: - Update Progress

    /// 更新成就进度（由游戏事件触发）
    func updateProgress(achievementId: String, progress: Double) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw AchievementError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        // 检查是否已解锁
        if let userAch = userAchievements.first(where: { $0.achievementId == achievementId }),
           userAch.isUnlocked {
            return // 已解锁，无需更新
        }

        // 准备更新数据
        let isUnlocked = progress >= 1.0
        let unlockedAt = isUnlocked ? ISO8601DateFormatter().string(from: Date()) : nil

        let updateData = UserAchievementUpdate(
            userId: userId.uuidString,
            achievementId: achievementId,
            progress: min(progress, 1.0),
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt
        )

        try await supabase
            .from("user_achievements")
            .upsert(updateData)
            .execute()

        // 刷新数据
        try await fetchUserAchievements()

        // 数据库触发器会自动更新排行榜
    }

    /// 批量检查和更新成就进度
    func checkAndUnlockAchievements(requirementType: String, currentValue: Int) async {
        for achievement in achievements {
            if shouldUpdateAchievement(achievement, requirementType: requirementType, currentValue: currentValue) {
                do {
                    try await updateProgress(
                        achievementId: achievement.id,
                        progress: calculateProgress(achievement, currentValue: currentValue)
                    )
                } catch {
                    print("更新成就进度失败: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func updateAchievementProgress() {
        for index in achievements.indices {
            let achievement = achievements[index]
            if let userAch = userAchievements.first(where: { $0.achievementId == achievement.id }) {
                achievements[index] = Achievement(
                    id: achievement.id,
                    category: achievement.category,
                    title: achievement.title,
                    description: achievement.description,
                    icon: achievement.icon,
                    requirement: achievement.requirement,
                    reward: achievement.reward,
                    isUnlocked: userAch.isUnlocked,
                    unlockedAt: userAch.unlockedAt,
                    progress: userAch.progress
                )
            }
        }
    }

    private func parseRequirement(_ reqString: String) -> AchievementRequirement {
        let parts = reqString.split(separator: ":").map(String.init)
        guard parts.count >= 2 else {
            return .custom(type: reqString, target: 1, current: 0)
        }

        let type = parts[0]
        switch type {
        case "build_count":
            return .buildCount(buildingType: parts[1], count: Int(parts[2]) ?? 1)
        case "resource_collected":
            return .resourceCollected(resourceId: parts[1], amount: Int(parts[2]) ?? 1)
        case "territory_level":
            return .territoryLevel(level: Int(parts[1]) ?? 1)
        case "territory_count":
            return .territoryCount(count: Int(parts[1]) ?? 1)
        case "poi_scavenged":
            return .poiScavenged(count: Int(parts[1]) ?? 1)
        case "trade_completed":
            return .tradeCompleted(count: Int(parts[1]) ?? 1)
        default:
            return .custom(type: type, target: Int(parts[1]) ?? 1, current: 0)
        }
    }

    private func shouldUpdateAchievement(_ achievement: Achievement, requirementType: String, currentValue: Int) -> Bool {
        switch achievement.requirement {
        case .buildCount(let type, _):
            return requirementType == "build_\(type)" || requirementType == "build_any"
        case .resourceCollected(let id, _):
            return requirementType == "resource_\(id)" || requirementType == "resource_any"
        case .territoryLevel:
            return requirementType == "territory_level"
        case .territoryCount:
            return requirementType == "territory_count"
        case .poiScavenged:
            return requirementType == "poi_scavenged"
        case .tradeCompleted:
            return requirementType == "trade_completed"
        case .custom(let type, _, _):
            return requirementType == type
        }
    }

    private func calculateProgress(_ achievement: Achievement, currentValue: Int) -> Double {
        switch achievement.requirement {
        case .buildCount(_, let target):
            return min(Double(currentValue) / Double(target), 1.0)
        case .resourceCollected(_, let target):
            return min(Double(currentValue) / Double(target), 1.0)
        case .territoryLevel(let target):
            return currentValue >= target ? 1.0 : Double(currentValue) / Double(target)
        case .territoryCount(let target):
            return min(Double(currentValue) / Double(target), 1.0)
        case .poiScavenged(let target):
            return min(Double(currentValue) / Double(target), 1.0)
        case .tradeCompleted(let target):
            return min(Double(currentValue) / Double(target), 1.0)
        case .custom(_, let target, _):
            return min(Double(currentValue) / Double(target), 1.0)
        }
    }

    // MARK: - Statistics

    var totalUnlocked: Int {
        userAchievements.filter { $0.isUnlocked }.count
    }

    var completionPercentage: Int {
        guard !achievements.isEmpty else { return 0 }
        return Int(Double(totalUnlocked) / Double(achievements.count) * 100)
    }

    var totalPoints: Int {
        var points = 0
        for userAch in userAchievements where userAch.isUnlocked {
            if let _ = achievements.first(where: { $0.id == userAch.achievementId }) {
                // 假设成就有积分属性（需要从数据库获取）
                points += 10 // 默认积分，实际应从成就定义中获取
            }
        }
        return points
    }
}

// MARK: - Data Models

struct AchievementDefinition: Codable {
    let id: String
    let category: String
    let title: String
    let description: String
    let icon: String
    let requirement: String
    let rewardEmblemId: String?
    let rewardResources: [String: Int]?
    let rewardTitle: String?
    let rewardExperience: Int
    let difficulty: String?
    let points: Int?
    let isActive: Bool
}

struct UserAchievementData: Codable {
    let id: UUID
    let userId: UUID
    let achievementId: String
    let progress: Double
    let isUnlocked: Bool
    let unlockedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, progress
        case userId = "user_id"
        case achievementId = "achievement_id"
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

struct UserAchievement {
    let id: UUID
    let userId: UUID
    let achievementId: String
    let progress: Double
    let isUnlocked: Bool
    let unlockedAt: Date?
}

// MARK: - Update Model

struct UserAchievementUpdate: Encodable {
    let userId: String
    let achievementId: String
    let progress: Double
    let isUnlocked: Bool
    let unlockedAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case achievementId = "achievement_id"
        case progress
        case isUnlocked = "is_unlocked"
        case unlockedAt = "unlocked_at"
    }
}

// MARK: - Errors

enum AchievementError: LocalizedError {
    case notAuthenticated
    case achievementNotFound
    case alreadyUnlocked
    case invalidProgress

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "未登录"
        case .achievementNotFound:
            return "成就不存在"
        case .alreadyUnlocked:
            return "成就已解锁"
        case .invalidProgress:
            return "无效的进度值"
        }
    }
}