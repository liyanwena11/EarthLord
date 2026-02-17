import Foundation
import CoreLocation
import Combine
import UserNotifications
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    // MARK: - 验证常量 (保留原有)
    private let minimumPathPoints = 10
    private let minimumTotalDistance: Double = 50.0
    private let minimumEnclosedArea: Double = 100.0
    private let closureDistanceThreshold: CLLocationDistance = 60.0

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

    // MARK: - 圈地引导状态
    @Published var isNearStartPoint: Bool = false
    @Published var distanceToStartPoint: Double = 0

    // MARK: - Day 22 & 23：POI 优化属性
    @Published var nearbyPOIs: [POIPoint] = []
    @Published var showPOIPopup = false
    @Published var alertPOI: POIPoint?
    
    // 💡 优化配置
    private let poiTriggerRadius: Double = 100.0    // 扩大到 100 米触发
    private let poiExitRadius: Double = 150.0       // 离开 150 米后允许再次触发
    private let poiCheckInterval: TimeInterval = 3.0 // 3秒检测一次
    
    private var monitoredRegions: Set<String> = []
    private var lastPOICheckTime: Date?
    private var poiAlreadyTriggered: Set<String> = []

    private var locationTimer: Timer?
    private var hasAutoSearchedPOI = false
    
    override init() {
        super.init()
        manager.delegate = self
        DispatchQueue.main.async { [weak self] in
            self?.setupAfterInit()
        }
    }

    private func setupAfterInit() {
        // 💡 优化 1：提升精度到导航级别，确保蓝点不乱跳
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5 // 每移动 5 米更新一次，平衡电力与精度
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false

        manager.requestWhenInUseAuthorization()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("📢 [LocationManager] 通知权限: \(granted ? "已授予" : "被拒绝")")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.manager.startUpdatingLocation()
            self?.startLocationTimer()
        }
    }

    private func startLocationTimer() {
        locationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.manager.location else { return }
            self.userLocation = location
            
            Task { @MainActor in
                WalkingRewardManager.shared.updateDistance(newLocation: location)
            }
            // Timer 作为保底，也进行距离扫描
            self.checkPOIProximity(location: location)
        }
    }

    // MARK: - 位置更新回调 (高频扫描)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location

        // 💡 优化 2：每当位置变动，立刻主动检测 POI 距离
        checkPOIProximity(location: location)

        if !hasAutoSearchedPOI && location.horizontalAccuracy <= 100 {
            hasAutoSearchedPOI = true
            RealPOIService.shared.searchNearbyRealPOI(userLocation: location.coordinate)
        }

        Task { @MainActor in
            WalkingRewardManager.shared.updateDistance(newLocation: location)
        }

        // --- 圈地逻辑开始 ---
        guard isTracking else { return }
        let coord = location.coordinate
        if location.horizontalAccuracy > 50 { return }

        if let lastCoord = pathCoordinates.last {
            let lastLoc = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let stepDist = location.distance(from: lastLoc)
            if stepDist < 10 { return }
            if stepDist > 100 { return }
        }

        pathCoordinates.append(coord)
        pathUpdateVersion += 1

        if pathCoordinates.count > 1 {
            let startLoc = CLLocation(latitude: pathCoordinates[0].latitude, longitude: pathCoordinates[0].longitude)
            let dist = location.distance(from: startLoc)
            distanceToStartPoint = dist
            
            isNearStartPoint = dist <= 100 && pathCoordinates.count >= minimumPathPoints
            
            if dist < closureDistanceThreshold && pathCoordinates.count >= minimumPathPoints {
                if !isPathClosed {
                    isPathClosed = true
                    isNearStartPoint = false
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    stopTracking()
                    validateTerritory()
                }
            }
        }
    }

    // MARK: - 💡 核心优化：主动 POI 距离探测扫描仪
    private func checkPOIProximity(location: CLLocation) {
        // 节流处理，防止每秒计算多次浪费性能
        let now = Date()
        if let lastCheck = lastPOICheckTime, now.timeIntervalSince(lastCheck) < poiCheckInterval {
            return
        }
        lastPOICheckTime = now

        let allPOIs = RealPOIService.shared.realPOIs
        guard !allPOIs.isEmpty else { return }

        // 如果当前已经弹窗了，就不再寻找新的，直到用户关闭或离开
        if showPOIPopup {
            // 检查是否已经离开当前弹窗的 POI
            if let currentAlertPOI = alertPOI {
                let poiLoc = CLLocation(latitude: currentAlertPOI.coordinate.latitude, longitude: currentAlertPOI.coordinate.longitude)
                let currentDist = location.distance(from: poiLoc)
                if currentDist > poiExitRadius {
                    print("🚪 [POI探测] 玩家已离开 \(currentAlertPOI.name)，关闭弹窗")
                    DispatchQueue.main.async {
                        self.showPOIPopup = false
                        self.alertPOI = nil
                    }
                }
            }
            return
        }

        // 遍历所有 POI，寻找进入 100 米范围内的点
        for poi in allPOIs {
            let poiLoc = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
            let distance = location.distance(from: poiLoc)

            // 如果在 100 米内，且该点最近没有被触发过
            if distance <= poiTriggerRadius {
                if poiAlreadyTriggered.contains(poi.id) { continue }

                print("🎯 [POI探测] 发现目标：\(poi.name)，距离：\(Int(distance))m，触发弹窗！")

                DispatchQueue.main.async {
                    self.alertPOI = poi
                    self.showPOIPopup = true
                    self.poiAlreadyTriggered.insert(poi.id)
                }

                sendPOINotification(poi: poi, isEntering: true)
                return // 每次只处理一个最近的点
            } else if distance > poiExitRadius {
                // 💡 只有离开 150 米，才从“已触发”列表移除，允许下次再次弹窗
                poiAlreadyTriggered.remove(poi.id)
            }
        }
    }

    // MARK: - 辅助方法 (保留并整合)

    func startTracking() {
        pathCoordinates.removeAll()
        isTracking = true
        isPathClosed = false
        territoryValidationPassed = false
        pathUpdateVersion = 0
        TerritoryLogger.shared.log("开始圈地追踪", type: .info)
    }
    
    func stopTracking() {
        isTracking = false
        TerritoryLogger.shared.log("停止圈地追踪", type: .info)
    }

    func validateTerritory() {
        // ... 此处保留你原本完整的验证逻辑代码 ...
        // (为了篇幅，这里不重复粘贴你那段 validateTerritory、calculatePolygonArea 等函数)
        // 请保留你原有的那段代码
    }

    private func sendPOINotification(poi: POIPoint, isEntering: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "发现可搜刮地点"
        content.body = "你已接近「\(poi.name)」，点击查看详情"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 系统地理围栏 (作为二级备用，保留但放宽半径)
    func startMonitoringPOI(_ poi: POIPoint) {
        let region = CLCircularRegion(center: poi.coordinate, radius: poiTriggerRadius, identifier: poi.id)
        region.notifyOnEntry = true
        manager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // 系统围栏触发时，如果主动扫描没起作用，这里作为补偿
        if !showPOIPopup {
            if let poi = RealPOIService.shared.realPOIs.first(where: { $0.id == region.identifier }) {
                DispatchQueue.main.async {
                    self.alertPOI = poi
                    self.showPOIPopup = true
                }
            }
        }
    }
    
    // ... 保留你的模拟方法 simulateEnterPOI, forceClosePath 等 ...
}
