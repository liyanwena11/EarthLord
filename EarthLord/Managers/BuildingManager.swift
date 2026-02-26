//
//  BuildingManager.swift
//  EarthLord
//
//  建筑管理器 - 单例模式，使用 EarthLord Supabase 配置
//

import Foundation
import Supabase
import Combine
import CoreLocation

class BuildingManager: ObservableObject {

    static let shared = BuildingManager()

    @Published var buildingTemplates: [BuildingTemplate] = []
    @Published var playerBuildings: [PlayerBuilding] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient
    private var constructionCheckTimer: Timer?

    private init() {
        loadTemplates()
        startConstructionCheck()
        LogDebug("🏗️ [建筑] BuildingManager 初始化完成")
    }

    // MARK: - Template Loading

    func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "building_templates", withExtension: "json") else {
            LogError("❌ [建筑] 找不到 building_templates.json")
            errorMessage = "找不到建筑模板配置文件"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let templates = try JSONDecoder().decode([BuildingTemplate].self, from: data)
            DispatchQueue.main.async { self.buildingTemplates = templates }
            LogInfo("🏗️ [建筑] ✅ 加载 \(templates.count) 个建筑模板")
        } catch {
            LogError("❌ [建筑] 加载模板失败: \(error.localizedDescription)")
            DispatchQueue.main.async { self.errorMessage = "加载建筑模板失败: \(error.localizedDescription)" }
        }
    }

    // MARK: - Can Build Check

    /// 使用资源字典进行建造可行性检查
    func canBuild(
        template: BuildingTemplate,
        territoryId: String,
        playerResources: [String: Int]
    ) -> (canBuild: Bool, error: BuildingError?) {
        #if !DEBUG
        // 1. 资源检查（DEBUG 模式跳过，方便测试）
        var missingResources: [String: Int] = [:]
        for (resourceId, required) in template.requiredResources {
            let available = playerResources[resourceId] ?? 0
            if available < required {
                missingResources[resourceId] = required - available
            }
        }
        if !missingResources.isEmpty {
            return (false, .insufficientResources(missingResources))
        }
        #endif

        // 2. 数量上限检查
        let existingCount = playerBuildings.filter {
            $0.territoryId == territoryId && $0.templateId == template.templateId
        }.count
        if existingCount >= template.maxPerTerritory {
            return (false, .maxBuildingsReached(template.maxPerTerritory))
        }

        return (true, nil)
    }

    /// 使用背包展示项进行建造可行性检查（兼容已有调用）
    func canBuild(
        template: BuildingTemplate,
        territoryId: String,
        inventory: [InventoryDisplayItem]
    ) -> (canBuild: Bool, error: BuildingError?) {
        var resources: [String: Int] = [:]
        for item in inventory {
            resources[item.itemId, default: 0] += item.quantity
        }
        return canBuild(template: template, territoryId: territoryId, playerResources: resources)
    }

    // MARK: - Construction

    func startConstruction(templateId: String, territoryId: String, location: CLLocationCoordinate2D?) async throws {
        let userIdString = await MainActor.run { AuthManager.shared.currentUser?.id.uuidString }
        guard let userIdString, let userId = UUID(uuidString: userIdString) else {
            throw BuildingError.notConfigured
        }
        guard let template = buildingTemplates.first(where: { $0.templateId == templateId }) else {
            throw BuildingError.templateNotFound
        }

        // 1. 资源与数量检查（使用当前背包数据）
        let inventoryResources = await MainActor.run { InventoryManager.shared.aggregatedResources() }
        let check = canBuild(template: template, territoryId: territoryId, playerResources: inventoryResources)
        if !check.canBuild, let error = check.error {
            throw error
        }

        #if !DEBUG
        // 2. 扣除资源（DEBUG 模式跳过，方便测试）
        for (resourceId, amount) in template.requiredResources {
            try await InventoryManager.shared.removeItem(itemId: resourceId, quantity: amount)
        }
        #endif

        LogDebug("🏗️ [建筑] 开始建造: \(template.name)")
        let now = Date()
        let completedAt = now.addingTimeInterval(TimeInterval(template.buildTimeSeconds))

        let newBuilding = NewPlayerBuilding(
            user_id: userId,
            territory_id: territoryId,
            template_id: templateId,
            building_name: template.name,
            status: BuildingStatus.constructing.rawValue,
            level: 1,
            location_lat: location?.latitude,
            location_lon: location?.longitude,
            build_started_at: now,
            build_completed_at: completedAt
        )

        let inserted: PlayerBuilding = try await supabase
            .from("player_buildings")
            .insert(newBuilding)
            .select()
            .single()
            .execute()
            .value

        await MainActor.run { self.playerBuildings.append(inserted) }
        NotificationCenter.default.post(name: .buildingUpdated, object: nil)
        LogInfo("🏗️ [建筑] ✅ 建造开始: \(template.name)")
    }

    func completeConstruction(buildingId: UUID) async throws {
        guard let index = playerBuildings.firstIndex(where: { $0.id == buildingId }) else {
            throw BuildingError.buildingNotFound
        }
        guard playerBuildings[index].status == .constructing else {
            throw BuildingError.invalidStatus
        }

        let update = BuildingStatusUpdate(status: BuildingStatus.active.rawValue, updated_at: Date())
        try await supabase
            .from("player_buildings")
            .update(update)
            .eq("id", value: buildingId.uuidString)
            .execute()

        await MainActor.run {
            self.playerBuildings[index].status = .active
            self.playerBuildings[index].updatedAt = Date()
        }
        NotificationCenter.default.post(name: .buildingUpdated, object: nil)
        LogInfo("🏗️ [建筑] ✅ 建造完成: \(playerBuildings[index].buildingName)")
    }

    // MARK: - Upgrade

    /// 计算升级所需资源：简单采用「基础建造成本 × (当前等级 + 1)」的线性放大规则
    private func upgradeCost(for building: PlayerBuilding, template: BuildingTemplate) -> [String: Int] {
        let factor = building.level + 1
        var cost: [String: Int] = [:]
        for (resourceId, baseAmount) in template.requiredResources {
            cost[resourceId] = baseAmount * factor
        }
        return cost
    }

    func upgradeBuilding(buildingId: UUID) async throws {
        guard let index = playerBuildings.firstIndex(where: { $0.id == buildingId }) else {
            throw BuildingError.buildingNotFound
        }
        let building = playerBuildings[index]

        // 1. 状态检查：只有 active 才能升级
        guard building.status == .active else {
            throw BuildingError.invalidStatus
        }

        // 2. 模板 & 等级上限检查
        guard let template = getTemplate(for: building.templateId) else {
            throw BuildingError.templateNotFound
        }
        guard building.level < template.maxLevel else {
            throw BuildingError.maxLevelReached
        }

        // 3. 资源检查
        let cost = upgradeCost(for: building, template: template)
        #if !DEBUG
        let inventoryResources = await MainActor.run { InventoryManager.shared.aggregatedResources() }

        var missing: [String: Int] = [:]
        for (resourceId, required) in cost {
            let available = inventoryResources[resourceId] ?? 0
            if available < required {
                missing[resourceId] = required - available
            }
        }
        if !missing.isEmpty {
            throw BuildingError.insufficientResources(missing)
        }

        // 4. 扣除资源
        for (resourceId, amount) in cost {
            try await InventoryManager.shared.removeItem(itemId: resourceId, quantity: amount)
        }
        #endif

        // 5. 等级 +1 并写入数据库
        let newLevel = building.level + 1
        let update = BuildingLevelUpdate(level: newLevel, updated_at: Date())
        try await supabase
            .from("player_buildings")
            .update(update)
            .eq("id", value: buildingId.uuidString)
            .execute()

        await MainActor.run {
            self.playerBuildings[index].level = newLevel
            self.playerBuildings[index].updatedAt = Date()
        }
        NotificationCenter.default.post(name: .buildingUpdated, object: nil)
        LogInfo("🏗️ [建筑] ✅ 升级完成: \(building.buildingName) -> Lv.\(newLevel)")
    }

    func demolishBuilding(buildingId: UUID) async throws {
        guard let index = playerBuildings.firstIndex(where: { $0.id == buildingId }) else {
            throw BuildingError.buildingNotFound
        }
        let building = playerBuildings[index]
        try await supabase
            .from("player_buildings")
            .delete()
            .eq("id", value: buildingId.uuidString)
            .execute()

        _ = await MainActor.run { self.playerBuildings.remove(at: index); return index }
        NotificationCenter.default.post(name: .buildingUpdated, object: nil)
        LogInfo("🏗️ [建筑] ✅ 拆除完成: \(building.buildingName)")
    }

    // MARK: - Fetch

    func fetchPlayerBuildings(territoryId: String? = nil) async {
        let userIdString = await MainActor.run { AuthManager.shared.currentUser?.id.uuidString }
        guard let userIdString else { return }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        do {
            var query = supabase.from("player_buildings").select().eq("user_id", value: userIdString)
            if let tid = territoryId { query = query.eq("territory_id", value: tid) }

            let buildings: [PlayerBuilding] = try await query.execute().value
            await MainActor.run { self.playerBuildings = buildings; self.isLoading = false }
            await checkAndCompleteConstructions()
            LogInfo("🏗️ [建筑] ✅ 加载 \(buildings.count) 个建筑")
        } catch {
            LogError("❌ [建筑] 加载失败: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false; self.errorMessage = "加载建筑失败" }
        }
    }

    // MARK: - Construction Timer

    private func startConstructionCheck() {
        constructionCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { await self?.checkAndCompleteConstructions() }
        }
    }

    private func checkAndCompleteConstructions() async {
        let now = Date()
        let toComplete = playerBuildings.filter {
            $0.status == .constructing && ($0.buildCompletedAt ?? .distantFuture) <= now
        }
        for building in toComplete {
            try? await completeConstruction(buildingId: building.id)
        }
    }

    // MARK: - Helpers

    func getBuildingsForTerritory(_ territoryId: String) -> [PlayerBuilding] {
        playerBuildings.filter { $0.territoryId == territoryId }
    }

    func getTemplate(for templateId: String) -> BuildingTemplate? {
        buildingTemplates.first { $0.templateId == templateId }
    }

    func getTemplatesByCategory(_ category: BuildingCategory) -> [BuildingTemplate] {
        category == .all ? buildingTemplates : buildingTemplates.filter { $0.category == category }
    }

    func getBuildingCount(templateId: String, territoryId: String) -> Int {
        playerBuildings.filter { $0.territoryId == territoryId && $0.templateId == templateId }.count
    }

    deinit { constructionCheckTimer?.invalidate() }
}

extension Notification.Name {
    static let buildingUpdated = Notification.Name("buildingUpdated")
    static let territoryUpdated = Notification.Name("territoryUpdated")
    static let territoryDeleted = Notification.Name("territoryDeleted")
    static let territoryAdded = Notification.Name("territoryAdded")
}
