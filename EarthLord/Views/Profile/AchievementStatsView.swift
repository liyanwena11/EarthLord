//
//  AchievementStatsView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  个人界面 - 成就统计模块
//

import SwiftUI

struct AchievementStatsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var leaderboardManager = LeaderboardManager()
    @Binding var showFullLeaderboard: Bool
    @State private var userStats: UserLeaderboardStats?
    @State private var isLoading = false

    // 参考设计颜色
    private let cardBackground = Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)
    private let dividerColor = Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)
    private let iconBlue = Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏（参考资源统计样式）
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(iconBlue)

                Text("成就统计")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x24/255))

            // 成就统计卡片
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                } else if let stats = userStats {
                    achievementContent(stats: stats)
                } else {
                    emptyState
                }
            }
            .background(cardBackground)
            .cornerRadius(0)
        }
        .onAppear {
            loadStats()
        }
    }

    private func achievementContent(stats: UserLeaderboardStats) -> some View {
        VStack(spacing: 0) {
            // 总积分（使用 AchievementManager 的数据）
            AchievementStatRow(
                icon: "star.fill",
                title: "成就积分",
                value: "\(achievementManager.totalPoints)",
                color: iconBlue
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(dividerColor)
                .padding(.leading, 16)

            // 解锁数量
            AchievementStatRow(
                icon: "lock.open.fill",
                title: "已解锁",
                value: "\(achievementManager.totalUnlocked)",
                color: iconBlue
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(dividerColor)
                .padding(.leading, 16)

            // 完成度
            AchievementStatRow(
                icon: "percent",
                title: "完成度",
                value: "\(achievementManager.completionPercentage)%",
                color: iconBlue
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(dividerColor)
                .padding(.leading, 16)

            // 当前排名
            AchievementStatRow(
                icon: "list.number",
                title: "当前排名",
                value: stats.rankingPosition != nil ? "#\(stats.rankingPosition!)" : "-",
                color: iconBlue
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // 查看完整排行榜按钮
            Button {
                showFullLeaderboard = true
            } label: {
                HStack {
                    Text("查看完整排行榜")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("暂无成就数据")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func loadStats() {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("⚠️ 用户未登录，无法加载成就统计")
            return
        }

        isLoading = true

        Task {
            // 同时加载成就数据和排行榜数据
            async let achievementData = achievementManager.refreshData()
            async let leaderboardData = fetchLeaderboardStats(userId: userId)

            do {
                let (_, stats) = try await (achievementData, leaderboardData)
                await MainActor.run {
                    self.userStats = stats
                    self.isLoading = false
                }
            } catch {
                print("❌ 加载成就统计失败: \(error)")
                await MainActor.run {
                    // 创建默认统计
                    self.userStats = UserLeaderboardStats(
                        userId: userId,
                        totalPoints: 0,
                        totalAchievements: 0,
                        completionRate: 0,
                        rankingPosition: nil,
                        categoryStats: [],
                        speedRecords: nil
                    )
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchLeaderboardStats(userId: UUID) async throws -> UserLeaderboardStats {
        return try await leaderboardManager.fetchUserLeaderboardStats(userId: userId)
    }
}

// MARK: - AchievementStatRow（重命名避免与 ResourcesTabView.StatRow 冲突）

struct AchievementStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}

// MARK: - AchievementLeaderboardDetailView

struct AchievementLeaderboardDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = LeaderboardManager()
    let userStats: UserLeaderboardStats?

    @State private var selectedTab: LeaderboardTab = .points
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false

    // 参考设计颜色
    private let cardBackground = Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)
    private let dividerColor = Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)
    private let iconBlue = Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0x12/255, green: 0x18/255, blue: 0x24/255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部标题栏
                    HStack {
                        Text("成就排行榜")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // 标签页
                    HStack(spacing: 0) {
                        ForEach([LeaderboardTab.points, .achievements, .completion], id: \.self) { tab in
                            AchievementLeaderboardTabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                color: iconBlue
                            ) {
                                withAnimation {
                                    selectedTab = tab
                                    Task { await loadLeaderboard() }
                                }
                            }

                            if tab != .completion {
                                Spacer()
                                    .frame(width: 1)
                                    .background(dividerColor)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(cardBackground)

                    // 排行榜内容
                    ScrollView {
                        VStack(spacing: 0) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            } else {
                                leaderboardContent
                            }
                        }
                    }

                    // 底部我的排名
                    if let stats = userStats {
                        myRankCard(stats: stats)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadLeaderboard()
            }
        }
    }

    private var leaderboardContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                AchievementLeaderboardEntryRow(
                    entry: entry,
                    rank: index + 1,
                    iconColor: iconBlue,
                    dividerColor: dividerColor
                )

                if index < entries.count - 1 {
                    Divider()
                        .background(dividerColor)
                        .padding(.leading, 60)
                }
            }
        }
        .background(cardBackground)
    }

    private func myRankCard(stats: UserLeaderboardStats) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(iconBlue)

                Text("我的排名")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Spacer()

                if let ranking = stats.rankingPosition {
                    Text("#\(ranking)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(iconBlue)
                } else {
                    Text("-")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private func loadLeaderboard() async {
        isLoading = true

        do {
            switch selectedTab {
            case .points:
                entries = try await manager.fetchPointsLeaderboard(limit: 50)
            case .achievements:
                entries = try await manager.fetchAchievementsLeaderboard(limit: 50)
            case .completion:
                entries = try await manager.fetchCompletionLeaderboard(limit: 50)
            default:
                entries = []
            }
        } catch {
            print("加载排行榜失败: \(error)")
        }

        isLoading = false
    }
}

// MARK: - AchievementLeaderboardTabButton（重命名避免冲突）

struct AchievementLeaderboardTabButton: View {
    let tab: LeaderboardTab
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(tab.displayName)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? color : Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AchievementLeaderboardEntryRow

struct AchievementLeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let iconColor: Color
    let dividerColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // 排名
            Text(rankDisplay)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(rankColor)
                .frame(width: 40)

            // 玩家信息
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName ?? entry.username)
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                Text(rankSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var rankDisplay: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255)
        case 2: return Color(red: 0xC0/255, green: 0xC0/255, blue: 0xC0/255)
        case 3: return Color(red: 0xCD/255, green: 0x7F/255, blue: 0x32/255)
        default: return .gray
        }
    }

    private var rankSubtitle: String {
        // 根据当前显示的数据类型显示
        return "\(entry.totalPoints) 积分 • \(entry.totalAchievements) 成就"
    }
}

// MARK: - Preview

#Preview {
    AchievementStatsView(showFullLeaderboard: .constant(false))
}
