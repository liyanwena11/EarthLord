import SwiftUI

#if DEBUG
import CoreLocation

struct LocationDebugView: View {
    @StateObject private var engine = EarthLordEngine.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("开发测试面板")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal)

                // MARK: - GPS 状态
                GroupBox(label: Label("GPS 状态", systemImage: "location.circle.fill")) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let loc = engine.userLocation {
                            Text("纬度: \(String(format: "%.6f", loc.coordinate.latitude))")
                            Text("经度: \(String(format: "%.6f", loc.coordinate.longitude))")
                            Text("精度: \(String(format: "%.1f", loc.horizontalAccuracy))m")
                        } else {
                            Text("正在等待 GPS 信号...").foregroundColor(.orange)
                        }
                    }
                    .font(.caption)
                    .padding(4)
                }
                .padding(.horizontal)

                // MARK: - 游戏状态
                GroupBox(label: Label("游戏状态", systemImage: "gamecontroller.fill")) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("POI 数量:").foregroundColor(.secondary)
                            Text("\(engine.nearbyPOIs.count)").bold()
                            Spacer()
                            Text("可搜刮:").foregroundColor(.secondary)
                            Text("\(engine.nearbyPOIs.filter { !$0.isScavenged }.count)").bold().foregroundColor(.green)
                        }
                        HStack {
                            Text("领地数量:").foregroundColor(.secondary)
                            Text("\(engine.claimedTerritories.count)").bold()
                            Spacer()
                            Text("附近人数:").foregroundColor(.secondary)
                            Text("\(engine.nearbyPlayerCount)").bold()
                        }
                        HStack {
                            Text("探索状态:").foregroundColor(.secondary)
                            Text(engine.isExploring ? "扫描中..." : "待机")
                                .foregroundColor(engine.isExploring ? .yellow : .gray)
                                .bold()
                            Spacer()
                            Text("弹窗:").foregroundColor(.secondary)
                            Text(engine.showProximityAlert ? "显示中" : "隐藏")
                                .foregroundColor(engine.showProximityAlert ? .green : .gray)
                        }
                    }
                    .font(.caption)
                    .padding(4)
                }
                .padding(.horizontal)

                // MARK: - POI 列表预览
                if !engine.nearbyPOIs.isEmpty {
                    GroupBox(label: Label("POI 列表", systemImage: "mappin.circle.fill")) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(engine.nearbyPOIs) { poi in
                                HStack {
                                    Circle()
                                        .fill(poi.rarity.color)
                                        .frame(width: 8, height: 8)
                                    Text(poi.name).font(.caption)
                                    Spacer()
                                    Text(poi.rarity.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(poi.rarity.color)
                                    if poi.isScavenged {
                                        Text("已搜刮").font(.system(size: 9)).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(4)
                    }
                    .padding(.horizontal)
                }

                Divider().padding(.horizontal)

                // MARK: - 操作按钮

                Text("调试操作").font(.caption).foregroundColor(.gray).padding(.horizontal)

                // 生成 POI
                DebugButton(title: "生成 1 个测试 POI", icon: "plus.circle.fill", color: .blue) {
                    engine.createTestPOI()
                }

                // 批量生成
                DebugButton(title: "批量生成 5 个 POI", icon: "plus.circle.fill", color: .indigo) {
                    engine.createMultipleTestPOIs(count: 5)
                }

                // 开始/停止采样圈地
                DebugButton(
                    title: engine.isTracking ? "停止采样圈地" : "开始采样圈地",
                    icon: engine.isTracking ? "stop.fill" : "flag.2.crossed.fill",
                    color: engine.isTracking ? .orange : .red
                ) {
                    if engine.isTracking {
                        engine.stopTracking()
                    } else {
                        engine.startTracking()
                    }
                }

                // 强制完成圈地
                if engine.isTracking && engine.pathPoints.count >= 3 {
                    DebugButton(title: "强制完成圈地（\(engine.pathPoints.count)点）", icon: "checkmark.circle.fill", color: .green) {
                        engine.forceFinishTracking()
                    }
                }

                // 快速圈地（旧）
                DebugButton(title: "快速圈地（单点）", icon: "flag.2.crossed.fill", color: .gray) {
                    engine.claimTerritory()
                }

                // 模拟搜刮最近 POI
                DebugButton(title: "强行搜刮最近 POI", icon: "shippingbox.fill", color: .purple) {
                    forceScavengeNearest()
                }

                // 强行触发搜刮弹窗
                DebugButton(title: "模拟进入 POI 范围（弹窗）", icon: "mappin.and.ellipse", color: .orange) {
                    simulateEnterPOI()
                }

                // 刷新所有 POI
                DebugButton(title: "刷新所有已搜刮 POI", icon: "arrow.clockwise", color: .green) {
                    refreshAllPOIs()
                }

                // 打印完整状态
                DebugButton(title: "打印完整状态到 Console", icon: "doc.text", color: .mint) {
                    printFullStatus()
                }

                // 测试掉落物品（预设）
                DebugButton(title: "测试掉落（预设物品）", icon: "gift.fill", color: .yellow) {
                    testLootDrop()
                }

                // 测试 AI 掉落
                DebugButton(title: "测试 AI 搜刮", icon: "brain.fill", color: .purple) {
                    testAILoot()
                }

                // 查看背包
                DebugButton(title: "打印背包内容", icon: "bag.fill", color: .cyan) {
                    printBackpack()
                }

                // 清空背包
                DebugButton(title: "清空背包", icon: "trash.circle", color: .pink) {
                    ExplorationManager.shared.clearBackpack()
                    LogDebug("🗑️ [调试] 已清空背包")
                }

                // 清空所有数据
                DebugButton(title: "清空所有 POI 和领地", icon: "trash", color: .red) {
                    engine.nearbyPOIs.removeAll()
                    engine.claimedTerritories.removeAll()
                    engine.showProximityAlert = false
                    engine.activePOI = nil
                    LogDebug("🗑️ [调试] 已清空所有数据")
                }

                Spacer().frame(height: 50)
            }
            .padding(.top)
        }
        .navigationTitle("开发测试")
    }

    // MARK: - 调试方法

    private func forceScavengeNearest() {
        guard let poi = engine.nearbyPOIs.first(where: { !$0.isScavenged }) else {
            LogDebug("🧪 [调试] 没有可搜刮的 POI")
            return
        }
        if let index = engine.nearbyPOIs.firstIndex(where: { $0.id == poi.id }) {
            engine.nearbyPOIs[index].isScavenged = true
            engine.nearbyPOIs[index].lastScavengedAt = Date()
            LogDebug("🧪 [调试] 强行搜刮：\(poi.name)")
        }
    }

    private func simulateEnterPOI() {
        guard let poi = engine.nearbyPOIs.first(where: { !$0.isScavenged }) ?? engine.nearbyPOIs.first else {
            LogDebug("🧪 [调试] 没有 POI 可模拟，先生成一个")
            engine.createTestPOI()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let newPOI = engine.nearbyPOIs.last {
                    engine.activePOI = newPOI
                    engine.showProximityAlert = true
                    LogDebug("🧪 [调试] 模拟进入 POI 范围：\(newPOI.name)")
                }
            }
            return
        }
        engine.activePOI = poi
        engine.showProximityAlert = true
        LogDebug("🧪 [调试] 模拟进入 POI 范围：\(poi.name)")
    }

    private func refreshAllPOIs() {
        var count = 0
        for index in engine.nearbyPOIs.indices {
            if engine.nearbyPOIs[index].isScavenged {
                engine.nearbyPOIs[index].isScavenged = false
                engine.nearbyPOIs[index].lastScavengedAt = nil
                count += 1
            }
        }
        LogDebug("🔄 [调试] 已刷新 \(count) 个 POI")
    }

    private func testAILoot() {
        engine.createTestPOI()
        guard let poi = engine.nearbyPOIs.last else { return }
        engine.activePOI = poi
        Task {
            let items = await engine.scavengeWithAI()
            LogDebug("🤖 [调试] AI 搜刮结果（\(poi.rarity.rawValue)）：")
            for item in items {
                LogDebug("  🤖 \(item.name) [AI:\(item.isAIGenerated)] \(item.weight)kg")
                if let story = item.backstory {
                    LogDebug("     📜 \(story)")
                }
            }
        }
    }

    private func testLootDrop() {
        let rarities: [POIRarity] = [.common, .rare, .epic, .legendary]
        let rarity = rarities.randomElement()!
        // 创建一个临时 POI 用来测试掉落
        engine.createTestPOI()
        if let lastPOI = engine.nearbyPOIs.last {
            var testPOI = lastPOI
            testPOI.rarity = rarity
            if let index = engine.nearbyPOIs.firstIndex(where: { $0.id == testPOI.id }) {
                engine.nearbyPOIs[index] = testPOI
            }
            engine.activePOI = testPOI
            let items = engine.scavengeWithLoot()
            LogDebug("🧪 [调试] 测试掉落（\(rarity.rawValue)）：\(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
        }
    }

    private func printBackpack() {
        let backpack = ExplorationManager.shared
        LogDebug("🎒🎒🎒 [调试] ========== 背包内容 ==========")
        LogDebug("📦 物品种类: \(backpack.backpackItems.count)")
        LogDebug("⚖️ 总重量: \(String(format: "%.1f", backpack.totalWeight)) / \(Int(backpack.maxCapacity)) kg")
        for item in backpack.backpackItems {
            LogDebug("  📦 \(item.name) [\(item.category.rawValue)] x\(item.quantity) = \(String(format: "%.1f", item.totalWeight))kg")
        }
        LogDebug("🎒🎒🎒 ========== 背包结束 ==========")
    }

    private func printFullStatus() {
        LogDebug("📊📊📊 [调试] ========== 完整状态 ==========")
        LogDebug("📍 GPS: \(engine.userLocation?.coordinate.latitude ?? 0), \(engine.userLocation?.coordinate.longitude ?? 0)")
        LogDebug("📍 精度: \(engine.userLocation?.horizontalAccuracy ?? -1)m")
        LogDebug("🗺️ POI 总数: \(engine.nearbyPOIs.count)")
        LogDebug("🗺️ 可搜刮: \(engine.nearbyPOIs.filter { !$0.isScavenged }.count)")
        LogDebug("🚩 领地数: \(engine.claimedTerritories.count)")
        LogDebug("👥 附近人数: \(engine.nearbyPlayerCount)")
        LogDebug("🎯 弹窗状态: \(engine.showProximityAlert)")
        LogDebug("📡 探索中: \(engine.isExploring)")
        for (i, poi) in engine.nearbyPOIs.enumerated() {
            LogDebug("  POI[\(i)]: \(poi.name) (\(poi.rarity.rawValue)) 搜刮:\(poi.isScavenged) 坐标:(\(String(format: "%.5f", poi.latitude)),\(String(format: "%.5f", poi.longitude)))")
        }
        LogDebug("📊📊📊 ========== 状态结束 ==========")
    }
}

// MARK: - 调试按钮样式

struct DebugButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
#endif
