import SwiftUI
import MapKit
import CoreLocation

struct MainMapView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), latitudinalMeters: 1000, longitudinalMeters: 1000)
    @State private var pois: [POI] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    private let locationManager = CLLocationManager()
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: pois) { poi in
                MapAnnotation(coordinate: poi.coordinate) {
                    VStack {
                        Image(systemName: poi.type.iconName)
                            .padding(5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                        Text(poi.name)
                            .font(.caption)
                            .background(Color.white.opacity(0.8))
                            .padding(2)
                            .cornerRadius(4)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                setupLocationManager()
                requestLocation()
            }
            
            VStack {
                HStack {
                    Button(action: {
                        requestLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await searchPOIs()
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack {
                    Text("附近玩家: \(PlayerLocationManager.shared.nearbyPlayerCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    Text("密度等级: \(densityLevelText)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.top, 5)
                }
                .padding()
            }
            
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                    }
            }
            
            if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                    
                    Button(action: {
                        self.errorMessage = nil
                    }) {
                        Text("确定")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.top, 10)
                    }
                }
                .padding()
            }
        }
    }
    
    private var densityLevelText: String {
        let level = PlayerLocationManager.shared.densityLevel
        switch level {
        case .solo:
            return "独行者"
        case .low:
            return "低密度"
        case .medium:
            return "中密度"
        case .high:
            return "高密度"
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
    }
    
    private func requestLocation() {
        locationManager.requestLocation()
    }
    
    private func searchPOIs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let location = locationManager.location else {
                throw NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取当前位置"])
            }
            
            // 先上报位置并查询附近玩家数量
            try await PlayerLocationManager.shared.updateLocation(location)
            try await PlayerLocationManager.shared.getNearbyPlayerCount(location)
            
            // 然后搜索POI
            pois = try await RealPOIService.shared.searchNearbyRealPOI(location: location)
        } catch {
            errorMessage = "搜索 POI 失败: \(error.localizedDescription)"
            print("搜索 POI 失败: \(error)")
        } finally {
            isLoading = false
        }
    }
}

extension MainMapView: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "获取位置失败: \(error.localizedDescription)"
        print("获取位置失败: \(error)")
    }
}

struct MainMapView_Previews: PreviewProvider {
    static var previews: some View {
        MainMapView()
    }
}
