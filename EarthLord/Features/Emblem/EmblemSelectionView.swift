//
//  EmblemSelectionView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  徽章选择界面
//

import SwiftUI

struct EmblemSelectionView: View {
    let territoryId: String
    let onDismiss: () -> Void
    let onEmblemSelected: (String) -> Void

    @State private var selectedCategory: EmblemCategory? = nil
    @State private var unlockedEmblems: [Emblem] = []
    @State private var equippedEmblemId: String? = nil

    var filteredEmblems: [Emblem] {
        let base = unlockedEmblems.filter { $0.isUnlocked }
        if let category = selectedCategory {
            return base.filter { $0.category == category }
        }
        return base
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        EmblemCategoryChip(
                            title: "全部",
                            isSelected: selectedCategory == nil
                        ) {
                            withAnimation {
                                selectedCategory = nil
                            }
                        }

                        ForEach(EmblemCategory.allCases, id: \.self) { category in
                            EmblemCategoryChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(ApocalypseTheme.cardBackground)

                Divider()

                // 徽章列表
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredEmblems) { emblem in
                            EmblemCard(
                                emblem: emblem,
                                isEquipped: equippedEmblemId == emblem.id
                            ) {
                                equipEmblem(emblem)
                            }
                        }
                    }
                    .padding()
                }

                Spacer()

                // 底部说明
                VStack(spacing: 8) {
                    Text("选择徽章以装备到领地")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Text("徽章会为领地提供各种加成效果")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("选择徽章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
            .task {
                loadEmblems()
            }
        }
    }

    private func loadEmblems() {
        // TODO: 从数据库加载已解锁的徽章
        unlockedEmblems = Emblem.allEmblems.map { emblem in
            Emblem(
                id: emblem.id,
                name: emblem.name,
                description: emblem.description,
                icon: emblem.icon,
                category: emblem.category,
                rarity: emblem.rarity,
                bonus: emblem.bonus,
                requirement: emblem.requirement,
                isUnlocked: emblem.requirement.isMet
            )
        }
    }

    private func equipEmblem(_ emblem: Emblem) {
        equippedEmblemId = emblem.id
        onEmblemSelected(emblem.id)
        LogInfo("🏆 [徽章] 装备徽章: \(emblem.name)")
    }
}

// MARK: - EmblemCard

struct EmblemCard: View {
    let emblem: Emblem
    let isEquipped: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 徽章图标
            ZStack {
                Circle()
                    .fill(emblem.displayColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: emblem.icon)
                    .font(.system(size: 28))
                    .foregroundColor(emblem.displayColor)

                // 稀有度光晕
                if emblem.rarity == .legendary || emblem.rarity == .epic {
                    Circle()
                        .stroke(emblem.displayColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 68, height: 68)
                }
            }

            // 徽章信息
            VStack(spacing: 4) {
                HStack {
                    Text(emblem.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Spacer()

                    // 稀有度标签
                    Text(emblem.rarity.displayName)
                        .font(.caption2)
                        .foregroundColor(emblem.displayColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(emblem.displayColor.opacity(0.15))
                        .cornerRadius(4)
                }

                Text(emblem.description)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .lineLimit(2)

                // 加成效果
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.warning)
                    Text(emblem.bonus.formattedDescription)
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            // 装备按钮
            Button {
                onTap()
            } label: {
                HStack {
                    Image(systemName: isEquipped ? "checkmark.circle.fill" : "circle")
                    Text(isEquipped ? "已装备" : "装备")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundColor(isEquipped ? .white : ApocalypseTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isEquipped ? ApocalypseTheme.success : ApocalypseTheme.primary.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEquipped ? ApocalypseTheme.success.opacity(0.5) : emblem.displayColor.opacity(0.3), lineWidth: isEquipped ? 2 : 1)
        )
    }
}

// MARK: - EmblemCategoryChip

struct EmblemCategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.background)
                .cornerRadius(8)
        }
    }
}

// 预览
#Preview {
    EmblemSelectionView(
        territoryId: "test-territory",
        onDismiss: {},
        onEmblemSelected: { _ in }
    )
}
