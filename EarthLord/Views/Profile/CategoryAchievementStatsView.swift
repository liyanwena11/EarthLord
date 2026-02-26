//
//  CategoryAchievementStatsView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  个人界面 - 分类成就统计（详细统计）
//

import SwiftUI

struct CategoryAchievementStatsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var leaderboardManager = LeaderboardManager()
    @State private var categoryStats: [CategoryStats] = []
    @State private var isLoading = false

    // 参考设计颜色
    private let cardBackground = Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255)
    private let dividerColor = Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)
    private let iconBlue = Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // 标题栏
                        HStack {
                            Text("详细统计")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(AchievementCategory.allCases, id: \.self) { category in
                                    if let stats = categoryStats.first(where: { $0.category == category }) {
                                        CategoryModuleCard(
                                            category: category,
                                            stats: stats,
                                            cardBackground: cardBackground,
                                            dividerColor: dividerColor,
                                            iconColor: iconBlue
                                        )
                                    } else {
                                        // 没有统计数据时显示默认值
                                        CategoryModuleCard(
                                            category: category,
                                            stats: CategoryStats(category: category, points: 0, achievements: 0, ranking: nil),
                                            cardBackground: cardBackground,
                                            dividerColor: dividerColor,
                                            iconColor: iconBlue
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadStats()
        }
    }

            ScrollView {
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            if let stats = categoryStats.first(where: { $0.category == category }) {
                                CategoryModuleCard(
                                    category: category,
                                    stats: stats,
                                    cardBackground: cardBackground,
                                    dividerColor: dividerColor,
                                    iconColor: iconBlue
                                )
                            }
                        }
                    }
                }
            }
        }
        .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
        .onAppear {
            loadStats()
        }
    }

    private func loadStats() {
        guard let userId = AuthManager.shared.currentUser?.id else { return }

        isLoading = true

        Task {
            // 同时加载成就数据和排行榜数据
            async let achievementData = achievementManager.refreshData()
            async let leaderboardData = fetchLeaderboardStats(userId: userId)

            do {
                let (_, stats) = try await (achievementData, leaderboardData)
                await MainActor.run {
                    self.categoryStats = stats.categoryStats
                    self.isLoading = false
                }
            } catch {
                print("❌ 加载分类统计失败: \(error)")
                await MainActor.run {
                    // 使用默认数据
                    self.categoryStats = AchievementCategory.allCases.map { category in
                        CategoryStats(category: category, points: 0, achievements: 0, ranking: nil)
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchLeaderboardStats(userId: UUID) async throws -> UserLeaderboardStats {
        return try await leaderboardManager.fetchUserLeaderboardStats(userId: userId)
    }
}

// MARK: - CategoryModuleCard

struct CategoryModuleCard: View {
    let category: AchievementCategory
    let stats: CategoryStats
    let cardBackground: Color
    let dividerColor: Color
    let iconColor: Color

    var body: some View {
        VStack(spacing: 0) {
            // 模块标题（参考探索统计、活动统计样式）
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)

                Text("\(category.displayName)统计")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)

            // 统计列表
            VStack(spacing: 0) {
                // 积分
                CategoryStatRow(
                    label: "成就积分",
                    value: "\(stats.points)"
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 16)

                // 解锁数量
                CategoryStatRow(
                    label: "已解锁",
                    value: "\(stats.achievements)"
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(dividerColor)
                    .padding(.leading, 16)

                // 当前排名
                CategoryStatRow(
                    label: "当前排名",
                    value: stats.ranking != nil ? "#\(stats.ranking!)" : "-"
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(cardBackground)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - CategoryStatRow

struct CategoryStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryAchievementStatsView()
}
