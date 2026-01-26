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
            return true
        } catch {
            return false
        }
    }
    
    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        // 上传逻辑占位
    }
}
