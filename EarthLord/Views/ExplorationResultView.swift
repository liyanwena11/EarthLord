import SwiftUI

struct ExplorationResultView: View {
    // 1. 外部数据
    let result: ExplorationResult
    
    // 2. 内部管家
    @Environment(\.dismiss) var dismiss
    // 使用 @ObservedObject 确保它不会干扰初始化
    @ObservedObject private var manager = ExplorationManager.shared
    
    // ✅ 核心修复：手动声明一个“公开的入口”
    // 这样 MapTabView 就能通过 ExplorationResultView(result: ...) 调用它了
    init(result: ExplorationResult) {
        self.result = result
    }
    
    var body: some View {
        ZStack {
            // 深色背景氛围
            Color(red: 0.1, green: 0.08, blue: 0.12).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // 顶部标题
                    VStack(spacing: 15) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 30)
                        
                        Text("探索完成！")
                            .font(.system(size: 34, weight: .black))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                Image(systemName: "star.fill").font(.title2).foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    // 统计卡片 (调用下方的子组件)
                    VStack(spacing: 20) {
                        ResultDetailRow(title: "行走距离", value: "\(Int(result.walkDistance))米", rank: "#\(result.walkRanking)", icon: "figure.walk", color: .blue)
                        ResultDetailRow(title: "探索面积", value: "\(Int(result.exploredArea))㎡", rank: "#\(result.areaRanking)", icon: "square.dashed", color: .purple)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // 奖励列表
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
                    
                    // ✅ Day 20: 真正放入背包（调用 addItems）
                    Button(action: {
                        // 将探索获得的物品添加到背包
                        let addedCount = manager.addItems(items: result.itemsFound)
                        print("✅ 已放入背包：\(addedCount) 件物品")
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("放入背包")
                        }
                        .font(.headline).foregroundColor(.black)
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

// 统计行子组件 (确保在此文件内定义，防止跨文件找不到)
struct ResultDetailRow: View {
    let title: String; let value: String; let rank: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline).foregroundColor(.white)
            }
            Spacer()
            Text(rank).font(.caption).bold().padding(5).background(Color.green.opacity(0.2)).foregroundColor(.green).cornerRadius(5)
        }
    }
}
