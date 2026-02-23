//
//  TasksTabView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  任务主界面 - 包含每日任务和成就
//

import SwiftUI

struct TasksTabView: View {
    @State private var selectedTab: TaskTab = .daily

    enum TaskTab: String, CaseIterable {
        case daily = "每日任务"
        case achievements = "成就"

        var icon: String {
            switch self {
            case .daily: return "calendar.day.timeline.left"
            case .achievements: return "trophy.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab选择器
                Picker("任务类型", selection: $selectedTab) {
                    ForEach(TaskTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 内容区域
                if selectedTab == .daily {
                    DailyTasksView()
                } else {
                    AchievementsView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("任务中心")
        }
    }
}

// 预览
#Preview {
    TasksTabView()
}
