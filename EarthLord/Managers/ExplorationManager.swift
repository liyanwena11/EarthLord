import Foundation
import Combine
import Supabase

class ExplorationManager: ObservableObject {
    static let shared = ExplorationManager()

    // 背包物品
    @Published var backpackItems: [BackpackItem] = [] {
        didSet {
            if !isLoadingFromStorage { saveToLocal() }
        }
    }
    // 当前总重量
    @Published var totalWeight: Double = 0
    // 最大容量
    @Published var maxCapacity: Double = 100.0

    private let supabase = supabaseClient
    private static let localStorageKey = "EarthLord_BackpackItems"
    private var isLoadingFromStorage = false

    private init() {
        // 优先从本地加载（秒开）
        loadFromLocal()
        // 然后异步从 Supabase 同步（有网时覆盖本地）
        Task { @MainActor in
            await loadBackpackFromSupabase()
        }
    }

    // MARK: - 本地持久化（UserDefaults + JSON）

    /// 保存背包到本地
    private func saveToLocal() {
        do {
            let data = try JSONEncoder().encode(backpackItems)
            UserDefaults.standard.set(data, forKey: Self.localStorageKey)
            LogDebug("💾 [本地] 背包已保存，\(backpackItems.count) 种物品")
        } catch {
            LogError("❌ [本地] 保存背包失败：\(error)")
        }
    }

    /// 从本地加载背包
    private func loadFromLocal() {
        guard let data = UserDefaults.standard.data(forKey: Self.localStorageKey) else {
            LogDebug("📦 [本地] 无本地背包数据")
            return
        }
        do {
            isLoadingFromStorage = true
            let items = try JSONDecoder().decode([BackpackItem].self, from: data)
            self.backpackItems = items
            isLoadingFromStorage = false
            updateWeight()
            LogDebug("📦 [本地] 从本地加载 \(items.count) 种物品")
        } catch {
            isLoadingFromStorage = false
            LogError("❌ [本地] 加载背包失败：\(error)")
        }
    }

    // MARK: - Supabase Integration

    /// 从 Supabase 加载背包数据
    @MainActor
    private func loadBackpackFromSupabase() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            struct InventoryItem: Codable {
                let item_id: String
                let quantity: Int
            }

            let response: [InventoryItem] = try await supabase
                .from("inventory_items")
                .select("item_id, quantity")
                .eq("user_id", value: userId)
                .execute()
                .value

            // 将 Supabase 数据转换为 BackpackItem
            isLoadingFromStorage = true
            var newItems: [BackpackItem] = []
            for dbItem in response {
                guard let template = getItemTemplate(itemId: dbItem.item_id) else {
                    LogWarning("⚠️ 未知物品 ID: \(dbItem.item_id)")
                    continue
                }

                newItems.append(BackpackItem(
                    id: UUID().uuidString,
                    itemId: dbItem.item_id,
                    name: template.name,
                    category: template.category,
                    quantity: dbItem.quantity,
                    weight: template.weight,
                    quality: template.quality,
                    icon: template.icon
                ))
            }

            // ✅ 合并云端数据和本地数据（以云端为准，但保留本地独有的物品）
            let cloudItemIds = Set(newItems.map { $0.itemId })
            let localOnlyItems = self.backpackItems.filter { !cloudItemIds.contains($0.itemId) }
            self.backpackItems = newItems + localOnlyItems

            isLoadingFromStorage = false
            saveToLocal()
            updateWeight()
            LogDebug("📦 从云端加载 \(newItems.count) 种物品，合并本地 \(localOnlyItems.count) 种独有物品")
        } catch {
            isLoadingFromStorage = false
            LogError("❌ 加载背包数据失败：\(error.localizedDescription)，保留本地数据")
            // 不清空 - 保留本地数据
            updateWeight()
        }
    }

    /// 物品模板映射（根据 itemId 获取物品属性）
    private func getItemTemplate(itemId: String) -> (name: String, category: ItemCategory, weight: Double, quality: ItemQuality?, icon: String)? {
        let templates: [String: (String, ItemCategory, Double, ItemQuality?, String)] = [
            "water_001": ("矿泉水", .water, 0.5, nil, "drop.fill"),
            "food_001": ("罐头食品", .food, 0.3, .normal, "square.stack.3d.up.fill"),
            "food_002": ("压缩饼干", .food, 0.2, .good, "rectangle.compress.vertical"),
            "medical_001": ("绷带", .medical, 0.05, .normal, "cross.case.fill"),
            "medical_002": ("止痛药", .medical, 0.02, .good, "pills.fill"),
            "medical_003": ("抗生素", .medical, 0.03, .excellent, "syringe.fill"),
            "material_001": ("木材", .material, 1.5, .normal, "rectangle.stack.fill"),
            "material_002": ("废金属", .material, 2.0, .poor, "cube.fill"),
            "material_003": ("燃料罐", .material, 2.0, .normal, "fuelpump.fill"),
            "material_004": ("布料", .material, 0.5, .normal, "square.fill"),
            "tool_001": ("手电筒", .tool, 0.3, .good, "flashlight.on.fill"),
            "tool_002": ("绳子", .tool, 0.8, .normal, "link")
        ]

        guard let template = templates[itemId] else { return nil }
        return (template.0, template.1, template.2, template.3, template.4)
    }

    // MARK: - Core Methods

    // 核心方法：刷新重量
    func updateWeight() {
        self.totalWeight = backpackItems.reduce(0) { $0 + ($1.weight * Double($1.quantity)) }
        LogDebug("📝 系统：背包重量已更新为 \(self.totalWeight) kg")
    }
    
    // 核心方法：使用物品
    func useItem(item: BackpackItem) {
        if let index = backpackItems.firstIndex(where: { $0.id == item.id }) {
            if backpackItems[index].quantity > 1 {
                backpackItems[index].quantity -= 1
            } else {
                backpackItems.remove(at: index)
            }
            updateWeight()
            objectWillChange.send()
            LogDebug("🔧 [使用] \(item.name)，剩余 \(backpackItems.first(where: { $0.id == item.id })?.quantity ?? 0)")
        }
    }

    // MARK: - Day 20: 添加物品到背包

    /// 将探索获得的物品添加到背包
    /// - Parameter items: 要添加的物品列表
    /// - Returns: 成功添加的物品数量
    /// ✅ Day 22：确保在主线程上更新，触发 SwiftUI 实时刷新
    @MainActor
    @discardableResult
    func addItems(items: [BackpackItem]) -> Int {
        var addedCount = 0

        for newItem in items {
            // 检查背包中是否已有相同物品（通过 itemId 判断）
            if let index = backpackItems.firstIndex(where: { $0.itemId == newItem.itemId }) {
                // 相同物品：增加数量
                backpackItems[index].quantity += newItem.quantity
                LogDebug("📦 合并物品：\(newItem.name) +\(newItem.quantity)，现有 \(backpackItems[index].quantity)")
            } else {
                // 新物品：直接添加（生成新 ID 避免冲突）
                let itemToAdd = BackpackItem(
                    id: UUID().uuidString,
                    itemId: newItem.itemId,
                    name: newItem.name,
                    category: newItem.category,
                    quantity: newItem.quantity,
                    weight: newItem.weight,
                    quality: newItem.quality,
                    icon: newItem.icon,
                    backstory: newItem.backstory,
                    isAIGenerated: newItem.isAIGenerated,
                    itemRarity: newItem.itemRarity
                )
                backpackItems.append(itemToAdd)
                LogDebug("📦 新增物品：\(newItem.name) x\(newItem.quantity)")
            }
            addedCount += newItem.quantity
        }

        // ✅ 强制触发 objectWillChange 通知 SwiftUI 刷新
        objectWillChange.send()

        // 更新总重量
        updateWeight()
        LogDebug("🎒 背包更新完成，共添加 \(addedCount) 件物品，当前 \(backpackItems.count) 种物品")
        // ✅ 同步到 Supabase
        Task { @MainActor in
            await syncToSupabase(items: items)
        }

        return addedCount
    }

    /// 将物品同步到 Supabase
    @MainActor
    private func syncToSupabase(items: [BackpackItem]) async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            for item in items {
                struct InventoryUpsert: Encodable {
                    let user_id: String
                    let item_id: String
                    let name: String
                    let quantity: Int
                }

                // 获取当前背包中该物品的总数量
                let currentQuantity = backpackItems.first(where: { $0.itemId == item.itemId })?.quantity ?? 0

                let upsertData = InventoryUpsert(
                    user_id: userId,
                    item_id: item.itemId,
                    name: item.name,  // ✅ 添加 name 字段
                    quantity: currentQuantity
                )

                try await supabase
                    .from("inventory_items")
                    .upsert(upsertData)
                    .execute()

                LogDebug("☁️ 物品已存入云端：\(item.name) x\(currentQuantity)")
            }
        } catch {
            LogError("❌ Supabase 存储失败：\(error)")
        }
    }

    // MARK: - 探索会话管理

    /// 当前探索会话开始时间
    @Published var currentExplorationStartTime: Date?
    /// 当前探索会话的 POI（如果有）
    @Published var currentExplorationPOI: POIPoint?
    /// 当前探索会话的行走距离（米）
    @Published var currentExplorationDistance: Double = 0
    /// 发现的 POI 数量
    @Published var discoveredPOICount: Int = 0

    /// 开始探索会话
    @MainActor
    func startExplorationSession(poi: POIPoint? = nil) {
        currentExplorationStartTime = Date()
        currentExplorationPOI = poi
        currentExplorationDistance = 0
        discoveredPOICount = 0
        LogDebug("🚩 [探索] 开始探索会话 \(poi.map { "（POI: \($0.name))" } ?? "（自由探索）")")
    }

    /// 完成探索会话并记录到后端
    @MainActor
    func completeExplorationSession(itemsFound: [BackpackItem], walkDistance: Double? = nil) async -> ExplorationResult? {
        guard let startTime = currentExplorationStartTime else {
            LogError("❌ [探索] 没有活动的探索会话")
            return nil
        }

        let duration = Date().timeIntervalSince(startTime)
        let finalDistance = walkDistance ?? currentExplorationDistance

        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            // 准备探索会话数据
            struct LootedItem: Encodable {
                let item_id: String
                let name: String
                let quantity: Int
                let category: String
                let quality: String?
            }

            struct ExplorationSessionRecord: Encodable {
                let user_id: String
                let poi_id: String?
                let started_at: String
                let duration_seconds: Int
                let items_looted: [LootedItem]
                // 移除 completed_at - 数据库表中没有此字段
            }

            // 物品数据转为 JSON
            let itemsJson = itemsFound.map { item -> LootedItem in
                LootedItem(
                    item_id: item.itemId,
                    name: item.name,
                    quantity: item.quantity,
                    category: item.category.rawValue,
                    quality: item.quality?.rawValue
                )
            }

            let formatter = ISO8601DateFormatter()
            let record = ExplorationSessionRecord(
                user_id: userId,
                poi_id: currentExplorationPOI?.id,
                started_at: formatter.string(from: startTime),
                duration_seconds: Int(duration),
                items_looted: itemsJson
            )

            // 保存到 Supabase
            do {
                try await supabase
                    .from("exploration_sessions")
                    .insert(record)
                    .execute()
                LogInfo("☁️ [探索] 探索会话已保存到云端")
            } catch {
                LogError("❌ [探索] 保存探索会话失败: \(error.localizedDescription)")
                // 不中断流程，继续执行
            }
            LogDebug("   - 时长: \(Int(duration))秒")
            LogDebug("   - 距离: \(Int(finalDistance))米")
            LogDebug("   - 物品: \(itemsFound.count)种")
            LogDebug("   - POI: \(currentExplorationPOI?.name ?? "无")")

            // 创建探索结果
            let result = ExplorationResult(
                walkDistance: finalDistance,
                totalWalkDistance: finalDistance, // TODO: 累计距离需要从数据库加载
                walkRanking: 0, // TODO: 排名需要查询
                exploredArea: 0, // 探索模式没有面积
                totalExploredArea: 0,
                areaRanking: 0,
                duration: duration,
                itemsFound: itemsFound,
                poisDiscovered: discoveredPOICount,
                experienceGained: itemsFound.count * 10 // 每个物品10点经验
            )

            // 清理会话状态
            currentExplorationStartTime = nil
            currentExplorationPOI = nil
            currentExplorationDistance = 0

            return result

        } catch {
            LogError("❌ [探索] 保存探索会话失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Day 22：POI 冷却机制

    /// 检查 POI 是否可以搜刮（24 小时冷却）
    @MainActor
    func canLootPOI(_ poiId: String) async -> Bool {
        do {
            struct POICooldown: Decodable {
                let cooldown_until: String?
            }

            let response: [POICooldown] = try await supabase
                .from("pois")
                .select("cooldown_until")
                .eq("id", value: poiId)
                .execute()
                .value

            guard let cooldownString = response.first?.cooldown_until,
                  let cooldownDate = ISO8601DateFormatter().date(from: cooldownString) else {
                return true  // 没有冷却记录，可以搜刮
            }

            let canLoot = Date() > cooldownDate
            if !canLoot {
                LogDebug("⏱️ [冷却] POI \(poiId) 冷却中，剩余时间：\(Int(cooldownDate.timeIntervalSinceNow / 60)) 分钟")
            }
            return canLoot
        } catch {
            LogError("❌ [冷却] 检查冷却失败：\(error.localizedDescription)")
            return true  // 出错时允许搜刮
        }
    }

    /// 记录 POI 搜刮并设置冷却
    @MainActor
    func recordPOILoot(poiId: String, items: [BackpackItem]) async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString

            // 设置 24 小时冷却
            let cooldownUntil = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!

            // 更新 POI 冷却时间
            struct POIUpdate: Encodable {
                let last_looted_by: String
                let last_looted_at: String
                let cooldown_until: String
            }

            let formatter = ISO8601DateFormatter()
            let update = POIUpdate(
                last_looted_by: userId,
                last_looted_at: formatter.string(from: Date()),
                cooldown_until: formatter.string(from: cooldownUntil)
            )

            try await supabase
                .from("pois")
                .update(update)
                .eq("id", value: poiId)
                .execute()

            // 记录探索会话
            struct ExplorationSession: Encodable {
                let user_id: String
                let poi_id: String
                let items_looted: String
                // 移除 completed_at - 数据库表中没有此字段
            }

            let itemsJson = items.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", ")

            let sessionRecord = ExplorationSession(
                user_id: userId,
                poi_id: poiId,
                items_looted: itemsJson
            )

            try await supabase
                .from("exploration_sessions")
                .insert(sessionRecord)
                .execute()

            LogDebug("☁️ [冷却] POI 搜刮记录已存入云端，冷却 24 小时")
        } catch {
            LogError("❌ [冷却] 记录搜刮失败：\(error.localizedDescription)")
        }
    }

    /// 清空背包（测试专用）
    func clearBackpackForTesting() {
        backpackItems.removeAll()
        updateWeight()
        LogDebug("🗑️ 背包已清空")
    }

    /// 清空背包（兼容旧调用）
    @available(*, deprecated, message: "仅用于测试，生产环境请使用真实探索流程")
    func clearBackpack() {
        clearBackpackForTesting()
    }

    // MARK: - Day 20 完善：根据 POI 类型生成随机掉落物品

    /// 根据 POI 类型生成 1-3 件随机物品
    /// - Parameter poiType: POI 类型
    /// - Returns: 生成的物品数组
    func generateLoot(for poiType: POIType) -> [BackpackItem] {
        // 根据 POI 类型定义可能掉落的物品池
        let lootTable: [POIType: [(itemId: String, name: String, category: ItemCategory, weight: Double, icon: String)]] = [
            .supermarket: [
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
                ("food_002", "压缩饼干", .food, 0.2, "rectangle.compress.vertical")
            ],
            .hospital: [
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill")
            ],
            .pharmacy: [
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill")
            ],
            .gasStation: [
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill")
            ],
            .factory: [
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
                ("material_002", "废金属", .material, 2.0, "cube.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link")
            ],
            .warehouse: [
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link")
            ],
            .school: [
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("material_004", "布料", .material, 0.5, "square.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill")
            ]
        ]

        // 获取该类型的掉落池，默认使用超市
        let pool = lootTable[poiType] ?? lootTable[.supermarket]!

        // 随机生成 1-3 件物品
        let itemCount = Int.random(in: 1...3)
        var generatedItems: [BackpackItem] = []

        for _ in 0..<itemCount {
            let randomIndex = Int.random(in: 0..<pool.count)
            let template = pool[randomIndex]
            let quantity = Int.random(in: 1...3)

            // 随机品质
            let qualities: [ItemQuality] = [.poor, .normal, .good, .excellent]
            let quality = qualities.randomElement()

            let item = BackpackItem(
                id: UUID().uuidString,
                itemId: template.itemId,
                name: template.name,
                category: template.category,
                quantity: quantity,
                weight: template.weight,
                quality: quality,
                icon: template.icon
            )
            generatedItems.append(item)
        }

        LogDebug("🎲 生成掉落物品：\(generatedItems.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
        return generatedItems
    }
}
