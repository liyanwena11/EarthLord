import SwiftUI
import MapKit

struct POIDetailView: View {
    let poi: POIPoint
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @State private var showResult = false

    /// 搜寻距离限制（米）
    private let searchDistanceLimit: Double = 100
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 顶部大图区域 (渐变背景 + 动态图标)
                ZStack {
                    LinearGradient(
                        colors: [getPoiColor(poi.type).opacity(0.7), getPoiColor(poi.type)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    VStack(spacing: 12) {
                        // ✅ 这里不再调用 poi.iconName，而是调用内部方法 getPoiIcon
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
                        detailInfoRow(icon: "mappin.and.ellipse", title: "当前状态", value: poi.status.rawValue, color: poi.status == .looted ? .gray : .green)
                        
                        detailInfoRow(icon: "exclamationmark.shield.fill", title: "危险等级", value: "\(poi.dangerLevel) 级", color: dangerColor)
                        
                        // 显示实时距离（动态计算）
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
                    
                    // 4. 底部主按钮（距离锁定逻辑）
                    Button(action: {
                        showResult = true
                    }) {
                        HStack {
                            Image(systemName: canSearch ? "hammer.fill" : "location.slash.fill")
                            Text(searchButtonText)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSearch ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: canSearch ? Color.orange.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!canSearch)
                }
                .padding(20)
                .background(Color(.systemGroupedBackground))
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showResult) {
            ExplorationResultView(result: MockExplorationData.mockExplorationResult)
        }
    }
    
    // MARK: - 内部辅助 Helper (修复报错的关键)
    
    // 1. 手动映射图标
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
    
    // 2. 手动映射颜色
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
    
    // 3. 危险等级颜色
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

    /// 计算玩家与 POI 的实时距离
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

    /// 是否可以搜寻（距离 < 100m 且未被搜空）
    private var canSearch: Bool {
        guard poi.status != .looted else { return false }
        return liveDistance < searchDistanceLimit
    }

    /// 搜寻按钮文字
    private var searchButtonText: String {
        if poi.status == .looted {
            return "资源已枯竭"
        } else if liveDistance >= searchDistanceLimit {
            return "距离太远，请继续靠近（\(Int(liveDistance))m）"
        } else {
            return "立即搜寻物资"
        }
    }
}
