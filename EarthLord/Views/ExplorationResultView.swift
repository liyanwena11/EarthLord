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

            VStack(spacing: 30) {
                // 标题区
                VStack(spacing: 20) {
                    Text("xmark.circle")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("探索完成！")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                    Text("你发现了一处废弃的营地，里面有些物资")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)

                // 统计卡片
                VStack(spacing: 15) {
                    ResultRow(
                        title: "行走距离",
                        value: "0m",
                        icon: "figure.walk"
                    )
                    ResultRow(
                        title: "探索时间",
                        value: "1分钟",
                        icon: "clock"
                    )
                    ResultRow(
                        title: "获得物品",
                        value: "2个",
                        icon: "star.fill"
                    )
                }
                .padding(.horizontal, 30)

                // 奖励物品列表
                VStack(spacing: 10) {
                    ForEach(result.itemsFound) {
                        item in
                        HStack {
                            Image(systemName: item.icon).foregroundColor(.blue)
                            Text(item.name).foregroundColor(.white)
                            Spacer()
                            Text("x\(item.quantity)").bold().foregroundColor(.orange)
                        }
                        .padding(.horizontal, 30)
                    }
                }

                Spacer()

                // 确认按钮
                Button(action: {
                    // ✅ 核心修复：调用 addItems 真正添加物品
                    let count = manager.addItems(items: result.itemsFound)
                    print("✅ 已放入背包：\(count) 件物品")
                    dismiss()
                }) {
                    Text("好的")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

// 统计行子组件
struct ResultRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white).frame(width: 30)
            Text(title).font(.caption).foregroundColor(.gray)
            Spacer()
            Text(value).font(.headline).foregroundColor(.white)
        }
        .padding(.vertical, 10)
    }
}
