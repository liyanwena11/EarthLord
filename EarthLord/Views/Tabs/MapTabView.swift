import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    // Day 18 云端管理器（使用修正后的单例引用）
    private let territoryManager = TerritoryManager.shared
    
    // UI 控制状态
    @State private var showValidationBanner = false
    @State private var showSpeedWarning = false
    @State private var showUploadAlert = false
    @State private var uploadMessage = ""
    @State private var isUploading = false
    
    var body: some View {
        ZStack {
            // 1. 地图底层
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                isPathClosed: $locationManager.isPathClosed,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .edgesIgnoringSafeArea(.all)
            
            // 2. UI 覆盖层
            VStack {
                // 顶部验证结果/报错横幅
                if showValidationBanner {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 速度警告
                if showSpeedWarning, let warning = locationManager.speedWarning {
                    Text(warning)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.top, 10)
                }
                
                Spacer()
                
                // 底部控制区
                VStack(spacing: 16) {
                    
                    // 【Day 18 核心】确认登记按钮：仅在验证通过且未在上传时出现
                    if locationManager.territoryValidationPassed && !isUploading {
                        Button(action: {
                            Task {
                                await uploadCurrentTerritory()
                            }
                        }) {
                            HStack {
                                Image(systemName: isUploading ? "hourglass" : "cloud.fill")
                                Text(isUploading ? "正在上传..." : "确认登记领地")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 开始/停止按钮
                    HStack {
                        if !locationManager.isTracking {
                            Button(action: {
                                withAnimation {
                                    showValidationBanner = false
                                    locationManager.startTracking()
                                }
                            }) {
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
                }
                .padding(.bottom, 30)
            }
        }
        // MARK: - 监听逻辑 (iOS 17+ 新语法)
        .onChange(of: locationManager.speedWarning) { oldValue, newValue in
            withAnimation {
                showSpeedWarning = (newValue != nil)
            }
        }
        .onChange(of: locationManager.isPathClosed) { oldValue, newValue in
            if newValue {
                // 闭环后显示验证结果
                withAnimation {
                    showValidationBanner = true
                }
            }
        }
        // 上传结果弹窗
        .alert(isPresented: $showUploadAlert) {
            Alert(
                title: Text(uploadMessage.contains("成功") ? "登记成功" : "登记失败"),
                message: Text(uploadMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // MARK: - 子视图：验证结果横幅
    private var validationResultBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: locationManager.territoryValidationPassed
                  ? "checkmark.circle.fill"
                  : "xmark.circle.fill")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                if locationManager.territoryValidationPassed {
                    Text("路径已闭合！验证通过 ✓")
                        .font(.headline)
                    Text("面积: \(Int(locationManager.calculatedArea))㎡，点击下方登记")
                        .font(.caption)
                } else {
                    Text("验证未通过")
                        .font(.headline)
                    Text(locationManager.territoryValidationError ?? "请重新走一圈，避免交叉")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .foregroundColor(.white)
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    // MARK: - 云端上传方法 (Day 18)
    private func uploadCurrentTerritory() async {
        isUploading = true
        TerritoryLogger.shared.log("正在上传领地...", type: .info)
        
        do {
            // 调用管理器进行上传（直接使用单例）
            try await territoryManager.uploadTerritory(
                coordinates: locationManager.pathCoordinates,
                area: locationManager.calculatedArea,
                startTime: Date()
            )
            
            // 成功反馈
            uploadMessage = "领地已成功同步至云端！面积：\(Int(locationManager.calculatedArea))㎡"
            
            // 震动反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            showUploadAlert = true
            
            // ⚠️ 关键：上传成功后停止追踪并重置状态
            locationManager.stopTracking()
            locationManager.clearPath()
            showValidationBanner = false
            
        } catch {
            // 失败反馈
            uploadMessage = "登记失败: \(error.localizedDescription)"
            showUploadAlert = true
            TerritoryLogger.shared.log("上传失败: \(error.localizedDescription)", type: .error)
        }
        
        isUploading = false
    }
}
