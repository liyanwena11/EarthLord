import Foundation
import MapKit

class RealPOIService: ObservableObject {
    static let shared = RealPOIService()
    @Published var realPOIs: [POIPoint] = []
    @Published var isScanning = false

    /// 成都龙泉驿中心点 - 默认回退坐标
    private let chengduFallback = CLLocationCoordinate2D(latitude: 30.565, longitude: 104.265)

    func searchNearbyRealPOI(userLocation: CLLocationCoordinate2D?) {
        self.isScanning = true

        // ✅ 强制校验：如果坐标为 nil 或接近 (0,0)，自动回退到成都龙泉驿
        let searchCenter: CLLocationCoordinate2D
        if let loc = userLocation,
           abs(loc.latitude) > 1.0 && abs(loc.longitude) > 1.0 {
            // 有效坐标（纬度和经度绝对值都大于1，排除原点附近）
            searchCenter = loc
            print("🗺️ POI搜索：使用真实位置 (\(loc.latitude), \(loc.longitude))")
        } else {
            // 无效坐标，回退到成都
            searchCenter = chengduFallback
            print("🗺️ POI搜索：坐标无效，回退到成都龙泉驿 (30.565, 104.265)")
        }
            
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "超市 餐厅 药店 景点"
        request.region = MKCoordinateRegion(center: searchCenter, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else { self.isScanning = false; return }
            
            self.realPOIs = response.mapItems.map { item in
                POIPoint(
                    id: item.phoneNumber ?? UUID().uuidString,
                    name: item.name ?? "神秘遗迹",
                    type: .supermarket, // 简化处理
                    coordinate: item.placemark.coordinate,
                    status: .discovered,
                    hasResources: true,
                    dangerLevel: 2,
                    description: "这是一处真实的遗迹",
                    distance: nil
                )
            }
            self.isScanning = false
        }
    }
}
