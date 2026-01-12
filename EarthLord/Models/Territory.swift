import Foundation
import CoreLocation

struct Territory: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String?             // Optional - database allows null
    let path: [[String: Double]]  // Format: [{"lat": x, "lon": y}]
    let area: Double
    let pointCount: Int?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case path
        case area
        case pointCount = "point_count"
        case isActive = "is_active"
    }

    /// Convert path JSON to CLLocationCoordinate2D array
    func toCoordinates() -> [CLLocationCoordinate2D] {
        return path.compactMap { point in
            guard let lat = point["lat"], let lon = point["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}
