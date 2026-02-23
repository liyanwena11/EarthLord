import SwiftUI
import MapKit

struct POIDetailView: View {
    let poi: POIPoint
    @Environment(\.dismiss) var dismiss
    @State private var isSearching = false
    @State private var showResult = false
    @State private var lootedItems: [BackpackItem] = []  // ✅ 存储搜刮到的物品
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 顶部大图区域 (根据 POI 类型显示渐变色)
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [getPoiColor(poi.type).opacity(0.7), getPoiColor(poi.type)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 250)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: getPoiIcon(poi.type))
                            .font(.system(size: 70))
                            .shadow(radius: 5)
                        
                        Text(poi.name).font(.title.bold())
                        Text(poi.type.rawValue).font(.subheadline)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.white.opacity(0.2)).cornerRadius(8)
                    }
                    .foregroundColor(.white)
                    .padding(25)
                }
                
                VStack(spacing: 20) {
                    // 2. 信息卡片
                    VStack(spacing: 16) {
                        infoRow(icon: "mappin.and.ellipse", title: "当前状态", value: poi.status.rawValue, color: poi.status == .looted ? .gray : .green)
                        infoRow(icon: "exclamationmark.shield.fill", title: "危险等级", value: "\(poi.dangerLevel) 级", color: .orange)
                        if let dist = poi.distance {
                            infoRow(icon: "figure.walk", title: "预计距离", value: "\(Int(dist)) 米", color: .blue)
                        }
                    }
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(16)
                    
                    // 3. 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("搜刮情报").font(.headline)
                        Text(poi.description)
                            .font(.subheadline).foregroundColor(.secondary).lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(16)

                    Spacer(minLength: 40)
                    
                    // 4. 搜刮按钮
                    Button(action: {
                        // ✅ 真实搜刮逻辑
                        isSearching = true

                        // 根据 POI 类型生成真实掉落物品
                        lootedItems = ExplorationManager.shared.generateLoot(for: poi.type)

                        // 模拟搜刮时间
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            // 将物品添加到背包（自动同步到 Supabase）
                            ExplorationManager.shared.addItems(items: lootedItems)

                            isSearching = false
                            showResult = true

                            LogDebug("🎲 在 \(poi.name) 搜刮到：\(lootedItems.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
                        }
                    }) {
                        HStack {
                            if isSearching {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "hammer.fill")
                                Text(poi.status == .looted ? "资源已枯竭" : "立即搜寻物资")
                            }
                        }
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(poi.status == .looted ? Color.gray : Color.orange)
                        .foregroundColor(.white).cornerRadius(15)
                    }
                    .disabled(poi.status == .looted || isSearching)
                }
                .padding(20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showResult) {
            // ✅ 显示真实搜刮结果
            QuickLootResultView(lootItems: lootedItems)
        }
    }
    
    // MARK: - 辅助方法
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundColor(.secondary)
            Spacer()
            Text(value).bold().foregroundColor(color)
        }
    }
    
    private func getPoiIcon(_ type: POIType) -> String {
        switch type {
        case .hospital: return "cross.case.fill"
        case .supermarket: return "cart.fill"
        case .pharmacy: return "pills.fill"
        case .gasStation: return "fuelpump.fill"
        default: return "building.2.fill"
        }
    }
    
    private func getPoiColor(_ type: POIType) -> Color {
        switch type {
        case .hospital: return .red
        case .supermarket: return .green
        case .pharmacy: return .purple
        default: return .orange
        }
    }
} // ✅ 这一次确保加上了这个最关键的结尾大括号！
