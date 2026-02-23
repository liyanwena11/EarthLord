//
//  AchievementsView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  成就列表视图
//

import SwiftUI

struct AchievementsView: View {
    @State private var achievements: [Achievement] = []
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var isLoading = false

    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            icon: "square.grid.2x2",
                            title: "全部",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                icon: category.icon,
                                title: category.displayName,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // 成就统计
                HStack(spacing: 12) {
                    AchievementStat(
                        icon: "trophy.fill",
                        title: "已解锁",
                        value: "\(unlockedCount)",
                        total: "\(achievements.count)",
                        color: ApocalypseTheme.warning
                    )

                    AchievementStat(
                        icon: "percent",
                        title: "完成度",
                        value: "\(completionPercentage)%",
                        total: "",
                        color: ApocalypseTheme.success
                    )
                }
                .padding(.horizontal)

                // 成就列表
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if filteredAchievements.isEmpty {
                    EmptyAchievementsView()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .task {
            await loadAchievements()
        }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    private var completionPercentage: Int {
        guard !achievements.isEmpty else { return 0 }
        return Int(Double(unlockedCount) / Double(achievements.count) * 100)
    }

    private func loadAchievements() async {
        isLoading = true
        // TODO: Implement actual data loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            self.achievements = sampleAchievements
            self.isLoading = false
        }
    }
}

// MARK: - AchievementCard

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.2) : ApocalypseTheme.textMuted.opacity(0.1))
                    .frame(width: 56, height: 56)

                if achievement.isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievement.category.color)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            // 内容
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? ApocalypseTheme.textPrimary : ApocalypseTheme.textSecondary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .lineLimit(2)

                if achievement.isUnlocked {
                    Text("已解锁 - \(achievement.requirement.displayText)")
                        .font(.caption2)
                        .foregroundColor(achievement.category.color)
                } else {
                    // 进度条
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(achievement.requirement.displayText)
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.textMuted)
                            Spacer()
                            Text("\(achievement.progressPercentage)%")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }

                        ProgressView(value: achievement.progress)
                            .tint(achievement.category.color)
                            .scaleEffect(x: 1, y: 0.8, anchor: .center)
                    }
                }
            }

            Spacer()

            // 状态
            VStack(spacing: 4) {
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(ApocalypseTheme.success)
                }

                if let reward = achievement.reward.title {
                    Text(reward)
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.warning)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? achievement.category.color.opacity(0.3) : ApocalypseTheme.textMuted.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - CategoryButton

struct CategoryButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
            .cornerRadius(8)
        }
    }
}

// MARK: - AchievementStat

struct AchievementStat: View {
    let icon: String
    let title: String
    let value: String
    let total: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(ApocalypseTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                if !total.isEmpty {
                    Text("/\(total)")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ApocalypseTheme.background)
        .cornerRadius(12)
    }
}

// MARK: - EmptyAchievementsView

struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "medal")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textMuted)
            Text("暂无成就")
                .font(.title3)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text("完成特定目标可解锁成就")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Sample Data

private let sampleAchievements: [Achievement] = [
    Achievement(
        id: "1",
        category: .building,
        title: "第一块砖",
        description: "建造你的第一个建筑",
        icon: "house.fill",
        requirement: .buildCount(buildingType: "any", count: 1),
        reward: AchievementReward(emblemId: "first_build", bonusResources: [:], title: "建筑师学徒", experience: 50),
        isUnlocked: true,
        unlockedAt: Date().addingTimeInterval(-86400),
        progress: 1.0
    ),
    Achievement(
        id: "2",
        category: .building,
        title: "建筑大师",
        description: "建造10个建筑",
        icon: "building.columns.fill",
        requirement: .buildCount(buildingType: "any", count: 10),
        reward: AchievementReward(emblemId: "master_builder", bonusResources: ["wood": 100], title: "建筑大师", experience: 500),
        isUnlocked: false,
        unlockedAt: nil,
        progress: 0.3
    ),
    Achievement(
        id: "3",
        category: .resource,
        title: "资源大亨",
        description: "收集10000单位资源",
        icon: "cube.fill",
        requirement: .resourceCollected(resourceId: "any", amount: 10000),
        reward: AchievementReward(emblemId: "resource_tycoon", bonusResources: [:], title: "资源大亨", experience: 300),
        isUnlocked: false,
        unlockedAt: nil,
        progress: 0.25
    ),
    Achievement(
        id: "4",
        category: .territory,
        title: "领主",
        description: "拥有1个领地",
        icon: "flag.fill",
        requirement: .territoryCount(count: 1),
        reward: AchievementReward(emblemId: "lord", bonusResources: [:], title: "领主", experience: 100),
        isUnlocked: true,
        unlockedAt: Date().addingTimeInterval(-43200),
        progress: 1.0
    )
]

// 预览
#Preview {
    AchievementsView()
}
