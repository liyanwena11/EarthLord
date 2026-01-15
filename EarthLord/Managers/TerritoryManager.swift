import Foundation
import CoreLocation

class TerritoryManager {
    static let shared = TerritoryManager()
    
    // 存储加载到的所有领地
    var territories: [Territory] = []
    
    private init() {}

    // MARK: - 1. 加载所有领地 (内置龙泉驿假数据)
    func loadAllTerritories() async throws -> [Territory] {
        let myLat = 30.565
        let myLon = 104.265
        
        let mockEnemy = Territory(
            id: "mock_enemy_99",
            userId: "ENEMY_ID",
            name: "敌占区",
            path: [
                ["lat": myLat + 0.0004, "lon": myLon - 0.0004],
                ["lat": myLat + 0.0008, "lon": myLon - 0.0004],
                ["lat": myLat + 0.0008, "lon": myLon + 0.0004],
                ["lat": myLat + 0.0004, "lon": myLon + 0.0004],
                ["lat": myLat + 0.0004, "lon": myLon - 0.0004]
            ],
            area: 1500.0,
            pointCount: 5,
            isActive: true,
            completedAt: nil,
            startedAt: nil,
            createdAt: nil
        )
        
        self.territories = [mockEnemy]
        return self.territories
    }

    // MARK: - 2. 修复领地列表页面的报错
    func loadMyTerritories() async throws -> [Territory] {
        // ✅ 开发调试阶段：无论 currentUserId 是否为空，都返回成都坐标的测试领地
        let mockTerritories: [Territory] = [
            Territory(
                id: "my_home_1",
                userId: "PLAYER_1",
                name: "龙泉驿桃花源领地",
                path: [
                    ["lat": 30.565, "lon": 104.265],
                    ["lat": 30.566, "lon": 104.265],
                    ["lat": 30.566, "lon": 104.266],
                    ["lat": 30.565, "lon": 104.266]
                ],
                area: 2500.0,
                pointCount: 11,
                isActive: true,
                completedAt: "2026-01-13T15:30:00",
                startedAt: "2026-01-13T15:00:00",
                createdAt: "2026-01-13T15:30:00"
            ),
            Territory(
                id: "my_home_2",
                userId: "PLAYER_1",
                name: "驿马河公园据点",
                path: [
                    ["lat": 30.570, "lon": 104.270],
                    ["lat": 30.571, "lon": 104.270],
                    ["lat": 30.571, "lon": 104.271],
                    ["lat": 30.570, "lon": 104.271]
                ],
                area: 1200.0,
                pointCount: 8,
                isActive: true,
                completedAt: "2026-01-14T10:15:00",
                startedAt: "2026-01-14T10:00:00",
                createdAt: "2026-01-14T10:15:00"
            )
        ]
        print("📍 TerritoryManager: 返回 \(mockTerritories.count) 个测试领地")
        return mockTerritories
    }

    // MARK: - 3. 碰撞检测逻辑 (直接引用 CollisionResult)
    
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
                return CollisionResult(hasCollision: true, collisionType: .pointInTerritory, message: "🛑 此处已被占领！", closestDistance: 0, warningLevel: .violation)
            }
        }
        return .safe
    }

    func checkPathCollisionComprehensive(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard let lastPoint = path.last else { return .safe }
        let currentLoc = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
        
        var minDistance = Double.infinity
        for territory in territories {
            let coords = territory.toCoordinates()
            if isPointInPolygon(point: lastPoint, polygon: coords) {
                return CollisionResult(hasCollision: true, collisionType: .pointInTerritory, message: "🛑 轨迹不能进入他人领地！", closestDistance: 0, warningLevel: .violation)
            }
            for vertex in coords {
                let dist = currentLoc.distance(from: CLLocation(latitude: vertex.latitude, longitude: vertex.longitude))
                minDistance = min(minDistance, dist)
            }
        }
        
        if minDistance < 25 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 危险：即将进入他人领地！(\(Int(minDistance))m)", closestDistance: minDistance, warningLevel: .danger)
        } else if minDistance < 60 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 警告：正在靠近他人领地", closestDistance: minDistance, warningLevel: .warning)
        } else if minDistance < 120 {
            return CollisionResult(hasCollision: false, collisionType: nil, message: "⚠️ 注意：距离他人领地 \(Int(minDistance))m", closestDistance: minDistance, warningLevel: .caution)
        }
        return .safe
    }

    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws { print("模拟上传") }
    func deleteTerritory(territoryId: String) async -> Bool { return true }
}
