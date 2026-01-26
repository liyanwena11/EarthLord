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

    func toCoordinates() -> [CLLocationCoordinate2D] {
        return path.compactMap { point in
            guard let lat = point["lat"], let lon = point["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}
