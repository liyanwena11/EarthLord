import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // MARK: - 验证常量（已降低测试难度）
    private let minimumPathPoints = 5           // 降低：10 → 5
    private let minimumTotalDistance: Double = 20.0  // 降低：50.0 → 20.0
    private let minimumEnclosedArea: Double = 20.0   // 降低：100.0 → 20.0（车位大小）
    private let closureDistanceThreshold: CLLocationDistance = 50.0  // 提高：30.0 → 50.0（更容易触发闭环）
    
    // MARK: - 数据发布属性
    @Published var userLocation: CLLocation?
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var isTracking = false
    @Published var isPathClosed = false
    
    // MARK: - UI 需要的变量 (修复报错的关键)
    @Published var pathUpdateVersion: Int = 0
    @Published var speedWarning: String? = nil
    
    // MARK: - 验证状态属性
    @Published var territoryValidationPassed: Bool = false
    @Published var territoryValidationError: String? = nil
    @Published var calculatedArea: Double = 0
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        pathCoordinates.removeAll()
        isTracking = true
        isPathClosed = false
        territoryValidationPassed = false
        territoryValidationError = nil
        calculatedArea = 0
        speedWarning = nil
        pathUpdateVersion = 0
        manager.startUpdatingLocation()
        TerritoryLogger.shared.log("开始追踪领地...", type: .info)
    }
    
    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()

        // ⚠️ 优化：验证失败时不清空路径，让用户能看到问题
        // 只在验证通过时清空路径（上传成功后）
        if territoryValidationPassed {
            // 验证通过，清空路径（上传成功后的清理）
            pathCoordinates.removeAll()
            pathUpdateVersion += 1
            TerritoryLogger.shared.log("验证通过，路径已清空", type: .info)
        } else {
            // 验证失败，保留路径让用户查看
            TerritoryLogger.shared.log("验证失败，路径已保留供检查", type: .warning)
        }

        // Reset validation states to prevent duplicate uploads
        territoryValidationPassed = false
        territoryValidationError = nil
        calculatedArea = 0
        isPathClosed = false
        speedWarning = nil

        TerritoryLogger.shared.log("Tracking stopped", type: .info)
    }

    func clearPath() {
        pathCoordinates.removeAll()
        isPathClosed = false
        pathUpdateVersion += 1
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isTracking else { return }
        userLocation = location
        
        // 速度警告逻辑 (防止作弊)
        if location.speed > 8.3 { // 超过 30km/h
            speedWarning = "速度过快！请步行圈地"
            return
        } else {
            speedWarning = nil
        }
        
        let coord = location.coordinate
        if let lastCoord = pathCoordinates.last {
            let lastLoc = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            if location.distance(from: lastLoc) < 5 { return }
        }
        
        pathCoordinates.append(coord)
        pathUpdateVersion += 1 // 触发地图刷新

        // 降低点数门槛：5 个点就可以开始检测闭环
        if pathCoordinates.count >= 5 {
            checkPathClosure(currentLocation: location)
        }
    }

    private func checkPathClosure(currentLocation: CLLocation) {
        guard pathCoordinates.count >= 5 else { return }

        let startCoord = pathCoordinates[0]
        let startLocation = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
        let distanceToStart = currentLocation.distance(from: startLocation)

        // 距离日志：100 米内每 10 米打印一次
        if distanceToStart <= 100 {
            let rounded = (distanceToStart / 10).rounded() * 10
            if Int(rounded) % 10 == 0 {
                TerritoryLogger.shared.log("距离起点: \(Int(distanceToStart))米", type: .info)
            }
        }

        // 闭环触发：距离 < 50米 且至少 5 个点
        if distanceToStart < closureDistanceThreshold && pathCoordinates.count >= 5 {
            if !isPathClosed {
                isPathClosed = true
                TerritoryLogger.shared.log("闭环触发！距离: \(Int(distanceToStart))米, 点数: \(pathCoordinates.count)", type: .success)
                stopTracking()
                let result = validateTerritory()
                territoryValidationPassed = result.isValid
                territoryValidationError = result.errorMessage
            }
        }
    }
    
    func validateTerritory() -> (isValid: Bool, errorMessage: String?) {
        TerritoryLogger.shared.log("━━━━━━━━━━ 领地验证开始 ━━━━━━━━━━", type: .info)

        // [1/4] 点数检查
        let pointCount = pathCoordinates.count
        TerritoryLogger.shared.log("[1/4] 点数检查: \(pointCount) 个点 (最低要求: \(minimumPathPoints))", type: .info)
        if pointCount < minimumPathPoints {
            TerritoryLogger.shared.log("❌ 验证失败: 点数不足 (\(pointCount) < \(minimumPathPoints))", type: .error)
            return (false, "点数不足（需要至少 \(minimumPathPoints) 个点）")
        }
        TerritoryLogger.shared.log("   ✓ 点数检查通过", type: .success)

        // [2/4] 距离检查
        let totalDistance = calculateTotalPathDistance()
        TerritoryLogger.shared.log("[2/4] 距离检查: \(String(format: "%.1f", totalDistance)) 米 (最低要求: \(minimumTotalDistance)米)", type: .info)
        if totalDistance < minimumTotalDistance {
            TerritoryLogger.shared.log("❌ 验证失败: 行走距离不足", type: .error)
            return (false, "行走距离不足（需要至少 \(Int(minimumTotalDistance)) 米）")
        }
        TerritoryLogger.shared.log("   ✓ 距离检查通过", type: .success)

        // [3/4] 自相交检查
        TerritoryLogger.shared.log("[3/4] 轨迹形状检查: 检测是否存在8字形自相交...", type: .info)
        if hasPathSelfIntersection() {
            TerritoryLogger.shared.log("❌ 验证失败: 轨迹自相交（8字形）", type: .error)
            return (false, "轨迹自相交，请勿画8字形")
        }
        TerritoryLogger.shared.log("   ✓ 轨迹形状检查通过", type: .success)

        // [4/4] 面积检查
        let area = calculatePolygonArea()
        calculatedArea = area
        TerritoryLogger.shared.log("[4/4] 面积检查: \(String(format: "%.2f", area)) ㎡ (最低要求: \(minimumEnclosedArea)㎡)", type: .info)
        if area < minimumEnclosedArea {
            TerritoryLogger.shared.log("❌ 验证失败: 围合面积不足", type: .error)
            return (false, "围合面积不足（需要至少 \(Int(minimumEnclosedArea)) 平方米）")
        }
        TerritoryLogger.shared.log("   ✓ 面积检查通过", type: .success)

        // 全部通过
        TerritoryLogger.shared.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .info)
        TerritoryLogger.shared.log("🏅 SUCCESS: 领地验证全部通过！", type: .success)
        TerritoryLogger.shared.log("   📍 点数: \(pointCount) | 📏 距离: \(String(format: "%.1f", totalDistance))m | 📐 面积: \(String(format: "%.2f", area))㎡", type: .success)
        TerritoryLogger.shared.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .info)

        return (true, nil)
    }
    
    // MARK: - 高容错自相交检测
    func hasPathSelfIntersection() -> Bool {
        guard pathCoordinates.count >= 12 else { return false }
        let pathSnapshot = Array(pathCoordinates)
        let count = pathSnapshot.count
        let buffer = 8
        let protection = 10
        
        for i in 0..<(count - 1) {
            let p1 = pathSnapshot[i]
            let p2 = pathSnapshot[i+1]
            for j in (i + buffer)..<(count - 1) {
                if i < protection && j > (count - protection) { continue }
                let p3 = pathSnapshot[j]
                let p4 = pathSnapshot[j+1]
                if segmentsIntersect(p1: p1, p2: p2, p3: p3, p4: p4) { return true }
            }
        }
        return false
    }
    
    private func segmentsIntersect(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D, p3: CLLocationCoordinate2D, p4: CLLocationCoordinate2D) -> Bool {
        func ccw(_ A: CLLocationCoordinate2D, _ B: CLLocationCoordinate2D, _ C: CLLocationCoordinate2D) -> Bool {
            return (C.latitude - A.latitude) * (B.longitude - A.longitude) > (B.latitude - A.latitude) * (C.longitude - A.longitude)
        }
        return ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
    }
    
    private func calculatePolygonArea() -> Double {
        let pointCount = pathCoordinates.count
        TerritoryLogger.shared.log("   面积计算中: 使用 Shoelace 公式（地球半径修正）", type: .info)

        var area: Double = 0
        for i in 0..<pointCount {
            let p1 = pathCoordinates[i], p2 = pathCoordinates[(i + 1) % pointCount]
            let lat1 = p1.latitude * .pi / 180, lon1 = p1.longitude * .pi / 180
            let lat2 = p2.latitude * .pi / 180, lon2 = p2.longitude * .pi / 180
            area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2))
        }

        let earthRadius: Double = 6371000.0  // 地球半径（米）
        let finalArea = abs(area * earthRadius * earthRadius / 2.0)

        TerritoryLogger.shared.log("   面积计算详情: \(pointCount)个点 -> \(String(format: "%.2f", finalArea))㎡", type: .info)

        return finalArea
    }
    
    private func calculateTotalPathDistance() -> Double {
        var total: Double = 0
        for i in 0..<(pathCoordinates.count - 1) {
            let l1 = CLLocation(latitude: pathCoordinates[i].latitude, longitude: pathCoordinates[i].longitude)
            let l2 = CLLocation(latitude: pathCoordinates[i+1].latitude, longitude: pathCoordinates[i+1].longitude)
            total += l2.distance(from: l1)
        }
        return total
    }
}
