import Foundation
import CoreLocation
import Supabase
import Combine

@MainActor
class TerritoryManager: ObservableObject {
    static let shared = TerritoryManager()
    
    // ✅ 修复：直接使用项目里的全局 supabaseClient
    private let supabase = supabaseClient
    
    @Published var territories: [Territory] = []
    @Published var defenseBonusMultiplier: Double = 1.0  // Tier权益防御倍数
    
    private var currentTierBenefit: TierBenefit?  // 当前应用的Tier权益
    
    // MARK: - UI Display
    
    /// 当前防御加成百分比 (用于UI显示： 0%, 15% 等)
    var defenseBonus: Int {
        let bonus = (defenseBonusMultiplier - 1.0) * 100
        return Int(round(bonus))
    }
    
    /// 当前防御加成状态描述 (用于UI显示)
    var defenseBonusDescription: String {
        if defenseBonus <= 0 {
            return "基础防御"
        }
        return "+\(defenseBonus)% 防御"
    }
    
    var myTerritories: [Territory] {
        return territories
    }
    
    private init() {}

    /// 本地立即插入领地（用于圈地完成后的即时 UI 反馈）
    func addLocalTerritoryIfNeeded(_ territory: Territory) {
        if !territories.contains(where: { $0.id == territory.id }) {
            territories.append(territory)
        }
    }

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
    
    // MARK: - Tier Benefits
    
    func applyTerritoryBenefit(_ benefit: TierBenefit) {
        currentTierBenefit = benefit
        // 防御加成转换为倍数
        if benefit.defenseBonus > 0 {
            defenseBonusMultiplier = 1.0 + benefit.defenseBonus
        } else {
            defenseBonusMultiplier = 1.0
        }
        LogDebug("🏰 [领地] 应用Tier权益: 防御倍数 = \(defenseBonusMultiplier)")
    }
    
    func resetTerritoryBenefit() {
        currentTierBenefit = nil
        defenseBonusMultiplier = 1.0
        LogDebug("🏰 [领地] 重置Tier权益: 防御倍数 = 1.0")
    }
    
    // MARK: - Defense Calculation
    
    /// 计算防御伤害减免（应用Tier加成倍数）
    /// - Parameter incomingDamage: 来袭伤害值
    /// - Parameter baseDamageReduction: 基础防御减免比例 (默认 20%)
    /// - Returns: 实际应该受到的伤害值
    func calculateDefenseReduction(incomingDamage: Double, baseDamageReduction: Double = 0.2) -> Double {
        // 应用防御加成倍数到基础减免
        let actualReduction = baseDamageReduction * defenseBonusMultiplier
        
        // 伤害减免 (限制最大95%，最小0%)
        let cappedReduction = min(max(actualReduction, 0.0), 0.95)
        
        // 实际受到的伤害 = 来袭伤害 * (1 - 减免比例)
        let actualDamage = incomingDamage * (1.0 - cappedReduction)
        
        LogDebug("🛡️ [防御] 来袭:\(incomingDamage) | 减免:\(String(format: "%.1f", cappedReduction * 100))% | 实际:\(String(format: "%.1f", actualDamage))")
        
        return actualDamage
    }
    
    /// 获取当前防御减免比例（用于UI显示）
    /// - Parameter baseDamageReduction: 基础防御减免比例 (默认 20%)
    /// - Returns: 实际防御减免百分比 (0-95%)
    func getCurrentDefenseReduction(baseDamageReduction: Double = 0.2) -> Double {
        let actualReduction = baseDamageReduction * defenseBonusMultiplier
        return min(max(actualReduction, 0.0), 0.95) // 限制 0-95%
    }
}
