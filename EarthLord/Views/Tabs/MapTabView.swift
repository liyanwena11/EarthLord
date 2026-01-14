import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var isExploring = false
    @State private var showExplorationResult = false
    
    // 碰撞警告状态
    @State private var collisionWarning: String?
    @State private var showCollisionWarning = false
    
    var body: some View {
        ZStack {
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                isPathClosed: $locationManager.isPathClosed,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 顶部：碰撞预警
                if showCollisionWarning, let warning = collisionWarning {
                    Text(warning)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .padding(.top, 100)
                }
                
                Spacer()
                
                // 底部：三合一控制区
                HStack(spacing: 15) {
                    // 圈地按钮
                    Button(action: { locationManager.isTracking.toggle() }) {
                        VStack {
                            Image(systemName: locationManager.isTracking ? "stop.fill" : "figure.walk")
                            Text(locationManager.isTracking ? "停止" : "圈地")
                        }
                        .frame(width: 80, height: 60)
                        .background(locationManager.isTracking ? Color.red : Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                    }
                    
                    // 定位按钮
                    Button(action: { }) {
                        Image(systemName: "location.fill")
                            .frame(width: 60, height: 60)
                            .background(Color.white).foregroundColor(.blue).cornerRadius(12).shadow(radius: 5)
                    }
                    
                    // 探索按钮 (Day 20)
                    Button(action: {
                        isExploring = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isExploring = false
                            showExplorationResult = true
                        }
                    }) {
                        VStack {
                            if isExploring { ProgressView().tint(.white) }
                            else { Image(systemName: "binoculars.fill"); Text("探索") }
                        }
                        .frame(width: 80, height: 60)
                        .background(isExploring ? Color.gray : Color.orange)
                        .foregroundColor(.white).cornerRadius(12)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showExplorationResult) {
            ExplorationResultView(result: MockExplorationData.mockExplorationResult)
        }
    }
}
