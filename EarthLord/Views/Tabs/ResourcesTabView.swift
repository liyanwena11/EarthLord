import SwiftUI

struct ResourcesTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. 顶部五段选择器 - 移除 ScrollView 修复触摸问题
                Picker("板块", selection: $selectedSegment) {
                    Text("POI").tag(0)
                    Text("背包").tag(1)
                    Text("已购").tag(2)
                    Text("领地").tag(3)
                    Text("交易").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

                // 2. 内容动态切换 - 添加动画确保切换生效
                Group {
                    switch selectedSegment {
                    case 0:
                        POIListView()
                    case 1:
                        BackpackView()
                    case 2:
                        PurchasedStoreView()
                    case 3:
                        TerritoryStatsView()
                    default:
                        TradeComingSoonView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }
            .navigationTitle("资源管理")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - 内部辅助视图 (补全缺失组件，修复报错)

/// 已购物品页面
struct PurchasedStoreView: View {
    var body: some View {
        List {
            Section("我的购买记录") {
                Label("新手生存礼包", systemImage: "shippingbox.fill")
                Label("成都区域地图", systemImage: "map.fill")
                Label("高级扫描雷达", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// 领地统计页面 (照片7风格)
struct TerritoryStatsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("实时防御统计").font(.headline).foregroundColor(.secondary)
                
                // ✅ 这里补全了之前报错缺失的 StatRow 组件
                StatRow(title: "当前占领区", value: "12", total: "150", rank: "#156", icon: "flag.fill", color: .blue)
                
                StatRow(title: "避难所等级", value: "Lv.4", total: "Lv.10", rank: "#99", icon: "shield.fill", color: .purple)
                
                Spacer()
            }
            .padding()
        }
    }
}

/// 交易系统预告
struct TradeComingSoonView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("正在搜索附近的幸存者信号...")
                .font(.headline)
            Text("多人在线交易系统即将上线，敬请期待")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

/// ✅ 核心修复：StatRow 组件定义
struct StatRow: View {
    let title: String
    let value: String
    let total: String
    let rank: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标圆圈
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                HStack(alignment: .bottom) {
                    Text(value).font(.title2).bold()
                    Text("/ \(total)").font(.caption).foregroundColor(.secondary).padding(.bottom, 3)
                }
            }
            
            Spacer()
            
            // 排名标签
            Text(rank)
                .font(.caption).bold()
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
