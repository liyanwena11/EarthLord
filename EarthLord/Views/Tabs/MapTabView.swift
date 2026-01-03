import SwiftUI
import MapKit

struct MapTabView: View {
    // 定义初始位置（北京中心）
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    var body: some View {
        ZStack {
            // 1. 使用 iOS 17 最新语法重建地图并找回标记点
            Map(position: $position) {
                // 还原并翻译标记点
                Annotation("Shelter Alpha", coordinate: CLLocationCoordinate2D(latitude: 39.9100, longitude: 116.4200)) {
                    MarkerIcon(icon: "house.fill")
                }
                Annotation("Resource Beta", coordinate: CLLocationCoordinate2D(latitude: 39.8900, longitude: 116.4000)) {
                    MarkerIcon(icon: "key.fill")
                }
                Annotation("Outpost Gamma", coordinate: CLLocationCoordinate2D(latitude: 39.9200, longitude: 116.4300)) {
                    MarkerIcon(icon: "flag.fill")
                }
            }
            .mapStyle(.standard(emphasis: .muted)) // 科技感暗色地图风格
            .ignoresSafeArea()
            
            VStack {
                // 2. 顶部状态栏
                HStack(spacing: 10) {
                    MapStatItem(icon: "person.2.fill", value: "127", label: "Survivors", color: .blue)
                    MapStatItem(icon: "exclamationmark.triangle.fill", value: "Medium", label: "Threat", color: .yellow)
                    MapStatItem(icon: "box.stack.fill", value: "5", label: "Resources", color: .green)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .padding(.top, 10)
                
                Spacer()
                
                // 3. 底部信息区
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.north.fill")
                            Text("CURRENT LOCATION")
                        }
                        .font(.caption).bold().foregroundColor(brandOrange)
                        
                        HStack(spacing: 40) {
                            CoordItem(label: "LATITUDE", value: "39.9042° N")
                            CoordItem(label: "LONGITUDE", value: "116.4074° E")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    
                    HStack(spacing: 15) {
                        CircleBtn(icon: "scope")
                        Button(action: {}) {
                            Text("Claim Territory").font(.headline).bold()
                                .frame(maxWidth: .infinity).padding().background(brandOrange).foregroundColor(.white).cornerRadius(15)
                        }
                        CircleBtn(icon: "list.bullet")
                    }
                }
                .padding(.horizontal).padding(.bottom, 100)
            }
        }
    }
}

// 辅助组件
struct MarkerIcon: View {
    let icon: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(red: 1.0, green: 0.42, blue: 0.13))
                .frame(width: 30, height: 30)
            Image(systemName: icon).foregroundColor(.white).font(.caption)
        }
    }
}

struct MapStatItem: View {
    let icon: String; let value: LocalizedStringKey; let label: LocalizedStringKey; let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: 10)).foregroundColor(.gray)
            }
        }.padding(.horizontal, 10).padding(.vertical, 8).background(Color.white.opacity(0.1)).cornerRadius(10)
    }
}

struct CoordItem: View {
    let label: LocalizedStringKey; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(.gray)
            Text(value).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.13))
        }
    }
}

struct CircleBtn: View {
    let icon: String
    var body: some View {
        Image(systemName: icon).font(.title3).bold().frame(width: 55, height: 55).background(Color.blue.opacity(0.8)).foregroundColor(.white).clipShape(Circle())
    }
}
