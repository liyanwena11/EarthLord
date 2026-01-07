import Foundation
import CoreLocation
import Combine

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
        
        if pathCoordinates.count >= 10 {
            checkPathClosure(currentLocation: location)
        }
    }
    
    private func checkPathClosure(currentLocation: CLLocation) {
        let startCoord = pathCoordinates[0]
        let startLocation = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
        if currentLocation.distance(from: startLocation) < closureDistanceThreshold && pathCoordinates.count > 15 {
            if !isPathClosed {
                isPathClosed = true
                stopTracking()
                let result = validateTerritory()
                territoryValidationPassed = result.isValid
                territoryValidationError = result.errorMessage
            }
        }
    }
    
    func validateTerritory() -> (isValid: Bool, errorMessage: String?) {
        if pathCoordinates.count < minimumPathPoints { return (false, "点数不足") }
        if calculateTotalPathDistance() < minimumTotalDistance { return (false, "距离不足") }
        
        if hasPathSelfIntersection() {
            return (false, "轨迹自相交，请勿画8字形")
        }
        
        let area = calculatePolygonArea()
        calculatedArea = area
        if area < minimumEnclosedArea { return (false, "面积不足") }
        
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
        var area: Double = 0
        for i in 0..<pathCoordinates.count {
            let p1 = pathCoordinates[i], p2 = pathCoordinates[(i + 1) % pathCoordinates.count]
            let lat1 = p1.latitude * .pi / 180, lon1 = p1.longitude * .pi / 180
            let lat2 = p2.latitude * .pi / 180, lon2 = p2.longitude * .pi / 180
            area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2))
        }
        return abs(area * 6371000.0 * 6371000.0 / 2.0)
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
