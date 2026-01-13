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

    // MARK: - Day 19: 碰撞检测状态
    @State private var collisionCheckTimer: Timer?
    @State private var collisionWarning: String?
    @State private var showCollisionWarning = false
    @State private var collisionWarningLevel: WarningLevel = .safe
    @State private var currentUserId: String?
    @State private var trackingStartTime: Date?
    
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

                // Day 19: 碰撞警告横幅（分级颜色）
                if showCollisionWarning, let warning = collisionWarning {
                    collisionWarningBanner(message: warning, level: collisionWarningLevel)
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
                                // Day 19: 带碰撞检测的开始圈地
                                startClaimingWithCollisionCheck()
                            }) {
                                Label("开始圈地", systemImage: "figure.walk")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                // Day 19: 停止时清除碰撞监控
                                stopCollisionMonitoring()
                                locationManager.stopTracking()
                            }) {
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
        // 加载所有领地数据（用于碰撞检测）
        .onAppear {
            Task {
                do {
                    // Day 19: 获取当前用户 ID
                    let session = try await supabaseClient.auth.session
                    currentUserId = session.user.id.uuidString
                    TerritoryLogger.shared.log("当前用户 ID: \(currentUserId ?? "未知")", type: .info)

                    // 加载所有领地
                    territoryManager.territories = try await territoryManager.loadAllTerritories()
                    TerritoryLogger.shared.log("已加载 \(territoryManager.territories.count) 个领地用于碰撞检测", type: .info)
                } catch {
                    TerritoryLogger.shared.log("初始化失败: \(error.localizedDescription)", type: .error)
                }
            }
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
            stopCollisionMonitoring()  // Day 19: 清除碰撞监控
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

    // MARK: - Day 19: 碰撞检测方法

    /// Day 19: 带碰撞检测的开始圈地
    private func startClaimingWithCollisionCheck() {
        guard let location = locationManager.userLocation,
              let userId = currentUserId else {
            TerritoryLogger.shared.log("无法获取位置或用户 ID", type: .error)
            return
        }

        // 检测起始点是否在他人领地内
        let result = territoryManager.checkPointCollision(
            location: location,
            currentUserId: userId
        )

        if result.hasCollision {
            // 起点在他人领地内，显示错误并震动
            collisionWarning = result.message
            collisionWarningLevel = .violation
            showCollisionWarning = true

            // 错误震动
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)

            TerritoryLogger.shared.log("起点碰撞：阻止圈地", type: .error)

            // 3秒后隐藏警告
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showCollisionWarning = false
                collisionWarning = nil
                collisionWarningLevel = .safe
            }

            return
        }

        // 起点安全，开始圈地
        withAnimation {
            showValidationBanner = false
        }
        TerritoryLogger.shared.log("起始点安全，开始圈地", type: .info)
        trackingStartTime = Date()
        locationManager.startTracking()
        startCollisionMonitoring()
    }

    /// Day 19: 启动碰撞检测监控
    private func startCollisionMonitoring() {
        // 先停止已有定时器
        stopCollisionCheckTimer()

        // 每 10 秒检测一次
        collisionCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [self] _ in
            performCollisionCheck()
        }

        TerritoryLogger.shared.log("碰撞检测定时器已启动", type: .info)
    }

    /// Day 19: 仅停止定时器（不清除警告状态）
    private func stopCollisionCheckTimer() {
        collisionCheckTimer?.invalidate()
        collisionCheckTimer = nil
        TerritoryLogger.shared.log("碰撞检测定时器已停止", type: .info)
    }

    /// Day 19: 完全停止碰撞监控（停止定时器 + 清除警告）
    private func stopCollisionMonitoring() {
        stopCollisionCheckTimer()
        // 清除警告状态
        showCollisionWarning = false
        collisionWarning = nil
        collisionWarningLevel = .safe
    }

    /// Day 19: 执行碰撞检测
    private func performCollisionCheck() {
        guard locationManager.isTracking,
              let userId = currentUserId else {
            return
        }

        let path = locationManager.pathCoordinates
        guard path.count >= 2 else { return }

        let result = territoryManager.checkPathCollisionComprehensive(
            path: path,
            currentUserId: userId
        )

        // 根据预警级别处理
        switch result.warningLevel {
        case .safe:
            // 安全，隐藏警告横幅
            showCollisionWarning = false
            collisionWarning = nil
            collisionWarningLevel = .safe

        case .caution:
            // 注意（50-100m）- 黄色横幅 + 轻震 1 次
            collisionWarning = result.message
            collisionWarningLevel = .caution
            showCollisionWarning = true
            triggerHapticFeedback(level: .caution)

        case .warning:
            // 警告（25-50m）- 橙色横幅 + 中震 2 次
            collisionWarning = result.message
            collisionWarningLevel = .warning
            showCollisionWarning = true
            triggerHapticFeedback(level: .warning)

        case .danger:
            // 危险（<25m）- 红色横幅 + 强震 3 次
            collisionWarning = result.message
            collisionWarningLevel = .danger
            showCollisionWarning = true
            triggerHapticFeedback(level: .danger)

        case .violation:
            // 【关键修复】违规处理 - 必须先显示横幅，再停止！

            // 1. 先设置警告状态（让横幅显示出来）
            collisionWarning = result.message
            collisionWarningLevel = .violation
            showCollisionWarning = true

            // 2. 触发震动
            triggerHapticFeedback(level: .violation)

            // 3. 只停止定时器，不清除警告状态！
            stopCollisionCheckTimer()

            // 4. 停止圈地追踪
            locationManager.stopTracking()
            trackingStartTime = nil

            TerritoryLogger.shared.log("碰撞违规，自动停止圈地", type: .error)

            // 5. 5秒后再清除警告横幅
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                showCollisionWarning = false
                collisionWarning = nil
                collisionWarningLevel = .safe
            }
        }
    }

    /// Day 19: 触发震动反馈
    private func triggerHapticFeedback(level: WarningLevel) {
        switch level {
        case .safe:
            // 安全：无震动
            break

        case .caution:
            // 注意：轻震 1 次
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)

        case .warning:
            // 警告：中震 2 次
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }

        case .danger:
            // 危险：强震 3 次
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                generator.impactOccurred()
            }

        case .violation:
            // 违规：错误震动
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }

    /// Day 19: 碰撞警告横幅（分级颜色）
    private func collisionWarningBanner(message: String, level: WarningLevel) -> some View {
        // 根据级别确定颜色
        let backgroundColor: Color
        switch level {
        case .safe:
            backgroundColor = .green
        case .caution:
            backgroundColor = .yellow
        case .warning:
            backgroundColor = .orange
        case .danger, .violation:
            backgroundColor = .red
        }

        // 根据级别确定文字颜色（黄色背景用黑字）
        let textColor: Color = (level == .caution) ? .black : .white

        // 根据级别确定图标
        let iconName = (level == .violation) ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"

        return VStack {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18))

                Text(message)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor.opacity(0.95))
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .padding(.top, 120)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: showCollisionWarning)
    }
}
