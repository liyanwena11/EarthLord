import SwiftUI
import MapKit
import Foundation

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var rewardManager = WalkingRewardManager.shared

    @State private var isExploring = false
    @State private var showExplorationResult = false
    @State private var shouldCenterOnUser = false  // ✅ 定位按钮触发器
    @State private var currentTime = Date()

    var body: some View {
        // ✅ 核心修复：使用 overlay 方式叠加 UI，不会阻挡地图触摸
        MapViewRepresentable(
            locationManager: locationManager,
            trackingPath: $locationManager.pathCoordinates,
            isPathClosed: $locationManager.isPathClosed,
            pathUpdateVersion: locationManager.pathUpdateVersion,
            shouldCenterOnUser: $shouldCenterOnUser
        )
        .ignoresSafeArea()
        // ✅ 顶部状态栏
        .overlay(alignment: .top) {
            VStack(spacing: 10) {
                // 坐标和时间
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundColor(.white)
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("当前坐标")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("23.1975, 114.4549")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding(.top, 60)
                .padding(.horizontal)
            }
        }
        // ✅ 接近起点引导横幅
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                // 圈地时的接近起点提示
                if locationManager.isNearStartPoint {
                    StartPointGuideBar(distance: locationManager.distanceToStartPoint)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 底部按钮区
                HStack(spacing: 12) {
                    Button(action: { locationManager.isTracking.toggle() }) {
                        HStack {
                            Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                            Text(locationManager.isTracking ? "停止圈地" : "开始圈地")
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(locationManager.isTracking ? Color.red : Color.orange)
                        .foregroundColor(.white).cornerRadius(12)
                        .font(.system(size: 14))
                    }

                    Button(action: { LogDebug("物资速递按钮点击") }) {
                        VStack {
                            Text("物资速递")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            HStack {
                                Image(systemName: "cube")
                                    .font(.system(size: 14))
                                Text("$21")
                                    .font(.system(size: 12))
                                    .bold()
                            }
                        }
                        .frame(width: 80, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                    }

                    Button(action: { LogDebug("定位按钮点击") }) {
                        Image(systemName: "location.fill")
                            .frame(width: 50, height: 50)
                            .background(Color.orange)
                            .foregroundColor(.white).cornerRadius(12)
                    }

                    Button(action: {
                        isExploring = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isExploring = false
                            showExplorationResult = true
                        }
                    }) {
                        HStack {
                            if isExploring { ProgressView().tint(.white) }
                            else { Image(systemName: "figure.walk"); Text("开始探索") }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(isExploring ? Color.gray : Color.green)
                        .foregroundColor(.white).cornerRadius(12)
                        .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .animation(.easeInOut(duration: 0.3), value: locationManager.isNearStartPoint)
        }
        // ✅ 定位按钮（右下角）
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                shouldCenterOnUser = true
                LogDebug("📍 [MapTabView] 用户点击定位按钮")
            }) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 110)
        }
        // 🚀 核心修复：不再引用已删除的 MockData
        .sheet(isPresented: $showExplorationResult) {
            ExplorationResultView(result: createMockExplorationResult())
        }
        // Day 22：POI 接近弹窗 (修复：透明区域不拦截点击)
        .overlay(alignment: .bottom) {
            Group {
                if locationManager.showPOIPopup, let poi = locationManager.alertPOI {
                    POIProximityPopup(
                        poi: poi,
                        onLoot: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                locationManager.showPOIPopup = false
                            }
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                locationManager.showPOIPopup = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // 避开 TabBar
                }
            }
            .allowsHitTesting(locationManager.showPOIPopup) // ✅ 核心修复：弹窗隐藏时不拦截点击
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: locationManager.showPOIPopup)
        .onAppear {
            // 更新时间
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // 创建模拟探索结果
    private func createMockExplorationResult() -> ExplorationResult {
        let items = [
            BackpackItem(
                id: UUID().uuidString,
                itemId: UUID().uuidString,
                name: "食物",
                category: .food,
                quantity: 1,
                weight: 0.5,
                quality: .normal,
                icon: "star.fill"
            ),
            BackpackItem(
                id: UUID().uuidString,
                itemId: UUID().uuidString,
                name: "水",
                category: .water,
                quantity: 2,
                weight: 1.0,
                quality: .normal,
                icon: "star.fill"
            )
        ]
        return ExplorationResult(
            walkDistance: 0,
            totalWalkDistance: 0,
            walkRanking: 156,
            exploredArea: 0,
            totalExploredArea: 0,
            areaRanking: 99,
            duration: 60,
            itemsFound: items,
            poisDiscovered: 1,
            experienceGained: 10
        )
    }
}

// MARK: - 起点引导横幅

struct StartPointGuideBar: View {
    let distance: Double
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 10) {
            // 闪烁圆点
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.4 : 0.8)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)

            VStack(alignment: .leading, spacing: 2) {
                Text("接近起点，请回到起点完成圈地")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("距起点 \(Int(distance))m（≤50m 自动闭合）")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .onAppear { isPulsing = true }
    }
}

// MARK: - 行走状态栏

struct WalkingDistanceStatusBar: View {
    @ObservedObject var manager: WalkingRewardManager

    /// 右侧奖励状态显示
    private var rewardStatusView: some View {
        VStack(alignment: .trailing) {
            if manager.nextTier == nil {
                // 所有奖励都已领取
                Text("今日奖励").font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("已满").foregroundColor(.green).bold()
            } else if manager.distanceToNextTier < 1 {
                // 距离不足 1m，可领取
                Text("奖励状态").font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("可领取").foregroundColor(.yellow).bold()
            } else {
                // 正常显示距离
                Text("距下一奖励").font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("\(Int(manager.distanceToNextTier))m").foregroundColor(.orange).bold()
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "figure.walk").foregroundColor(.white)
            VStack(alignment: .leading) {
                Text("今日已累计行走").font(.caption).foregroundColor(.white.opacity(0.7))
                Text("\(Int(manager.totalWalkingDistance)) 米").font(.title2).bold().foregroundColor(.white)
            }
            Spacer()
            rewardStatusView
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
}
