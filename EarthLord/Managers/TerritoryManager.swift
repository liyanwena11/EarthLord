import Foundation
import CoreLocation

// MARK: - 辅助结构体
struct TerritoryUploadPayload: Encodable {
    let user_id: UUID
    let area: Double
    let path: [[String: Double]]
    let polygon: String
    let bbox_min_lat: Double
    let bbox_max_lat: Double
    let bbox_min_lon: Double
    let bbox_max_lon: Double
    let point_count: Int
    let started_at: Date
    let is_active: Bool
    let name: String
}

class TerritoryManager {
    static let shared = TerritoryManager()
    var territories: [Territory] = []
    private init() {}

    // MARK: - 1. 加载所有领地 (内置龙泉驿敌军假数据)
    func loadAllTerritories() async throws -> [Territory] {
        let myLat = 30.565 // 桃花源别墅附近
        let myLon = 104.265
        
        let mockEnemy = Territory(
            id: "mock_enemy_1",
            userId: "00000000-0000-0000-0000-000000000000",
            name: "敌军占领区-警告点",
            path: [
                ["lat": myLat + 0.0003, "lon": myLon + 0.0003],
                ["lat": myLat + 0.0006, "lon": myLon + 0.0003],
                ["lat": myLat + 0.0006, "lon": myLon + 0.0006],
                ["lat": myLat + 0.0003, "lon": myLon + 0.0006],
                ["lat": myLat + 0.0003, "lon": myLon + 0.0003]
            ],
            area: 1200,
            pointCount: 5,
            isActive: true
        )
        
        self.territories = [mockEnemy]
        return self.territories
    }

    // MARK: - 2. 找回丢失的方法，修复编译报错
    
    // 修复 TerritoryTabView 的报错
    func loadMyTerritories() async throws -> [Territory] {
        return territories
    }

    // ✅ 修复 TerritoryDetailView 的报错：添加删除方法
    func deleteTerritory(territoryId: String) async -> Bool {
        print("模拟删除领地: \(territoryId)")
        return true
    }

    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        print("模拟上传成功")
    }

    // MARK: - 3. 碰撞检测核心算法
    
    func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
                (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    func checkPointCollision(location: CLLocationCoordinate2D, currentUserId: String) -> CollisionResult {
        for territory in territories {
            if isPointInPolygon(point: location, polygon: territory.toCoordinates()) {
                return CollisionResult(hasCollision: true, collisionType: .pointInTerritory, message: "🛑 轨迹不能进入他人领地！", closestDistance: 0, warningLevel: .violation)
            }
        }
        return .safe
    }

    func checkPathCollisionComprehensive(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard let lastPoint = path.last else { return .safe }
        let currentLoc = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
        
        var minDistance = Double.infinity
        for territory in territories {
            for vertex in territory.toCoordinates() {
                let dist = currentLoc.distance(from: CLLocation(latitude: vertex.latitude, longitude: vertex.longitude))
                minDistance = min(minDistance, dist)
            }
        }
        
        // 预警分级逻辑
        if minDistance < 25 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 危险：即将进入他人领地！", closestDistance: minDistance, warningLevel: .danger)
        } else if minDistance < 50 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 警告：正在靠近他人领地", closestDistance: minDistance, warningLevel: .warning)
        } else if minDistance < 100 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 注意：距离他人领地 \(Int(minDistance))m", closestDistance: minDistance, warningLevel: .caution)
        }
        return .safe
    }
}
