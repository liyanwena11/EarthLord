import Foundation
import CoreLocation
import SwiftUI

// MARK: - 稀有度

enum POIRarity: String, Codable, CaseIterable {
    case common = "普通", rare = "稀有", epic = "史诗", legendary = "传说"
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - 资源点模型

struct POIModel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    var rarity: POIRarity
    var isScavenged: Bool = false
    var lastScavengedAt: Date?
    var type: String = "POI"

    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }

    var canScavengeAgain: Bool {
        guard let last = lastScavengedAt else { return true }
        return Date().timeIntervalSince(last) > GameConfig.POI_RESPAWN_SECONDS
    }

    var respawnRemainingSeconds: TimeInterval {
        guard let last = lastScavengedAt else { return 0 }
        return max(0, GameConfig.POI_RESPAWN_SECONDS - Date().timeIntervalSince(last))
    }
}

// MARK: - 领地模型（支持多边形路径 + 面积 + 名称）

struct TerritoryModel: Identifiable, Codable {
    let id: UUID
    let lat: Double          // 中心点纬度
    let lon: Double          // 中心点经度
    let claimedAt: Date
    var name: String = "未命名领地"
    var area: Double = 0     // 面积（平方米）
    var pointCount: Int = 0  // 采样点数
    var pathLatitudes: [Double] = []   // 路径纬度数组
    var pathLongitudes: [Double] = []  // 路径经度数组

    var location: CLLocation { CLLocation(latitude: lat, longitude: lon) }

    /// 获取路径坐标数组
    var pathCoordinates: [CLLocationCoordinate2D] {
        zip(pathLatitudes, pathLongitudes).map {
            CLLocationCoordinate2D(latitude: $0, longitude: $1)
        }
    }
}

// MARK: - 全局配置

struct GameConfig {
    static let POI_TRIGGER_RADIUS: Double = 80.0
    static let CLAIM_RADIUS: Double = 150.0
    static let POI_RESPAWN_SECONDS: Double = 86400
    static let SAMPLING_MIN_DISTANCE: Double = 10.0   // 采样最小间距（米）
    static let SAMPLING_MIN_POINTS: Int = 5            // 最少采样点数
    static let SAMPLING_MAX_ACCURACY: Double = 25.0    // 采样最大精度误差（米）
    static let SAMPLING_MAX_STEP_DISTANCE: Double = 80.0 // 单步最大距离（米）
    static let SAMPLING_MAX_SPEED_KMH: Double = 20.0   // 采样最大速度（km/h）
    static let TERRITORY_CLOSE_DISTANCE: Double = 25.0 // 闭环判定（起点终点最大距离）
    static let TERRITORY_MIN_AREA: Double = 100.0      // 领地最小面积（㎡）
    static let TERRITORY_MAX_AREA: Double = 10_000_000 // 领地最大面积（㎡）
    static let TERRITORY_MIN_SPAN: Double = 8.0        // 包围盒最小短边（米），防止直线误圈
}
