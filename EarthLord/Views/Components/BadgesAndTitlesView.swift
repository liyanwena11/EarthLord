//
//  BadgesAndTitlesView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  徽章和称号展示视图
//

import SwiftUI

/// 徽章和称号展示视图
struct BadgesAndTitlesView: View {

    @StateObject private var rewardManager = AchievementRewardManager.shared
    @State private var selectedTab: Tab = .badges

    enum Tab {
        case badges
        case titles
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页切换
                tabsView

                Divider()
                    .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))

                // 内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == .badges {
                            badgesSection
                        } else {
                            titlesSection
                        }
                    }
                    .padding()
                }
            }
            .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Tabs
    private var tabsView: some View {
        HStack(spacing: 0) {
            // 徽章标签
            Button {
                withAnimation {
                    selectedTab = .badges
                }
            } label: {
                VStack(spacing: 8) {
                    Text("徽章")
                        .font(.system(size: 16, weight: selectedTab == .badges ? .semibold : .regular))
                        .foregroundColor(selectedTab == .badges ? .yellow : .gray)

                    if selectedTab == .badges {
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 40, height: 3)
                            .cornerRadius(1.5)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // 称号标签
            Button {
                withAnimation {
                    selectedTab = .titles
                }
            } label: {
                VStack(spacing: 8) {
                    Text("称号")
                        .font(.system(size: 16, weight: selectedTab == .titles ? .semibold : .regular))
                        .foregroundColor(selectedTab == .titles ? .yellow : .gray)

                    if selectedTab == .titles {
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 40, height: 3)
                            .cornerRadius(1.5)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
    }

    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(spacing: 16) {
            // 统计卡片
            HStack(spacing: 12) {
                BadgeStatCard(
                    icon: "🏅",
                    title: "徽章总数",
                    value: "\(rewardManager.userBadges.count)",
                    color: .blue
                )

                BadgeStatCard(
                    icon: "⭐",
                    title: "总积分",
                    value: "\(rewardManager.getTotalPoints())",
                    color: .yellow
                )
            }

            // 徽章列表
            if rewardManager.userBadges.isEmpty {
                emptyStateView(
                    icon: "🏅",
                    title: "还没有徽章",
                    description: "完成成就即可获得徽章奖励"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(rewardManager.userBadges) { badge in
                        BadgeCard(badge: badge)
                    }
                }
            }
        }
    }

    // MARK: - Titles Section
    private var titlesSection: some View {
        VStack(spacing: 16) {
            // 当前称号展示
            if let currentTitle = rewardManager.getCurrentTitle() {
                VStack(spacing: 12) {
                    Text("当前称号")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Text(currentTitle.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
                .cornerRadius(12)
            }

            // 称号列表
            if rewardManager.userTitles.isEmpty {
                emptyStateView(
                    icon: "🎖️",
                    title: "还没有称号",
                    description: "完成特殊成就即可获得称号"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(rewardManager.userTitles) { title in
                        TitleCard(
                            title: title,
                            isCurrent: rewardManager.getCurrentTitle()?.id == title.id
                        ) {
                            rewardManager.setCurrentTitle(title)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 64))

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Badge Card
struct BadgeCard: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 12) {
            // 徽章图标
            ZStack {
                Circle()
                    .fill(backgroundColorForRarity(badge.rarity))
                    .frame(width: 80, height: 80)

                Text(badge.icon)
                    .font(.system(size: 40)
                )
            }

            // 徽章信息
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(badge.rarity.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(textColorForRarity(badge.rarity))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
        .cornerRadius(12)
    }

    private func backgroundColorForRarity(_ rarity: BadgeRarity) -> Color {
        switch rarity {
        case .common:
            return Color.gray.opacity(0.3)
        case .rare:
            return Color.blue.opacity(0.3)
        case .epic:
            return Color.purple.opacity(0.3)
        case .legendary:
            return Color.orange.opacity(0.3)
        }
    }

    private func textColorForRarity(_ rarity: BadgeRarity) -> Color {
        switch rarity {
        case .common:
            return .gray
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return .orange
        }
    }
}

// MARK: - Title Card
struct TitleCard: View {
    let title: Title
    let isCurrent: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrent ? .yellow : .white)

                Text(title.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            if isCurrent {
                Text("使用中")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .cornerRadius(8)
            } else {
                Button {
                    onSelect()
                } label: {
                    Text("使用")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
        .cornerRadius(12)
    }
}

// MARK: - Badge Stat Card
struct BadgeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    BadgesAndTitlesView()
}
