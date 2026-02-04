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
            print("💾 [本地] 背包已保存，\(backpackItems.count) 种物品")
        } catch {
            print("❌ [本地] 保存背包失败：\(error)")
        }
    }

    /// 从本地加载背包
    private func loadFromLocal() {
        guard let data = UserDefaults.standard.data(forKey: Self.localStorageKey) else {
            print("📦 [本地] 无本地背包数据")
            return
        }
        do {
            isLoadingFromStorage = true
            let items = try JSONDecoder().decode([BackpackItem].self, from: data)
            self.backpackItems = items
            isLoadingFromStorage = false
            updateWeight()
            print("📦 [本地] 从本地加载 \(items.count) 种物品")
        } catch {
            isLoadingFromStorage = false
            print("❌ [本地] 加载背包失败：\(error)")
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
            self.backpackItems = response.compactMap { dbItem in
                guard let template = getItemTemplate(itemId: dbItem.item_id) else {
                    print("⚠️ 未知物品 ID: \(dbItem.item_id)")
                    return nil
                }

                return BackpackItem(
                    id: UUID().uuidString,
                    itemId: dbItem.item_id,
                    name: template.name,
                    category: template.category,
                    quantity: dbItem.quantity,
                    weight: template.weight,
                    quality: template.quality,
                    icon: template.icon
                )
            }

            isLoadingFromStorage = false
            saveToLocal()
            updateWeight()
            print("📦 从云端加载 \(backpackItems.count) 种物品")
        } catch {
            isLoadingFromStorage = false
            print("❌ 加载背包数据失败：\(error.localizedDescription)，使用本地数据")
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
        print("📝 系统：背包重量已更新为 \(self.totalWeight) kg")
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
            print("🔧 [使用] \(item.name)，剩余 \(backpackItems.first(where: { $0.id == item.id })?.quantity ?? 0)")
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
                print("📦 合并物品：\(newItem.name) +\(newItem.quantity)，现有 \(backpackItems[index].quantity)")
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
                print("📦 新增物品：\(newItem.name) x\(newItem.quantity)")
            }
            addedCount += newItem.quantity
        }

        // ✅ 强制触发 objectWillChange 通知 SwiftUI 刷新
        objectWillChange.send()

        // 更新总重量
        updateWeight()
        print("🎒 背包更新完成，共添加 \(addedCount) 件物品，当前 \(backpackItems.count) 种物品")

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
                    let quantity: Int
                }

                // 获取当前背包中该物品的总数量
                let currentQuantity = backpackItems.first(where: { $0.itemId == item.itemId })?.quantity ?? 0

                let upsertData = InventoryUpsert(
                    user_id: userId,
                    item_id: item.itemId,
                    quantity: currentQuantity
                )

                try await supabase
                    .from("inventory_items")
                    .upsert(upsertData)
                    .execute()

                print("☁️ 物品已存入云端：\(item.name) x\(currentQuantity)")
            }
        } catch {
            print("❌ Supabase 存储失败：\(error)")
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
                print("⏱️ [冷却] POI \(poiId) 冷却中，剩余时间：\(Int(cooldownDate.timeIntervalSinceNow / 60)) 分钟")
            }
            return canLoot
        } catch {
            print("❌ [冷却] 检查冷却失败：\(error.localizedDescription)")
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
                let completed_at: String
            }

            let itemsJson = items.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", ")

            let sessionRecord = ExplorationSession(
                user_id: userId,
                poi_id: poiId,
                items_looted: itemsJson,
                completed_at: formatter.string(from: Date())
            )

            try await supabase
                .from("exploration_sessions")
                .insert(sessionRecord)
                .execute()

            print("☁️ [冷却] POI 搜刮记录已存入云端，冷却 24 小时")
        } catch {
            print("❌ [冷却] 记录搜刮失败：\(error.localizedDescription)")
        }
    }

    /// 清空背包（测试用）
    @available(*, deprecated, message: "仅用于测试，生产环境请使用真实探索流程")
    func clearBackpack() {
        backpackItems.removeAll()
        updateWeight()
        print("🗑️ 背包已清空")
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

        print("🎲 生成掉落物品：\(generatedItems.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
        return generatedItems
    }
}
