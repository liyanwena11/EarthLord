import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var walkingRewardManager = WalkingRewardManager.shared

    @State private var isExploring = false
    @State private var showExplorationResult = false
    @State private var shouldCenterOnUser = false  // ✅ Day 21 修复：定位按钮触发器
    // 存储生成的搜刮奖励，用于展示
    @State private var explorationLoot: [BackpackItem] = []
    
    var body: some View {
        ZStack {
            // 1. 地图层
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                isPathClosed: $locationManager.isPathClosed,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                shouldCenterOnUser: $shouldCenterOnUser  // ✅ Day 21 修复：传递定位触发器
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 2. ✅ Day 21 修复：实时距离状态栏（心跳感）
                WalkingDistanceStatusBar(manager: walkingRewardManager)
                    .padding(.top, 60)
                    .padding(.horizontal)

                // 3. 验证结果横幅
                if locationManager.isPathClosed {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 4. 行走奖励通知
                if walkingRewardManager.showRewardNotification,
                   let reward = walkingRewardManager.recentReward {
                    WalkingRewardNotificationView(tier: reward, manager: walkingRewardManager)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }

                Spacer()
                
                // 4. 底部控制区 (Day 20)
                HStack(spacing: 12) {
                    // 圈地/停止按钮
                    Button(action: {
                        if locationManager.isTracking {
                            locationManager.stopTracking()
                        } else {
                            locationManager.startTracking()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: locationManager.isTracking ? "stop.fill" : "figure.walk")
                            Text(locationManager.isTracking ? "停止" : "圈地")
                        }
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(locationManager.isTracking ? Color.red : Color.blue)
                        .foregroundColor(.white).cornerRadius(12)
                    }
                    
                    // 定位按钮
                    Button(action: {
                        // ✅ Day 21 修复：触发地图定位到用户位置
                        shouldCenterOnUser.toggle()
                    }) {
                        Image(systemName: "location.fill")
                            .frame(width: 60, height: 60)
                            .background(Color.white).foregroundColor(.blue).cornerRadius(12).shadow(radius: 5)
                    }
                    
                    // 探索按钮
                    Button(action: {
                        runExplorationFlow()
                    }) {
                        VStack(spacing: 4) {
                            if isExploring {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "binoculars.fill")
                                Text("探索")
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(isExploring ? Color.gray : Color.orange)
                        .foregroundColor(.white).cornerRadius(12)
                    }
                    .disabled(isExploring)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        // ✅ 修正：使用独立文件定义的 QuickLootResultView，传入生成的奖励
        .sheet(isPresented: $showExplorationResult) {
            QuickLootResultView(lootItems: explorationLoot)
        }
    }
    
    // MARK: - 逻辑实现
    
    private func runExplorationFlow() {
        guard let userLoc = locationManager.userLocation?.coordinate else {
            print("❌ 无法获取位置，请确保 GPS 开启")
            return
        }

        isExploring = true

        // ✅ 调用真实 POI 搜索
        RealPOIService.shared.searchNearbyRealPOI(userLocation: userLoc)

        // 等待搜索完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard let nearestPOI = RealPOIService.shared.realPOIs.first else {
                print("❌ 附近 500 米内没有可搜刮的 POI")
                self.isExploring = false
                return
            }

            // ✅ 根据 POI 类型生成真实掉落物品
            self.explorationLoot = ExplorationManager.shared.generateLoot(for: nearestPOI.type)

            // 标记 POI 为已搜空
            RealPOIService.shared.markAsLooted(poiId: nearestPOI.id)

            self.isExploring = false
            self.showExplorationResult = true

            print("🎲 在 \(nearestPOI.name) 获得物品：\(self.explorationLoot.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
        }
    }

    // MARK: - UI 组件

    private var validationResultBanner: some View {
        HStack {
            Image(systemName: locationManager.territoryValidationPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(locationManager.territoryValidationPassed ? "验证通过！准备登记" : (locationManager.territoryValidationError ?? "验证失败"))
        }
        .padding().background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .foregroundColor(.white).cornerRadius(20).padding(.top, 50)
    }
}

// MARK: - 行走奖励通知视图

struct WalkingRewardNotificationView: View {
    let tier: WalkingRewardTier
    let manager: WalkingRewardManager

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("🎉 解锁成就：\(tier.displayName)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    manager.showRewardNotification = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Text("行走 \(Int(tier.distance)) 米")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Text("获得奖励：\(tier.rewards.map { $0.name }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.green.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.top, 60)
    }
}

// MARK: - 实时距离状态栏（心跳感）

struct WalkingDistanceStatusBar: View {
    @ObservedObject var manager: WalkingRewardManager

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：脚步图标
            Image(systemName: "figure.walk")
                .foregroundColor(.white)
                .font(.title3)

            // 中间：距离信息
            VStack(alignment: .leading, spacing: 2) {
                Text("今日已累计行走")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Text("\(Int(manager.totalWalkingDistance))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.3), value: manager.totalWalkingDistance)  // ✅ 心跳感动画

                    Text("米")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            // 右侧：下一个奖励提示
            if let nextTier = manager.nextTier {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("距下一奖励")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    Text("\(Int(manager.distanceToNextTier))m")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            } else {
                // 全部解锁
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}
