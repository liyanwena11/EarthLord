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
        request.naturalLanguageQuery = "超市 医院 药店 加油站 餐厅 景点 工厂"
        // ✅ Day 22：搜索范围扩展至 1km
        request.region = MKCoordinateRegion(center: searchCenter, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else { self.isScanning = false; return }
            
            self.realPOIs = response.mapItems.map { item in
                // ✅ Day 22：基于真实 POI 类型识别
                let poiType = self.identifyPOIType(from: item)

                // ✅ Day 22：计算与用户的距离
                let userLoc = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
                let poiLoc = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                let distanceFromUser = userLoc.distance(from: poiLoc)

                // ✅ Day 22：基于算法计算危险等级
                let dangerLevel = self.calculateDangerLevel(poiType: poiType, distanceFromUser: distanceFromUser)

                return POIPoint(
                    id: UUID().uuidString,  // 使用 UUID 确保唯一性
                    name: item.name ?? "神秘遗迹",
                    type: poiType,
                    coordinate: item.placemark.coordinate,
                    status: .discovered,
                    hasResources: true,
                    dangerLevel: dangerLevel,
                    description: self.generateDescription(for: poiType, name: item.name ?? "遗迹"),
                    distance: nil,
                    lastLootedTime: nil  // ✅ Day 22：初始化为未搜刮
                )
            }
            self.isScanning = false
            print("🗺️ POI搜索完成：找到 \(self.realPOIs.count) 个地点")
            print("🎯 [POI搜索] POI 列表已更新，距离检测将自动生效")
        }
    }

    // MARK: - Day 20 完善：POI 状态管理

    /// 将指定 POI 标记为已搜空
    /// - Parameter poiId: POI 的 ID
    func markAsLooted(poiId: String) {
        if let index = realPOIs.firstIndex(where: { $0.id == poiId }) {
            realPOIs[index].status = .looted
            realPOIs[index].hasResources = false
            realPOIs[index].lastLootedTime = Date()  // ✅ Day 22：记录搜刮时间
            print("🏴 POI 已搜空：\(realPOIs[index].name)，24小时后刷新")
        }
    }

    /// ✅ Day 22：检查 POI 是否可搜刮（未搜刮或已过冷却期）
    func isLootable(poiId: String) -> Bool {
        guard let poi = realPOIs.first(where: { $0.id == poiId }) else { return false }
        return poi.isLootable
    }

    /// ✅ Day 22：刷新所有 POI 的冷却状态
    func refreshCooldowns() {
        for index in realPOIs.indices {
            if realPOIs[index].isLootable && realPOIs[index].status == .looted {
                realPOIs[index].status = .discovered
                realPOIs[index].hasResources = true
                print("🔄 POI 已刷新：\(realPOIs[index].name)")
            }
        }
    }

    /// 检查 POI 是否已被搜空
    func isLooted(poiId: String) -> Bool {
        return realPOIs.first(where: { $0.id == poiId })?.status == .looted
    }

    // MARK: - Day 22：POI 类型识别算法

    /// 基于 MKMapItem 识别 POI 类型
    private func identifyPOIType(from mapItem: MKMapItem) -> POIType {
        // 优先使用 pointOfInterestCategory（iOS 13+）
        if let category = mapItem.pointOfInterestCategory {
            switch category {
            case .hospital:
                return .hospital
            case .pharmacy:
                return .pharmacy
            case .store, .foodMarket:
                return .supermarket
            case .gasStation, .evCharger:
                return .gasStation
            case .restaurant, .cafe, .bakery:
                return .supermarket  // 餐厅归类为超市（食物来源）
            case .school, .university:
                return .school
            default:
                // 未识别的类型，使用名称备用识别
                return fallbackTypeFromName(mapItem.name ?? "")
            }
        } else {
            // iOS 13 以下或无 category，使用名称识别
            return fallbackTypeFromName(mapItem.name ?? "")
        }
    }

    /// 基于名称关键词识别 POI 类型（备用方案）
    private func fallbackTypeFromName(_ name: String) -> POIType {
        let lowercased = name.lowercased()

        if lowercased.contains("医院") || lowercased.contains("hospital") || lowercased.contains("诊所") {
            return .hospital
        } else if lowercased.contains("药店") || lowercased.contains("pharmacy") || lowercased.contains("药房") {
            return .pharmacy
        } else if lowercased.contains("超市") || lowercased.contains("market") || lowercased.contains("商店") || lowercased.contains("便利店") {
            return .supermarket
        } else if lowercased.contains("加油") || lowercased.contains("gas") || lowercased.contains("石油") {
            return .gasStation
        } else if lowercased.contains("工厂") || lowercased.contains("factory") {
            return .factory
        } else if lowercased.contains("仓库") || lowercased.contains("warehouse") {
            return .warehouse
        } else if lowercased.contains("学校") || lowercased.contains("school") || lowercased.contains("大学") {
            return .school
        } else if lowercased.contains("餐厅") || lowercased.contains("restaurant") || lowercased.contains("饭店") {
            return .supermarket  // 餐厅归类为超市
        }

        // 默认类型：仓库（通用废墟）
        return .warehouse
    }

    // MARK: - Day 22：危险等级算法

    /// 基于 POI 类型和距离计算危险等级
    /// - Parameters:
    ///   - poiType: POI 类型
    ///   - distanceFromUser: 与用户的距离（米）
    /// - Returns: 危险等级（1-5）
    private func calculateDangerLevel(poiType: POIType, distanceFromUser: Double) -> Int {
        // 基础危险等级（根据 POI 类型）
        let baseDanger: Int
        switch poiType {
        case .hospital:
            baseDanger = 5  // 医院最危险（感染者聚集）
        case .gasStation:
            baseDanger = 4  // 加油站较危险（爆炸风险）
        case .factory:
            baseDanger = 4  // 工厂较危险（坍塌风险）
        case .pharmacy:
            baseDanger = 3  // 药店中等危险
        case .warehouse:
            baseDanger = 3  // 仓库中等危险
        case .supermarket:
            baseDanger = 2  // 超市相对安全
        case .school:
            baseDanger = 2  // 学校相对安全
        }

        // 距离修正（越远越危险，+0 到 +1）
        let distanceModifier: Int
        if distanceFromUser > 800 {
            distanceModifier = 1  // 超过 800m，+1 危险
        } else if distanceFromUser > 500 {
            distanceModifier = 1  // 超过 500m，+1 危险
        } else {
            distanceModifier = 0  // 500m 内不修正
        }

        // 随机波动 (-1 到 +1)，增加不确定性
        let randomVariation = Int.random(in: -1...1)

        // 最终危险等级：基础 + 距离修正 + 随机，限制在 1-5
        let finalDanger = max(1, min(5, baseDanger + distanceModifier + randomVariation))

        return finalDanger
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
