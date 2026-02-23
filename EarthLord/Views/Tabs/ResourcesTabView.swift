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
                Text("邮箱").tag(2)
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
                        MailboxView()
                    case 3:
                        TerritoryStatsView()
                    default:
                        TradeMainView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }
            .navigationTitle("资源管理")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - 资源背包视图

struct ResourceBackpackView: View {
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    // 模拟资源数据
    let resources = [
        ResourceItem(name: "大米", quantity: 20, capacity: 100, unit: "kg"),
        ResourceItem(name: "木材", quantity: 50, capacity: 200, unit: "个"),
        ResourceItem(name: "金属", quantity: 30, capacity: 150, unit: "个"),
        ResourceItem(name: "燃油", quantity: 15, capacity: 100, unit: "L"),
        ResourceItem(name: "工具", quantity: 5, capacity: 50, unit: "个")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题
                VStack(spacing: 12) {
                    Text("资源").font(.caption).foregroundColor(brandOrange)
                    
                    // 背包容量
                    VStack(spacing: 8) {
                        HStack {
                            Text("背包容量").foregroundColor(.white)
                            Spacer()
                            Text("20/100kg").foregroundColor(.white)
                        }
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .cornerRadius(5)
                                
                                Rectangle()
                                    .fill(brandOrange)
                                    .frame(width: geometry.size.width * 0.2)
                                    .cornerRadius(5)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                
                // 资源列表
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(resources) {
                            resource in
                            ResourcesResourceRow(item: resource)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 资源模型

struct ResourceItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Int
    let capacity: Int
    let unit: String
}

// MARK: - 资源行视图

struct ResourcesResourceRow: View {
    let item: ResourceItem
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    var body: some View {
        HStack(spacing: 0) {
            // 资源图标和名称
            HStack {
                Image(systemName: "star.fill").foregroundColor(brandOrange)
                Text(item.name).foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 资源数量
            Text("\(item.quantity)\(item.unit)").foregroundColor(.white)
            .padding(.horizontal, 20)
            
            // 使用按钮
            Button(action: {}) {
                Text("使用").foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(brandOrange)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 60)
        .background(Color.black)
        
        // 分割线
        Divider().background(Color.white.opacity(0.1))
    }
}

// MARK: - 内部辅助视图 (补全缺失组件，修复报错)

/// 已购物品页面
struct PurchasedStoreView: View {
    @State private var selectedPurchase: PurchasedItem?
    @State private var rating: Int = 5
    @State private var comment: String = ""
    
    // 已购物品模型
    struct PurchasedItem: Identifiable {
        let id: String
        let name: String
        let icon: String
        let rating: Int?
        let comment: String?
    }
    
    // 模拟已购物品数据
    private var purchasedItems: [PurchasedItem] {
        return [
            PurchasedItem(id: "1", name: "新手生存礼包", icon: "shippingbox.fill", rating: nil, comment: nil),
            PurchasedItem(id: "2", name: "成都区域地图", icon: "map.fill", rating: 5, comment: "地图非常详细"),
            PurchasedItem(id: "3", name: "高级扫描雷达", icon: "antenna.radiowaves.left.and.right", rating: nil, comment: nil)
        ]
    }
    
    var body: some View {
        List {
            Section("我的购买记录") {
                ForEach(purchasedItems) { item in
                    HStack {
                        Label(item.name, systemImage: item.icon)
                        Spacer()
                        if item.rating == nil {
                            Button("去评价") {
                                selectedPurchase = item
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        } else {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) {star in
                                    Image(systemName: star <= item.rating! ? "star.fill" : "star")
                                        .foregroundColor(star <= item.rating! ? .yellow : .gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $selectedPurchase) { purchase in
            RatingView(item: purchase, onDismiss: { 
                selectedPurchase = nil
                rating = 5
                comment = ""
            })
        }
    }
    
    // 评价视图
    struct RatingView: View {
        let item: PurchasedItem
        let onDismiss: () -> Void
        @State private var rating: Int = 5
        @State private var comment: String = ""
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("评价：\(item.name)")
                        .font(.title2.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    
                    Text("请给这次购买打分：")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 30))
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                    
                    TextField("评语（可选）", text: $comment, axis: .vertical)
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .lineLimit(3)
                    
                    Button(action: {
                        // 提交评价逻辑
                        LogDebug("提交评价：\(item.name), 评分：\(rating), 评语：\(comment)")
                        onDismiss()
                    }) {
                        Text("提交评价")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ApocalypseTheme.primary)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .navigationTitle("评价购买")
                .navigationBarTitleDisplayMode(.inline)
                .background(ApocalypseTheme.background)
            }
        }
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
