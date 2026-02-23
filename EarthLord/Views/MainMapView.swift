import SwiftUI
import MapKit
import Combine

struct MainMapView: View {
    @StateObject private var engine = EarthLordEngine.shared
    @StateObject private var explorationManager = ExplorationManager.shared

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var supabaseTerritories: [Territory] = []
    @State private var mapRefreshTrigger = UUID() // ✅ 强制刷新地图

    // 探索状态
    @State private var isExploring = false
    @State private var explorationStartTime: Date?
    @State private var explorationElapsed: TimeInterval = 0
    @State private var explorationDistance: Double = 0
    @State private var explorationTimer: Timer?
    @State private var showExplorationResults = false
    @State private var explorationResultItems: [BackpackItem] = []
    @State private var explorationResult: ExplorationResult?

    var body: some View {
        ZStack {
            // MARK: - 地图主体
            Map(position: $cameraPosition) {
                UserAnnotation()

                // ✅ 添加自定义用户位置箭头图标
                if let userLoc = engine.userLocation {
                    Annotation("", coordinate: userLoc.coordinate) {
                        CustomUserLocationArrow()
                    }
                }

                // 领地标注
                ForEach(engine.claimedTerritories) { territory in
                    Annotation(territory.name, coordinate: territory.location.coordinate) {
                        TerritoryAnnotationView()
                    }
                }

                // 圈地采样轨迹
                if engine.isTracking {
                    ForEach(Array(engine.pathPoints.enumerated()), id: \.offset) { index, point in
                        Annotation("", coordinate: point.coordinate) {
                            TrackingPointView(index: "\(index + 1)")
                        }
                    }
                    if engine.pathPoints.count >= 2 {
                        MapPolyline(coordinates: engine.pathPoints.map { $0.coordinate })
                            .stroke(.blue.opacity(0.6), lineWidth: 3)
                    }
                }

                // 已完成领地多边形（本地内存，圈地完成后立即显示）
                ForEach(Array(engine.claimedTerritories.enumerated()), id: \.element.id) { _, territory in
                    if !territory.pathCoordinates.isEmpty {
                        MapPolygon(coordinates: territory.pathCoordinates)
                            .stroke(Color.green.opacity(0.8), lineWidth: 3)
                            .foregroundStyle(Color.green.opacity(0.25))
                    }
                }

                // 从 Supabase 加载的历史领地多边形
                ForEach(supabaseTerritories) { territory in
                    let coords = territory.toCoordinates()
                    if coords.count >= 3 {
                        MapPolygon(coordinates: coords)
                            .stroke(Color.green.opacity(0.7), lineWidth: 2)
                            .foregroundStyle(Color.green.opacity(0.15))
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls { MapCompass() }
            .id(mapRefreshTrigger) // ✅ 使用 trigger 强制刷新
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.dark)

            // MARK: - 顶部：雷达 + 圈地状态栏
            VStack(spacing: 0) {
                RadarView(count: engine.nearbyPlayerCount, isExploring: isExploring)
                if engine.isTracking || !engine.trackingStatusText.isEmpty {
                    TrackingStatusBar(engine: engine)
                }
                Spacer()
            }

        }
        // 探索中悬浮卡片（overlay 方式，不阻挡地图触摸）
        .overlay(alignment: .bottom) {
            if isExploring {
                ExplorationActiveCard(
                    elapsed: explorationElapsed,
                    distance: explorationDistance,
                    onStop: stopExploration
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // 底部双按钮（overlay 方式）
        .overlay(alignment: .bottom) {
            if !isExploring {
                MapBottomButtons(
                    isTracking: engine.isTracking,
                    onExplore: startExploration,
                    onTerritory: {
                        if engine.isTracking { engine.stopTracking() }
                        else { engine.startTracking() }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .transition(.opacity)
            }
        }
        .task { await loadTerritories() }
        .onReceive(NotificationCenter.default.publisher(for: .territoryUpdated)) { _ in
            Task { await loadTerritories() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .territoryAdded)) { notification in
            // ✅ 立即添加新领土到地图，无需等待服务器刷新
            LogDebug("🗺️ [MainMapView] ===== 收到 territoryAdded 通知 =====")
            if let newTerritory = notification.object as? Territory {
                LogDebug("🗺️ [MainMapView] 新领地信息:")
                LogDebug("  - ID: \(newTerritory.id)")
                LogDebug("  - 名称: \(newTerritory.displayName)")
                LogDebug("  - 坐标点数: \(newTerritory.path.count)")
                LogDebug("  - 面积: \(newTerritory.area)㎡")
                let coords = newTerritory.toCoordinates()
                LogDebug("  - 解析后坐标数: \(coords.count)")
                withAnimation {
                    if !supabaseTerritories.contains(where: { $0.id == newTerritory.id }) {
                        supabaseTerritories.append(newTerritory)
                        LogInfo("✅ [MainMapView] 领地已添加到地图显示列表")
                        LogDebug("📊 [MainMapView] 当前地图上共有 \(supabaseTerritories.count) 个领地")
                        // ✅ 强制刷新地图
                        mapRefreshTrigger = UUID()
                    } else {
                        LogWarning("⚠️ [MainMapView] 领地已存在，跳过添加")
                    }
                }
            } else {
                LogError("❌ [MainMapView] 无法解析通知对象为 Territory")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExploring)
        .sheet(isPresented: $showExplorationResults) {
            if let result = explorationResult {
                ExplorationStopResultView(
                    result: result,
                    onDismiss: {
                        showExplorationResults = false
                        explorationResult = nil
                        explorationResultItems = []
                    }
                )
            } else {
                // 降级方案：使用旧接口
                ExplorationStopResultView(
                    distance: explorationDistance,
                    duration: explorationElapsed,
                    items: explorationResultItems,
                    onDismiss: {
                        showExplorationResults = false
                        explorationResultItems = []
                    }
                )
            }
        }
    }

    // MARK: - 探索逻辑

    private func startExploration() {
        isExploring = true
        explorationStartTime = Date()
        explorationElapsed = 0
        explorationDistance = 0

        // ✅ 使用 ExplorationManager 开始探索会话
        explorationManager.startExplorationSession()

        explorationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                explorationElapsed += 1
                // 模拟行走距离（真机环境应该使用 GPS 计算）
                explorationDistance += Double.random(in: 0.8 ... 1.5)
                // 更新到管理器
                explorationManager.currentExplorationDistance = explorationDistance
            }
        }
    }

    private func loadTerritories() async {
        LogDebug("🔄 [MainMapView] 开始加载领地数据...")
        do {
            let territories = try await TerritoryManager.shared.loadAllTerritories()
            await MainActor.run {
                supabaseTerritories = territories
                LogInfo("✅ [MainMapView] 领地加载成功，共 \(territories.count) 个")
                for territory in territories {
                    LogDebug("  - \(territory.displayName): \(territory.path.count) 个坐标点")
                }
            }
        } catch {
            LogError("❌ [MainMapView] 领地加载失败: \(error.localizedDescription)")
        }
    }

    private func stopExploration() {
        explorationTimer?.invalidate()
        explorationTimer = nil
        isExploring = false

        // 根据探索时长决定掉落量（至少1件）
        let poiTypes: [POIType] = [.supermarket, .hospital, .gasStation, .factory, .warehouse]
        let randomType = poiTypes.randomElement() ?? .supermarket
        let items = explorationManager.generateLoot(for: randomType)
        explorationResultItems = items

        // ✅ 将物品添加到背包
        explorationManager.addItems(items: items)

        // ✅ 完成探索会话并记录到后端
        Task { @MainActor in
            if let result = await explorationManager.completeExplorationSession(
                itemsFound: items,
                walkDistance: explorationDistance
            ) {
                explorationResult = result
                showExplorationResults = true
            }
        }
    }
}

// MARK: - 底部双按钮组件

struct MapBottomButtons: View {
    let isTracking: Bool
    let onExplore: () -> Void
    let onTerritory: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 开始探索
            Button(action: onExplore) {
                VStack(spacing: 5) {
                    Image(systemName: "binoculars.fill").font(.title2)
                    Text("开始探索").font(.caption.bold())
                }
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(Color(red: 0.12, green: 0.58, blue: 0.32))
                .foregroundColor(.white)
                .cornerRadius(14)
            }

            // 中间分隔符 - 使用更美观的图标
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 40)

            // 开始圈地
            Button(action: onTerritory) {
                VStack(spacing: 5) {
                    Image(systemName: isTracking ? "stop.fill" : "flag.2.crossed.fill").font(.title2)
                    Text(isTracking ? "停止圈地" : "开始圈地").font(.caption.bold())
                }
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(isTracking ? Color.orange : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}

// MARK: - 探索中悬浮卡片

struct ExplorationActiveCard: View {
    let elapsed: TimeInterval
    let distance: Double
    let onStop: () -> Void

    @State private var isPulsing = false
    // 模拟最近资源距离
    @State private var nearestResourceDist: Int = Int.random(in: 200 ... 600)

    var body: some View {
        VStack(spacing: 12) {
            // 顶栏
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 9, height: 9)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear { isPulsing = true }
                    Text("探索中")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                // 停止探索按钮
                Button(action: onStop) {
                    HStack(spacing: 5) {
                        Image(systemName: "stop.fill").font(.caption.bold())
                        Text("停止探索").font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(10)
                }
            }

            Divider().background(Color.white.opacity(0.2))

            // 数据行
            HStack(spacing: 0) {
                ExploreStatCell(icon: "figure.walk", label: "行走距离", value: formatDistance(distance))
                Divider().background(Color.white.opacity(0.2)).frame(height: 36)
                ExploreStatCell(icon: "clock", label: "探索时长", value: formatDuration(elapsed))
                Divider().background(Color.white.opacity(0.2)).frame(height: 36)
                ExploreStatCell(icon: "mappin.and.ellipse", label: "最近资源", value: "\(nearestResourceDist)m")
            }
        }
        .padding(14)
        .background(Color(white: 0.1).opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
    }

    private func formatDistance(_ m: Double) -> String {
        if m >= 1000 { return String(format: "%.1fkm", m / 1000) }
        return "\(Int(m))m"
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ExploreStatCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(.green)
            Text(value).font(.system(.subheadline, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 停止探索结果卡片

struct ExplorationStopResultView: View {
    let result: ExplorationResult
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    // 主初始化器
    init(result: ExplorationResult, onDismiss: @escaping () -> Void) {
        self.result = result
        self.onDismiss = onDismiss
    }

    // 便捷初始化（支持旧接口）
    init(distance: Double, duration: TimeInterval, items: [BackpackItem], onDismiss: @escaping () -> Void) {
        self.result = ExplorationResult(
            walkDistance: distance,
            totalWalkDistance: distance,
            walkRanking: 0,
            exploredArea: 0,
            totalExploredArea: 0,
            areaRanking: 0,
            duration: duration,
            itemsFound: items,
            poisDiscovered: 0,
            experienceGained: 0
        )
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // 标题
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                        .padding(.top, 40)
                    Text("探索结束").font(.title.bold()).foregroundColor(.white)
                    Text("共探索了 \(formatDuration(result.duration))").font(.subheadline).foregroundColor(.gray)
                }
                .padding(.bottom, 24)

                // 统计卡
                HStack(spacing: 12) {
                    SummaryCard(icon: "figure.walk", color: .blue, label: "行走距离", value: formatDistance(result.walkDistance))
                    SummaryCard(icon: "clock.fill", color: .orange, label: "探索时长", value: formatDuration(result.duration))
                    SummaryCard(icon: "shippingbox.fill", color: .green, label: "获得物品", value: "\(result.itemsFound.reduce(0) { $0 + $1.quantity }) 件")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // 物品列表
                VStack(alignment: .leading, spacing: 0) {
                    Text("新增物品").font(.headline).foregroundColor(.white).padding(.horizontal, 20).padding(.bottom, 10)

                    if result.itemsFound.isEmpty {
                        HStack {
                            Spacer()
                            Text("此次探索未发现物资").font(.subheadline).foregroundColor(.gray)
                            Spacer()
                        }.padding(.vertical, 20)
                    } else {
                        ForEach(result.itemsFound) { item in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(itemCategoryColor(item.category).opacity(0.18))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: item.icon)
                                        .foregroundColor(itemCategoryColor(item.category))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.subheadline.bold()).foregroundColor(.white)
                                    Text(item.category.rawValue).font(.caption2).foregroundColor(.gray)
                                }
                                Spacer()
                                Text("+\(item.quantity)").font(.headline.bold()).foregroundColor(.green)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 20)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(14)
                .padding(.horizontal, 16)

                // 探索经验值
                if result.experienceGained > 0 {
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        Text("获得经验: \(result.experienceGained) 点")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .padding(.top, 8)
                }

                // 背包容量
                let backpack = ExplorationManager.shared
                HStack {
                    Image(systemName: "scalemass.fill").foregroundColor(.orange).font(.caption)
                    Text("背包负重：\(String(format: "%.1f", backpack.totalWeight)) / \(Int(backpack.maxCapacity)) kg")
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.top, 14)

                Spacer()

                Button(action: { onDismiss(); dismiss() }) {
                    Text("收下物资")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func itemCategoryColor(_ category: ItemCategory) -> Color {
        switch category {
        case .water: return .cyan
        case .food: return .green
        case .medical: return .red
        case .material: return .brown
        case .tool: return .blue
        }
    }

    private func formatDistance(_ m: Double) -> String {
        if m >= 1000 { return String(format: "%.1fkm", m / 1000) }
        return "\(Int(m))m"
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct SummaryCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.system(.subheadline, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - 保留原有组件（TrackingPointView, TerritoryAnnotationView, TrackingStatusBar, RadarView, LootResultOverlay, ScavengePopup）

struct TrackingPointView: View {
    let index: String
    var body: some View {
        ZStack {
            Circle().fill(Color.green.opacity(0.3)).frame(width: 20, height: 20)
            Circle().fill(Color.green).frame(width: 10, height: 10).shadow(color: .green, radius: 4)
            Text(index).font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundColor(.white).offset(y: -14)
        }
    }
}

struct TerritoryAnnotationView: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.15)).frame(width: 60, height: 60)
            Circle().stroke(Color.blue.opacity(0.6), lineWidth: 2).frame(width: 60, height: 60)
            Image(systemName: "flag.fill").foregroundColor(.blue).font(.caption)
        }
    }
}

struct TrackingStatusBar: View {
    @ObservedObject var engine: EarthLordEngine

    var body: some View {
        HStack(spacing: 12) {
            if engine.isTracking {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                    .opacity(engine.isTracking ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: engine.isTracking)
            }

            VStack(alignment: .leading, spacing: 2) {
                if engine.isTracking {
                    let needed = engine.requiredSamplingPoints
                    let penalty = needed > GameConfig.SAMPLING_MIN_POINTS
                    HStack(spacing: 4) {
                        Text("采样 \(engine.pathPoints.count)/\(needed)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        if penalty {
                            Text("负重").font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.red.opacity(0.3)).foregroundColor(.red).cornerRadius(3)
                        }
                    }
                    HStack(spacing: 8) {
                        Text("距离 \(Int(engine.trackingDistance))m")
                        Text("面积 \(Int(engine.estimatedArea))㎡")
                    }
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(.green)
                } else {
                    Text(engine.trackingStatusText).font(.system(size: 11, weight: .bold)).foregroundColor(.green)
                }
            }

            Spacer()

            if engine.isTracking && engine.pathPoints.count >= 3 {
                Button("完成") { engine.forceFinishTracking() }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.green).foregroundColor(.black).cornerRadius(8)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RadarView: View {
    let count: Int
    let isExploring: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isExploring ? "📡 正在探索周边..." : "SURVIVAL RADAR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isExploring ? .yellow : .gray)
                Text("附近幸存者: \(count) 人").font(.callout).bold().foregroundColor(.white)
            }
            Spacer()
            Circle().fill(isExploring ? Color.yellow : Color.green).frame(width: 10, height: 10)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .padding(.horizontal).padding(.top, 4)
    }
}

// MARK: - 自定义用户位置箭头

struct CustomUserLocationArrow: View {
    @StateObject private var locationManager = LocationManager.shared

    var body: some View {
        ZStack {
            // 脉冲效果圆环
            Circle()
                .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                .frame(width: 50, height: 50)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: pulseOpacity
                )

            // 中心箭头
            Image(systemName: "location.north.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(-180)) // 指向北
                .shadow(color: .orange, radius: 3)

            // 外圈光晕
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                .frame(width: 60, height: 60)
        }
        .onAppear {
            pulseScale = 1.2
            pulseOpacity = 0
        }
    }

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
}

