//
//  BuildingBrowserView.swift
//  EarthLord
//
//  建筑图鉴浏览界面
//

import SwiftUI

struct BuildingBrowserView: View {
    @ObservedObject private var buildingManager = BuildingManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared

    var territoryId: String
    /// 选中某个建筑后回调，由上层决定后续流程（例如打开建造确认页）
    var onStartConstruction: ((BuildingTemplate) -> Void)?
    var onDismiss: (() -> Void)?

    @State private var selectedCategory: BuildingCategory = .all
    @State private var selectedTemplate: BuildingTemplate?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var filteredTemplates: [BuildingTemplate] {
        buildingManager.getTemplatesByCategory(selectedCategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分类筛选栏
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(BuildingCategory.allCases, id: \.self) { category in
                                BuildingCategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(ApocalypseTheme.cardBackground)

                    // 建筑网格
                    ScrollView {
                        if filteredTemplates.isEmpty {
                            VStack(spacing: 16) {
                                Spacer(minLength: 60)
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                                Text("暂无建筑模板")
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(filteredTemplates) { template in
                                    BuildingCardView(
                                        template: template,
                                        inventory: inventoryManager.items,
                                        buildingCount: buildingManager.getBuildingCount(
                                            templateId: template.templateId,
                                            territoryId: territoryId
                                        )
                                    )
                                    .onTapGesture {
                                        if let onStartConstruction {
                                            onStartConstruction(template)
                                        } else {
                                            selectedTemplate = template
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("建筑图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        if let onDismiss {
                            onDismiss()
                        }
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .sheet(item: $selectedTemplate) { template in
                BuildingDetailView(template: template, territoryId: territoryId)
            }
            .onAppear {
                LogDebug("🏗️ [BuildingBrowserView] onAppear 开始")
                LogDebug("  - territoryId: \(territoryId)")
                LogDebug("  - 建筑模板数量: \(buildingManager.buildingTemplates.count)")
                LogDebug("  - 筛选后的模板数量: \(filteredTemplates.count)")
                LogDebug("  - 当前分类: \(selectedCategory.rawValue)")

                Task {
                    await buildingManager.fetchPlayerBuildings(territoryId: territoryId)
                    await MainActor.run {
                        LogDebug("🏗️ [BuildingBrowserView] fetchPlayerBuildings 完成")
                        LogDebug("  - 建筑模板数量: \(buildingManager.buildingTemplates.count)")
                        LogDebug("  - 玩家建筑数量: \(buildingManager.playerBuildings.count)")
                    }
                }
                if inventoryManager.items.isEmpty {
                    Task {
                        await inventoryManager.loadInventory()
                        await MainActor.run {
                            LogDebug("🏗️ [BuildingBrowserView] loadInventory 完成")
                            LogDebug("  - 物品数量: \(inventoryManager.items.count)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Category Chip

struct BuildingCategoryChip: View {
    let category: BuildingCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.background)
            .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Building Card

struct BuildingCardView: View {
    let template: BuildingTemplate
    let inventory: [InventoryDisplayItem]
    let buildingCount: Int

    private var hasEnoughResources: Bool {
        for (resourceId, required) in template.requiredResources {
            let available = inventory.first { $0.itemId == resourceId }?.quantity ?? 0
            if available < required { return false }
        }
        return true
    }

    var body: some View {
        VStack(spacing: 10) {
            // 图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: template.icon)
                    .font(.system(size: 26))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            // 名称
            Text(template.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textPrimary)
                .lineLimit(1)

            // 等级标签
            HStack(spacing: 4) {
                Text("Tier \(template.tier)")
                    .font(.system(size: 10))
                    .foregroundColor(ApocalypseTheme.textMuted)
                Spacer()
                Text("\(buildingCount)/\(template.maxPerTerritory)")
                    .font(.system(size: 10))
                    .foregroundColor(buildingCount >= template.maxPerTerritory ? ApocalypseTheme.danger : ApocalypseTheme.textMuted)
            }

            // 资源是否足够指示
            Circle()
                .fill(hasEnoughResources ? ApocalypseTheme.success : ApocalypseTheme.warning)
                .frame(width: 8, height: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ApocalypseTheme.textMuted.opacity(0.15), lineWidth: 1)
        )
    }
}
