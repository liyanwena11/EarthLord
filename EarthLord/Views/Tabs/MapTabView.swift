import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var rewardManager = WalkingRewardManager.shared

    @State private var isExploring = false
    @State private var showExplorationResult = false
    @State private var shouldCenterOnUser = false  // ✅ 定位按钮触发器

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
            WalkingDistanceStatusBar(manager: rewardManager)
                .padding(.top, 60)
                .padding(.horizontal)
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
                        VStack {
                            Image(systemName: locationManager.isTracking ? "stop.fill" : "figure.walk")
                            Text(locationManager.isTracking ? "停止" : "圈地")
                        }
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(locationManager.isTracking ? Color.red : Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                    }

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
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(isExploring ? Color.gray : Color.orange)
                        .foregroundColor(.white).cornerRadius(12)
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
                print("📍 [MapTabView] 用户点击定位按钮")
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
            Text("探索结算功能开发中...") // 临时占位，防止编译报错
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
