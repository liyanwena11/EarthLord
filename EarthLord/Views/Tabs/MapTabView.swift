import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var rewardManager = WalkingRewardManager.shared

    @State private var isExploring = false
    @State private var showExplorationResult = false
    @State private var shouldCenterOnUser = false  // ✅ 定位按钮触发器

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 地图层 - 使用 GeometryReader 确保有明确尺寸
                MapViewRepresentable(
                    locationManager: locationManager,
                    trackingPath: $locationManager.pathCoordinates,
                    isPathClosed: $locationManager.isPathClosed,
                    pathUpdateVersion: locationManager.pathUpdateVersion,
                    shouldCenterOnUser: $shouldCenterOnUser
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

                // 2. UI 叠加层
                VStack(spacing: 0) {
                    // 顶部：行走状态栏
                    WalkingDistanceStatusBar(manager: rewardManager)
                        .padding(.top, 60)
                        .padding(.horizontal)

                    Spacer()
                        .allowsHitTesting(false)

                    // 底部控制区
                    HStack(spacing: 12) {
                        // 圈地按钮
                        Button(action: { locationManager.isTracking.toggle() }) {
                            VStack {
                                Image(systemName: locationManager.isTracking ? "stop.fill" : "figure.walk")
                                Text(locationManager.isTracking ? "停止" : "圈地")
                            }
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(locationManager.isTracking ? Color.red : Color.blue)
                            .foregroundColor(.white).cornerRadius(12)
                        }

                        // 探索按钮
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }

                // 3. 定位按钮（右下角）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                }
                .allowsHitTesting(true)
            }
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

// MARK: - ✅ 补全丢失的子组件

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
