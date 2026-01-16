import SwiftUI

/// 探索结果视图（保留兼容性，已更新为真实入包逻辑）
struct ExplorationResultView: View {
    let result: ExplorationResult

    @Environment(\.dismiss) var dismiss
    private var manager = ExplorationManager.shared

    init(result: ExplorationResult) {
        self.result = result
    }

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.08, blue: 0.12).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 25) {
                    // 标题区
                    VStack(spacing: 15) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("探索完成！")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)

                    // 统计卡片
                    VStack(spacing: 20) {
                        ResultDetailRow(
                            title: "行走距离",
                            value: "\(Int(result.walkDistance))米",
                            rank: "#\(result.walkRanking)",
                            icon: "figure.walk",
                            color: .blue
                        )
                        ResultDetailRow(
                            title: "探索面积",
                            value: "\(Int(result.exploredArea))㎡",
                            rank: "#\(result.areaRanking)",
                            icon: "square.dashed",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // 奖励物品列表
                    VStack(alignment: .leading, spacing: 15) {
                        Text("获得奖励").font(.headline).foregroundColor(.orange)
                        ForEach(result.itemsFound) { item in
                            HStack {
                                Image(systemName: item.icon).foregroundColor(.blue)
                                Text(item.name).foregroundColor(.white)
                                Spacer()
                                Text("x\(item.quantity)").bold().foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // 确认按钮 - 真正添加物品到背包
                    Button(action: {
                        // ✅ 核心修复：调用 addItems 真正添加物品
                        let count = manager.addItems(items: result.itemsFound)
                        print("✅ 已放入背包：\(count) 件物品")
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("放入背包")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                    }
                    .padding(30)
                }
            }
        }
    }
}

// 统计行子组件
struct ResultDetailRow: View {
    let title: String
    let value: String
    let rank: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline).foregroundColor(.white)
            }
            Spacer()
            Text(rank)
                .font(.caption).bold()
                .padding(5)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(5)
        }
    }
}
