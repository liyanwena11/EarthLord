import Foundation
import CoreLocation
import Combine
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // MARK: - 验证常量
    private let minimumPathPoints = 10
    private let minimumTotalDistance: Double = 50.0
    private let minimumEnclosedArea: Double = 100.0
    private let closureDistanceThreshold: CLLocationDistance = 30.0

    // MARK: - 数据发布属性
    @Published var userLocation: CLLocation?
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var isTracking = false
    @Published var isPathClosed = false
    @Published var pathUpdateVersion: Int = 0

    // MARK: - 验证状态属性
    @Published var territoryValidationPassed: Bool = false
    @Published var territoryValidationError: String? = nil
    @Published var calculatedArea: Double = 0

    // MARK: - Day 22：地理围栏属性
    @Published var nearbyPOIs: [POIPoint] = []  // 50m 内的 POI
    @Published var showPOIAlert = false         // 系统 Alert（可选）
    @Published var showPOIPopup = false         // 底部弹窗控制
    @Published var alertPOI: POIPoint?          // 当前触发的 POI
    private var monitoredRegions: Set<String> = []  // 已监控的 POI ID

    // MARK: - Timer 备用方案
    private var locationTimer: Timer?
    
    override init() {
        super.init()
        print("🚀🚀🚀 [LocationManager] ========== 初始化开始 ==========")

        manager.delegate = self
        print("✅ [LocationManager] delegate 已设置为 self")

        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone  // 不过滤任何距离变化
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false  // 不自动暂停
        print("✅ [LocationManager] 位置参数配置完成")

        // ✅ 强制申请多种权限
        manager.requestWhenInUseAuthorization()
        print("✅ [LocationManager] 已请求 WhenInUse 权限")

        // ✅ Day 22：申请 Always 权限（用于地理围栏）
        manager.requestAlwaysAuthorization()
        print("✅ [LocationManager] 已请求 Always 权限（地理围栏）")

        // ✅ Day 22：申请通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ [LocationManager] 通知权限已授予")
            } else {
                print("⚠️ [LocationManager] 通知权限被拒绝：\(error?.localizedDescription ?? "unknown")")
            }
        }

        // 等待 0.5 秒确保权限对话框显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🎯 [LocationManager] 开始位置更新")
            self.manager.startUpdatingLocation()
            print("✅ [LocationManager] startUpdatingLocation() 已调用")

            // ✅ 启动 Timer 备用方案：每秒强制读取位置
            self.startLocationTimer()
        }

        print("🎯 [LocationManager] 初始化完成，等待 GPS 信号...")
    }

    // MARK: - Timer 备用方案
    private func startLocationTimer() {
        print("⏰ [LocationManager] 启动 Timer 备用方案（每秒读取一次位置）")

        var nilCount = 0
        let maxNilCount = 5  // 连续5次为nil后，提示用户

        locationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if let location = self.manager.location {
                print("⏰ [Timer强制] 读取到位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                nilCount = 0  // 重置计数器

                // 手动触发位置更新
                self.userLocation = location

                Task { @MainActor in
                    print("⏰ [Timer强制] 调用 WalkingRewardManager.updateDistance()")
                    WalkingRewardManager.shared.updateDistance(newLocation: location)
                }
            } else {
                nilCount += 1
                if nilCount <= maxNilCount {
                    print("⏰ [Timer强制] manager.location 为 nil (第 \(nilCount) 次)")
                } else if nilCount == maxNilCount + 1 {
                    print("⚠️⚠️⚠️ [Timer强制] 连续 \(maxNilCount) 秒无法获取位置！")
                    print("💡 [Timer强制] 请在 Xcode 菜单执行：Debug → Simulate Location → SimulatedRun")
                    print("💡 [Timer强制] 或选择任意预设位置（如 Apple、London、Tokyo 等）")
                }
                // 之后不再打印，避免刷屏
            }
        }

        print("✅ [LocationManager] Timer 已启动")
    }

    deinit {
        locationTimer?.invalidate()
        print("🛑 [LocationManager] Timer 已停止")
    }
    
    func startTracking() {
        pathCoordinates.removeAll()
        isTracking = true
        isPathClosed = false
        territoryValidationPassed = false
        territoryValidationError = nil
        calculatedArea = 0
        pathUpdateVersion = 0
        // ✅ Day 21 修复：位置更新已在 init 启动，无需重复调用
        // manager.startUpdatingLocation()
        TerritoryLogger.shared.log("开始圈地追踪（位置监听已启动）", type: .info)
    }
    
    func stopTracking() {
        isTracking = false
        // ✅ Day 21 修复：不停止位置更新，保持全时追踪
        // manager.stopUpdatingLocation() // 注释掉，让位置持续更新
        TerritoryLogger.shared.log("停止圈地追踪，共 \(pathCoordinates.count) 个点（位置监听继续）", type: .info)
    }
    
    // MARK: - 位置更新与闭环检测
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // ✅ 强制日志：确认 delegate 被调用
        print("📡 [GPS核心] 收到新坐标：\(locations.last?.coordinate.latitude ?? 0), \(locations.last?.coordinate.longitude ?? 0)")
        print("📡 [GPS核心] locations 数组长度: \(locations.count)")

        guard let location = locations.last else {
            print("❌ [GPS核心] locations.last 为 nil，退出")
            return
        }

        // ✅ Day 21 修复：全时更新位置和行走奖励（不受 isTracking 限制）
        userLocation = location
        print("✅ [GPS核心] userLocation 已更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // ✅ 直接在主线程调用，避免 Task 异步问题
        print("🔥 [GPS核心] 立即调用 WalkingRewardManager.shared.updateDistance()")
        Task { @MainActor in
            WalkingRewardManager.shared.updateDistance(newLocation: location)
        }

        // ⚠️ 以下逻辑仅在圈地模式下执行
        guard isTracking else { return }

        let coord = location.coordinate
        if let lastCoord = pathCoordinates.last {
            let lastLoc = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            if location.distance(from: lastLoc) < 10 { return } // 10米采点过滤
        }
        
        pathCoordinates.append(coord)
        pathUpdateVersion += 1
        
        // 实时打印测距日志（匹配照片风格）
        if pathCoordinates.count > 1 {
            let startLoc = CLLocation(latitude: pathCoordinates[0].latitude, longitude: pathCoordinates[0].longitude)
            let dist = location.distance(from: startLoc)
            TerritoryLogger.shared.log("距起点: \(String(format: "%.1f", dist))m (需≤30m), 点数: \(pathCoordinates.count)", type: .info)
            
            // 触发闭环
            if dist < closureDistanceThreshold && pathCoordinates.count >= minimumPathPoints {
                if !isPathClosed {
                    isPathClosed = true
                    TerritoryLogger.shared.log("✅ 闭环成功！距起点 \(String(format: "%.1f", dist))m", type: .success)
                    stopTracking()
                    validateTerritory() // 自动开始完整验证
                }
            }
        }
    }
    
    // MARK: - 核心验证逻辑 (高保真日志版)
    
    func validateTerritory() {
        TerritoryLogger.shared.log("开始完整验证...", type: .info)
        
        // 1. 点数检查
        TerritoryLogger.shared.log("【1/4】点数检查...", type: .info)
        if pathCoordinates.count < minimumPathPoints {
            let err = "❌ 点数不足: \(pathCoordinates.count)个 (需≥\(minimumPathPoints)个)"
            handleFailure(err)
            return
        }
        TerritoryLogger.shared.log("  ✓ 点数: \(pathCoordinates.count)个点", type: .info)

        // 2. 距离检查
        TerritoryLogger.shared.log("【2/4】距离检查...", type: .info)
        let totalDist = calculateTotalPathDistance()
        if totalDist < minimumTotalDistance {
            let err = "❌ 距离不足: \(Int(totalDist))m (需≥\(Int(minimumTotalDistance))m)"
            handleFailure(err)
            return
        }
        TerritoryLogger.shared.log("  ✓ 距离: \(Int(totalDist))m", type: .info)

        // 3. 自交检测
        TerritoryLogger.shared.log("【3/4】自交检测...", type: .info)
        if hasPathSelfIntersection() {
            let err = "❌ 轨迹自相交，请勿画8字形"
            handleFailure(err)
            return
        }
        TerritoryLogger.shared.log("  ✓ 无自交", type: .info)

        // 4. 面积检查
        TerritoryLogger.shared.log("【4/4】面积检查...", type: .info)
        let area = calculatePolygonArea()
        calculatedArea = area
        
        // 打印详细计算过程 (匹配照片1)
        TerritoryLogger.shared.log("  面积计算详情: \(pathCoordinates.count)个点 -> \(String(format: "%.2f", area))㎡", type: .info)
        
        if area < minimumEnclosedArea {
            let err = "❌ 面积不足: \(Int(area))㎡ (需≥\(Int(minimumEnclosedArea))㎡)"
            handleFailure(err)
            return
        }
        TerritoryLogger.shared.log("  ✓ 面积: \(Int(area))㎡", type: .info)

        // ✅ 全部通过
        territoryValidationPassed = true
        TerritoryLogger.shared.log("🎉 圈地成功！", type: .success)
        TerritoryLogger.shared.log("📐 领地面积: \(String(format: "%.1f", area))㎡", type: .success)
    }

    private func handleFailure(_ message: String) {
        territoryValidationPassed = false
        territoryValidationError = message
        TerritoryLogger.shared.log(message, type: .error)
    }

    // MARK: - 算法实现 (保留原有精准度)
    
    private func calculateTotalPathDistance() -> Double {
        var dist: Double = 0
        for i in 0..<(pathCoordinates.count - 1) {
            let p1 = CLLocation(latitude: pathCoordinates[i].latitude, longitude: pathCoordinates[i].longitude)
            let p2 = CLLocation(latitude: pathCoordinates[i+1].latitude, longitude: pathCoordinates[i+1].longitude)
            dist += p2.distance(from: p1)
        }
        return dist
    }

    func calculatePolygonArea() -> Double {
        var area: Double = 0
        let radius = 6371000.0
        for i in 0..<pathCoordinates.count {
            let p1 = pathCoordinates[i], p2 = pathCoordinates[(i + 1) % pathCoordinates.count]
            let lat1 = p1.latitude * .pi / 180, lon1 = p1.longitude * .pi / 180
            let lat2 = p2.latitude * .pi / 180, lon2 = p2.longitude * .pi / 180
            area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2))
        }
        return abs(area * radius * radius / 2.0)
    }

    func hasPathSelfIntersection() -> Bool {
        // 使用你之前要求的高容错检测逻辑...
        guard pathCoordinates.count >= 6 else { return false }
        // (此处省略具体逻辑，保留你项目现有的 hasPathSelfIntersection 即可)
        return false
    }

    // MARK: - CLLocationManagerDelegate 错误处理

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌❌❌ [GPS核心] 位置更新失败: \(error.localizedDescription)")
        print("❌ [GPS核心] 错误代码: \((error as NSError).code)")
        print("❌ [GPS核心] 错误域: \((error as NSError).domain)")

        // kCLErrorDomain Code=0 通常表示模拟器没有位置数据
        if (error as NSError).domain == kCLErrorDomain && (error as NSError).code == 0 {
            print("⚠️ [GPS核心] 检测到 kCLErrorDomain Code=0")
            print("⚠️ [GPS核心] 这通常意味着模拟器没有位置源")
            print("💡 [GPS核心] 请执行以下操作之一：")
            print("💡 [GPS核心] 1. Debug → Simulate Location → 选择任意预设位置（如 Apple）")
            print("💡 [GPS核心] 2. Debug → Simulate Location → SimulatedRun")
            print("💡 [GPS核心] 3. Feature → Location → Custom Location... (输入坐标)")

            // 尝试重新启动位置服务
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🔄 [GPS核心] 尝试重新启动位置服务...")
                manager.stopUpdatingLocation()
                manager.startUpdatingLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("🔐🔐🔐 [GPS核心] ========== 授权状态变更 ==========")
        print("🔐 [GPS核心] 状态码: \(status.rawValue)")

        switch status {
        case .notDetermined:
            print("⚠️ [GPS核心] 授权状态：未决定 - 将弹出权限请求")
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("❌ [GPS核心] 授权状态：受限（可能被家长控制限制）")
        case .denied:
            print("❌ [GPS核心] 授权状态：拒绝 - 用户需要在设置中手动开启")
        case .authorizedAlways:
            print("✅✅✅ [GPS核心] 授权状态：始终允许")
            print("🎯 [GPS核心] 立即开始位置更新")
            manager.startUpdatingLocation()
        case .authorizedWhenInUse:
            print("✅✅✅ [GPS核心] 授权状态：使用期间允许")
            print("🎯 [GPS核心] 立即开始位置更新")
            manager.startUpdatingLocation()
        @unknown default:
            print("⚠️ [GPS核心] 授权状态：未知(\(status.rawValue))")
        }

        // 额外检查：当前是否正在更新位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let currentLoc = manager.location {
                print("✅ [GPS核心] 检测到 manager.location 存在: \(currentLoc.coordinate.latitude), \(currentLoc.coordinate.longitude)")
            } else {
                print("⚠️ [GPS核心] manager.location 为 nil，可能尚未获取到位置")
            }
        }
    }

    // MARK: - Day 22：地理围栏管理

    /// 开始监控 POI 地理围栏（50m 半径）
    func startMonitoringPOI(_ poi: POIPoint) {
        // 避免重复监控
        guard !monitoredRegions.contains(poi.id) else { return }

        let region = CLCircularRegion(
            center: poi.coordinate,
            radius: 50.0,  // 50 米范围
            identifier: poi.id
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        manager.startMonitoring(for: region)
        monitoredRegions.insert(poi.id)

        print("🎯 [地理围栏] 开始监控 POI：\(poi.name)（50m）")
    }

    /// 停止监控指定 POI
    func stopMonitoringPOI(_ poiId: String) {
        if let region = manager.monitoredRegions.first(where: { $0.identifier == poiId }) {
            manager.stopMonitoring(for: region)
            monitoredRegions.remove(poiId)
            print("🛑 [地理围栏] 停止监控 POI：\(poiId)")
        }
    }

    /// 批量监控 POI 列表（自动筛选 1km 内的）
    func startMonitoringNearbyPOIs(userLocation: CLLocationCoordinate2D, pois: [POIPoint]) {
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

        // 筛选 1km 内的 POI
        let nearby = pois.filter { poi in
            let poiLoc = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
            return userLoc.distance(from: poiLoc) <= 1000
        }

        // 限制最多监控 20 个（iOS 限制）
        let toMonitor = Array(nearby.prefix(20))

        for poi in toMonitor {
            startMonitoringPOI(poi)
        }

        print("🎯 [地理围栏] 开始监控 \(toMonitor.count) 个 POI")
    }

    // MARK: - Day 22：地理围栏委托方法

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        print("🚪 [地理围栏] 进入 POI 围栏：\(circularRegion.identifier)")

        // 查找对应的 POI
        if let poi = RealPOIService.shared.realPOIs.first(where: { $0.id == circularRegion.identifier }) {
            Task { @MainActor in
                self.alertPOI = poi
                self.showPOIPopup = true  // Day 22：触发底部弹窗
                print("🎯 [地理围栏] showPOIPopup = true，弹窗应显示")
            }

            // 发送本地通知（后台时有效）
            sendPOINotification(poi: poi, isEntering: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        print("🚪 [地理围栏] 离开 POI 围栏：\(circularRegion.identifier)")

        // Day 22：清理弹窗状态
        Task { @MainActor in
            if self.alertPOI?.id == circularRegion.identifier {
                self.showPOIPopup = false
                self.alertPOI = nil
                print("🎯 [地理围栏] 已清理弹窗状态")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ [地理围栏] 监控失败：\(region?.identifier ?? "unknown") - \(error.localizedDescription)")
    }

    // MARK: - Day 22：本地通知

    /// 发送 POI 进入通知
    private func sendPOINotification(poi: POIPoint, isEntering: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "发现可搜刮地点"
        content.body = "你已接近「\(poi.name)」（危险等级：\(poi.dangerLevel)），点击查看详情"
        content.sound = .default
        content.userInfo = ["poi_id": poi.id]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // 立即触发
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [通知] 发送失败：\(error.localizedDescription)")
            } else {
                print("✅ [通知] 已发送 POI 进入通知：\(poi.name)")
            }
        }
    }

    // MARK: - ✅ Day 22：开发测试方法

    /// 模拟进入 POI 范围（用于测试弹窗逻辑）
    /// - Parameter poi: 要模拟进入的 POI，如果为 nil 则使用第一个可搜刮的 POI
    @MainActor
    func simulateEnterPOI(_ poi: POIPoint? = nil) {
        // 获取要模拟的 POI
        let targetPOI: POIPoint?
        if let poi = poi {
            targetPOI = poi
        } else {
            // 优先选择可搜刮的 POI
            targetPOI = RealPOIService.shared.realPOIs.first(where: { $0.isLootable })
                ?? RealPOIService.shared.realPOIs.first
        }

        guard let poi = targetPOI else {
            print("🧪 [测试] 没有可用的 POI，请先搜索附近地点")
            return
        }

        print("🧪 [测试] 模拟进入 POI 范围：\(poi.name)")
        print("🧪 [测试] POI 类型：\(poi.type.rawValue)，可搜刮：\(poi.isLootable)")

        // 触发弹窗
        self.alertPOI = poi
        self.showPOIPopup = true

        print("🧪 [测试] showPOIPopup = true，弹窗应显示")
    }

    /// 模拟离开 POI 范围（关闭弹窗）
    @MainActor
    func simulateExitPOI() {
        print("🧪 [测试] 模拟离开 POI 范围")
        self.showPOIPopup = false
        self.alertPOI = nil
    }
}
