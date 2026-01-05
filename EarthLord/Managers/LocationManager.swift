import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Day 15 新增属性
    @Published var isTracking: Bool = false
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var pathUpdateVersion: Int = 0 // 用于通知 UI 刷新轨迹
    
    private var currentLocation: CLLocation? // 用于记录最新的 GPS 点
    private var pathUpdateTimer: Timer?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    // MARK: - 圈地控制方法
    
    func startPathTracking() {
        // 1. 彻底清空旧轨迹，防止长直线
        self.pathCoordinates.removeAll()
        self.pathUpdateVersion = 0
        self.isTracking = true
        
        // 2. 启动定时器，每 2 秒采样一次
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }
    
    func stopPathTracking() {
        isTracking = false
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }
    
    func clearPath() {
        pathCoordinates.removeAll()
        pathUpdateVersion += 1
    }
    
    private func recordPathPoint() {
        // 检查是否有位置数据且精度尚可
        guard let location = currentLocation else { return }
        
        // 过滤经纬度为 0 的异常点
        if location.coordinate.latitude == 0 && location.coordinate.longitude == 0 { return }
        
        let newCoord = location.coordinate
        
        if pathCoordinates.isEmpty {
            // 第一个点直接加入
            pathCoordinates.append(newCoord)
            pathUpdateVersion += 1
        } else {
            let lastCoord = pathCoordinates.last!
            let lastLocation = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let distance = location.distance(from: lastLocation)
            
            // 距离上次采样超过 10 米，且小于 500 米（防止瞬移长直线）才记录
            if distance > 10 && distance < 500 {
                pathCoordinates.append(newCoord)
                pathUpdateVersion += 1
            }
        }
    }
    
    // MARK: - Delegate 方法
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        self.currentLocation = location // 给 Timer 准备最新数据
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
}
