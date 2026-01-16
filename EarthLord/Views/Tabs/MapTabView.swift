import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    // MARK: - 状态控制
    @State private var collisionWarning: String?
    @State private var showCollisionWarning = false
    @State private var collisionWarningLevel: WarningLevel = .safe
    
    @State private var isExploring = false
    @State private var showExplorationResult = false
    @State private var isUploading = false
    @State private var explorationLoot: [BackpackItem] = []  // 探索获得的物品
    
    var body: some View {
        ZStack {
            // 1. 地图层
            MapViewRepresentable(
                locationManager: locationManager,
                trackingPath: $locationManager.pathCoordinates,
                isPathClosed: $locationManager.isPathClosed,
                pathUpdateVersion: locationManager.pathUpdateVersion
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 2. 顶部预警横幅 (Day 19 逻辑)
                if showCollisionWarning, let warning = collisionWarning {
                    collisionWarningBanner(message: warning, level: collisionWarningLevel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 3. 顶部验证结果 (Day 17/18 逻辑)
                if locationManager.isPathClosed && !showCollisionWarning {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // 4. 底部控制区 (Day 20 整合布局)
                VStack(spacing: 16) {
                    
                    // 【Day 18 核心】确认登记按钮：增加加载状态
                    if locationManager.territoryValidationPassed {
                        Button(action: {
                            Task {
                                isUploading = true
                                // 调用现有的上传逻辑
                                try? await TerritoryManager.shared.uploadTerritory(
                                    coordinates: locationManager.pathCoordinates,
                                    area: locationManager.calculatedArea,
                                    startTime: Date()
                                )
                                isUploading = false
                                locationManager.stopTracking()
                            }
                        }) {
                            HStack {
                                if isUploading {
                                    ProgressView().tint(.white)
                                    Text("正在登记到云端...")
                                } else {
                                    Image(systemName: "cloud.fill")
                                    Text("确认登记领地")
                                }
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isUploading ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                        }
                        .disabled(isUploading)
                        .padding(.horizontal, 40)
                    }
                    
                    // 三合一功能按钮
                    HStack(spacing: 12) {
                        // 圈地/停止
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
                        
                        // 定位
                        Button(action: { /* 定位逻辑 */ }) {
                            Image(systemName: "location.fill")
                                .frame(width: 60, height: 60)
                                .background(Color.white).foregroundColor(.blue).cornerRadius(12).shadow(radius: 5)
                        }
                        
                        // 探索（生成随机物品）
                        Button(action: {
                            isExploring = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                // 随机选择一种 POI 类型生成物品
                                let types: [POIType] = [.supermarket, .warehouse, .pharmacy]
                                let randomType = types.randomElement() ?? .supermarket
                                explorationLoot = ExplorationManager.shared.generateLoot(for: randomType)
                                isExploring = false
                                showExplorationResult = true
                            }
                        }) {
                            VStack(spacing: 4) {
                                if isExploring { ProgressView().tint(.white) }
                                else { Image(systemName: "binoculars.fill"); Text("探索") }
                            }
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(isExploring ? Color.gray : Color.orange)
                            .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(isExploring)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showExplorationResult) {
            // 使用新的 LootResultView，传入动态生成的物品
            QuickLootResultView(lootItems: explorationLoot)
        }
    }
    
    // MARK: - UI 组件保留
    
    private func collisionWarningBanner(message: String, level: WarningLevel) -> some View {
        HStack {
            Image(systemName: level == .violation ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
            Text(message)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(level == .warning ? Color.orange : (level == .caution ? Color.yellow : Color.red))
        .foregroundColor(level == .caution ? .black : .white).cornerRadius(25).padding(.top, 100)
    }
    
    private var validationResultBanner: some View {
        HStack {
            Image(systemName: locationManager.territoryValidationPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(locationManager.territoryValidationPassed ? "验证成功！准备登记" : (locationManager.territoryValidationError ?? "验证失败"))
        }
        .padding().background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .foregroundColor(.white).cornerRadius(20).padding(.top, 50)
    }
}

// MARK: - 快速探索结果视图

struct QuickLootResultView: View {
    let lootItems: [BackpackItem]
    @Environment(\.dismiss) var dismiss
    private var manager = ExplorationManager.shared

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.08, blue: 0.12).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 25) {
                    // 标题
                    VStack(spacing: 15) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("探索完成！")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        Text("在附近区域发现了物资")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)

                    // 物品列表
                    VStack(alignment: .leading, spacing: 15) {
                        Text("获得物资").font(.headline).foregroundColor(.orange)

                        ForEach(lootItems) { item in
                            HStack {
                                Image(systemName: item.icon).foregroundColor(.blue)
                                Text(item.name).foregroundColor(.white)
                                Spacer()
                                Text("x\(item.quantity)").bold().foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // 放入背包按钮
                    Button(action: {
                        let count = manager.addItems(items: lootItems)
                        print("✅ 探索物品已入包：\(count) 件")
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("放入背包")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                    }
                    .padding(30)
                }
            }
        }
    }
}
