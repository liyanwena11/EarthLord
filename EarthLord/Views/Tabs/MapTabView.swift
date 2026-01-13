import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    // MARK: - Day 19 核心状态
    @State private var collisionCheckTimer: Timer?
    @State private var collisionWarning: String?
    @State private var showCollisionWarning = false
    @State private var collisionWarningLevel: WarningLevel = .safe
    
    // 虚拟位移（步长加大，确保能“撞”上去）
    @State private var simulatedLatOffset: Double = 0
    @State private var enemyLocation: CLLocation? // 固定敌人位置
    
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
                // 顶部：醒目的雷达横幅
                if showCollisionWarning, let warning = collisionWarning {
                    collisionWarningBanner(message: warning, level: collisionWarningLevel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // 【实战冲刺工具】
                if locationManager.isTracking {
                    VStack(spacing: 12) {
                        Text("--- 快速通关控制台 ---").font(.caption).foregroundColor(.white)
                        
                        Button(action: {
                            // 🚀 暴力步长：每点一次靠近 15 米，3下必撞！
                            simulatedLatOffset += 0.00015
                            performInstantCheck()
                        }) {
                            Label("大幅靠近敌军 (15m)", systemImage: "bolt.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 20)
                }
                
                // 底部大按钮
                Button(action: {
                    if locationManager.isTracking {
                        stopAll()
                    } else {
                        startClaimingTest()
                    }
                }) {
                    Text(locationManager.isTracking ? "停止测试" : "开始实战圈地")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(locationManager.isTracking ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .onAppear { setupFixedEnemy() }
    }
    
    // MARK: - 通关逻辑
    
    private func setupFixedEnemy() {
        guard let loc = locationManager.userLocation?.coordinate else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { setupFixedEnemy() }
            return
        }
        // 将敌人固定在此时位置的北边 45 米
        let enemyLat = loc.latitude + 0.0004
        enemyLocation = CLLocation(latitude: enemyLat, longitude: loc.longitude)
        
        let enemy = Territory(
            id: "boss", userId: "ENEMY", name: "禁区",
            path: [["lat": enemyLat, "lon": loc.longitude]], // 简化逻辑
            area: 1000, pointCount: 5, isActive: true
        )
        TerritoryManager.shared.territories = [enemy]
    }

    private func startClaimingTest() {
        simulatedLatOffset = 0
        locationManager.startTracking()
        // 缩短检测间隔到 3 秒，让你反馈更快
        collisionCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            performInstantCheck()
        }
    }

    private func performInstantCheck() {
        guard let realLoc = locationManager.userLocation?.coordinate,
              let enemyLoc = enemyLocation else { return }
        
        // 当前模拟位置
        let currentPos = CLLocation(latitude: realLoc.latitude + simulatedLatOffset, longitude: realLoc.longitude)
        let dist = currentPos.distance(from: enemyLoc)
        
        withAnimation(.easeInOut) {
            if dist < 10 { // 🛑 撞上了！
                collisionWarning = "🛑 轨迹不能进入他人领地！"
                collisionWarningLevel = .violation
                showCollisionWarning = true
                stopAll()
                // 震动反馈
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else if dist < 25 {
                collisionWarning = "⚠️ 危险：即将进入他人领地！(\(Int(dist))m)"
                collisionWarningLevel = .danger
                showCollisionWarning = true
            } else if dist < 50 {
                collisionWarning = "⚠️ 警告：正在靠近他人领地 (\(Int(dist))m)"
                collisionWarningLevel = .warning
                showCollisionWarning = true
            } else {
                collisionWarning = "⚠️ 注意：距离他人领地 \(Int(dist))m"
                collisionWarningLevel = .caution
                showCollisionWarning = true
            }
        }
    }
    
    private func stopAll() {
        collisionCheckTimer?.invalidate()
        collisionCheckTimer = nil
        locationManager.stopTracking()
        // 延时关闭横幅，方便截图
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !locationManager.isTracking { showCollisionWarning = false }
        }
    }

    private func collisionWarningBanner(message: String, level: WarningLevel) -> some View {
        HStack {
            Image(systemName: level == .violation ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
            Text(message)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(level == .caution ? Color.yellow : (level == .warning ? Color.orange : Color.red))
        .foregroundColor(level == .caution ? .black : .white)
        .cornerRadius(25)
        .padding(.top, 80)
    }
}
