import Foundation
import CoreLocation

// MARK: - 领地验证结果

enum TerritoryValidationResult {
    case valid(area: Double)
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }

    var area: Double? {
        if case .valid(let area) = self { return area }
        return nil
    }
}

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
    // 🆕 领地等级系统字段
    let level: Int?
    let experience: Int?
    let prosperity: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, path, area
        case pointCount = "point_count"
        case isActive = "is_active"
        case completedAt = "completed_at"
        case startedAt = "started_at"
        case createdAt = "created_at"
        case level
        case experience
        case prosperity
    }

    /// 显示名称（有名称返回名称，否则返回默认文本）
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return "未命名领地"
    }

    /// 领地等级显示名称
    var levelName: String {
        guard let lvl = level else { return "临时营地" }
        switch lvl {
        case 1: return "临时营地"
        case 2: return "避难所"
        case 3: return "据点"
        case 4: return "要塞"
        case 5: return "城邦"
        default: return "临时营地"
        }
    }

    /// 下一等级所需经验值
    var experienceToNextLevel: Int {
        guard let lvl = level else { return 100 }
        return lvl * 500 // 简单的经验曲线
    }

    /// 经验进度（0.0 ~ 1.0）
    var experienceProgress: Double {
        guard let exp = experience, let lvl = level else { return 0 }
        let needed = experienceToNextLevel
        return needed > 0 ? min(Double(exp) / Double(needed), 1.0) : 0
    }

    func toCoordinates() -> [CLLocationCoordinate2D] {
        return path.compactMap { point in
            guard let lat = point["lat"], let lon = point["lon"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    /// 计算实际采样点数量（从path数组计算，作为pointCount的后备）
    var calculatedPointCount: Int {
        return pointCount ?? path.count
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
