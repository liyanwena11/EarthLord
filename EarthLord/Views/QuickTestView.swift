//
//  QuickTestView.swift
//  EarthLord
//
//  快速测试所有探索功能的完整流程
//  ⚠️ 仅在 DEBUG 模式下编译
//

import SwiftUI

#if DEBUG

struct QuickTestView: View {
    var body: some View {
        TabView {
            // 测试完整的资源Tab流程
            ResourcesTabView()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("资源测试")
                }
                .tag(0)

            // 测试单独的POI列表（带导航）
            NavigationStack {
                POIListView()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("POI列表")
            }
            .tag(1)

            // 测试单独的背包（带导航）
            NavigationStack {
                BackpackView()
            }
            .tabItem {
                Image(systemName: "backpack.fill")
                Text("背包")
            }
            .tag(2)

            // 测试探索结果弹窗
            ExplorationTestSheetView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("探索结果")
                }
                .tag(3)
        }
        .tint(ApocalypseTheme.primary)
    }
}

/// 测试探索结果弹窗的视图
struct ExplorationTestSheetView: View {
    @State private var showResult = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // 测试说明
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ApocalypseTheme.success)

                    Text("探索功能测试")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("点击下方按钮测试各项功能")
                        .font(.system(size: 14))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                // 测试按钮
                VStack(spacing: 16) {
                    // 测试探索结果弹窗
                    Button(action: {
                        showResult = true
                    }) {
                        testButtonLabel(
                            icon: "gift.fill",
                            title: "测试探索结果弹窗",
                            color: ApocalypseTheme.primary
                        )
                    }

                    // 测试数据说明
                    VStack(alignment: .leading, spacing: 8) {
                        testDataRow(icon: "mappin.circle.fill", text: "5个POI测试数据")
                        testDataRow(icon: "shippingbox.fill", text: "8种背包物品")
                        testDataRow(icon: "chart.bar.fill", text: "完整的探索统计")
                        testDataRow(icon: "arrow.triangle.branch", text: "完整的导航流程")
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ApocalypseTheme.cardBackground)
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(isPresented: $showResult) {
            // ✅ 使用真实数据创建测试结果
            let testResult = ExplorationResult(
                walkDistance: 850.0,
                totalWalkDistance: WalkingRewardManager.shared.totalWalkingDistance,
                walkRanking: 15,
                exploredArea: 3200.0,
                totalExploredArea: 8900.0,
                areaRanking: 11,
                duration: 1200,
                itemsFound: ExplorationManager.shared.backpackItems.prefix(3).map { $0 },
                poisDiscovered: 2,
                experienceGained: 320
            )
            ExplorationResultView(result: testResult)
        }
    }

    private func testButtonLabel(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))

            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private func testDataRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ApocalypseTheme.success)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    QuickTestView()
}

#endif
