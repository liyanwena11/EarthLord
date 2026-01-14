import SwiftUI
import CoreLocation

struct POIListView: View {
    @EnvironmentObject var locationManager: LocationManager // ✅ 引入真实位置
    @State private var isSearching = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(MockExplorationData.mockPOIs) { poi in
                    NavigationLink(destination: POIDetailView(poi: poi)) {
                        HStack(spacing: 15) {
                            // 图标
                            Image(systemName: getIcon(for: poi.type))
                                .font(.title2).foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(poiColor(for: poi.type).cornerRadius(10))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poi.name).font(.headline).foregroundColor(.primary)
                                // ✅ 关键：显示实时计算的真实距离
                                Text("距离: \(calculateLiveDistance(to: poi))").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(poi.status.rawValue).font(.system(size: 10)).padding(5)
                                .background(Color.green.opacity(0.1)).foregroundColor(.green).cornerRadius(6)
                        }
                        .padding().background(Color(.secondarySystemGroupedBackground)).cornerRadius(15)
                    }
                }
            }.padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // ✅ 实时计算距离的方法
    private func calculateLiveDistance(to poi: POIPoint) -> String {
        guard let userLoc = locationManager.userLocation else { return "定位中..." }
        let poiLoc = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
        let distance = userLoc.distance(from: poiLoc)
        
        if distance < 1000 {
            return "\(Int(distance)) 米"
        } else {
            return String(format: "%.1f 公里", distance / 1000)
        }
    }

    func getIcon(for type: POIType) -> String {
        switch type {
        case .hospital: return "cross.case.fill"
        case .supermarket: return "cart.fill"
        default: return "building.2.fill"
        }
    }
    
    func poiColor(for type: POIType) -> Color {
        switch type {
        case .hospital: return .red
        case .supermarket: return .green
        default: return .orange
        }
    }
}
