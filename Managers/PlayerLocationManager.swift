import Foundation
import CoreLocation
import Supabase

class PlayerLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = PlayerLocationManager()
    private let locationManager = CLLocationManager()
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://gqqkmgwpmwwvtrcpcchv.supabase.co")!,
        supabaseKey: "**************************************************************************************************************************************************************************************************************************"
    )
    private var locationUpdateTimer: Timer?
    private var lastReportedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 30
    private let locationChangeThreshold: CLLocationDistance = 50
    
    @Published var nearbyPlayerCount: Int = 0
    @Published var densityLevel: DensityLevel = .solo
    
    enum DensityLevel {
        case solo
        case low
        case medium
        case high
        
        var poiCount: Int {
            switch self {
            case .solo: return 1
            case .low: return 3
            case .medium: return 5
            case .high: return 10
            }
        }
    }
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
    }
    
    func startLocationTracking() {
        locationManager.startUpdatingLocation()
        startLocationUpdateTimer()
        print("位置追踪已启动")
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
        stopLocationUpdateTimer()
        markAsOffline()
        print("位置追踪已停止")
    }
    
    private func startLocationUpdateTimer() {
        locationUpdateTimer = Timer.scheduledTimer(
            timeInterval: locationUpdateInterval,
            target: self,
            selector: #selector(reportLocation),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    @objc private func reportLocation() {
        guard let currentLocation = locationManager.location else { return }
        
        if shouldReportLocation(currentLocation) {
            Task {
                try await updateLocation(currentLocation)
                lastReportedLocation = currentLocation
            }
        }
    }
    
    private func shouldReportLocation(_ location: CLLocation) -> Bool {
        guard let lastLocation = lastReportedLocation else { return true }
        return location.distance(from: lastLocation) >= locationChangeThreshold
    }
    
    private func updateLocation(_ location: CLLocation) async throws {
        let params = [
            "player_id": AuthManager.shared.getCurrentUser()?.id ?? "anonymous",
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "is_online": true
        ] as [String: Any]
        
        _ = try await supabase.rpc(
            "upsert_player_location",
            params: params
        ).execute()
        
        print("位置已上报: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    private func markAsOffline() {
        Task {
            let params = [
                "player_id": AuthManager.shared.getCurrentUser()?.id ?? "anonymous",
                "is_online": false
            ] as [String: Any]
            
            do {
                _ = try await supabase.rpc(
                    "upsert_player_location",
                    params: params
                ).execute()
                print("已标记为离线")
            } catch {
                print("标记离线失败: \(error)")
            }
        }
    }
    
    func getNearbyPlayerCount(_ location: CLLocation) async throws -> Int {
        let params = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "radius": 1000,
            "player_id": AuthManager.shared.getCurrentUser()?.id ?? "anonymous"
        ] as [String: Any]
        
        let result: Int = try await supabase.rpc(
            "get_nearby_player_count",
            params: params
        ).execute()
        
        nearbyPlayerCount = result
        updateDensityLevel(count: result)
        print("附近玩家数量: \(result)")
        return result
    }
    
    private func updateDensityLevel(count: Int) {
        switch count {
        case 0:
            densityLevel = .solo
        case 1...5:
            densityLevel = .low
        case 6...20:
            densityLevel = .medium
        default:
            densityLevel = .high
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 位置更新时的处理
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways,
             .authorizedWhenInUse:
            print("位置授权成功")
        case .denied,
             .restricted:
            print("位置授权被拒绝")
        default:
            break
        }
    }
}
