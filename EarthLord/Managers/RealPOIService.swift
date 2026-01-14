//
//  RealPOIService.swift
//  EarthLord
//
//  Day 20: 真实 POI 搜索引擎
//  使用 MKLocalSearch 搜索玩家周围的真实地点
//

import Foundation
import MapKit
import Combine

/// 真实 POI 搜索服务
class RealPOIService: ObservableObject {
    static let shared = RealPOIService()

    // MARK: - 属性

    /// 搜索到的真实 POI 列表
    @Published var realPOIs: [POIPoint] = []

    /// 是否正在搜索
    @Published var isSearching = false

    /// 搜索错误信息
    @Published var searchError: String?

    /// 搜索半径（米）
    let searchRadius: CLLocationDistance = 1000  // 1公里

    /// 支持搜索的 POI 类型
    private let searchCategories: [(query: String, type: POIType)] = [
        ("超市", .supermarket),
        ("医院", .hospital),
        ("药店", .pharmacy),
        ("加油站", .gasStation)
    ]

    private init() {}

    // MARK: - 核心搜索方法

    /// 搜索玩家周围的所有类型 POI
    /// - Parameter center: 搜索中心点（玩家位置）
    func searchNearbyPOIs(center: CLLocationCoordinate2D) {
        isSearching = true
        searchError = nil
        realPOIs = []

        let group = DispatchGroup()
        var allResults: [POIPoint] = []
        let lock = NSLock()

        for category in searchCategories {
            group.enter()
            searchPOIs(query: category.query, type: category.type, center: center) { results in
                lock.lock()
                allResults.append(contentsOf: results)
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // 按距离排序
            self.realPOIs = allResults.sorted { poi1, poi2 in
                (poi1.distance ?? Double.infinity) < (poi2.distance ?? Double.infinity)
            }

            self.isSearching = false
            print("🗺️ RealPOIService: 搜索完成，找到 \(self.realPOIs.count) 个真实地点")
        }
    }

    /// 搜索单一类型的 POI
    private func searchPOIs(
        query: String,
        type: POIType,
        center: CLLocationCoordinate2D,
        completion: @escaping ([POIPoint]) -> Void
    ) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else {
                completion([])
                return
            }

            if let error = error {
                print("❌ 搜索 \(query) 出错: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.searchError = error.localizedDescription
                }
                completion([])
                return
            }

            guard let response = response else {
                completion([])
                return
            }

            // 转换为 POIPoint 模型
            let pois = response.mapItems.compactMap { mapItem -> POIPoint? in
                guard let name = mapItem.name else { return nil }

                let coordinate = mapItem.placemark.coordinate
                let distance = self.calculateDistance(from: center, to: coordinate)

                // 只保留 1 公里内的结果
                guard distance <= self.searchRadius else { return nil }

                return POIPoint(
                    id: UUID().uuidString,
                    name: name,
                    type: type,
                    coordinate: coordinate,
                    status: .discovered,  // 真实地点默认为已发现
                    hasResources: true,   // 真实地点默认有资源
                    dangerLevel: self.randomDangerLevel(for: type),
                    description: self.generateDescription(for: type, name: name),
                    distance: distance
                )
            }

            print("🔍 搜索 \(query): 找到 \(pois.count) 个")
            completion(pois)
        }
    }

    // MARK: - 辅助方法

    /// 计算两点之间的距离（米）
    private func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// 根据类型生成随机危险等级
    private func randomDangerLevel(for type: POIType) -> Int {
        switch type {
        case .hospital:
            return Int.random(in: 3...5)  // 医院危险度较高
        case .supermarket:
            return Int.random(in: 2...4)
        case .pharmacy:
            return Int.random(in: 1...3)
        case .gasStation:
            return Int.random(in: 2...4)
        default:
            return Int.random(in: 1...5)
        }
    }

    /// 生成地点描述
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
        default:
            return "废弃的「\(name)」，可能有物资残留"
        }
    }

    // MARK: - 刷新距离

    /// 根据新的玩家位置刷新所有 POI 的距离
    func updateDistances(from playerLocation: CLLocationCoordinate2D) {
        for i in 0..<realPOIs.count {
            realPOIs[i].distance = calculateDistance(
                from: playerLocation,
                to: realPOIs[i].coordinate
            )
        }

        // 重新排序
        realPOIs.sort { poi1, poi2 in
            (poi1.distance ?? Double.infinity) < (poi2.distance ?? Double.infinity)
        }
    }
}
