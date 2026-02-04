import SwiftUI
import CoreLocation

struct POIListView: View {
    @StateObject private var engine = EarthLordEngine.shared

    var body: some View {
        VStack(spacing: 0) {
            // 1. 生成 POI 按钮
            Button(action: {
                engine.createMultipleTestPOIs(count: 3)
            }) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("扫描附近资源点")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()

            // 2. 结果展示
            if engine.nearbyPOIs.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "binoculars.fill").font(.system(size: 60)).foregroundColor(.gray)
                    Text("雷达未发现目标")
                    Text("请点击上方按钮开始扫描").font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(engine.nearbyPOIs) { poi in
                    HStack(spacing: 15) {
                        Circle()
                            .fill(poi.rarity.color.opacity(0.2))
                            .frame(width: 45, height: 45)
                            .overlay(Image(systemName: "mappin.and.ellipse").foregroundColor(poi.rarity.color))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(poi.name).font(.headline)
                            Text("等级: \(poi.rarity.rawValue)")
                                .font(.caption)
                                .foregroundColor(poi.rarity.color)
                            if let userLoc = engine.userLocation {
                                let dist = userLoc.distance(from: poi.location)
                                Text("距离: \(Int(dist))m")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(poi.isScavenged ? "已搜刮" : "可搜刮")
                            .font(.system(size: 10))
                            .padding(5)
                            .background((poi.isScavenged ? Color.gray : Color.green).opacity(0.1))
                            .foregroundColor(poi.isScavenged ? .gray : .green)
                            .cornerRadius(5)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
