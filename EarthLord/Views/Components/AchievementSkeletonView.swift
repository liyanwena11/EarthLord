//
//  AchievementSkeletonView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-27.
//  成就系统骨架屏加载视图
//

import SwiftUI

/// 成就卡片骨架屏
struct AchievementCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // 图标骨架
            Circle()
                .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                .frame(width: 60, height: 60)

            // 内容骨��
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                    .frame(width: 150, height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                    .frame(width: 200, height: 12)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                    .frame(width: 120, height: 8)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .fill(shimmerGradient)
                .opacity(isAnimating ? 0.3 : 0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.2),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// 统计卡片骨架屏
struct AchievementStatSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                .frame(width: 24, height: 24)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                .frame(width: 60, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                .frame(width: 40, height: 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .fill(shimmerGradient)
                .opacity(isAnimating ? 0.3 : 0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.2),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// 排行榜骨架屏
struct LeaderboardRowSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // 排名骨架
            Circle()
                .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                .frame(width: 32, height: 32)

            // 玩家信息骨架
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                    .frame(width: 100, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                    .frame(width: 140, height: 12)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .fill(shimmerGradient)
                .opacity(isAnimating ? 0.3 : 0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.2),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// 骨架屏容器 - 用于显示多个骨架卡片
struct AchievementListSkeleton: View {
    let count: Int

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                AchievementCardSkeleton()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Card Skeleton") {
    VStack {
        AchievementCardSkeleton()
        AchievementCardSkeleton()
        AchievementCardSkeleton()
    }
    .padding()
    .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
}

#Preview("Stat Skeleton") {
    HStack(spacing: 12) {
        AchievementStatSkeleton()
        AchievementStatSkeleton()
        AchievementStatSkeleton()
    }
    .padding()
    .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
}

#Preview("Leaderboard Skeleton") {
    VStack {
        LeaderboardRowSkeleton()
        LeaderboardRowSkeleton()
        LeaderboardRowSkeleton()
    }
    .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
}
