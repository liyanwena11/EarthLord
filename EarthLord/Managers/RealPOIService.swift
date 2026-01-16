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
                // 随机分配 POI 类型
                let types: [POIType] = [.supermarket, .hospital, .pharmacy, .gasStation, .warehouse]
                let randomType = types.randomElement() ?? .supermarket

                return POIPoint(
                    id: UUID().uuidString,  // 使用 UUID 确保唯一性
                    name: item.name ?? "神秘遗迹",
                    type: randomType,
                    coordinate: item.placemark.coordinate,
                    status: .discovered,
                    hasResources: true,
                    dangerLevel: Int.random(in: 1...5),
                    description: self.generateDescription(for: randomType, name: item.name ?? "遗迹"),
                    distance: nil
                )
            }
            self.isScanning = false
            print("🗺️ POI搜索完成：找到 \(self.realPOIs.count) 个地点")
        }
    }

    // MARK: - Day 20 完善：POI 状态管理

    /// 将指定 POI 标记为已搜空
    /// - Parameter poiId: POI 的 ID
    func markAsLooted(poiId: String) {
        if let index = realPOIs.firstIndex(where: { $0.id == poiId }) {
            realPOIs[index].status = .looted
            realPOIs[index].hasResources = false
            print("🏴 POI 已搜空：\(realPOIs[index].name)")
        }
    }

    /// 检查 POI 是否已被搜空
    func isLooted(poiId: String) -> Bool {
        return realPOIs.first(where: { $0.id == poiId })?.status == .looted
    }

    /// 根据类型生成描述
    private func generateDescription(for type: POIType, name: String) -> String {
        switch type {
        case .supermarket:
            return "「\(name)」的废墟，货架可能还有残留物资，小心感染者出没"
        case .hospital:
            return "「\(name)」的医疗废墟，可能有珍贵的医疗用品，但危险程度极高"
        case .pharmacy:
            return "「\(name)」的药店残骸，可能还有药品残留，相对安全"
        case .gasStation:
            return "「\(name)」加油站，可能有燃料和便利店物资"
        case .warehouse:
            return "「\(name)」仓库，可能有大量材料和工具"
        default:
            return "废弃的「\(name)」，可能有物资残留"
        }
    }
}
