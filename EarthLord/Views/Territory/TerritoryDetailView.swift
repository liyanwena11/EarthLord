//
//  TerritoryDetailView.swift
//  EarthLord
//
//  领地详情页 - 全屏地图布局
//  显示领地多边形、建筑标记、悬浮工具栏、可折叠信息面板
//

import SwiftUI
import MapKit

struct TerritoryDetailView: View {

    // MARK: - Properties

    @State var territory: Territory
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var showInfoPanel = true
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showBuildingBrowser = false
    @State private var selectedTemplateForConstruction: BuildingTemplate?
    @State private var selectedBuilding: PlayerBuilding?
    @State private var showUpgradeConfirm = false
    @State private var showDemolishConfirm = false
    @State private var showRenameDialog = false
    @State private var newTerritoryName = ""

    @ObservedObject private var territoryManager = TerritoryManager.shared
    @ObservedObject private var buildingManager = BuildingManager.shared

    // MARK: - Computed Properties

    /// 领地坐标
    private var territoryCoordinates: [CLLocationCoordinate2D] {
        territory.toCoordinates()
    }

    /// 该领地的建筑列表
    private var territoryBuildings: [PlayerBuilding] {
        buildingManager.playerBuildings.filter { $0.territoryId == territory.id }
    }

    /// 建筑模板字典
    private var templateDict: [String: BuildingTemplate] {
        Dictionary(uniqueKeysWithValues: buildingManager.buildingTemplates.map { ($0.templateId, $0) })
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1. 全屏地图（底层）
            TerritoryMapView(
                territoryCoordinates: territoryCoordinates,
                buildings: territoryBuildings,
                templates: templateDict
            )
            .ignoresSafeArea()

            // 2. 悬浮工具栏（顶部）
            VStack {
                TerritoryToolbarView(
                    onDismiss: { dismiss() },
                    onBuildingBrowser: { showBuildingBrowser = true },
                    showInfoPanel: $showInfoPanel
                )
                Spacer()
            }

            // 3. 可折叠信息面板（底部）
            VStack {
                Spacer()
                if showInfoPanel {
                    infoPanelView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        // 各种弹窗
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task { await deleteTerritory() }
            }
        } message: {
            Text("确定要删除这块领地吗？此操作不可撤销。")
        }
        .alert("升级建筑", isPresented: $showUpgradeConfirm) {
            Button("取消", role: .cancel) { }
            Button("升级") {
                Task { await upgradeBuilding() }
            }
        } message: {
            if let building = selectedBuilding {
                Text("确定要将「\(building.buildingName)」升级到 Lv.\(building.level + 1) 吗？")
            }
        }
        .alert("拆除建筑", isPresented: $showDemolishConfirm) {
            Button("取消", role: .cancel) { }
            Button("拆除", role: .destructive) {
                Task { await demolishBuilding() }
            }
        } message: {
            if let building = selectedBuilding {
                Text("确定要拆除「\(building.buildingName)」吗？此操作不可撤销。")
            }
        }
        .alert("重命名领地", isPresented: $showRenameDialog) {
            TextField("输入新名称", text: $newTerritoryName)
            Button("取消", role: .cancel) { }
            Button("确定") {
                Task { await renameTerritory() }
            }
            .disabled(newTerritoryName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("请输入领地的新名称")
        }
        // 建筑浏览器 Sheet
        .sheet(isPresented: $showBuildingBrowser) {
            NavigationStack {
                BuildingBrowserView(
                    territoryId: territory.id,
                    onStartConstruction: { template in
                        LogDebug("🏗️ [TerritoryDetailView] 用户选择建筑: \(template.name)")
                        showBuildingBrowser = false
                        // 使用 async/await 确保 Sheet 动画完成
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
                            await MainActor.run {
                                LogDebug("🏗️ [TerritoryDetailView] 准备显示建造确认页")
                                selectedTemplateForConstruction = template
                            }
                        }
                    },
                    onDismiss: { showBuildingBrowser = false }
                )
            }
        }
        // 建造确认 Sheet（使用 item: 绑定传递数据）
        .sheet(item: $selectedTemplateForConstruction) { template in
            BuildingPlacementView(
                template: template,
                territoryId: territory.id,
                territoryCoordinates: territoryCoordinates,
                onDismiss: { selectedTemplateForConstruction = nil },
                onConstructionStarted: { _ in
                    selectedTemplateForConstruction = nil
                    Task {
                        await buildingManager.fetchPlayerBuildings(territoryId: territory.id)
                    }
                }
            )
        }
        .onAppear {
            LogDebug("🏰 [TerritoryDetailView] onAppear")
            LogDebug("  - 领地 ID: \(territory.id)")
            LogDebug("  - 领地名称: \(territory.displayName)")
            LogDebug("  - 领地路径点数: \(territory.path.count)")
            LogDebug("  - 转换后坐标数: \(territoryCoordinates.count)")

            buildingManager.loadTemplates()
            Task {
                await buildingManager.fetchPlayerBuildings(territoryId: territory.id)
            }
        }
    }

    // MARK: - Info Panel

    private var infoPanelView: some View {
        VStack(spacing: 0) {
            // 拖拽指示器
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 16) {
                    // 领地名称 + 重命名按钮
                    HStack {
                        Text(territory.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            newTerritoryName = territory.name ?? ""
                            showRenameDialog = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                    }

                    // 领地信息
                    HStack(spacing: 16) {
                        Label("\(Int(territory.area)) ㎡", systemImage: "map.fill")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                    
                    // 防御加成卡片 (Tier权益)
                    defenseBoostCard

                    // 建筑区域
                    buildingSection

                    // 删除按钮
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ApocalypseTheme.cardBackground.opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
        .contentShape(Rectangle())
    }
    
    /// 防御加成卡片
    private var defenseBoostCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("防御", systemImage: "shield.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                
                Spacer()
                
                // 防御加成显示
                HStack(spacing: 4) {
                    Text(territoryManager.defenseBonusDescription)
                        .font(.subheadline.bold())
                        .foregroundColor(
                            territoryManager.defenseBonus > 0
                                ? ApocalypseTheme.success
                                : ApocalypseTheme.textSecondary
                        )
                    
                    if territoryManager.defenseBonus > 0 {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.success)
                    }
                }
            }
            
            // 防御减免比例显示
            let reduction = territoryManager.getCurrentDefenseReduction()
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("伤害减免")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", reduction * 100))
                        .font(.caption.bold())
                        .foregroundColor(ApocalypseTheme.info)
                }
                
                ProgressView(value: reduction)
                    .tint(
                        territoryManager.defenseBonus > 0
                            ? ApocalypseTheme.success
                            : ApocalypseTheme.info
                    )
            }
            
            // 防御加成说明（仅在有加成时显示）
            if territoryManager.defenseBonus > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.success)
                    
                    Text("Empire Tier 权益：额外 \(territoryManager.defenseBonus)% 防御加成")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(ApocalypseTheme.success.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 建筑区域
    private var buildingSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("建筑", systemImage: "building.2")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
                Text("\(territoryBuildings.count)")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)

            Divider().background(ApocalypseTheme.textMuted.opacity(0.3))

            if territoryBuildings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "hammer")
                        .font(.system(size: 40))
                        .foregroundColor(ApocalypseTheme.textMuted)
                    Text("暂无建筑")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text("点击顶部「建造」按钮开始")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(ApocalypseTheme.cardBackground)
            } else {
                VStack(spacing: 0) {
                    ForEach(territoryBuildings) { building in
                        if let template = buildingManager.getTemplate(for: building.templateId) {
                            VStack(spacing: 0) {
                                TerritoryBuildingRow(
                                    building: building,
                                    template: template,
                                    onUpgrade: {
                                        selectedBuilding = building
                                        showUpgradeConfirm = true
                                    },
                                    onDemolish: {
                                        selectedBuilding = building
                                        showDemolishConfirm = true
                                    }
                                )
                                .padding(.horizontal)
                                .padding(.vertical, 8)

                                if building.id != territoryBuildings.last?.id {
                                    Divider().background(ApocalypseTheme.textMuted.opacity(0.3))
                                }
                            }
                        }
                    }
                }
                .background(ApocalypseTheme.cardBackground)
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "trash")
                }
                Text(isDeleting ? "删除中..." : "删除领地")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
        }
        .disabled(isDeleting)
    }



    // MARK: - Methods

    private func deleteTerritory() async {
        isDeleting = true
        let success = await territoryManager.deleteTerritory(territoryId: territory.id)
        await MainActor.run {
            isDeleting = false
            if success {
                onDelete?()
                dismiss()
            }
        }
    }

    private func upgradeBuilding() async {
        guard let building = selectedBuilding else { return }
        do {
            try await buildingManager.upgradeBuilding(buildingId: building.id)
            await buildingManager.fetchPlayerBuildings(territoryId: territory.id)
        } catch {
            LogError("[TerritoryDetailView] 升级失败: \(error.localizedDescription)")
        }
    }

    private func demolishBuilding() async {
        guard let building = selectedBuilding else { return }
        do {
            try await buildingManager.demolishBuilding(buildingId: building.id)
            await buildingManager.fetchPlayerBuildings(territoryId: territory.id)
        } catch {
            LogError("[TerritoryDetailView] 拆除失败: \(error.localizedDescription)")
        }
    }

    /// 重命名领地
    private func renameTerritory() async {
        let trimmedName = newTerritoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let success = await territoryManager.updateTerritoryName(
            territoryId: territory.id,
            newName: trimmedName
        )

        if success {
            await MainActor.run {
                // 更新本地显示的名称
                territory = Territory(
                    id: territory.id,
                    userId: territory.userId,
                    name: trimmedName,
                    path: territory.path,
                    area: territory.area,
                    pointCount: territory.pointCount,
                    isActive: territory.isActive,
                    completedAt: territory.completedAt,
                    startedAt: territory.startedAt,
                    createdAt: territory.createdAt,
                    level: territory.level,
                    experience: territory.experience,
                    prosperity: territory.prosperity
                )

                // 发送通知刷新领地列表
                NotificationCenter.default.post(name: .territoryUpdated, object: nil)
            }
        }
    }
}
