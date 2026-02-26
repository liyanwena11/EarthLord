//
//  AchievementsView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就系统完整视图
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var manager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedAchievement: Achievement?
    @State private var showAchievementDetail = false
    @State private var showLeaderboard = false

    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return manager.achievements.filter { $0.category == category }
        }
        return manager.achievements
    }

    var body: some View {
        ZStack {
            // 背景
            Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                navigationBar

                ScrollView {
                    VStack(spacing: 16) {
                        // 统计概览
                        statsOverview
                            .padding(.horizontal, 16)

                        // 分类筛选
                        categoryFilter

                        // 成就列表
                        achievementsList
                    }
                    .padding(.bottom, 80)
                }
            }

            // 成就详情弹窗
            if showAchievementDetail, let achievement = selectedAchievement {
                AchievementDetailPopup(
                    achievement: achievement,
                    isPresented: $showAchievementDetail
                )
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            AchievementLeaderboardDetailView(userStats: nil)
        }
        .task {
            await manager.refreshData()
        }
        .refreshable {
            await manager.refreshData()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Text("成就")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                showLeaderboard = true
            } label: {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255))
                    .frame(width: 36, height: 36)
                    .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        HStack(spacing: 12) {
            // 解锁数量
            AchievementStatCard(
                icon: "trophy.fill",
                title: "已解锁",
                value: "\(manager.totalUnlocked)",
                subtitle: "/\(manager.achievements.count)",
                color: Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255)
            )

            // 完成度
            AchievementStatCard(
                icon: "percent",
                title: "完成度",
                value: "\(manager.completionPercentage)%",
                subtitle: "",
                color: Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255)
            )

            // 总积分
            AchievementStatCard(
                icon: "star.fill",
                title: "总积分",
                value: "\(manager.totalPoints)",
                subtitle: "",
                color: Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)
            )
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(
                    icon: "square.grid.2x2",
                    title: "全部",
                    count: manager.achievements.count,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        icon: category.icon,
                        title: category.displayName,
                        count: manager.achievements.filter { $0.category == category }.count,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Achievements List

    private var achievementsList: some View {
        LazyVStack(spacing: 12) {
            if manager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredAchievements.isEmpty {
                EmptyAchievementsView()
            } else {
                ForEach(filteredAchievements) { achievement in
                    AchievementCardEnhanced(achievement: achievement)
                        .onTapGesture {
                            selectedAchievement = achievement
                            showAchievementDetail = true
                        }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Achievement Stat Card

struct AchievementStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 13))

                Text("(\(count))")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
            }
            .foregroundColor(isSelected ? .white : Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)
                    : Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Achievement Card Enhanced

struct AchievementCardEnhanced: View {
    let achievement: Achievement

    private let cardBackground = Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)
    private let iconBlue = Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

    var body: some View {
        HStack(spacing: 16) {
            // 成就图标
            achievementIcon

            // 成就信息
            achievementInfo

            Spacer()

            // 状态指示
            statusIndicator
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    achievement.isUnlocked
                        ? achievement.category.color.opacity(0.5)
                        : Color.clear,
                    lineWidth: 2
                )
        )
    }

    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(
                    achievement.isUnlocked
                        ? achievement.category.color.opacity(0.2)
                        : Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)
                )
                .frame(width: 60, height: 60)

            if achievement.isUnlocked {
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.category.color)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
            }
        }
    }

    private var achievementInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题
            Text(achievement.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

            // 描述
            Text(achievement.description)
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
                .lineLimit(2)

            // 进度条（未解锁时显示）
            if !achievement.isUnlocked {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(achievement.requirement.displayText)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))

                        Spacer()

                        Text("\(achievement.progressPercentage)%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(achievement.category.color)
                    }

                    ProgressView(value: achievement.progress)
                        .tint(achievement.category.color)
                        .frame(height: 4)
                }
            }

            // 奖励标签
            if achievement.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10))

                    Text("已获得奖励")
                        .font(.system(size: 11))
                }
                .foregroundColor(Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255))
            }
        }
    }

    private var statusIndicator: some View {
        VStack(spacing: 4) {
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
            }
        }
    }
}

// MARK: - Achievement Detail Popup

struct AchievementDetailPopup: View {
    let achievement: Achievement
    @Binding var isPresented: Bool

    private let cardBackground = Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)
    private let iconBlue = Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 0) {
                // 关闭按钮
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                            .clipShape(Circle())
                    }
                }
                .padding(16)

                VStack(spacing: 20) {
                    // 成就图标
                    ZStack {
                        Circle()
                            .fill(
                                achievement.isUnlocked
                                    ? achievement.category.color.opacity(0.2)
                                    : Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)
                            )
                            .frame(width: 100, height: 100)

                        if achievement.isUnlocked {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 40))
                                .foregroundColor(achievement.category.color)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
                        }
                    }

                    // 标题
                    Text(achievement.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // 描述
                    Text(achievement.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // 进度
                    if !achievement.isUnlocked {
                        VStack(spacing: 8) {
                            Text("进度: \(achievement.progressPercentage)%")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(achievement.category.color)

                            ProgressView(value: achievement.progress)
                                .tint(achievement.category.color)
                                .frame(width: 200, height: 6)

                            Text(achievement.requirement.displayText)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
                        }
                    }

                    // 奖励
                    VStack(alignment: .leading, spacing: 12) {
                        Text("奖励")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 8) {
                            if let emblemId = achievement.reward.emblemId {
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255))
                                    Text("专属徽章")
                                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                                    Spacer()
                                }
                            }

                            if let title = achievement.reward.title {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255))
                                    Text("称号: \(title)")
                                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                                    Spacer()
                                }
                            }

                            if achievement.reward.experience > 0 {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(iconBlue)
                                    Text("\(achievement.reward.experience) 经验")
                                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                                    Spacer()
                                }
                            }

                            ForEach(Array(achievement.reward.bonusResources.keys.sorted()), id: \.self) { resource in
                                if let amount = achievement.reward.bonusResources[resource] {
                                    HStack {
                                        Image(systemName: "cube.fill")
                                            .foregroundColor(Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255))
                                        Text("\(resource): \(amount)")
                                            .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .background(cardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Empty Achievements View

struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))

            Text("暂无成就")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

            Text("完成特定目标可解锁成就")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
}