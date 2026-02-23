//

#if DEBUG
//  ExplorationTestView.swift
//  EarthLord
//
//  测试探索功能的演示页面
//  ⚠️ 仅在 DEBUG 模式下编译
//

import SwiftUI

#if DEBUG

struct ExplorationTestView: View {
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // POI列表入口
                    NavigationLink(destination: POIListView()) {
                        testCard(
                            title: "POI列表",
                            icon: "mappin.and.ellipse",
                            color: ApocalypseTheme.primary,
                            description: "查看附近的兴趣点"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 背包入口
                    NavigationLink(destination: BackpackView()) {
                        testCard(
                            title: "背包",
                            icon: "backpack.fill",
                            color: ApocalypseTheme.success,
                            description: "管理你的物品"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 探索结果弹窗测试
                    Button(action: {
                        showResult = true
                    }) {
                        testCard(
                            title: "探索结果",
                            icon: "gift.fill",
                            color: ApocalypseTheme.info,
                            description: "查看探索收获"
                        )
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("探索功能测试")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showResult) {
                // ✅ 使用真实数据创建测试结果
                let testResult = ExplorationResult(
                    walkDistance: 1250.0,
                    totalWalkDistance: WalkingRewardManager.shared.totalWalkingDistance,
                    walkRanking: 12,
                    exploredArea: 5600.0,
                    totalExploredArea: 12300.0,
                    areaRanking: 8,
                    duration: 1800,
                    itemsFound: ExplorationManager.shared.backpackItems.prefix(3).map { $0 },
                    poisDiscovered: 3,
                    experienceGained: 450
                )
                ExplorationResultView(result: testResult)
            }
        }
    }

    private func testCard(title: String, icon: String, color: Color, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ApocalypseTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ExplorationTestView()
}

#endif
#endif
