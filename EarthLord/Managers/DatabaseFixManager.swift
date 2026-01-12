import Foundation
import Supabase
import CoreLocation

/// Database Fix Manager - 用于修复数据库结构和插入测试数据
class DatabaseFixManager {
    static let shared = DatabaseFixManager()
    private let supabase = supabaseClient

    private init() {}

    // MARK: - Payload Structures

    /// Profile insert payload
    private struct ProfilePayload: Encodable {
        let id: UUID
        let email: String
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case createdAt = "created_at"
        }
    }

    /// Territory insert payload for database fix
    private struct TerritoryPayload: Encodable {
        let userId: UUID
        let name: String
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
            case name
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

    // MARK: - Task 1: Sync Profiles Table

    /// 检查并同步当前用户到 profiles 表
    func syncUserToProfiles() async throws {
        // 获取当前用户
        let session = try await supabase.auth.session
        let userId = session.user.id
        let userEmail = session.user.email ?? ""

        print("=== Syncing User to Profiles ===")
        print("User ID: \(userId)")
        print("User Email: \(userEmail)")

        // 检查用户是否已存在于 profiles 表
        let checkQuery = """
        SELECT id FROM profiles WHERE id = '\(userId.uuidString)'
        """

        do {
            let result: [[String: String]] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value

            if result.isEmpty {
                print("User not found in profiles, inserting...")

                // 插入用户到 profiles 表
                let profile = ProfilePayload(
                    id: userId,
                    email: userEmail,
                    createdAt: Date().ISO8601Format()
                )

                try await supabase
                    .from("profiles")
                    .insert(profile)
                    .execute()

                print("✅ User synced to profiles table!")
                TerritoryLogger.shared.log("User synced to profiles table", type: .success)
            } else {
                print("✅ User already exists in profiles")
                TerritoryLogger.shared.log("User already exists in profiles", type: .info)
            }
        } catch {
            print("⚠️ Profiles table may not exist or different structure")
            TerritoryLogger.shared.log("Profiles sync skipped: \(error.localizedDescription)", type: .warning)
        }
    }

    // MARK: - Task 2: Fix Database Constraints

    /// 弱化 territories 表的约束
    func fixTerritoryConstraints() async throws {
        print("=== Fixing Territory Constraints ===")

        // 尝试删除 NOT NULL 约束
        let sql1 = "ALTER TABLE territories ALTER COLUMN user_id DROP NOT NULL;"

        do {
            try await supabase.rpc("exec_sql", params: ["query": sql1]).execute()
            print("✅ Removed NOT NULL constraint from user_id")
            TerritoryLogger.shared.log("NOT NULL constraint removed", type: .success)
        } catch {
            print("⚠️ Could not remove NOT NULL constraint: \(error.localizedDescription)")
            TerritoryLogger.shared.log("Constraint fix skipped: \(error.localizedDescription)", type: .warning)
        }

        // 尝试弱化外键约束（改为 ON DELETE SET NULL）
        let sql2 = """
        ALTER TABLE territories
        DROP CONSTRAINT IF EXISTS territories_user_id_fkey;

        ALTER TABLE territories
        ADD CONSTRAINT territories_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE SET NULL;
        """

        do {
            try await supabase.rpc("exec_sql", params: ["query": sql2]).execute()
            print("✅ Weakened foreign key constraint")
            TerritoryLogger.shared.log("Foreign key constraint weakened", type: .success)
        } catch {
            print("⚠️ Could not weaken foreign key: \(error.localizedDescription)")
            TerritoryLogger.shared.log("FK constraint fix skipped: \(error.localizedDescription)", type: .warning)
        }
    }

    // MARK: - Task 3: Insert Chengdu Test Territory

    /// 插入龙泉驿桃花源别墅测试领地
    func insertChengduTestTerritory() async throws {
        print("=== Inserting Chengdu Test Territory ===")

        // 获取当前用户 ID
        let session = try await supabase.auth.session
        let userId = session.user.id

        print("User ID: \(userId)")

        // 龙泉驿桃花源别墅坐标：30.565, 104.265
        // 创建边长约 50 米的正方形（约 0.00045 度）
        let centerLat = 30.565
        let centerLon = 104.265
        let offset = 0.00022  // 约 25 米

        let coordinates = [
            ["lat": centerLat - offset, "lon": centerLon - offset],  // 西南角
            ["lat": centerLat + offset, "lon": centerLon - offset],  // 西北角
            ["lat": centerLat + offset, "lon": centerLon + offset],  // 东北角
            ["lat": centerLat - offset, "lon": centerLon + offset],  // 东南角
            ["lat": centerLat - offset, "lon": centerLon - offset]   // 闭合
        ]

        // 创建 WKT 格式的多边形
        let wktCoords = coordinates.map { point in
            "\(point["lon"]!) \(point["lat"]!)"
        }.joined(separator: ", ")

        let wktPolygon = "SRID=4326;POLYGON((\(wktCoords)))"

        // 计算边界框
        let lats = coordinates.map { $0["lat"]! }
        let lons = coordinates.map { $0["lon"]! }

        let payload = TerritoryPayload(
            userId: userId,
            name: "龙泉驿桃花源别墅测试领地",
            path: coordinates,
            polygon: wktPolygon,
            bboxMinLat: lats.min()!,
            bboxMaxLat: lats.max()!,
            bboxMinLon: lons.min()!,
            bboxMaxLon: lons.max()!,
            area: 2500.0,
            pointCount: coordinates.count,
            startedAt: Date().ISO8601Format(),
            isActive: true
        )

        print("Payload prepared:")
        print("- Name: 龙泉驿桃花源别墅测试领地")
        print("- Center: \(centerLat), \(centerLon)")
        print("- Area: 2500m²")
        print("- Points: \(coordinates.count)")

        try await supabase
            .from("territories")
            .insert(payload)
            .execute()

        print("✅ Test territory inserted successfully!")
        TerritoryLogger.shared.log("龙泉驿测试领地已插入", type: .success)
    }

    // MARK: - Complete Fix Flow

    /// 执行完整的修复流程
    func executeCompleteFixFlow() async throws {
        print("\n" + String(repeating: "=", count: 50))
        print("开始执行数据库修复流程")
        print(String(repeating: "=", count: 50) + "\n")

        // Step 1: 同步用户到 profiles
        print("📋 Step 1: 同步用户到 profiles 表")
        try await syncUserToProfiles()
        print("")

        // Step 2: 修复约束（可能会失败，继续执行）
        print("🔧 Step 2: 尝试修复 territories 表约束")
        try? await fixTerritoryConstraints()
        print("")

        // Step 3: 插入测试数据
        print("📍 Step 3: 插入龙泉驿测试领地")
        try await insertChengduTestTerritory()
        print("")

        print(String(repeating: "=", count: 50))
        print("✅ 数据库修复流程完成！")
        print("请重启 App 并进入地图页面查看龙泉驿的测试领地")
        print(String(repeating: "=", count: 50) + "\n")
    }
}
