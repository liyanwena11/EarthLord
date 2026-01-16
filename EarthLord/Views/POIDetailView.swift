import SwiftUI
import MapKit

struct POIDetailView: View {
    let poi: POIPoint
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject private var poiService = RealPOIService.shared

    // 搜刮状态
    @State private var showResult = false
    @State private var isSearching = false
    @State private var generatedLoot: [BackpackItem] = []

    /// 搜寻距离限制（米）
    private let searchDistanceLimit: Double = 100

    /// 检查 POI 是否已被搜空（实时从服务获取）
    private var isLooted: Bool {
        poiService.isLooted(poiId: poi.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 顶部大图区域
                ZStack {
                    LinearGradient(
                        colors: [getPoiColor(poi.type).opacity(0.7), getPoiColor(poi.type)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(spacing: 12) {
                        Image(systemName: getPoiIcon(poi.type))
                            .font(.system(size: 80))
                            .shadow(radius: 5)

                        Text(poi.name)
                            .font(.title).bold()

                        Text(poi.type.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .foregroundColor(.white)
                }
                .frame(height: 280)

                VStack(spacing: 20) {
                    // 2. 核心信息卡片
                    VStack(spacing: 16) {
                        detailInfoRow(
                            icon: "mappin.and.ellipse",
                            title: "当前状态",
                            value: isLooted ? "已搜空" : poi.status.rawValue,
                            color: isLooted ? .gray : .green
                        )

                        detailInfoRow(
                            icon: "exclamationmark.shield.fill",
                            title: "危险等级",
                            value: "\(poi.dangerLevel) 级",
                            color: dangerColor
                        )

                        detailInfoRow(
                            icon: "figure.walk",
                            title: "当前距离",
                            value: liveDistance < Double.infinity ? "\(Int(liveDistance)) 米" : "定位中...",
                            color: liveDistance < searchDistanceLimit ? .green : .orange
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // 3. 地点描述
                    VStack(alignment: .leading, spacing: 10) {
                        Text("搜刮情报").font(.headline)
                        Text(poi.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    Spacer(minLength: 40)

                    // 4. 底部主按钮
                    Button(action: startSearching) {
                        HStack {
                            if isSearching {
                                ProgressView().tint(.white)
                                Text("正在搜刮...")
                            } else {
                                Image(systemName: canSearch ? "hammer.fill" : "location.slash.fill")
                                Text(searchButtonText)
                            }
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSearch ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: canSearch ? Color.orange.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!canSearch || isSearching)
                }
                .padding(20)
                .background(Color(.systemGroupedBackground))
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showResult, onDismiss: {
            // 搜刮完成后返回上一页
            dismiss()
        }) {
            // 传递动态生成的物品和 POI ID
            LootResultView(
                poiId: poi.id,
                poiName: poi.name,
                lootItems: generatedLoot
            )
        }
    }

    // MARK: - 搜刮逻辑

    private func startSearching() {
        isSearching = true

        // 模拟搜刮过程（1.5秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 根据 POI 类型生成随机掉落物品
            generatedLoot = ExplorationManager.shared.generateLoot(for: poi.type)
            isSearching = false
            showResult = true
        }
    }

    // MARK: - 辅助方法

    private func getPoiIcon(_ type: POIType) -> String {
        switch type {
        case .supermarket: return "cart.fill"
        case .hospital: return "cross.case.fill"
        case .gasStation: return "fuelpump.fill"
        case .pharmacy: return "pills.fill"
        case .factory: return "building.2.fill"
        case .warehouse: return "archivebox.fill"
        case .school: return "book.fill"
        }
    }

    private func getPoiColor(_ type: POIType) -> Color {
        switch type {
        case .hospital: return .red
        case .supermarket: return .green
        case .pharmacy: return .purple
        case .gasStation: return .orange
        case .factory, .warehouse: return .gray
        case .school: return .blue
        }
    }

    private var dangerColor: Color {
        if poi.dangerLevel >= 4 { return .red }
        if poi.dangerLevel >= 2 { return .orange }
        return .green
    }

    private func detailInfoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.secondary).frame(width: 24)
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).bold().foregroundColor(color)
        }
    }

    // MARK: - 距离锁定逻辑

    private var liveDistance: Double {
        guard let userLocation = locationManager.userLocation else {
            return poi.distance ?? Double.infinity
        }
        let poiLocation = CLLocation(
            latitude: poi.coordinate.latitude,
            longitude: poi.coordinate.longitude
        )
        return userLocation.distance(from: poiLocation)
    }

    private var canSearch: Bool {
        guard !isLooted else { return false }
        return liveDistance < searchDistanceLimit
    }

    private var searchButtonText: String {
        if isLooted {
            return "资源已枯竭"
        } else if liveDistance >= searchDistanceLimit {
            return "距离太远，请继续靠近（\(Int(liveDistance))m）"
        } else {
            return "立即搜寻物资"
        }
    }
}

// MARK: - 搜刮结果视图（重新设计）

struct LootResultView: View {
    let poiId: String
    let poiName: String
    let lootItems: [BackpackItem]

    @Environment(\.dismiss) var dismiss
    private var manager = ExplorationManager.shared
    private var poiService = RealPOIService.shared

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

                        Text("搜刮成功！")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)

                        Text(poiName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)

                    // 奖励物品列表
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("获得物资")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("\(lootItems.count) 种物品")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        if lootItems.isEmpty {
                            Text("什么都没找到...")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(lootItems) { item in
                                HStack(spacing: 12) {
                                    // 物品图标
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: item.icon)
                                            .foregroundColor(.blue)
                                    }

                                    // 物品信息
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .foregroundColor(.white)
                                            .fontWeight(.medium)
                                        if let quality = item.quality {
                                            Text(quality.rawValue)
                                                .font(.caption)
                                                .foregroundColor(qualityColor(quality))
                                        }
                                    }

                                    Spacer()

                                    // 数量
                                    Text("x\(item.quantity)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // 总重量提示
                    let totalLootWeight = lootItems.reduce(0) { $0 + $1.weight * Double($1.quantity) }
                    Text("总重量：+\(String(format: "%.1f", totalLootWeight)) kg")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // 确认按钮
                    Button(action: collectLoot) {
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
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - 收集物品逻辑

    private func collectLoot() {
        // 1. 将物品添加到背包
        let addedCount = manager.addItems(items: lootItems)
        print("✅ 已放入背包：\(addedCount) 件物品")

        // 2. 将 POI 标记为已搜空
        poiService.markAsLooted(poiId: poiId)

        // 3. 关闭页面
        dismiss()
    }

    private func qualityColor(_ quality: ItemQuality) -> Color {
        switch quality {
        case .poor: return .gray
        case .normal: return .white
        case .good: return .green
        case .excellent: return .purple
        }
    }
}
