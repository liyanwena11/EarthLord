import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showValidationBanner = false
    @State private var showSpeedWarning = false
    
    var body: some View {
        ZStack {
            // 地图层
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                isPathClosed: $locationManager.isPathClosed,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 顶部状态栏：验证结果横幅
                if showValidationBanner {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 速度警告
                if showSpeedWarning, let warning = locationManager.speedWarning {
                    Text(warning)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                }
                
                Spacer()
                
                // 底部控制按钮
                HStack {
                    if !locationManager.isTracking {
                        Button(action: { locationManager.startTracking() }) {
                            Label("开始圈地", systemImage: "figure.walk")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: { locationManager.stopTracking() }) {
                            Label("停止追踪", systemImage: "stop.fill")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        // 监听速度警告
        .onChange(of: locationManager.speedWarning) { newValue in
            withAnimation { showSpeedWarning = (newValue != nil) }
        }
        // 监听闭环结果
        .onChange(of: locationManager.isPathClosed) { newValue in
            if newValue {
                withAnimation { showValidationBanner = true }
                // 5秒后自动重置
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showValidationBanner = false
                        locationManager.clearPath()
                    }
                }
            }
        }
    }
    
    private var validationResultBanner: some View {
        HStack {
            Image(systemName: locationManager.territoryValidationPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
            VStack(alignment: .leading) {
                if locationManager.territoryValidationPassed {
                    Text("圈地成功！")
                        .font(.headline)
                    Text("面积: \(Int(locationManager.calculatedArea)) ㎡")
                        .font(.subheadline)
                } else {
                    Text("验证失败")
                        .font(.headline)
                    Text(locationManager.territoryValidationError ?? "未知错误")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.top, 50)
    }
}
