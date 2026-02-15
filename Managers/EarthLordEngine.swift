import Foundation
import CoreLocation

class EarthLordEngine: ObservableObject {
    static let shared = EarthLordEngine()
    
    @Published var totalExplorationDistance: Double = 0
    @Published var currentExplorationDistance: Double = 0
    @Published var isExploring: Bool = false
    
    private var lastLocation: CLLocation?
    private let distanceThreshold: CLLocationDistance = 1
    private var locationUpdateTimer: Timer?
    
    private init() {}
    
    func startExploration() {
        isExploring = true
        currentExplorationDistance = 0
        PlayerLocationManager.shared.startLocationTracking()
        print("开始探索")
    }
    
    func stopExploration() {
        isExploring = false
        PlayerLocationManager.shared.stopLocationTracking()
        stopLocationUpdates()
        print("停止探索")
    }
    
    func handleExplorationTracking(_ location: CLLocation) {
        guard isExploring else { return }
        
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            if distance >= distanceThreshold {
                currentExplorationDistance += distance
                totalExplorationDistance += distance
                lastLocation = location
                print("探索距离更新: \(currentExplorationDistance)米")
            }
        } else {
            lastLocation = location
        }
    }
    
    private func startLocationUpdates() {
        locationUpdateTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updateLocation),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func stopLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    @objc private func updateLocation() {
        guard let location = PlayerLocationManager.shared.locationManager.location else { return }
        handleExplorationTracking(location)
    }
}
