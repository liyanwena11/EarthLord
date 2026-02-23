import Foundation
import CoreLocation
import Supabase

class TerritoryManager {
    static let shared = TerritoryManager()
    
    // ✅ 修复：直接使用项目里的全局 supabaseClient
    private let supabase = supabaseClient
    
    var territories: [Territory] = []
    
    private init() {}

    func loadAllTerritories() async throws -> [Territory] {
        let response: [Territory] = try await supabase
            .from("territories")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value
        self.territories = response
        return response
    }

    func loadMyTerritories() async throws -> [Territory] {
        // 先拉取所有活跃领地用于测试显示
        return try await loadAllTerritories()
    }

    func deleteTerritory(territoryId: String) async -> Bool {
        do {
            try await supabase.from("territories").update(["is_active": false]).eq("id", value: territoryId).execute()
            NotificationCenter.default.post(name: .territoryDeleted, object: UUID(uuidString: territoryId))
            return true
        } catch {
            return false
        }
    }
    
    func updateTerritoryName(territoryId: String, newName: String) async -> Bool {
        do {
            try await supabase.from("territories")
                .update(["name": newName])
                .eq("id", value: territoryId)
                .execute()
            return true
        } catch {
            LogDebug(" ❌ 重命名失败: \(error.localizedDescription)")
            return false
        }
    }

    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        let session = try await supabaseClient.auth.session
        let userId = session.user.id.uuidString

        // 准备路径数据
        let path = coordinates.map { point in
            return ["lat": point.latitude, "lon": point.longitude]
        }

        // 准备上传数据
        struct TerritoryUpload: Encodable {
            let user_id: String
            let path: [[String: Double]]
            let area: Double
            let point_count: Int
            let started_at: String
            let completed_at: String
            let created_at: String
        }

        let formatter = ISO8601DateFormatter()
        let uploadData = TerritoryUpload(
            user_id: userId,
            path: path,
            area: area,
            point_count: coordinates.count,
            started_at: formatter.string(from: startTime),
            completed_at: formatter.string(from: Date()),
            created_at: formatter.string(from: Date())
        )

        // 上传到 Supabase
        try await supabase
            .from("territories")
            .insert(uploadData)
            .execute()

        LogDebug(" ✅ 领地上传成功，面积: \(area)㎡，点数: \(coordinates.count)")

        // 发送通知，刷新领地列表
        NotificationCenter.default.post(name: .territoryUpdated, object: nil)
    }
}

