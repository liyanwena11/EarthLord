//
//  BuildingPlacementView.swift
//  EarthLord
//
//  建造确认页：资源检查 + 地图选点 + 执行建造
//

import SwiftUI
import CoreLocation

struct BuildingPlacementView: View {
    let template: BuildingTemplate
    let territoryId: String
    let territoryCoordinates: [CLLocationCoordinate2D]

    var onDismiss: (() -> Void)?
    var onConstructionStarted: ((PlayerBuilding) -> Void)?

    @ObservedObject private var buildingManager = BuildingManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showLocationPicker = false
    @State private var isBuilding = false
    @State private var errorMessage: String?

    private var canBuildResult: (canBuild: Bool, error: BuildingError?) {
        buildingManager.canBuild(
            template: template,
            territoryId: territoryId,
            inventory: inventoryManager.items
        )
    }

    private var existingBuildingsInTerritory: [PlayerBuilding] {
        buildingManager.playerBuildings.filter { $0.territoryId == territoryId }
    }

    private var templateDict: [String: BuildingTemplate] {
        Dictionary(uniqueKeysWithValues: buildingManager.buildingTemplates.map { ($0.templateId, $0) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        locationCard
                        resourceCard

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        buildButton
                    }
                    .padding()
                }
            }
            .navigationTitle("确认建造")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { close() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                BuildingLocationPickerView(
                    territoryCoordinates: territoryCoordinates,
                    existingBuildings: existingBuildingsInTerritory,
                    buildingTemplates: templateDict,
                    selectedCoordinate: $selectedCoordinate
                )
            }
            .onAppear {
                LogDebug("🏗️ [BuildingPlacementView] onAppear")
                LogDebug("  - template: \(template.name)")
                LogDebug("  - territoryId: \(territoryId)")
                LogDebug("  - 领地坐标数量: \(territoryCoordinates.count)")

                if territoryCoordinates.isEmpty {
                    LogWarning("⚠️ [BuildingPlacementView] 领地坐标为空！")
                } else if territoryCoordinates.count < 3 {
                    LogWarning("⚠️ [BuildingPlacementView] 领地坐标不完整，只有 \(territoryCoordinates.count) 个点")
                } else {
                    LogDebug("✅ [BuildingPlacementView] 领地坐标完整")
                }

                // 确保建筑与背包数据就绪
                Task {
                    await buildingManager.fetchPlayerBuildings(territoryId: territoryId)
                    if inventoryManager.items.isEmpty {
                        await inventoryManager.loadInventory()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 70, height: 70)
                Image(systemName: template.icon)
                    .font(.system(size: 32))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            Text(template.name)
                .font(.title3.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            HStack(spacing: 10) {
                Label(template.category.displayName, systemImage: template.category.icon)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)

                Text("建造时间 \(formatBuildTime(template.buildTimeSeconds))")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("建造位置", systemImage: "mappin.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 验证领地坐标
            if territoryCoordinates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ApocalypseTheme.warning)
                        Text("领地坐标数据缺失")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    Text("该领地可能尚未完成圈地，或坐标数据损坏。请联系管理员或尝试重新圈地。")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .padding()
                .background(ApocalypseTheme.warning.opacity(0.1))
                .cornerRadius(8)
            } else if territoryCoordinates.count < 3 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ApocalypseTheme.warning)
                        Text("领地坐标不完整")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    Text("坐标点数量不足（至少需要 3 个点），无法显示多边形边界。当前数量: \(territoryCoordinates.count)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .padding()
                .background(ApocalypseTheme.warning.opacity(0.1))
                .cornerRadius(8)
            } else if let coord = selectedCoordinate {
                Text("已选择位置：\(String(format: "%.4f", coord.latitude)), \(String(format: "%.4f", coord.longitude))")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            } else {
                Text("请在地图上选择建造位置")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            // 只有在有足够坐标时才显示地图选择按钮
            if territoryCoordinates.count >= 3 {
                Button {
                    showLocationPicker = true
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("在地图上选择位置")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(ApocalypseTheme.primary.opacity(0.1))
                    .foregroundColor(ApocalypseTheme.primary)
                    .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var resourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("资源消耗", systemImage: "cube.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            let resources = template.requiredResources.sorted { $0.key < $1.key }
            ForEach(Array(resources), id: \.key) { resourceId, required in
                ResourceRowView(
                    resourceId: resourceId,
                    required: required,
                    owned: inventoryManager.items.first { $0.itemId == resourceId }?.quantity ?? 0
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var buildButton: some View {
        let canBuild = canBuildResult.canBuild
        let atMax = buildingManager.getBuildingCount(templateId: template.templateId, territoryId: territoryId) >= template.maxPerTerritory
        let locationSelected = selectedCoordinate != nil

        return Button(action: startBuild) {
            HStack(spacing: 10) {
                if isBuilding {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "hammer.fill")
                    Text(buttonTitle(canBuild: canBuild, atMax: atMax, locationSelected: locationSelected))
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canBuild && !atMax && locationSelected ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!canBuild || atMax || !locationSelected || isBuilding)
        .opacity((!canBuild || atMax || !locationSelected) ? 0.6 : 1.0)
    }

    // MARK: - Actions

    private func startBuild() {
        guard let coord = selectedCoordinate else {
            errorMessage = "请先在地图上选择建造位置"
            return
        }

        isBuilding = true
        errorMessage = nil

        Task {
            do {
                let beforeCount = buildingManager.playerBuildings.count

                try await buildingManager.startConstruction(
                    templateId: template.templateId,
                    territoryId: territoryId,
                    location: coord
                )

                // 重新拉取当前领地建筑
                await buildingManager.fetchPlayerBuildings(territoryId: territoryId)

                let newBuilding = buildingManager.playerBuildings.dropFirst(beforeCount).last

                await MainActor.run {
                    isBuilding = false
                    if let newBuilding {
                        onConstructionStarted?(newBuilding)
                    }
                    close()
                }
            } catch {
                await MainActor.run {
                    isBuilding = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func close() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func buttonTitle(canBuild: Bool, atMax: Bool, locationSelected: Bool) -> String {
        if atMax { return "已达上限" }
        if !canBuild { return "资源不足" }
        if !locationSelected { return "请选择位置" }
        return "确认建造"
    }

    private func formatBuildTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)秒" }
        if seconds < 3600 { return "\(seconds / 60)分钟" }
        return "\(seconds / 3600)小时\((seconds % 3600) / 60)分"
    }
}

