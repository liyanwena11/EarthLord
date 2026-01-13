import Foundation
import CoreLocation
import Supabase

class TerritoryManager {

    static let shared = TerritoryManager()
    private let supabase = supabaseClient

    // 存储所有领地数据，用于碰撞检测
    var territories: [Territory] = []

    private init() {}

    // MARK: - Upload Payload

    /// Private struct for territory upload (Encodable required by Supabase)
    private struct TerritoryUploadPayload: Encodable {
        let userId: UUID  // Changed from String to UUID to match database type
        let path: [[String: Double]]
        let polygon: String
        let bboxMinLat: Double
        let bboxMaxLat: Double
        let bboxMinLon: Double
        let bboxMaxLon: Double
        let area: Double
        let pointCount: Int
        let startedAt: String
        let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case path
            case polygon
            case bboxMinLat = "bbox_min_lat"
            case bboxMaxLat = "bbox_max_lat"
            case bboxMinLon = "bbox_min_lon"
            case bboxMaxLon = "bbox_max_lon"
            case area
            case pointCount = "point_count"
            case startedAt = "started_at"
            case isActive = "is_active"
        }
    }

    // MARK: - Helper Methods

    /// Convert coordinates to path JSON format: [{"lat": x, "lon": y}, ...]
    /// WARNING: Only include lat and lon, no extra fields!
    private func coordinatesToPathJSON(_ coordinates: [CLLocationCoordinate2D]) -> [[String: Double]] {
        return coordinates.map { coord in
            return [
                "lat": coord.latitude,
                "lon": coord.longitude
            ]
        }
    }

    /// Convert coordinates to WKT (Well-Known Text) format for PostGIS
    /// WARNING: WKT format is (longitude, latitude) - longitude first!
    /// WARNING: Polygon must be closed (first point = last point)!
    private func coordinatesToWKT(_ coordinates: [CLLocationCoordinate2D]) -> String {
        guard coordinates.count >= 3 else {
            return ""
        }

        var wktCoords = coordinates.map { coord in
            // WKT format: longitude first, then latitude
            return "\(coord.longitude) \(coord.latitude)"
        }

        // Ensure polygon is closed (first point = last point)
        if let first = coordinates.first, let last = coordinates.last {
            if first.latitude != last.latitude || first.longitude != last.longitude {
                wktCoords.append("\(first.longitude) \(first.latitude)")
            }
        }

        let wktString = wktCoords.joined(separator: ", ")
        return "SRID=4326;POLYGON((\(wktString)))"
    }

    /// Calculate bounding box for coordinates
    /// Returns: (minLat, maxLat, minLon, maxLon)
    private func calculateBoundingBox(_ coordinates: [CLLocationCoordinate2D]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        guard !coordinates.isEmpty else {
            return (0, 0, 0, 0)
        }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        return (minLat, maxLat, minLon, maxLon)
    }

    // MARK: - Public Methods

    /// Upload territory to Supabase
    /// - Parameters:
    ///   - coordinates: Path coordinates
    ///   - area: Territory area in square meters
    ///   - startTime: When tracking started
    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        // Get current user ID
        guard let userId = try? await supabase.auth.session.user.id else {
            throw NSError(domain: "TerritoryManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        // Prepare data
        let pathJSON = coordinatesToPathJSON(coordinates)
        let wktPolygon = coordinatesToWKT(coordinates)
        let bbox = calculateBoundingBox(coordinates)

        // Build upload payload using Encodable struct
        let payload = TerritoryUploadPayload(
            userId: userId,  // Pass UUID directly, not as string
            path: pathJSON,
            polygon: wktPolygon,
            bboxMinLat: bbox.minLat,
            bboxMaxLat: bbox.maxLat,
            bboxMinLon: bbox.minLon,
            bboxMaxLon: bbox.maxLon,
            area: area,
            pointCount: coordinates.count,
            startedAt: startTime.ISO8601Format(),
            isActive: true
        )

        // Upload to database
        try await supabase
            .from("territories")
            .insert(payload)
            .execute()

        TerritoryLogger.shared.log("Territory uploaded successfully - Area: \(Int(area))m², Points: \(coordinates.count)", type: .success)
    }

    /// Load all active territories from Supabase
    /// - Returns: Array of Territory objects
    func loadAllTerritories() async throws -> [Territory] {
        let response: [Territory] = try await supabase
            .from("territories")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value

        TerritoryLogger.shared.log("Loaded \(response.count) active territories", type: .info)
        return response
    }

    // MARK: - My Territories Management

    /// Load territories belonging to current user
    /// - Returns: Array of Territory objects owned by current user
    func loadMyTerritories() async throws -> [Territory] {
        // Get current user ID
        guard let userId = try? await supabase.auth.session.user.id else {
            throw NSError(domain: "TerritoryManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let response: [Territory] = try await supabase
            .from("territories")
            .select()
            .eq("user_id", value: userId)  // Pass UUID directly
            .eq("is_active", value: true)
            .execute()
            .value

        TerritoryLogger.shared.log("Loaded \(response.count) territories for current user", type: .info)
        return response
    }

    /// Delete a territory by ID
    /// - Parameter territoryId: The ID of the territory to delete
    func deleteTerritory(territoryId: String) async throws {
        // Soft delete: set is_active to false
        try await supabase
            .from("territories")
            .update(["is_active": false])
            .eq("id", value: territoryId)
            .execute()

        TerritoryLogger.shared.log("Territory deleted: \(territoryId)", type: .info)
    }

    // MARK: - Debug/Test Methods

    /// Debug: Print current user information
    func debugCurrentUser() async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        let userEmail = session.user.email ?? "No email"

        print("=== DEBUG: Current User Info ===")
        print("User ID: \(userId)")
        print("User ID (String): \(userId.uuidString)")
        print("User Email: \(userEmail)")
        print("================================")

        TerritoryLogger.shared.log("User ID: \(userId.uuidString)", type: .info)
    }

    /// 插入测试领地数据（成都附近的正方形）- 仅用于室内调试
    func insertTestTerritory() async throws {
        // 先打印用户信息进行调试
        try await debugCurrentUser()

        // 成都附近的正方形坐标（四个点，面积约 500m²）
        // 中心点：30.65°N, 104.06°E
        let testCoordinates = [
            CLLocationCoordinate2D(latitude: 30.65, longitude: 104.06),      // 西南角
            CLLocationCoordinate2D(latitude: 30.651, longitude: 104.06),     // 西北角
            CLLocationCoordinate2D(latitude: 30.651, longitude: 104.061),    // 东北角
            CLLocationCoordinate2D(latitude: 30.65, longitude: 104.061),     // 东南角
            CLLocationCoordinate2D(latitude: 30.65, longitude: 104.06)       // 回到起点（闭合）
        ]

        print("=== DEBUG: About to upload territory ===")
        print("Coordinates count: \(testCoordinates.count)")
        print("Area: 500m²")

        // 使用现有的 uploadTerritory 方法
        try await uploadTerritory(
            coordinates: testCoordinates,
            area: 500.0,
            startTime: Date()
        )

        TerritoryLogger.shared.log("✅ 测试领地已插入！打开 App 查看成都附近的绿色多边形", type: .success)
    }

    // MARK: - 碰撞检测算法

    /// 射线法判断点是否在多边形内
    func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        let x = point.longitude
        let y = point.latitude

        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            let intersect = ((yi > y) != (yj > y)) &&
                           (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

            if intersect {
                inside.toggle()
            }
            j = i
        }

        return inside
    }

    /// 检查起始点是否在他人领地内
    func checkPointCollision(location: CLLocationCoordinate2D, currentUserId: String) -> CollisionResult {
        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else {
            return .safe
        }

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()
            guard polygon.count >= 3 else { continue }

            if isPointInPolygon(point: location, polygon: polygon) {
                TerritoryLogger.shared.log("起点碰撞：位于他人领地内", type: .error)
                return CollisionResult(
                    hasCollision: true,
                    collisionType: .pointInTerritory,
                    message: "不能在他人领地内开始圈地！",
                    closestDistance: 0,
                    warningLevel: .violation
                )
            }
        }

        return .safe
    }

    /// 判断两条线段是否相交（CCW 算法）
    private func segmentsIntersect(
        p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D, p4: CLLocationCoordinate2D
    ) -> Bool {
        func ccw(_ A: CLLocationCoordinate2D, _ B: CLLocationCoordinate2D, _ C: CLLocationCoordinate2D) -> Bool {
            return (C.latitude - A.latitude) * (B.longitude - A.longitude) >
                   (B.latitude - A.latitude) * (C.longitude - A.longitude)
        }

        return ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
    }

    /// 检查路径是否穿越他人领地边界
    func checkPathCrossTerritory(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 2 else { return .safe }

        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return .safe }

        for i in 0..<(path.count - 1) {
            let pathStart = path[i]
            let pathEnd = path[i + 1]

            for territory in otherTerritories {
                let polygon = territory.toCoordinates()
                guard polygon.count >= 3 else { continue }

                // 检查与领地每条边的相交
                for j in 0..<polygon.count {
                    let boundaryStart = polygon[j]
                    let boundaryEnd = polygon[(j + 1) % polygon.count]

                    if segmentsIntersect(p1: pathStart, p2: pathEnd, p3: boundaryStart, p4: boundaryEnd) {
                        TerritoryLogger.shared.log("路径碰撞：轨迹穿越他人领地边界", type: .error)
                        return CollisionResult(
                            hasCollision: true,
                            collisionType: .pathCrossTerritory,
                            message: "轨迹不能穿越他人领地！",
                            closestDistance: 0,
                            warningLevel: .violation
                        )
                    }
                }

                // 检查路径点是否在领地内
                if isPointInPolygon(point: pathEnd, polygon: polygon) {
                    TerritoryLogger.shared.log("路径碰撞：轨迹点进入他人领地", type: .error)
                    return CollisionResult(
                        hasCollision: true,
                        collisionType: .pointInTerritory,
                        message: "轨迹不能进入他人领地！",
                        closestDistance: 0,
                        warningLevel: .violation
                    )
                }
            }
        }

        return .safe
    }

    /// 计算当前位置到他人领地的最近距离
    func calculateMinDistanceToTerritories(location: CLLocationCoordinate2D, currentUserId: String) -> Double {
        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return Double.infinity }

        var minDistance = Double.infinity
        let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()

            for vertex in polygon {
                let vertexLocation = CLLocation(latitude: vertex.latitude, longitude: vertex.longitude)
                let distance = currentLocation.distance(from: vertexLocation)
                minDistance = min(minDistance, distance)
            }
        }

        return minDistance
    }

    /// 综合碰撞检测（主方法）
    func checkPathCollisionComprehensive(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 2 else { return .safe }

        // 1. 检查路径是否穿越他人领地
        let crossResult = checkPathCrossTerritory(path: path, currentUserId: currentUserId)
        if crossResult.hasCollision {
            return crossResult
        }

        // 2. 计算到最近领地的距离
        guard let lastPoint = path.last else { return .safe }
        let minDistance = calculateMinDistanceToTerritories(location: lastPoint, currentUserId: currentUserId)

        // 3. 根据距离确定预警级别和消息
        let warningLevel: WarningLevel
        let message: String?

        if minDistance > 100 {
            warningLevel = .safe
            message = nil
        } else if minDistance > 50 {
            warningLevel = .caution
            message = "注意：距离他人领地 \(Int(minDistance))m"
        } else if minDistance > 25 {
            warningLevel = .warning
            message = "警告：正在靠近他人领地（\(Int(minDistance))m）"
        } else {
            warningLevel = .danger
            message = "危险：即将进入他人领地！（\(Int(minDistance))m）"
        }

        if warningLevel != .safe {
            TerritoryLogger.shared.log("距离预警：\(warningLevel.description)，距离 \(Int(minDistance))m", type: .warning)
        }

        return CollisionResult(
            hasCollision: false,
            collisionType: nil,
            message: message,
            closestDistance: minDistance,
            warningLevel: warningLevel
        )
    }
}
