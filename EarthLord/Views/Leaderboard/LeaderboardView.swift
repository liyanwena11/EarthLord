//
//  LeaderboardView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就排行榜主视图
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var manager = LeaderboardManager()
    @State private var selectedTab: LeaderboardTab = .points
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedMilestone: MilestoneType = .first10
    @State private var season: LeaderboardSeason?
    @State private var entries: [LeaderboardEntry] = []
    @State private var categoryEntries: [CategoryLeaderboardEntry] = []
    @State private var speedRecords: [SpeedRecord] = []
    @State private var currentUserStats: UserLeaderboardStats?
    @State private var isShowingMyRank = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部赛季信息
                if let season = season {
                    SeasonHeader(season: season)
                }

                // 标签页
                TabsScrollView(selectedTab: $selectedTab)
                    .padding(.horizontal)

                // 内容
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView("加载中...")
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            switch selectedTab {
                            case .points:
                                LeaderboardListView(
                                    entries: entries,
                                    type: .points
                                )
                            case .achievements:
                                LeaderboardListView(
                                    entries: entries,
                                    type: .achievements
                                )
                            case .completion:
                                LeaderboardListView(
                                    entries: entries,
                                    type: .completion
                                )
                            case .category:
                                CategoryLeaderboardContentView(
                                    categoryEntries: categoryEntries,
                                    selectedCategory: $selectedCategory
                                )
                            case .speed:
                                SpeedLeaderboardContentView(
                                    speedRecords: speedRecords,
                                    selectedMilestone: $selectedMilestone
                                )
                            }
                        }
                    }
                    .padding()
                }

                // 底部我的排名
                if let stats = currentUserStats {
                    MyRankingCard(stats: stats, tab: selectedTab)
                        .padding()
                }
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedTab) { _, newValue in
            Task {
                await loadData()
            }
        }
        .onChange(of: selectedCategory) { _, newValue in
            if newValue != nil {
                Task {
                    await loadCategoryLeaderboard()
                }
            }
        }
        .onChange(of: selectedMilestone) { _, newValue in
            Task {
                await loadSpeedLeaderboard()
            }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 加载赛季信息
            if season == nil {
                season = try? await manager.fetchCurrentSeason()
            }

            // 根据选中的标签加载不同数据
            switch selectedTab {
            case .points:
                entries = try await manager.fetchPointsLeaderboard()
            case .achievements:
                entries = try await manager.fetchAchievementsLeaderboard()
            case .completion:
                entries = try await manager.fetchCompletionLeaderboard()
            case .category:
                if selectedCategory == nil {
                    selectedCategory = .building
                }
                await loadCategoryLeaderboard()
            case .speed:
                await loadSpeedLeaderboard()
            }

            // 加载用户统计
            if let userId = AuthManager.shared.currentUser?.id {
                currentUserStats = try? await manager.fetchUserLeaderboardStats(userId: userId)
            }
        } catch {
            print("加载排行榜失败: \(error)")
        }
    }

    private func loadCategoryLeaderboard() async {
        guard let category = selectedCategory else { return }
        do {
            categoryEntries = try await manager.fetchCategoryLeaderboard(category: category)
        } catch {
            print("加载分类排行榜失败: \(error)")
        }
    }

    private func loadSpeedLeaderboard() async {
        do {
            speedRecords = try await manager.fetchSpeedLeaderboard(milestone: selectedMilestone)
        } catch {
            print("加载速度排行榜失败: \(error)")
        }
    }
}

// MARK: - SeasonHeader

struct SeasonHeader: View {
    let season: LeaderboardSeason

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(season.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    if let description = season.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }

                Spacer()

                if let daysRemaining = season.daysRemaining {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("剩余 \(daysRemaining) 天")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.warning)

                        if let progress = season.seasonProgress {
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)

            // 进度条
            if let progress = season.seasonProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(ApocalypseTheme.background)
                            .frame(height: 4)

                        Rectangle()
                            .fill(ApocalypseTheme.primary)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                .cornerRadius(2)
            }
        }
        .padding()
    }
}

// MARK: - TabsScrollView

struct TabsScrollView: View {
    @Binding var selectedTab: LeaderboardTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                    LeaderboardTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
    }
}

struct LeaderboardTabButton: View {
    let tab: LeaderboardTab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                Text(tab.displayName)
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

// MARK: - LeaderboardListView

struct LeaderboardListView: View {
    let entries: [LeaderboardEntry]
    let type: LeaderboardTab

    var body: some View {
        VStack(spacing: 12) {
            ForEach(entries) { entry in
                LeaderboardRow(entry: entry, type: type)
            }
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardTab

    var body: some View {
        HStack(spacing: 16) {
            // 排名
            Text(entry.rankDisplay)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(entry.rankColor)
                .frame(width: 50)

            // 头像
            if let avatarUrl = entry.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ApocalypseTheme.textMuted.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(ApocalypseTheme.textMuted.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
            }

            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName ?? entry.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                HStack(spacing: 8) {
                    switch type {
                    case .points:
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.warning)
                            Text("\(entry.totalPoints) 积分")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    case .achievements:
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.warning)
                            Text("\(entry.totalAchievements) 成就")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    case .completion:
                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.success)
                            Text("\(entry.completionPercentage)%")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    default:
                        EmptyView()
                    }
                }
            }

            Spacer()

            // 标记
            if entry.isCurrentUser {
                Text("我")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ApocalypseTheme.primary)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    entry.isCurrentUser ? ApocalypseTheme.primary : ApocalypseTheme.textMuted.opacity(0.2),
                    lineWidth: entry.isCurrentUser ? 2 : 1
                )
        )
    }
}

// MARK: - CategoryLeaderboardContentView

struct CategoryLeaderboardContentView: View {
    let categoryEntries: [CategoryLeaderboardEntry]
    @Binding var selectedCategory: AchievementCategory?

    var body: some View {
        VStack(spacing: 12) {
            // 分类选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }

            // 分类排行榜
            ForEach(categoryEntries) { entry in
                CategoryLeaderboardRow(entry: entry)
            }
        }
    }
}

struct CategoryFilterButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : ApocalypseTheme.cardBackground)
            .cornerRadius(8)
        }
    }
}

struct CategoryLeaderboardRow: View {
    let entry: CategoryLeaderboardEntry

    var body: some View {
        HStack(spacing: 16) {
            // 排名
            Text("#\(entry.rankingPosition)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(entry.rankingPosition <= 3 ? ApocalypseTheme.warning : ApocalypseTheme.textSecondary)
                .frame(width: 50)

            // 头像
            Circle()
                .fill(entry.category.color.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: entry.category.icon)
                        .foregroundColor(entry.category.color)
                }

            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName ?? entry.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.warning)
                        Text("\(entry.categoryPoints) 积分")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                        Text("\(entry.categoryAchievements) 个")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - SpeedLeaderboardContentView

struct SpeedLeaderboardContentView: View {
    let speedRecords: [SpeedRecord]
    @Binding var selectedMilestone: MilestoneType

    var body: some View {
        VStack(spacing: 12) {
            // 里程碑选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([MilestoneType.first10, .first50, .first100, .allAchievements], id: \.self) { milestone in
                        MilestoneFilterButton(
                            milestone: milestone,
                            isSelected: selectedMilestone == milestone
                        ) {
                            withAnimation {
                                selectedMilestone = milestone
                            }
                        }
                    }
                }
            }

            // 速度排行榜
            ForEach(speedRecords) { record in
                SpeedRecordRow(record: record)
            }
        }
    }
}

struct MilestoneFilterButton: View {
    let milestone: MilestoneType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: milestone.icon)
                    .font(.caption)
                Text(milestone.displayName)
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

struct SpeedRecordRow: View {
    let record: SpeedRecord

    var body: some View {
        HStack(spacing: 16) {
            // 排名
            Text("#\(record.ranking)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(record.ranking <= 3 ? ApocalypseTheme.warning : ApocalypseTheme.textSecondary)
                .frame(width: 50)

            // 里程碑图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.success.opacity(0.3))
                    .frame(width: 44, height: 44)

                Image(systemName: record.milestoneType.icon)
                    .foregroundColor(ApocalypseTheme.success)
            }

            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                Text(record.displayName ?? record.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.success)
                        Text("\(record.daysTaken) 天")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }

                    Text("•")
                        .foregroundColor(ApocalypseTheme.textMuted)

                    Text(record.achievedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            Spacer()
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - MyRankingCard

struct MyRankingCard: View {
    let stats: UserLeaderboardStats
    let tab: LeaderboardTab

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("我的排名")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                if let ranking = stats.rankingPosition {
                    Text("#\(ranking)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.warning)
                } else {
                    Text("未上榜")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            HStack(spacing: 16) {
                // 积分
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.warning)
                        Text("\(stats.totalPoints)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    Text("积分")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Divider()
                    .frame(height: 30)

                // 成就数
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.warning)
                        Text("\(stats.totalAchievements)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    Text("成就")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Divider()
                    .frame(height: 30)

                // 完成度
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "percent")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.success)
                        Text("\(Int(stats.completionRate * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    Text("完成度")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.primary.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    LeaderboardView()
}
