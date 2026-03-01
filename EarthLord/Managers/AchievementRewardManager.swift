//
//  AchievementRewardManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就奖励管理器 - 处理徽章、称号、资源奖励发放
//

import Foundation
import SwiftUI

/// 成就奖励管理器
class AchievementRewardManager: ObservableObject {

    // MARK: - Singleton
    static let shared = AchievementRewardManager()

    // MARK: - Published Properties
    @Published var userBadges: [Badge] = []
    @Published var userTitles: [Title] = []
    @Published var rewardHistory: [RewardRecord] = []

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let badgesKey = "achievement_badges"
    private let titlesKey = "achievement_titles"
    private let rewardsKey = "achievement_rewards"

    private init() {
        loadUserData()
    }

    // MARK: - Public Methods

    /// 发放成就奖励
    /// - Parameters:
    ///   - reward: 奖励内容
    ///   - achievementId: 成就ID
    func distributeReward(_ reward: AchievementReward, achievementId: UUID) {
        var distributedRewards: [String] = []

        // 发放积分
        if reward.points > 0 {
            addPoints(reward.points)
            distributedRewards.append("\(reward.points) 积分")
        }

        // 发放徽章
        if let badgeName = reward.badge {
            let badge = Badge(
                id: UUID().uuidString,
                name: badgeName,
                icon: "🏅",
                description: "成就徽章",
                rarity: .rare,
                unlockedAt: Date()
            )
            grantBadge(badge)
            distributedRewards.append("徽章: \(badge.name)")
        }

        // 发放称号
        if let titleName = reward.title {
            let title = Title(
                id: UUID().uuidString,
                name: titleName,
                description: "成就称号"
            )
            grantTitle(title)
            distributedRewards.append("称号: \(title.name)")
        }

        // 发放资源奖励
        if let resources = reward.resources {
            Task { @MainActor in
                distributeResources(resources)
            }
            distributedRewards.append("资源奖励")
        }

        // 发放经验值
        if reward.experience > 0 {
            addExperience(reward.experience)
            distributedRewards.append("\(reward.experience) 经验")
        }

        // 记录奖励历史
        let record = RewardRecord(
            id: UUID(),
            achievementId: achievementId,
            rewards: distributedRewards,
            grantedAt: Date()
        )
        rewardHistory.append(record)
        saveRewardHistory()

        LogDebug("🎁 [奖励] 成就奖励已发放: \(distributedRewards.joined(separator: ", "))")
    }

    /// 发放多个成就奖励
    /// - Parameter rewards: 奖励数组
    func distributeMultipleRewards(_ rewards: [(reward: AchievementReward, achievementId: UUID)]) {
        for (reward, achievementId) in rewards {
            distributeReward(reward, achievementId: achievementId)
        }
    }

    // MARK: - 积分系统

    /// 添加积分
    private func addPoints(_ points: Int) {
        let currentPoints = userDefaults.integer(forKey: "total_achievement_points")
        userDefaults.set(currentPoints + points, forKey: "total_achievement_points")
        LogDebug("⭐ [积分] 获得 \(points) 积分，总计: \(currentPoints + points)")
    }

    /// 获取总积分
    func getTotalPoints() -> Int {
        userDefaults.integer(forKey: "total_achievement_points")
    }

    // MARK: - 徽章系统

    /// 授予徽章
    private func grantBadge(_ badge: Badge) {
        // 检查是否已拥有
        guard !userBadges.contains(where: { $0.id == badge.id }) else {
            LogDebug("🏅 [徽章] 已拥有徽章: \(badge.name)")
            return
        }

        userBadges.append(badge)
        saveBadges()

        // 播放获得徽章的特效
        playBadgeUnlockEffect()

        LogDebug("🏅 [徽章] 获得新徽章: \(badge.name)")
    }

    /// 检查是否拥有徽章
    func hasBadge(_ badgeId: String) -> Bool {
        userBadges.contains(where: { $0.id == badgeId })
    }

    /// 获取徽章数量
    func getBadgeCount() -> Int {
        userBadges.count
    }

    // MARK: - 称号系统

    /// 授予称号
    private func grantTitle(_ title: Title) {
        // 检查是否已拥有
        guard !userTitles.contains(where: { $0.id == title.id }) else {
            LogDebug("🎖️ [称号] 已拥有称号: \(title.name)")
            return
        }

        userTitles.append(title)
        saveTitles()

        LogDebug("🎖️ [称号] 获得新称号: \(title.name)")
    }

    /// 检查是否拥有称号
    func hasTitle(_ titleId: String) -> Bool {
        userTitles.contains(where: { $0.id == titleId })
    }

    /// 获取称号数量
    func getTitleCount() -> Int {
        userTitles.count
    }

    /// 设置当前使用的称号
    func setCurrentTitle(_ title: Title?) {
        if let title = title {
            userDefaults.set(title.id, forKey: "current_title_id")
            LogDebug("🎖️ [称号] 设置当前称号: \(title.name)")
        } else {
            userDefaults.removeObject(forKey: "current_title_id")
            LogDebug("🎖️ [称号] 取消称号")
        }
    }

    /// 获取当前使用的称号
    func getCurrentTitle() -> Title? {
        guard let titleId = userDefaults.string(forKey: "current_title_id") else {
            return nil
        }
        return userTitles.first(where: { $0.id == titleId })
    }

    // MARK: - 资源系统

    /// 分发资源奖励
    @MainActor
    private func distributeResources(_ resources: [AchievementResourceItem]) {
        let backpack = ExplorationManager.shared

        for resource in resources {
            let item = BackpackItem(
                id: UUID().uuidString,
                itemId: UUID().uuidString,
                name: resource.name,
                category: .material,  // 使用材料分类
                quantity: resource.quantity,
                weight: resource.weight,
                quality: nil,
                icon: "cube.fill",
                backstory: nil,
                isAIGenerated: false
            )
            backpack.addItems(items: [item])
        }

        LogDebug("📦 [资源] 发放资源奖励: \(resources.map { "\($0.name)x\($0.quantity)" }.joined(separator: ", "))")
    }

    // MARK: - 经验系统

    /// 添加经验值
    private func addExperience(_ experience: Int) {
        let currentExp = userDefaults.integer(forKey: "total_experience")
        userDefaults.set(currentExp + experience, forKey: "total_experience")
        LogDebug("📈 [经验] 获得 \(experience) 经验，总计: \(currentExp + experience)")

        // TODO: 触发等级检查
        checkLevelUp()
    }

    /// 获取总经验值
    func getTotalExperience() -> Int {
        userDefaults.integer(forKey: "total_experience")
    }

    /// 检查是否升级
    private func checkLevelUp() {
        let experience = getTotalExperience()
        let currentLevel = userDefaults.integer(forKey: "player_level")

        // 简单的等级计算公式：每100经验升1级
        let newLevel = experience / 100

        if newLevel > currentLevel {
            userDefaults.set(newLevel, forKey: "player_level")
            LogDebug("🎉 [升级] 恭喜升级！当前等级: \(newLevel)")

            // TODO: 触发升级奖励和通知
        }
    }

    /// 获取当前等级
    func getCurrentLevel() -> Int {
        userDefaults.integer(forKey: "player_level")
    }

    // MARK: - 数据持久化

    private func loadUserData() {
        // 加载徽章
        if let badgesData = userDefaults.data(forKey: badgesKey),
           let badges = try? JSONDecoder().decode([Badge].self, from: badgesData) {
            userBadges = badges
        }

        // 加载称号
        if let titlesData = userDefaults.data(forKey: titlesKey),
           let titles = try? JSONDecoder().decode([Title].self, from: titlesData) {
            userTitles = titles
        }

        // 加载奖励历史
        if let rewardsData = userDefaults.data(forKey: rewardsKey),
           let rewards = try? JSONDecoder().decode([RewardRecord].self, from: rewardsData) {
            rewardHistory = rewards
        }
    }

    private func saveBadges() {
        if let data = try? JSONEncoder().encode(userBadges) {
            userDefaults.set(data, forKey: badgesKey)
        }
    }

    private func saveTitles() {
        if let data = try? JSONEncoder().encode(userTitles) {
            userDefaults.set(data, forKey: titlesKey)
        }
    }

    private func saveRewardHistory() {
        if let data = try? JSONEncoder().encode(rewardHistory) {
            userDefaults.set(data, forKey: rewardsKey)
        }
    }

    // MARK: - 特效和反馈

    private func playBadgeUnlockEffect() {
        // 触觉反馈
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Data Models

/// 徽章
struct Badge: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let rarity: BadgeRarity
    let unlockedAt: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.id == rhs.id
    }
}

/// 徽章稀有度
enum BadgeRarity: String, Codable {
    case common = "普通"
    case rare = "稀有"
    case epic = "史诗"
    case legendary = "传说"
}

/// 称号
struct Title: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Title, rhs: Title) -> Bool {
        lhs.id == rhs.id
    }
}

/// 奖励记录
struct RewardRecord: Identifiable, Codable {
    let id: UUID
    let achievementId: UUID
    let rewards: [String]
    let grantedAt: Date
}

// MARK: - AchievementReward Extension
extension AchievementReward {

    /// 创建徽章对象
    func toBadge() -> Badge? {
        guard let badge = self.badge else { return nil }
        return Badge(
            id: UUID().uuidString,
            name: badge,
            icon: "🏅",
            description: "成就徽章",
            rarity: .rare,
            unlockedAt: Date()
        )
    }

    /// 创建称号对象
    func toTitle() -> Title? {
        guard let title = self.title else { return nil }
        return Title(
            id: UUID().uuidString,
            name: title,
            description: "成就称号"
        )
    }
}
