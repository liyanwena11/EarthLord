import Foundation
import CoreLocation

struct Territory: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String?
    let path: [[String: Double]]
    let area: Double
    let pointCount: Int?
    let isActive: Bool?
    // ✅ 必须补全这三个字段，否则管理器会报错
    let completedAt: String?
    let startedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, path, area
        case pointCount = "point_count"
        case isActive = "is_active"
        case completedAt = "completed_at"
        case startedAt = "started_at"
        case createdAt = "created_at"
    }

    /// 显示名称（有名称返回名称，否则返回默认文本）
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return "未命名领地"
    }

    func toCoordinates() -> [CLLocationCoordinate2D] {
        return path.compactMap { point in
            guard let lat = point["lat"], let lon = point["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

// Hashable conformance for sheet(item:)
extension Territory: Hashable {
    static func == (lhs: Territory, rhs: Territory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
