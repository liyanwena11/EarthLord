import SwiftUI

struct MapTabView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            // 地图层
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .ignoresSafeArea(edges: .top)
            
            // 顶层 UI
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // 圈地按钮
                    Button(action: {
                        if locationManager.isTracking {
                            locationManager.stopPathTracking()
                        } else {
                            locationManager.startPathTracking()
                        }
                    }) {
                        HStack {
                            Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                            Text(locationManager.isTracking ? "停止圈地 (\(locationManager.pathCoordinates.count)点)" : "开始圈地")
                        }
                        .padding()
                        .background(locationManager.isTracking ? Color.red : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}
