import SwiftUI
import CoreLocation
import UIKit
import Supabase

class EarthLordEngine: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = EarthLordEngine()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var survivorTimer: Timer?
    private var respawnTimer: Timer?

    // MARK: - 基础状态
    @Published var userLocation: CLLocation?
    @Published var nearbyPOIs: [POIModel] = []
    @Published var claimedTerritories: [TerritoryModel] = []
    @Published var nearbyPlayerCount: Int = 0
    @Published var activePOI: POIModel?
    @Published var showProximityAlert: Bool = false
    @Published var isExploring: Bool = false
    @Published var exploringStatusText: String = ""

    // MARK: - 采样圈地状态
    @Published var isTracking: Bool = false              // 是否正在圈地
    @Published var pathPoints: [CLLocation] = []         // 采样轨迹点
    @Published var trackingDistance: Double = 0           // 已行走距离（米）
    @Published var estimatedArea: Double = 0             // 预估面积（㎡）
    @Published var trackingStatusText: String = ""       // 顶部状态文字

    /// 动态采样点需求：负重 > 80kg 时从 5 增加到 8
    var requiredSamplingPoints: Int {
        let weight = ExplorationManager.shared.totalWeight
        if weight > 80 {
            return 8
        }
        return GameConfig.SAMPLING_MIN_POINTS
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        print("🚀 [Engine] EarthLordEngine 初始化完成")

        survivorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateSurvivorCount() }
        }
        respawnTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkRespawns() }
        }
    }

    deinit {
        survivorTimer?.invalidate()
        respawnTimer?.invalidate()
    }

    // MARK: - 幸存者扫描

    @MainActor
    private func updateSurvivorCount() {
        self.isExploring = true
        self.exploringStatusText = "正在扫描周边信号..."
        self.nearbyPlayerCount = Int.random(in: 1...30)
        print("📡 [探索] 雷达扫描中... 检测到 \(nearbyPlayerCount) 名幸存者")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isExploring = false
            self?.exploringStatusText = ""
        }
    }

    // MARK: - POI 刷新

    @MainActor
    private func checkRespawns() {
        var refreshed = 0
        for index in nearbyPOIs.indices {
            if nearbyPOIs[index].isScavenged && nearbyPOIs[index].canScavengeAgain {
                nearbyPOIs[index].isScavenged = false
                nearbyPOIs[index].lastScavengedAt = nil
                refreshed += 1
            }
        }
        if refreshed > 0 {
            print("🔄 [刷新] \(refreshed) 个 POI 已刷新")
        }
    }

    // MARK: - ========== 采样行走圈地 ==========

    /// 开始圈地：清空旧路径，进入采样模式
    @MainActor
    func startTracking() {
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0
        isTracking = true
        trackingStatusText = "开始圈地，请行走采集轨迹..."
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        print("🚩 [圈地] ========== 开始采样行走 ==========")

        // 立即记录第一个点
        if let loc = userLocation {
            pathPoints.append(loc)
            print("📌 [采样] 起点: (\(String(format: "%.5f", loc.coordinate.latitude)), \(String(format: "%.5f", loc.coordinate.longitude)))")
        }
    }

    /// 停止圈地（取消）
    @MainActor
    func stopTracking() {
        isTracking = false
        trackingStatusText = ""
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0
        print("🛑 [圈地] 已取消圈地")
    }

    /// GPS 回调中调用：采样逻辑
    @MainActor
    private func handleTrackingSample(_ location: CLLocation) {
        guard isTracking else { return }

        // 精度过滤
        if location.horizontalAccuracy > 50 {
            print("⚠️ [采样] 精度差 \(String(format: "%.0f", location.horizontalAccuracy))m，跳过")
            return
        }

        // 距离过滤：距上一个采样点 ≥ 10m 才记录
        if let lastPoint = pathPoints.last {
            let dist = location.distance(from: lastPoint)
            if dist < GameConfig.SAMPLING_MIN_DISTANCE { return }

            // 跳点过滤：单步 > 200m 视为异常
            if dist > 200 {
                print("⚠️ [采样] 跳点 \(String(format: "%.0f", dist))m，丢弃")
                return
            }

            trackingDistance += dist
        }

        pathPoints.append(location)
        estimatedArea = calculatePolygonArea(pathPoints)

        let pointCount = pathPoints.count
        let needed = requiredSamplingPoints
        let weightPenalty = needed > GameConfig.SAMPLING_MIN_POINTS ? " [负重惩罚]" : ""
        trackingStatusText = "采样 \(pointCount)/\(needed)\(weightPenalty) · 距离 \(Int(trackingDistance))m · 面积 \(Int(estimatedArea))㎡"

        print("📌 [采样] 第\(pointCount)点 移动距离: \(String(format: "%.1f", trackingDistance))m")
        print("📐 [面积] 当前闭合面积: \(String(format: "%.1f", estimatedArea))㎡")

        // 达到最少采样点数 → 自动完成圈地
        if pointCount >= needed {
            finishTracking()
        }
    }

    /// 完成圈地：生成领地
    @MainActor
    private func finishTracking() {
        guard pathPoints.count >= 3 else { return }

        let area = calculatePolygonArea(pathPoints)

        // 计算中心点
        let centerLat = pathPoints.map { $0.coordinate.latitude }.reduce(0, +) / Double(pathPoints.count)
        let centerLon = pathPoints.map { $0.coordinate.longitude }.reduce(0, +) / Double(pathPoints.count)

        var newTerritory = TerritoryModel(
            id: UUID(),
            lat: centerLat,
            lon: centerLon,
            claimedAt: Date(),
            name: "领地 #\(claimedTerritories.count + 1)",
            area: area,
            pointCount: pathPoints.count,
            pathLatitudes: pathPoints.map { $0.coordinate.latitude },
            pathLongitudes: pathPoints.map { $0.coordinate.longitude }
        )

        // 重度震动反馈
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        print("🚩 [圈地] ✅ 领地确认！面积: \(String(format: "%.1f", area))㎡，采样点: \(pathPoints.count)")

        // 地理逆编码获取街道名
        let centerLocation = CLLocation(latitude: centerLat, longitude: centerLon)
        geocoder.reverseGeocodeLocation(centerLocation) { [weak self] placemarks, error in
            Task { @MainActor in
                if let placemark = placemarks?.first {
                    let street = placemark.thoroughfare ?? placemark.name ?? placemark.subLocality ?? ""
                    let district = placemark.subLocality ?? placemark.locality ?? ""
                    let geocodedName = street.isEmpty ? district : street
                    if !geocodedName.isEmpty {
                        // 更新领地名称
                        if let index = self?.claimedTerritories.firstIndex(where: { $0.id == newTerritory.id }) {
                            self?.claimedTerritories[index].name = geocodedName
                            print("🏷️ [圈地] 领地命名为: \(geocodedName)")
                        }
                    }
                }
            }
        }

        self.claimedTerritories.append(newTerritory)

        // 重置状态
        isTracking = false
        trackingStatusText = "圈地完成！面积 \(Int(area))㎡"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.trackingStatusText = ""
        }
        pathPoints.removeAll()
        trackingDistance = 0
        estimatedArea = 0
    }

    /// 强制完成圈地（调试用 / 手动闭合）
    @MainActor
    func forceFinishTracking() {
        guard isTracking, pathPoints.count >= 3 else {
            print("🧪 [调试] 采样点不足 3 个，无法强制完成")
            return
        }
        print("🧪 [调试] 强制完成圈地，当前 \(pathPoints.count) 个点")
        finishTracking()
    }

    // MARK: - 多边形面积计算（Shoelace 公式 + 经纬度→米换算）

    private func calculatePolygonArea(_ points: [CLLocation]) -> Double {
        guard points.count >= 3 else { return 0 }

        // 以第一个点为原点，将经纬度转为平面米坐标
        let origin = points[0].coordinate
        let metersPerDegreeLat = 111320.0
        let metersPerDegreeLon = 111320.0 * cos(origin.latitude * .pi / 180)

        let xyPoints = points.map { p -> (x: Double, y: Double) in
            let x = (p.coordinate.longitude - origin.longitude) * metersPerDegreeLon
            let y = (p.coordinate.latitude - origin.latitude) * metersPerDegreeLat
            return (x, y)
        }

        // Shoelace 公式
        var area: Double = 0
        let n = xyPoints.count
        for i in 0..<n {
            let j = (i + 1) % n
            area += xyPoints[i].x * xyPoints[j].y
            area -= xyPoints[j].x * xyPoints[i].y
        }
        return abs(area) / 2.0
    }

    // MARK: - GPS 位置更新

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location
            self.checkProximity(location)
            self.handleTrackingSample(location)
        }
    }

    // MARK: - POI 接近检测

    @MainActor
    private func checkProximity(_ current: CLLocation) {
        let found = nearbyPOIs.first {
            !$0.isScavenged && current.distance(from: $0.location) <= GameConfig.POI_TRIGGER_RADIUS
        }
        if let target = found {
            if activePOI?.id != target.id {
                self.activePOI = target
                self.showProximityAlert = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                print("🎯 [搜刮] 进入 POI 范围：\(target.name)（\(target.rarity.rawValue)）")
            }
        } else {
            if showProximityAlert {
                self.showProximityAlert = false
                self.activePOI = nil
            }
        }
    }

    // MARK: - 搜刮

    @MainActor
    func scavenge() {
        guard let poi = activePOI else { return }
        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
            print("📦 [搜刮] 已搜刮 POI：\(poi.name)")
        }
        self.showProximityAlert = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// 搜刮状态
    @Published var isScavenging: Bool = false
    @Published var lastScavengeResult: [BackpackItem] = []

    /// 搜刮并生成掉落物品（同步版本，用预设掉落表）
    @MainActor
    func scavengeWithLoot() -> [BackpackItem] {
        guard let poi = activePOI else { return [] }

        let backpack = ExplorationManager.shared
        if backpack.totalWeight >= backpack.maxCapacity {
            print("⚠️ [搜刮] 背包已满，无法搜刮")
            return []
        }

        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
        }
        self.showProximityAlert = false

        let items = generateLootByRarity(poi.rarity)
        backpack.addItems(items: items)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        print("📦 [搜刮] 在「\(poi.name)」(\(poi.rarity.rawValue)) 获得：\(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")

        return items
    }

    /// AI 搜刮：调用 Edge Function 生成独特物品（异步）
    @MainActor
    func scavengeWithAI() async -> [BackpackItem] {
        guard let poi = activePOI else { return [] }

        let backpack = ExplorationManager.shared
        if backpack.totalWeight >= backpack.maxCapacity {
            print("⚠️ [搜刮] 背包已满，无法搜刮")
            return []
        }

        isScavenging = true

        // 标记 POI 已搜刮
        if let index = nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            nearbyPOIs[index].isScavenged = true
            nearbyPOIs[index].lastScavengedAt = Date()
        }
        self.showProximityAlert = false

        // 调用 AI 生成（内含静默降级）
        let items = await AIItemGenerator.shared.generateItems(for: poi)

        // 存入背包
        backpack.addItems(items: items)

        // 同步到 Supabase user_inventory
        Task {
            await syncScavengeToSupabase(poi: poi, items: items)
        }

        isScavenging = false
        lastScavengeResult = items
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        print("🤖 [AI搜刮] 在「\(poi.name)」获得：\(items.map { $0.name }.joined(separator: ", "))")

        return items
    }

    /// 同步搜刮结果到 Supabase
    @MainActor
    private func syncScavengeToSupabase(poi: POIModel, items: [BackpackItem]) async {
        do {
            let session = try await supabaseClient.auth.session
            let userId = session.user.id.uuidString

            struct InventoryRecord: Encodable {
                let user_id: String
                let item_name: String
                let item_rarity: String
                let weight: Double
                let backstory: String?
                let is_ai_generated: Bool
                let source_poi: String
                let created_at: String
            }

            let formatter = ISO8601DateFormatter()
            for item in items {
                let record = InventoryRecord(
                    user_id: userId,
                    item_name: item.name,
                    item_rarity: item.itemRarity?.rawValue ?? "普通",
                    weight: item.weight,
                    backstory: item.backstory,
                    is_ai_generated: item.isAIGenerated,
                    source_poi: poi.name,
                    created_at: formatter.string(from: Date())
                )
                try await supabaseClient
                    .from("user_inventory")
                    .insert(record)
                    .execute()
            }
            print("☁️ [同步] \(items.count) 件物品已同步到 user_inventory")
        } catch {
            print("❌ [同步] user_inventory 同步失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 稀有度掉落表

    /// 根据 POI 稀有度生成掉落物品
    private func generateLootByRarity(_ rarity: POIRarity) -> [BackpackItem] {
        // 掉落池：按稀有度决定物品种类和数量
        let lootPool: [(itemId: String, name: String, category: ItemCategory, weight: Double, icon: String)]
        let itemCount: Int
        let maxQuantity: Int

        switch rarity {
        case .common:
            itemCount = Int.random(in: 1...2)
            maxQuantity = 2
            lootPool = [
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
                ("food_002", "压缩饼干", .food, 0.2, "rectangle.compress.vertical"),
                ("material_004", "布料", .material, 0.5, "square.fill"),
            ]
        case .rare:
            itemCount = Int.random(in: 2...3)
            maxQuantity = 3
            lootPool = [
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("medical_001", "绷带", .medical, 0.05, "cross.case.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("material_001", "木材", .material, 1.5, "rectangle.stack.fill"),
            ]
        case .epic:
            itemCount = Int.random(in: 2...3)
            maxQuantity = 4
            lootPool = [
                ("medical_002", "止痛药", .medical, 0.02, "pills.fill"),
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link"),
                ("material_002", "废金属", .material, 2.0, "cube.fill"),
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
            ]
        case .legendary:
            itemCount = Int.random(in: 3...4)
            maxQuantity = 5
            lootPool = [
                ("medical_003", "抗生素", .medical, 0.03, "syringe.fill"),
                ("material_003", "燃料罐", .material, 2.0, "fuelpump.fill"),
                ("tool_001", "手电筒", .tool, 0.3, "flashlight.on.fill"),
                ("tool_002", "绳子", .tool, 0.8, "link"),
                ("food_001", "罐头食品", .food, 0.3, "square.stack.3d.up.fill"),
                ("water_001", "矿泉水", .water, 0.5, "drop.fill"),
            ]
        }

        let qualities: [ItemQuality] = [.poor, .normal, .good, .excellent]

        var result: [BackpackItem] = []
        var usedIds: Set<String> = []
        let count = min(itemCount, lootPool.count)

        for _ in 0..<count {
            // 随机选一个未用过的物品
            let available = lootPool.filter { !usedIds.contains($0.itemId) }
            guard let template = available.randomElement() else { break }
            usedIds.insert(template.itemId)

            let quantity = Int.random(in: 1...maxQuantity)
            let quality = qualities.randomElement()

            result.append(BackpackItem(
                id: UUID().uuidString,
                itemId: template.itemId,
                name: template.name,
                category: template.category,
                quantity: quantity,
                weight: template.weight,
                quality: quality,
                icon: template.icon
            ))
        }

        return result
    }

    // MARK: - 旧的一键圈地（保留兼容）

    @MainActor
    func claimTerritory() {
        guard let loc = userLocation else { return }
        let newT = TerritoryModel(
            id: UUID(), lat: loc.coordinate.latitude, lon: loc.coordinate.longitude,
            claimedAt: Date(), name: "快速领地", area: 0, pointCount: 1
        )
        self.claimedTerritories.append(newT)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        print("🚩 [圈地] 快速占领 @ (\(String(format: "%.5f", newT.lat)), \(String(format: "%.5f", newT.lon)))")
    }

    // MARK: - 测试 POI

    @MainActor
    func createTestPOI() {
        guard let loc = userLocation else { return }
        let rarity = POIRarity.allCases.randomElement()!
        let new = POIModel(
            id: UUID(),
            name: "废弃补给点 #\(Int.random(in: 10...99))",
            latitude: loc.coordinate.latitude + Double.random(in: -0.0008...0.0008),
            longitude: loc.coordinate.longitude + Double.random(in: -0.0008...0.0008),
            rarity: rarity
        )
        self.nearbyPOIs.append(new)
        print("📍 [测试] 生成 POI：\(new.name)（\(rarity.rawValue)）")
    }

    @MainActor
    func createMultipleTestPOIs(count: Int = 5) {
        for _ in 0..<count { createTestPOI() }
        print("📍 [测试] 批量生成 \(count) 个 POI")
    }
}
