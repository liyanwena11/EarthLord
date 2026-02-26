//
//  BuildingDetailView.swift
//  EarthLord
//
//  建筑详情 & 建造界面
//

import SwiftUI

struct BuildingDetailView: View {
    let template: BuildingTemplate
    let territoryId: String

    @ObservedObject private var buildingManager = BuildingManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isBuilding = false
    @State private var buildError: String?
    @State private var showSuccess = false

    private var canBuildResult: (Bool, BuildingError?) {
        buildingManager.canBuild(
            template: template,
            territoryId: territoryId,
            inventory: inventoryManager.items
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 建筑预览卡
                        previewCard

                        // 描述
                        descriptionCard

                        // 建造信息
                        buildInfoCard

                        // 资源需求
                        resourcesCard

                        // 错误提示
                        if let error = buildError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.danger)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }

                        // 建造按钮
                        buildButton
                    }
                    .padding()
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .alert("建造成功！", isPresented: $showSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text("\(template.name) 开始建造，预计 \(formatBuildTime(template.buildTimeSeconds)) 后完成")
            }
        }
    }

    // MARK: - Subviews

    private var previewCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: template.icon)
                    .font(.system(size: 36))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            Text(template.name)
                .font(.title2.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            HStack(spacing: 12) {
                Label(template.category.displayName, systemImage: template.category.icon)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ApocalypseTheme.background)
                    .cornerRadius(8)

                Text("Tier \(template.tier)")
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ApocalypseTheme.primary.opacity(0.1))
                    .cornerRadius(8)
            }

            let count = buildingManager.getBuildingCount(templateId: template.templateId, territoryId: territoryId)
            Text("已建 \(count) / 最多 \(template.maxPerTerritory) 个")
                .font(.caption)
                .foregroundColor(count >= template.maxPerTerritory ? ApocalypseTheme.danger : ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("建筑描述", systemImage: "doc.text.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text(template.description)
                .font(.body)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var buildInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("建造信息", systemImage: "info.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            HStack {
                Label(formatBuildTime(template.buildTimeSeconds), systemImage: "clock.fill")
                    .foregroundColor(ApocalypseTheme.textSecondary)
                Spacer()
                Label("最高 Lv.\(template.maxLevel)", systemImage: "arrow.up.circle.fill")
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .font(.subheadline)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("所需资源", systemImage: "cube.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            if template.requiredResources.isEmpty {
                Text("无需材料").font(.subheadline).foregroundColor(ApocalypseTheme.textMuted)
            } else {
                ForEach(Array(template.requiredResources.sorted(by: { $0.key < $1.key })), id: \.key) { resourceId, required in
                    ResourceRowView(
                        resourceId: resourceId,
                        required: required,
                        owned: inventoryManager.items.first { $0.itemId == resourceId }?.quantity ?? 0
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private var buildButton: some View {
        let (canBuild, _) = canBuildResult
        let atMax = buildingManager.getBuildingCount(templateId: template.templateId, territoryId: territoryId) >= template.maxPerTerritory

        return Button(action: startBuild) {
            HStack(spacing: 10) {
                if isBuilding {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "hammer.fill")
                    Text(atMax ? "已达上限" : "开始建造")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canBuild && !atMax ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!canBuild || atMax || isBuilding)
        .opacity((!canBuild || atMax) ? 0.6 : 1.0)
    }

    private func startBuild() {
        isBuilding = true
        buildError = nil

        Task {
            do {
                try await buildingManager.startConstruction(
                    templateId: template.templateId,
                    territoryId: territoryId,
                    location: nil
                )
                await MainActor.run { isBuilding = false; showSuccess = true }
            } catch {
                await MainActor.run { isBuilding = false; buildError = error.localizedDescription }
            }
        }
    }

    private func formatBuildTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)秒" }
        if seconds < 3600 { return "\(seconds / 60)分钟" }
        return "\(seconds / 3600)小时\((seconds % 3600) / 60)分"
    }
}

// MARK: - Resource Row

struct ResourceRowView: View {
    let resourceId: String
    let required: Int
    let owned: Int

    private var isSufficient: Bool { owned >= required }

    var body: some View {
        HStack {
            Image(systemName: "cube.fill")
                .foregroundColor(isSufficient ? ApocalypseTheme.success : ApocalypseTheme.warning)
                .frame(width: 20)

            Text(resourceDisplayName(resourceId))
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Spacer()

            Text("\(owned) / \(required)")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(isSufficient ? ApocalypseTheme.success : ApocalypseTheme.danger)
        }
        .padding(.vertical, 4)
    }

    private func resourceDisplayName(_ id: String) -> String {
        switch id {
        case "wood": return "木材"
        case "stone": return "石头"
        case "metal": return "金属"
        case "glass": return "玻璃"
        case "cloth": return "布料"
        case "food": return "食物"
        case "water": return "水"
        default: return id
        }
    }
}
