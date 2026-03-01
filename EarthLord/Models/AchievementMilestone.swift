//
//  AchievementMilestone.swift
//  EarthLord
//
//  Created by Claude on 2026-02-27.
//  成就里程碑系统模型
//

import Foundation
import SwiftUI

// MARK: - Achievement Milestone

enum AchievementMilestone: String, Codable, CaseIterable {
    case firstAchievement = "first"
    case tenAchievements = "ten"
    case twentyFiveAchievements = "twenty_five"
    case fiftyAchievements = "fifty"
    case hundredAchievements = "hundred"
    case allAchievements = "all"

    var displayName: String {
        switch self {
        case .firstAchievement: return "初出茅庐"
        case .tenAchievements: return "小有所成"
        case .twentyFiveAchievements: return "渐入佳境"
        case .fiftyAchievements: return "成就大师"
        case .hundredAchievements: return "传奇猎人"
        case .allAchievements: return "全能收藏家"
        }
    }

    var requiredCount: Int {
        switch self {
        case .firstAchievement: return 1
        case .tenAchievements: return 10
        case .twentyFiveAchievements: return 25
        case .fiftyAchievements: return 50
        case .hundredAchievements: return 100
        case .allAchievements: return -1 // 动态计算总成就数
        }
    }

    var icon: String {
        switch self {
        case .firstAchievement: return "🌱"
        case .tenAchievements: return "🌿"
        case .twentyFiveAchievements: return "🌳"
        case .fiftyAchievements: return "🏆"
        case .hundredAchievements: return "👑"
        case .allAchievements: return "💎"
        }
    }

    var reward: AchievementMilestoneReward {
        switch self {
        case .firstAchievement:
            return AchievementMilestoneReward(
                title: "新手称号",
                bonusPoints: 50,
                emblem: "novice_badge",
                resources: ["wood": 100, "stone": 50]
            )
        case .tenAchievements:
            return AchievementMilestoneReward(
                title: "探索者称号",
                bonusPoints: 150,
                emblem: "explorer_badge",
                resources: ["wood": 200, "stone": 100, "iron": 50]
            )
        case .twentyFiveAchievements:
            return AchievementMilestoneReward(
                title: "专家称号",
                bonusPoints: 300,
                emblem: "expert_badge",
                resources: ["wood": 500, "stone": 300, "iron": 200]
            )
        case .fiftyAchievements:
            return AchievementMilestoneReward(
                title: "大师称号",
                bonusPoints: 500,
                emblem: "master_badge",
                resources: ["wood": 1000, "stone": 500, "iron": 300, "gold": 100]
            )
        case .hundredAchievements:
            return AchievementMilestoneReward(
                title: "传奇称号",
                bonusPoints: 1000,
                emblem: "legend_badge",
                resources: ["wood": 2000, "stone": 1000, "iron": 500, "gold": 200]
            )
        case .allAchievements:
            return AchievementMilestoneReward(
                title: "全能收藏家",
                bonusPoints: 2000,
                emblem: "collector_badge",
                resources: ["wood": 5000, "stone": 3000, "iron": 1500, "gold": 500]
            )
        }
    }
}

// MARK: - Achievement Milestone Reward

struct AchievementMilestoneReward: Codable {
    let title: String
    let bonusPoints: Int
    let emblem: String
    let resources: [String: Int]
}

// MARK: - User Achievement Milestone

struct UserAchievementMilestone: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let milestoneType: AchievementMilestone
    let isUnlocked: Bool
    let unlockedAt: Date?
    let isClaimed: Bool
    let claimedAt: Date?
}

// MARK: - Achievement Milestone Progress

struct AchievementMilestoneProgress {
    let milestone: AchievementMilestone
    let current: Int
    let target: Int
    let isUnlocked: Bool
    let isClaimed: Bool

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

// MARK: - Achievement Milestone Manager

@MainActor
class AchievementMilestoneManager: ObservableObject {
    static let shared = AchievementMilestoneManager()

    @Published var milestones: [AchievementMilestoneProgress] = []
    @Published var unlockedMilestones: [UserAchievementMilestone] = []

    private init() {}

    /// 检查并解锁里程碑
    func checkMilestones(currentAchievements: Int, totalAchievements: Int) async {
        var newMilestones: [AchievementMilestoneProgress] = []

        for milestone in AchievementMilestone.allCases {
            let target = milestone == .allAchievements ? totalAchievements : milestone.requiredCount
            let isUnlocked = currentAchievements >= target

            let progress = AchievementMilestoneProgress(
                milestone: milestone,
                current: currentAchievements,
                target: target,
                isUnlocked: isUnlocked,
                isClaimed: false
            )

            newMilestones.append(progress)

            // 如果刚解锁，触发奖励
            if isUnlocked && !unlockedMilestones.contains(where: { $0.milestoneType == milestone }) {
                await unlockMilestone(milestone)
            }
        }

        milestones = newMilestones
    }

    private func unlockMilestone(_ milestone: AchievementMilestone) async {
        guard let userId = AuthManager.shared.currentUser?.id else {
            return
        }

        let userMilestone = UserAchievementMilestone(
            id: UUID(),
            userId: userId,
            milestoneType: milestone,
            isUnlocked: true,
            unlockedAt: Date(),
            isClaimed: false,
            claimedAt: nil
        )

        unlockedMilestones.append(userMilestone)

        // 发送通知
        print("🎉 里程碑解锁: \(milestone.displayName)")
    }

    /// 领取里程碑奖励
    func claimMilestoneReward(_ milestone: AchievementMilestone) async throws {
        guard let userMilestone = unlockedMilestones.first(where: { $0.milestoneType == milestone && !$0.isClaimed }) else {
            return
        }

        // 标记为已领取
        if let index = unlockedMilestones.firstIndex(where: { $0.id == userMilestone.id }) {
            unlockedMilestones[index] = UserAchievementMilestone(
                id: userMilestone.id,
                userId: userMilestone.userId,
                milestoneType: userMilestone.milestoneType,
                isUnlocked: true,
                unlockedAt: userMilestone.unlockedAt,
                isClaimed: true,
                claimedAt: Date()
            )
        }
    }
}