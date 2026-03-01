//
//  AchievementMilestoneView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-27.
//  成就里程碑展示视图
//

import SwiftUI

struct AchievementMilestoneView: View {
    @StateObject private var milestoneManager = AchievementMilestoneManager.shared
    @State private var selectedMilestone: AchievementMilestone?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255))

                Text("成就里程碑")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)

            // 里程碑列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AchievementMilestone.allCases, id: \.self) { milestone in
                        AchievementMilestoneCard(milestone: milestone)
                            .onTapGesture {
                                selectedMilestone = milestone
                            }
                    }
                }
                .padding(.horizontal, 16)
            }

            // 里程碑进度条
            milestoneProgressTracker
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
        .sheet(item: $selectedMilestone) { milestone in
            AchievementMilestoneDetailPopup(milestone: milestone)
        }
    }

    private var milestoneProgressTracker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("整体进度")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

                Spacer()

                let currentUnlocked = milestoneManager.milestones.filter({ $0.isUnlocked }).count
                Text("\(currentUnlocked)/\(AchievementMilestone.allCases.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255))
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                        .frame(height: 8)

                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255),
                                    Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * milestoneProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var milestoneProgress: Double {
        guard !milestoneManager.milestones.isEmpty else { return 0 }
        let unlocked = milestoneManager.milestones.filter { $0.isUnlocked }.count
        return Double(unlocked) / Double(milestoneManager.milestones.count)
    }
}

// MARK: - Milestone Card

struct AchievementMilestoneCard: View {
    let milestone: AchievementMilestone
    @StateObject private var milestoneManager = AchievementMilestoneManager.shared

    private let cardSize: CGFloat = 100

    var body: some View {
        VStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(isUnlocked ? AnyShapeStyle(milestoneGradient) : AnyShapeStyle(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)))
                    .frame(width: 50, height: 50)

                Text(milestone.icon)
                    .font(.system(size: 24))
                    .opacity(isUnlocked ? 1.0 : 0.4)

                if isUnlocked {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 50)
                }
            }

            // 标题
            Text(milestone.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isUnlocked ? .white : Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: cardSize)

            // 状态
            if let progress = milestoneManager.milestones.first(where: { $0.milestone == milestone }) {
                if progress.isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))

                        Text("已解锁")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255))
                } else {
                    VStack(spacing: 4) {
                        Text("\(progress.current)/\(progress.target)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)

                        ProgressView(value: progress.progress)
                            .tint(Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255))
                            .frame(width: 60, height: 4)
                    }
                }
            }
        }
        .frame(width: cardSize)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
                .shadow(
                    color: isUnlocked ? Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255).opacity(0.3) : .clear,
                    radius: isUnlocked ? 8 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isUnlocked ? Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255).opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isUnlocked)
    }

    private var isUnlocked: Bool {
        milestoneManager.milestones.first(where: { $0.milestone == milestone })?.isUnlocked ?? false
    }

    private var milestoneGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255),
                Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Milestone Detail Popup

struct AchievementMilestoneDetailPopup: View {
    @Environment(\.dismiss) var dismiss
    let milestone: AchievementMilestone
    @StateObject private var milestoneManager = AchievementMilestoneManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 0) {
                // 关闭按钮
                HStack {
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
                .padding(16)

                VStack(spacing: 24) {
                    // 里程碑图标
                    ZStack {
                        Circle()
                            .fill(milestoneGradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255).opacity(0.5), radius: 20)

                        Text(milestone.icon)
                            .font(.system(size: 50))

                        if isUnlocked {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 100, height: 100)
                        }
                    }

                    // 标题
                    Text(milestone.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // 描述
                    Text(milestoneDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // 进度
                    if let progress = milestoneManager.milestones.first(where: { $0.milestone == milestone }) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("进度")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))

                                Spacer()

                                Text("\(progress.current)/\(progress.target)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            ProgressView(value: progress.progress)
                                .tint(Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255))
                                .frame(height: 8)
                        }
                        .padding(.horizontal, 20)
                    }

                    // 奖励
                    VStack(alignment: .leading, spacing: 12) {
                        Text("奖励")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        rewardCard
                    }
                    .padding(16)
                    .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
                    .cornerRadius(12)

                    // 领取按钮
                    if isUnlocked {
                        Button {
                            Task {
                                try? await milestoneManager.claimMilestoneReward(milestone)
                                dismiss()
                            }
                        } label: {
                            Text("领取奖励")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.yellow)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }

    private var rewardCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255))

                Text("\(milestone.reward.bonusPoints) 积分")
                    .foregroundColor(.white)

                Spacer()
            }

            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255))

                Text(milestone.reward.title)
                    .foregroundColor(.white)

                Spacer()
            }

            ForEach(Array(milestone.reward.resources.keys.sorted()), id: \.self) { resource in
                HStack {
                    Image(systemName: "cube.fill")
                        .foregroundColor(Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255))

                    Text("\(resource): \(milestone.reward.resources[resource] ?? 0)")
                        .foregroundColor(.white)

                    Spacer()
                }
            }
        }
    }

    private var isUnlocked: Bool {
        milestoneManager.milestones.first(where: { $0.milestone == milestone })?.isUnlocked ?? false
    }

    private var milestoneGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255),
                Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var milestoneDescription: String {
        let target = milestone.requiredCount
        return "解锁 \(target) 个成就即可达成此里程碑"
    }
}

// MARK: - Identifiable for AchievementMilestone

extension AchievementMilestone: Identifiable {
    var id: String { return rawValue }
}

// MARK: - Preview

#Preview {
    AchievementMilestoneView()
        .padding()
        .background(Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255))
}
