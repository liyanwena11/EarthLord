import SwiftUI
import CoreLocation

struct POIListView: View {
    @EnvironmentObject var locationManager: LocationManager
    // ✅ 核心修复：单例必须用 @ObservedObject，不能用 @StateObject
    @ObservedObject private var poiService = RealPOIService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 实时扫描按钮
            Button(action: {
                // ✅ 修复：直接获取当前位置进行搜索
                let currentLoc = locationManager.userLocation?.coordinate
                poiService.searchNearbyRealPOI(userLocation: currentLoc)
            }) {
                HStack {
                    // ✅ 修复：直接访问 isScanning，不要加 $
                    if poiService.isScanning {
                        ProgressView().tint(.white)
                        Text("正在同步成都地理数据...")
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("扫描附近真实废墟")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(poiService.isScanning ? Color.gray : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()

            // 2. 结果展示
            // ✅ 修复：直接访问属性，不要加 $
            if poiService.realPOIs.isEmpty && !poiService.isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "binoculars.fill").font(.system(size: 60)).foregroundColor(.gray)
                    Text("雷达未发现目标")
                    Text("请点击上方按钮开始实时扫描").font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(poiService.realPOIs) { poi in
                    NavigationLink(destination: POIDetailView(poi: poi)) {
                        HStack(spacing: 15) {
                            // 动态图标
                            Circle().fill(Color.blue.opacity(0.1)).frame(width: 45, height: 45)
                                .overlay(Image(systemName: "mappin.and.ellipse").foregroundColor(.blue))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poi.name).font(.headline)
                                // 实时距离计算逻辑
                                Text("距离: \(calculateDistance(to: poi.coordinate))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("有物资").font(.system(size: 10)).padding(5)
                                .background(Color.green.opacity(0.1)).foregroundColor(.green).cornerRadius(5)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // 测距方法
    private func calculateDistance(to target: CLLocationCoordinate2D) -> String {
        let userLoc = locationManager.userLocation ?? CLLocation(latitude: 30.565, longitude: 104.265)
        let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
        let distance = userLoc.distance(from: targetLoc)
        return distance < 1000 ? "\(Int(distance)) 米" : String(format: "%.1f 公里", distance / 1000)
    }
}
