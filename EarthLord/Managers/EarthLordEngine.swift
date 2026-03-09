import SwiftUI
import CoreLocation
import UIKit
import Supabase

@MainActor
class EarthLordEngine: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = EarthLordEngine()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var survivorTimer: Timer?
    private var respawnTimer: Timer?

    // MARK: - 基础状态
    @Published var userLocation: CLLocation?
    @Published var nearbyPOIs: [POIModel] = []
    @Published var claimedTerritories: [TerritoryModel] = []
    @Published var nearbyPlayerCount: Int = 0
    @Published var activePOI: POIModel?
    @Published var showProximityAlert: Bool = false
    @Published var isExploring: Bool = false
    @Published var exploringStatusText: String = ""

    // ✅ 新增：速度和用时状态
    @Published var currentSpeed: Double = 0  // 当前速度 m/min
    @Published var trackingDuration: TimeInterval = 0  // 圈地用时（秒）
    private var trackingStartTime: Date?  // 圈地开始时间
    private var lastSpeedUpdateTime: Date?  // 上次速度更新时间

    // MARK: - 采样圈地状态
    @Published var isTracking: Bool = false              // 是否正在圈地
    @Published var pathPoints: [CLLocation] = []         // 采样轨迹点
    @Published var trackingDistance: Double = 0           // 已行走距离（米）
    @Published var estimatedArea: Double = 0             // 预估面积（㎡）
    @Published var trackingStatusText: String = ""       // 顶部状态文字

    /// 动态采样点需求：负重 > 80kg 时从 5 增加到 8
    var requiredSamplingPoints: Int {
        let weight = ExplorationManager.shared.totalWeight
        if weight > 80 {
            return 8
        }
        return GameConfig.SAMPLING_MIN_POINTS
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        LogDebug("🚀 [Engine] EarthLordEngine 初始化完成")
        LogDebug("📍 [GPS] 定位服务已启动")

        // ✅ 新增：用时更新定时器（每秒更新）
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateTrackingDuration() }
        }

        survivorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateSurvivorCount() }
        }
        respawnTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkRespawns() }
        }
    }

    deinit {
        survivorTimer?.invalidate()
        respawnTimer?.invalidate()
    }

    // MARK: - 幸存者扫描

    @MainActor
    private func updateSurvivorCount() {
        self.isExploring = true
        self.exploringStatusText = "正在扫描周边信号..."
        self.nearbyPlayerCount = Int.random(in: 1...30)
        LogDebug("📡 [探索] 雷达扫描中... 检测到 \(nearbyPlayerCount) 名幸存者")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isExploring = false
            self?.exploringStatusText = ""
        }
    }

    // MARK: - POI 刷新

    @MainActor
    private func checkRespawns() {
        var refreshed = 0
        for index in nearbyPOIs.indices {
            if nearbyPOIs[index].isScavenged && nearbyPOIs[index].canScavengeAgain {
                nearbyPOIs[index].isScavenged = false
                nearbyPOIs[index].lastScavengedAt = nil
                refreshed += 1
            }
        }
        if refreshed > 0 {
            LogDebug("🔄 [刷新] \(refreshed) 个 POI 已刷新")
        }
    }

    // MARK: - ========== 采样行走圈地 ==========

    /// 开始圈地：清空旧路径，进入圈地模式
    @MainActor
    func startTracking() {
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0
        isTracking = true
        trackingStatusText = "开始圈地，请行走创建领地边界..."

        // ✅ 新增：记录开始时间和初始化速度
        trackingStartTime = Date()
        trackingDuration = 0
        currentSpeed = 0
        lastSpeedUpdateTime = Date()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        LogDebug("🚩 [圈地] ========== 开始圈地 ==========")
        LogDebug("🎯 [圈地] 采样点需求: \(requiredSamplingPoints) 个点 (当前负重: \(String(format: "%.1f", ExplorationManager.shared.totalWeight))kg)")
        LogDebug("📍 [圈地] 距离过滤: ≥ \(GameConfig.SAMPLING_MIN_DISTANCE)m")
        LogWarning("⚠️ [圈地] GPS 精度过滤: ≤ \(Int(GameConfig.SAMPLING_MAX_ACCURACY))m")
        // 立即记录第一个点
        if let loc = userLocation,
           loc.horizontalAccuracy > 0,
           loc.horizontalAccuracy <= GameConfig.SAMPLING_MAX_ACCURACY {
            pathPoints.append(loc)
            LogInfo("📍 [圈地] ✅ 起点1已记录: (\(String(format: "%.5f", loc.coordinate.latitude)), \(String(format: "%.5f", loc.coordinate.longitude))), 精度: \(String(format: "%.1f", loc.horizontalAccuracy))m")
        } else {
            LogWarning("⚠️ [圈地] 起点未记录（当前位置缺失或精度不足），等待下一次高精度定位")
        }
    }

    /// 停止圈地（取消）
    @MainActor
    func stopTracking() {
        let previousPointCount = pathPoints.count
        LogDebug("🛑 [圈地] stopTracking() 被调用")
        LogDebug("   - 当前路径点数: \(previousPointCount)")
        LogDebug("   - 追踪状态: \(isTracking)")

        isTracking = false
        trackingStatusText = ""
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0

        // ✅ 新增：重置速度和用时
        currentSpeed = 0
        trackingDuration = 0
        trackingStartTime = nil
        lastSpeedUpdateTime = nil

        LogDebug("🛑 [圈地] 已取消圈地，清除了 \(previousPointCount) 个路径点")
    }

    /// GPS 回调中调用：圈地逻辑（移除自动完成）
    @MainActor
    private func handleTrackingSample(_ location: CLLocation) {
        guard isTracking else { return }

        LogDebug("📍 [GPS回调] 收到位置更新，精度: \(String(format: "%.1f", location.horizontalAccuracy))m")
        // 时间过滤：丢弃明显过期的缓存坐标
        let sampleAge = abs(location.timestamp.timeIntervalSinceNow)
        if sampleAge > 3 {
            LogWarning("⚠️ [圈地] 坐标时间戳过旧(\(String(format: "%.1f", sampleAge))s)，跳过")
            return
        }

        // 精度过滤
        if location.horizontalAccuracy <= 0 || location.horizontalAccuracy > GameConfig.SAMPLING_MAX_ACCURACY {
            LogWarning("⚠️ [圈地] 精度不足 \(String(format: "%.0f", location.horizontalAccuracy))m，跳过（要求 ≤ \(Int(GameConfig.SAMPLING_MAX_ACCURACY))m）")
            return
        }

        // 距离过滤：距上一个点 ≥ 10m 才记录
        if let lastPoint = pathPoints.last {
            let dist = location.distance(from: lastPoint)
            LogDebug("📏 [圈地] 距上一个点: \(String(format: "%.1f", dist))m (需要 ≥ \(GameConfig.SAMPLING_MIN_DISTANCE)m)")
            if dist < GameConfig.SAMPLING_MIN_DISTANCE {
                return
            }

            // 跳点过滤：单步过远视为异常
            if dist > GameConfig.SAMPLING_MAX_STEP_DISTANCE {
                LogWarning("⚠️ [圈地] 跳点 \(String(format: "%.0f", dist))m，丢弃（阈值 \(Int(GameConfig.SAMPLING_MAX_STEP_DISTANCE))m）")
                return
            }

            // 速度��滤：计算移动速度
            let time = location.timestamp.timeIntervalSince(lastPoint.timestamp)
            guard time > 0 else {
                LogWarning("⚠️ [圈地] 时间戳倒退，忽略该点")
                return
            }
            let speed = (dist / time) * 3.6 // 转换为 km/h

            // ✅ 新增：计算并更新实时速度（m/min）
            if time > 0 && time <= 10 {
                let speedMPerMin = (dist / time) * 60  // m/min
                currentSpeed = speedMPerMin
                lastSpeedUpdateTime = Date()
                LogDebug("📊 [速度] 实时速度: \(Int(speedMPerMin)) m/分 (\(String(format: "%.1f", speed)) km/h)")
            }

            // 长时间无更新，认为停止移动
            if let lastUpdate = lastSpeedUpdateTime {
                let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
                if timeSinceUpdate > 10 {
                    currentSpeed = 0
                }
            }

            if speed > GameConfig.SAMPLING_MAX_SPEED_KMH {
                LogWarning("⚠️ [圈地] 速度异常 \(String(format: "%.1f", speed))km/h，跳过此点（阈值 \(Int(GameConfig.SAMPLING_MAX_SPEED_KMH))km/h）")
                return
            }

            trackingDistance += dist
        }

        // ✅ 新增：自相交检测
        if hasSelfIntersection() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            LogWarning("⚠️ [圈地] 检测到自相交（画8字形），拒绝此点")
            return  // 不添加这个点
        }

        pathPoints.append(location)
        estimatedArea = calculatePolygonArea(pathPoints)

        let pointCount = pathPoints.count
        let closureDistance = (pathPoints.first != nil && pathPoints.last != nil)
            ? pathPoints.first!.distance(from: pathPoints.last!)
            : 0

        if pointCount < requiredSamplingPoints {
            trackingStatusText = "圈地中 · 采样 \(pointCount)/\(requiredSamplingPoints) · 距离 \(Int(trackingDistance))m · 面积 \(Int(estimatedArea))㎡"
        } else if closureDistance <= GameConfig.TERRITORY_CLOSE_DISTANCE {
            trackingStatusText = "已闭环，点击“完成”确认圈地 · 面积 \(Int(estimatedArea))㎡"
        } else {
            trackingStatusText = "采样达标，请回到起点（剩余 \(Int(closureDistance))m）"
        }

        LogInfo("✅ [圈地] 第\(pointCount)点已记录！移动距离: \(String(format: "%.1f", trackingDistance))m")
        LogDebug("📐 [面积] 当前闭合面积: \(String(format: "%.1f", estimatedArea))㎡")
        if pointCount >= requiredSamplingPoints {
            LogDebug("🧭 [圈地] 采样点达标 \(pointCount)/\(requiredSamplingPoints)，等待用户手动点击完成")
        }
    }

    // ✅ 新增：更新圈地用时（每秒调用）
    @MainActor
    private func updateTrackingDuration() {
        guard isTracking, let startTime = trackingStartTime else { return }
        trackingDuration = Date().timeIntervalSince(startTime)
    }

    /// 验证轨迹是否合理
    @MainActor
    private func validateTrajectory() -> (isValid: Bool, errorMessage: String?) {
        guard pathPoints.count >= requiredSamplingPoints else {
            return (false, "采样点不足，至少需要\(requiredSamplingPoints)个点（当前: \(pathPoints.count)个）")
        }

        // 检查起点终点距离（应该接近，形成闭环）
        let start = pathPoints.first!
        let end = pathPoints.last!
        let closureDistance = start.distance(from: end)

        if closureDistance > GameConfig.TERRITORY_CLOSE_DISTANCE {
            LogWarning("⚠️ [圈地验证] 轨迹未闭合，起点终点距离: \(closureDistance)m")
            return (false, "轨迹未闭合，起点终点距离 \(Int(closureDistance))m，请回到起点 \(Int(GameConfig.TERRITORY_CLOSE_DISTANCE))m 内")
        }

        // 检查面积合理性
        let area = calculatePolygonArea(pathPoints)
        if area < GameConfig.TERRITORY_MIN_AREA {
            LogWarning("⚠️ [圈地验证] 面积过小: \(area)㎡")
            return (false, "面积过小 \(Int(area))㎡，最小需要\(Int(GameConfig.TERRITORY_MIN_AREA))㎡")
        }

        if area > GameConfig.TERRITORY_MAX_AREA {
            LogWarning("⚠️ [圈地验证] 面积异常过大: \(area)㎡")
            return (false, "面积异常过大 \(Int(area))㎡，可能存在GPS漂移")
        }

        // 防止“直线误圈”：必须形成有厚度且非极端狭长的闭合面
        let span = calculatePathSpan(pathPoints)
        let minSpan = min(span.width, span.height)
        if minSpan < GameConfig.TERRITORY_MIN_SPAN {
            LogWarning("⚠️ [圈地验证] 轨迹过窄，疑似直线/噪声：短边 \(String(format: "%.1f", minSpan))m")
            return (false, "轨迹过于狭长，疑似未形成有效闭环，请按区域边界行走")
        }

        let compactness = area / max(trackingDistance * trackingDistance, 1)
        if compactness < 0.01 {
            LogWarning("⚠️ [圈地验证] 面积密度过低，疑似直线误圈：compactness=\(String(format: "%.4f", compactness))")
            return (false, "轨迹过于接近直线，请围绕区域行走形成闭环")
        }

        // 检查轨迹自相交
        if hasSelfIntersection() {
            LogWarning("⚠️ [圈地验证] 轨迹存在自相交")
            return (false, "轨迹存在自相交，请重新规划路径")
        }

        LogInfo("✅ [圈地验证] 验证通过 - 采样点: \(pathPoints.count), 面积: \(Int(area))㎡, 闭合距离: \(Int(closureDistance))m")
        return (true, nil)
    }

    /// 检查轨迹是否自相交
    private func hasSelfIntersection() -> Bool {
        guard pathPoints.count >= 4 else { return false }

        // 简化检查：检查任意两条边（不相邻）是否相交
        let coords = pathPoints.map { $0.coordinate }

        // 安全检查：确保有足够的点进行相交检测
        guard coords.count >= 4 else { return false }

        for i in 0..<(coords.count - 1) {
            // 安全检查：确保内层循环范围有效
            let startJ = i + 2
            guard startJ < coords.count - 1 else { continue }

            for j in startJ..<(coords.count - 1) {
                // 跳过连接到起点的边（最后一个点和第一个点连接是正常的闭合）
                if j == coords.count - 2 && i == 0 {
                    continue
                }

                if doLinesIntersect(
                    coords[i], coords[i + 1],
                    coords[j], coords[j + 1]
                ) {
                    return true
                }
            }
        }
        return false
    }

    /// 判断两条线段是否相交
    private func doLinesIntersect(_ p1: CLLocationCoordinate2D, _ p2: CLLocationCoordinate2D,
                                  _ p3: CLLocationCoordinate2D, _ p4: CLLocationCoordinate2D) -> Bool {
        // 使用向量叉积判断线段相交
        func crossProduct(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, _ c: CLLocationCoordinate2D) -> Double {
            return (b.longitude - a.longitude) * (c.latitude - a.latitude) -
                   (b.latitude - a.latitude) * (c.longitude - a.longitude)
        }

        let cp1 = crossProduct(p3, p4, p1)
        let cp2 = crossProduct(p3, p4, p2)
        let cp3 = crossProduct(p1, p2, p3)
        let cp4 = crossProduct(p1, p2, p4)

        // 检查是否跨立
        if ((cp1 > 0 && cp2 < 0) || (cp1 < 0 && cp2 > 0)) &&
           ((cp3 > 0 && cp4 < 0) || (cp3 < 0 && cp4 > 0)) {
            return true
        }

        // 检查端点重合
        if cp1 == 0 && isPointOnLine(p1, p3, p4) { return true }
        if cp2 == 0 && isPointOnLine(p2, p3, p4) { return true }
        if cp3 == 0 && isPointOnLine(p3, p1, p2) { return true }
        if cp4 == 0 && isPointOnLine(p4, p1, p2) { return true }

        return false
    }

    /// 判断点是否在线段上
    private func isPointOnLine(_ p: CLLocationCoordinate2D, _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        let cross = (p.longitude - a.longitude) * (b.latitude - a.latitude) -
                    (p.latitude - a.latitude) * (b.longitude - a.longitude)
        if abs(cross) > 1e-10 { return false }

        let dot = (p.longitude - a.longitude) * (b.longitude - a.longitude) +
                  (p.latitude - a.latitude) * (b.latitude - a.latitude)
        if dot < 0 { return false }

        let squaredLength = (b.longitude - a.longitude) * (b.longitude - a.longitude) +
                            (b.latitude - a.latitude) * (b.latitude - a.latitude)
        return dot <= squaredLength
    }

    /// 完成圈地：生成领地
    @MainActor
    private func finishTracking() {
        guard pathPoints.count >= requiredSamplingPoints else { return }

        // 验证轨迹
        let validation = validateTrajectory()
        guard validation.isValid else {
            LogError("❌ [圈地] 验证失败: \(validation.errorMessage ?? "未知错误")")
            trackingStatusText = "⚠️ \(validation.errorMessage ?? "验证失败")"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // 不自动完成，让用户继续采样或手动取消
            return
        }

        let area = calculatePolygonArea(pathPoints)

        // 计算中心点
        let centerLat = pathPoints.map { $0.coordinate.latitude }.reduce(0, +) / Double(pathPoints.count)
        let centerLon = pathPoints.map { $0.coordinate.longitude }.reduce(0, +) / Double(pathPoints.count)

        let newTerritory = TerritoryModel(
            id: UUID(),
            lat: centerLat,
            lon: centerLon,
            claimedAt: Date(),
            name: "领地 #\(claimedTerritories.count + 1)",
            area: area,
            pointCount: pathPoints.count,
            pathLatitudes: pathPoints.map { $0.coordinate.latitude },
            pathLongitudes: pathPoints.map { $0.coordinate.longitude }
        )

        // 重度震动反馈
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        LogInfo("🚩 [圈地] ✅ 领地确认！面积: \(String(format: "%.1f", area))㎡，采样点: \(pathPoints.count)")
        // 地理逆编码获取街道名
        let centerLocation = CLLocation(latitude: centerLat, longitude: centerLon)
        let territoryId = newTerritory.id // 捕获ID而不是整个对象
        geocoder.reverseGeocodeLocation(centerLocation) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                if let placemark = placemarks?.first {
                    let street = placemark.thoroughfare ?? placemark.name ?? placemark.subLocality ?? ""
                    let district = placemark.subLocality ?? placemark.locality ?? ""
                    let geocodedName = street.isEmpty ? district : street
                    if !geocodedName.isEmpty {
                        // 更新领地名称
                        if let index = self?.claimedTerritories.firstIndex(where: { $0.id == territoryId }) {
                            self?.claimedTerritories[index].name = geocodedName
                            LogDebug("🏷️ [圈地] 领地命名为: \(geocodedName)")
                        }
                    }
                }
            }
        }

        self.claimedTerritories.append(newTerritory)

        LogDebug("🗺️ [圈地] 当前本地领地数量: \(claimedTerritories.count)")
        LogDebug("🗺️ [圈地] 新领地 pathCoordinates 数量: \(newTerritory.pathCoordinates.count)")

        // ✅ 触发领地成就检查
        AchievementGameIntegration.shared.checkTerritoryAchievements(territoryCount: claimedTerritories.count)

        // ✅ 触发领地面积成就检查
        AchievementGameIntegration.shared.checkTerritoryAreaAchievements(area: area)

        // ✅ 触发移动距离成就检查
        AchievementGameIntegration.shared.checkTravelDistanceAchievements(distance: trackingDistance)

        // 先快照坐标，避免异步任务读取到被清空后的 pathPoints
        let coordinates = pathPoints.map { $0.coordinate }
        let startTime = Date()

        // 圈地完成后立刻把数据加入领地列表（无需等待网络）
        if let userId = AuthManager.shared.currentUser?.id.uuidString {
            let formatter = ISO8601DateFormatter()
            let territoryPreview = Territory(
                id: newTerritory.id.uuidString,
                userId: userId,
                name: newTerritory.name,
                path: coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] },
                area: area,
                pointCount: coordinates.count,
                isActive: true,
                completedAt: formatter.string(from: Date()),
                startedAt: formatter.string(from: startTime),
                createdAt: formatter.string(from: Date()),
                level: 1,
                experience: 0,
                prosperity: 0
            )
            TerritoryManager.shared.addLocalTerritoryIfNeeded(territoryPreview)
            NotificationCenter.default.post(name: .territoryUpdated, object: nil)
        }

        // 上传领地上传到 Supabase
        Task {
            do {
                // ✅ 获取当前用户会话
                let session = try await supabaseClient.auth.session

                try await TerritoryManager.shared.uploadTerritory(
                    coordinates: coordinates,
                    area: area,
                    startTime: startTime
                )
                LogInfo("🚩 [圈地] 领地上传成功！")
                // ✅ 立即刷新地图上的领土显示
                await MainActor.run {
                    NotificationCenter.default.post(name: .territoryUpdated, object: nil)
                }

                // ✅ 添加到Supabase领土列表以便立即显示
                await MainActor.run {
                    // 创建一个新的Territory对象用于立即显示
                    let formatter = ISO8601DateFormatter()
                    let territoryToAdd = Territory(
                        id: newTerritory.id.uuidString,
                        userId: session.user.id.uuidString,
                        name: newTerritory.name,
                        path: coordinates.map { ["lat": $0.latitude, "lon": $0.longitude] },
                        area: area,
                        pointCount: coordinates.count,
                        isActive: true,
                        completedAt: formatter.string(from: Date()),
                        startedAt: formatter.string(from: startTime),
                        createdAt: formatter.string(from: Date()),
                        level: 1,
                        experience: 0,
                        prosperity: 0
                    )
                    // 通知地图添加新领土
                    NotificationCenter.default.post(name: .territoryAdded, object: territoryToAdd)
                }
            } catch {
                LogError("🚩 [圈地] 领地上传失败: \(error.localizedDescription)")
            }
        }

        // 重置状态
        isTracking = false
        trackingStatusText = "圈地完成！面积 \(Int(area))㎡"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.trackingStatusText = ""
        }
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0
    }

    /// 强制完成圈地（调试用 / 手动闭合）
    @MainActor
    func forceFinishTracking() {
        guard isTracking else {
            LogError("❌ [圈地] 当前未在圈地状态，无法完成")
            return
        }

        guard pathPoints.count >= requiredSamplingPoints else {
            LogError("❌ [圈地] 采样点不足 \(requiredSamplingPoints) 个（当前: \(pathPoints.count) 个），无法完成")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        LogInfo("🧪 [圈地] ✅ 强制完成圈地！当前采样点: \(pathPoints.count) 个")
        finishTracking()
    }

    // MARK: - 多边形面积计算（Shoelace 公式 + 经纬度→米换算）

    private func calculatePolygonArea(_ points: [CLLocation]) -> Double {
        guard points.count >= 3 else { return 0 }

        // 以第一个点为原点，将经纬度转为平面米坐标
        let origin = points[0].coordinate
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(origin.latitude * .pi / 180)

        let xyPoints = points.map { p -> (x: Double, y: Double) in
            let x = (p.coordinate.longitude - origin.longitude) * metersPerDegreeLon
            let y = (p.coordinate.latitude - origin.latitude) * metersPerDegreeLat
            return (x, y)
        }

        // Shoelace 公式
        var area: Double = 0
        let n = xyPoints.count
        for i in 0..<n {
            let j = (i + 1) % n
            area += xyPoints[i].x * xyPoints[j].y
            area -= xyPoints[j].x * xyPoints[i].y
        }
        return abs(area) / 2.0
    }

    /// 轨迹包围盒（米）用于判断是否为“直线误圈”
    private func calculatePathSpan(_ points: [CLLocation]) -> (width: Double, height: Double) {
        guard points.count >= 2 else { return (0, 0) }

        let origin = points[0].coordinate
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(origin.latitude * .pi / 180)

        var minX = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        for point in points {
            let x = (point.coordinate.longitude - origin.longitude) * metersPerDegreeLon
            let y = (point.coordinate.latitude - origin.latitude) * metersPerDegreeLat
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }

        return (abs(maxX - minX), abs(maxY - minY))
    }

    // MARK: - GPS 位置更新

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        LogDebug("🛰��� [GPS] 位置更新: lat=\(String(format: "%.5f", location.coordinate.latitude)), lon=\(String(format: "%.5f", location.coordinate.longitude)), 精度=\(String(format: "%.1f", location.horizontalAccuracy))m")
        Task { @MainActor in
            self.userLocation = location
            self.checkProximity(location)
            self.handleTrackingSample(location)
        }
    }

    // MARK: - POI 接近检测

    @MainActor
    private func checkProximity(_ current: CLLocation) {
        let found = nearbyPOIs.first {
            !$0.isScavenged && current.distance(from: $0.location) <= GameConfig.POI_TRIGGER_RADIUS
        }
        if let target = found {
            if activePOI?.id != target.id {
                self.activePOI = target
                self.showProximityAlert = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                LogDebug("🎯 [搜刮] 进入 POI 范围：\(target.name)（\(target.rarity.rawValue)）")

                // ✅ 触发POI发现成就检查
                AchievementGameIntegration.shared.checkPOIDiscoveryAchievements(
                    discoveredCount: nearbyPOIs.count
                )
            }
        } else {
            if showProximityAlert {
                self.showProximityAlert = false
                self.activePOI = nil
            }
        }
    }

    // MARK: - 搜刮

    @MainActor
    func scavenge() {
        guard let poi = activePOI else { return }
        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
            LogDebug("📦 [搜刮] 已搜刮 POI：\(poi.name)")
        }
        self.showProximityAlert = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// 搜刮状态
    @Published var isScavenging: Bool = false
    @Published var lastScavengeResult: [BackpackItem] = []

    /// 搜刮并生成掉落物品（同步版本，用预设掉落表）
    @MainActor
    func scavengeWithLoot() -> [BackpackItem] {
        guard let poi = activePOI else { return [] }

        let backpack = ExplorationManager.shared
        if backpack.totalWeight >= backpack.maxCapacity {
            LogWarning("⚠️ [搜刮] 背包已满，无法搜刮")
            return []
        }

        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
        }
        self.showProximityAlert = false

        let items = generateLootByRarity(poi.rarity)
        backpack.addItems(items: items)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        LogDebug("📦 [搜刮] 在「\(poi.name)」(\(poi.rarity.rawValue)) 获得：\(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")

        // ✅ 触发搜刮成就检查
        let scavengedCount = nearbyPOIs.filter { $0.isScavenged }.count
        AchievementGameIntegration.shared.checkScavengeAchievements(
            scavengedCount: scavengedCount,
            rarity: poi.rarity.rawValue
        )

        // ✅ 触发资源收集成就检查
        for item in items {
            AchievementGameIntegration.shared.checkResourceCollectionAchievements(
                itemType: item.category.rawValue,
                count: item.quantity
            )
        }

        // ✅ 触发背包容量成就检查
        AchievementGameIntegration.shared.checkBackpackCapacityAchievements(
            capacity: Int(backpack.totalWeight)
        )

        return items
    }

    /// AI 搜刮：调用 Edge Function 生成独特物品（异步）
    @MainActor
    func scavengeWithAI() async -> [BackpackItem] {
        guard let poi = activePOI else { return [] }

        let backpack = ExplorationManager.shared
        if backpack.totalWeight >= backpack.maxCapacity {
            LogWarning("⚠️ [搜刮] 背包已满，无法搜刮")
            return []
        }

        isScavenging = true

        // 标记 POI 已搜刮
        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
        }
        self.showProximityAlert = false

        // 调用 AI 生成（内含静默降级）
        let items = await AIItemGenerator.shared.generateItems(for: poi)

        // 存入背包
        backpack.addItems(items: items)

        // 同步到 Supabase user_inventory
        Task {
            await syncScavengeToSupabase(poi: poi, items: items)
        }

        isScavenging = false
        lastScavengeResult = items
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        LogDebug("🤖 [AI搜刮] 在「\(poi.name)」获得：\(items.map { $0.name }.joined(separator: ", "))")
        return items
    }

    /// 同步搜刮结果到 Supabase
    @MainActor
    private func syncScavengeToSupabase(poi: POIModel, items: [BackpackItem]) async {
        do {
            let session = try await supabaseClient.auth.session
            let userId = session.user.id.uuidString

            struct InventoryRecord: Encodable {
                let user_id: String
                let item_name: String
                let item_rarity: String
                let weight: Double
                let backstory: String?
                let is_ai_generated: Bool
                let source_poi: String
                let created_at: String
            }

            let formatter = ISO8601DateFormatter()
            for item in items {
                let record = InventoryRecord(
                    user_id: userId,
                    item_name: item.name,
                    item_rarity: item.itemRarity?.rawValue ?? "普通",
                    weight: item.weight,
                    backstory: item.backstory,
                    is_ai_generated: item.isAIGenerated,
                    source_poi: poi.name,
                    created_at: formatter.string(from: Date())
                )
                try await supabaseClient
                    .from("user_inventory")
                    .insert(record)
                    .execute()
            }
            LogDebug("☁️ [同步] \(items.count) 件物品已同步到 user_inventory")
        } catch {
            LogError("❌ [同步] user_inventory 同步失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 稀有度掉落表

    /// 根据 POI 稀有度生成掉落物品
    private func generateLootByRarity(_ rarity: POIRarity) -> [BackpackItem] {
        // 掉落池：按稀有度决定物品种类和数量
        let lootPool: [(itemId: String, name: String, category: ItemCategory, weight: Double, icon: String)]
        let itemCount: Int
        let maxQuantity: Int

        switch rarity {
        case .common:
            itemCount = Int.random(in: 1...2)
            maxQuantity = 2
            lootPool = [
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
                ("food_002", "压缩饼干", .food, 0.2, "rectangle.compress.vertical"),
                ("material_004", "布料", .material, 0.5, "square.fill"),
            ]
        case .rare:
            itemCount = Int.random(in: 2...3)
            maxQuantity = 3
            lootPool = [
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
            ]
        case .epic:
            itemCount = Int.random(in: 2...3)
            maxQuantity = 4
            lootPool = [
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link"),
                ("material_002", "废金属", .material, 2.0, "cube.fill"),
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
            ]
        case .legendary:
            itemCount = Int.random(in: 3...4)
            maxQuantity = 5
            lootPool = [
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill"),
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
            ]
        }

        let qualities: [ItemQuality] = [.poor, .normal, .good, .excellent]

        var result: [BackpackItem] = []
        var usedIds: Set<String> = []
        let count = min(itemCount, lootPool.count)

        for _ in 0..<count {
            // 随机选一个未用过的物品
            let available = lootPool.filter { !usedIds.contains($0.itemId) }
            guard let template = available.randomElement() else { break }
            usedIds.insert(template.itemId)

            let quantity = Int.random(in: 1...maxQuantity)
            let quality = qualities.randomElement()

            result.append(BackpackItem(
                id: UUID().uuidString,
                itemId: template.itemId,
                name: template.name,
                category: template.category,
                quantity: quantity,
                weight: template.weight,
                quality: quality,
                icon: template.icon
            ))
        }

        return result
    }

    // MARK: - 旧的一键圈地（保留兼容）

    @MainActor
    func claimTerritory() {
        guard let loc = userLocation else { return }
        let newT = TerritoryModel(
            id: UUID(), lat: loc.coordinate.latitude, lon: loc.coordinate.longitude,
            claimedAt: Date(), name: "快速领地", area: 0, pointCount: 1
        )
        self.claimedTerritories.append(newT)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        LogDebug("🚩 [圈地] 快速占领 @ (\(String(format: "%.5f", newT.lat)), \(String(format: "%.5f", newT.lon)))")

        // ✅ 触发领地成就检查
        AchievementGameIntegration.shared.checkTerritoryAchievements(territoryCount: claimedTerritories.count)
    }

    // MARK: - 测试 POI

    #if DEBUG

    @MainActor
    func createTestPOI() {
        guard let loc = userLocation else { return }
        let rarity = POIRarity.allCases.randomElement()!
        let new = POIModel(
            id: UUID(),
            name: "废弃补给点 #\(Int.random(in: 10...99))",
            latitude: loc.coordinate.latitude + Double.random(in: -0.0008...0.0008),
            longitude: loc.coordinate.longitude + Double.random(in: -0.0008...0.0008),
            rarity: rarity
        )
        self.nearbyPOIs.append(new)
        LogDebug("📍 [测试] 生成 POI：\(new.name)（\(rarity.rawValue)）")
    }

    @MainActor
    func createMultipleTestPOIs(count: Int = 5) {
        for _ in 0..<count { createTestPOI() }
        LogDebug("📍 [测试] 批量生成 \(count) 个 POI")
    }

    #endif

    // MARK: - 生产环境 POI 发现

    /// 触发 POI 发现（在生产环境中生成附近的 POI）
    @MainActor
    func triggerPOIDiscovery() async {
        guard let loc = userLocation else {
            LogDebug("📍 [POI] 无法发现 POI：用户位置未知")
            return
        }

        // 检查是否已有足够的 POI
        let nearbyCount = nearbyPOIs.filter { !$0.isScavenged }.count
        if nearbyCount >= 5 {
            LogDebug("📍 [POI] 附近已有足够的 POI（\(nearbyCount) 个）")
            return
        }

        // 生成一个新的 POI
        let rarity = POIRarity.allCases.randomElement() ?? .common
        let newPOI = POIModel(
            id: UUID(),
            name: generatePOIName(for: rarity),
            latitude: loc.coordinate.latitude + Double.random(in: -0.001...0.001),
            longitude: loc.coordinate.longitude + Double.random(in: -0.001...0.001),
            rarity: rarity
        )

        self.nearbyPOIs.append(newPOI)
        LogDebug("📍 [POI] 发现新资源点：\(newPOI.name)（\(rarity.rawValue)）")

        // 触发 POI 发现成就检查
        AchievementGameIntegration.shared.checkPOIDiscoveryAchievements(
            discoveredCount: nearbyPOIs.count
        )
    }

    /// 生成 POI 名称
    private func generatePOIName(for rarity: POIRarity) -> String {
        let prefixes = ["废弃的", "神秘的", "古老的", "荒废的", "遗失的"]
        let types = ["补给站", "仓库", "营地", "避难所", "物资箱"]

        switch rarity {
        case .common:
            return "\(types.randomElement()!) #\(Int.random(in: 100...999))"
        case .rare:
            return "\(prefixes.randomElement()!)\(types.randomElement()!)"
        case .epic:
            return "精英\(types.randomElement()!)"
        case .legendary:
            return "传说\(types.randomElement()!)"
        }
    }

}
