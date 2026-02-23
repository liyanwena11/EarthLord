//
//  DailyTasksView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  每日任务视图
//

import SwiftUI

struct DailyTasksView: View {
    @State private var dailyTasks: [DailyTask] = []
    @State private var isLoading = false
    @State private var showClaimAlert = false
    @State private var taskToClaim: DailyTask?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部统计
                HStack(spacing: 12) {
                    StatBox(
                        icon: "checkmark.circle.fill",
                        title: "已完成",
                        value: "\(completedCount)",
                        total: "\(dailyTasks.count)",
                        color: ApocalypseTheme.success
                    )

                    StatBox(
                        icon: "gift.fill",
                        title: "可领取",
                        value: "\(claimableCount)",
                        total: "",
                        color: ApocalypseTheme.warning
                    )

                    StatBox(
                        icon: "clock.fill",
                        title: "剩余时间",
                        value: formattedRemainingTime,
                        total: "",
                        color: ApocalypseTheme.info
                    )
                }
                .padding()

                // 任务列表
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if dailyTasks.isEmpty {
                    EmptyTasksView()
                } else {
                    ForEach(dailyTasks) { task in
                        DailyTaskCard(task: task) {
                            taskToClaim = task
                            if task.isCompleted {
                                showClaimAlert = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .task {
            await loadDailyTasks()
        }
        .alert("领取奖励", isPresented: $showClaimAlert) {
            Button("取消", role: .cancel) { }
            Button("领取") {
                Task {
                    if let task = taskToClaim {
                        await claimTaskReward(task)
                    }
                }
            }
        } message: {
            if let task = taskToClaim {
                Text("确定要领取任务奖励吗？\n经验: \(task.reward.experience)")
            }
        }
    }

    private var completedCount: Int {
        dailyTasks.filter { $0.isCompleted }.count
    }

    private var claimableCount: Int {
        dailyTasks.filter { $0.isCompleted && !$0.isClaimed }.count
    }

    private var earliestExpiry: Date? {
        dailyTasks.map { $0.expiresAt }.min()
    }

    private var formattedRemainingTime: String {
        guard let expiry = earliestExpiry else { return "--:--" }
        let remaining = max(expiry.timeIntervalSince(Date()), 0)
        if remaining <= 0 { return "已过期" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func loadDailyTasks() async {
        isLoading = true
        // TODO: Implement actual data loading
        // Simulate loading for now
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            self.dailyTasks = sampleTasks
            self.isLoading = false
        }
    }

    private func claimTaskReward(_ task: DailyTask) async {
        // TODO: Implement actual reward claiming
        LogInfo("✅ 领取任务奖励: \(task.title)")
        await MainActor.run {
            if let index = dailyTasks.firstIndex(where: { $0.id == task.id }) {
                dailyTasks[index].isClaimed = true
            }
        }
    }
}

// MARK: - DailyTaskCard

struct DailyTaskCard: View {
    let task: DailyTask
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack {
                // 任务类型图标
                ZStack {
                    Circle()
                        .fill(task.type.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: task.type.icon)
                        .foregroundColor(task.type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                // 状态标签
                if task.isClaimed {
                    StatusBadge(text: "已领取", color: ApocalypseTheme.textMuted)
                } else if task.isCompleted {
                    StatusBadge(text: "可领取", color: ApocalypseTheme.success)
                } else {
                    StatusBadge(text: "进行中", color: ApocalypseTheme.primary)
                }
            }

            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Spacer()
                    Text(task.formattedProgress)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(task.isCompleted ? ApocalypseTheme.success : ApocalypseTheme.textPrimary)
                }

                ProgressView(value: task.progress)
                    .tint(task.isCompleted ? ApocalypseTheme.success : task.type.color)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            // 奖励信息
            HStack {
                Image(systemName: "gift.fill")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.warning)
                Text("奖励: 经验+\(task.reward.experience)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                if !task.reward.resources.isEmpty {
                    let resources = task.reward.resources.map { "\($0.key)x\($0.value)" }.joined(separator: ", ")
                    Text(", \(resources)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                if task.isCompleted && !task.isClaimed {
                    Button {
                        onTap()
                    } label: {
                        Text("领取")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(ApocalypseTheme.success)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.isCompleted ? ApocalypseTheme.success.opacity(0.3) : ApocalypseTheme.cardBackground, lineWidth: 1)
        )
    }
}

// MARK: - StatBox

struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    let total: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                if !total.isEmpty {
                    Text("/\(total)")
                        .font(.caption)
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

// MARK: - StatusBadge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - EmptyTasksView

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textMuted)
            Text("暂无任务")
                .font(.title3)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text("每日任务会在每天0点刷新")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Sample Data

private let sampleTasks: [DailyTask] = [
    DailyTask(
        id: "1",
        type: .production,
        title: "生产专家",
        description: "生产100单位食物",
        target: 100,
        current: 75,
        reward: TaskReward(experience: 100, resources: ["food": 50], items: []),
        isCompleted: false,
        isClaimed: false,
        expiresAt: Date().addingTimeInterval(86400),
        createdAt: Date()
    ),
    DailyTask(
        id: "2",
        type: .building,
        title: "建筑大师",
        description: "建造2个建筑",
        target: 2,
        current: 2,
        reward: TaskReward(experience: 200, resources: ["wood": 100, "metal": 50], items: []),
        isCompleted: true,
        isClaimed: false,
        expiresAt: Date().addingTimeInterval(86400),
        createdAt: Date()
    ),
    DailyTask(
        id: "3",
        type: .upgrade,
        title: "升级达人",
        description: "升级1个建筑",
        target: 1,
        current: 0,
        reward: TaskReward(experience: 150, resources: ["metal": 50], items: []),
        isCompleted: false,
        isClaimed: false,
        expiresAt: Date().addingTimeInterval(86400),
        createdAt: Date()
    )
]

// 预览
#Preview {
    DailyTasksView()
}
