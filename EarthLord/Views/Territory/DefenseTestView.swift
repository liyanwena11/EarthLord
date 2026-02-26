#if DEBUG
//
//  DefenseTestView.swift
//  EarthLord
//
//  防御系统测试视图 - 用于验证 Tier 权益应用和防御计算
//
//  Created by Claude on 2026-02-25
//

import SwiftUI

struct DefenseTestView: View {
    @ObservedObject private var territoryManager = TerritoryManager.shared
    @ObservedObject private var tierManager = TierManager.shared
    
    @State private var testDamage: Double = 100.0
    @State private var showCalculation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // MARK: - 当前防御状态
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前防御状态")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    
                    // 防御倍数显示
                    HStack {
                        Text("防御倍数")
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.2f x", territoryManager.defenseBonusMultiplier))
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.info)
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                    
                    // 防御加成显示
                    HStack {
                        Text("防御加成")
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(territoryManager.defenseBonusDescription)
                                .font(.subheadline.bold())
                                .foregroundColor(
                                    territoryManager.defenseBonus > 0
                                        ? ApocalypseTheme.success
                                        : ApocalypseTheme.textMuted
                                )
                            if territoryManager.defenseBonus > 0 {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(ApocalypseTheme.success)
                            }
                        }
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                    
                    // 伤害减免显示
                    let reduction = territoryManager.getCurrentDefenseReduction()
                    HStack {
                        Text("伤害减免")
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f%%", reduction * 100))
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.info)
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground.opacity(0.5))
                .cornerRadius(12)
                
                Divider()
                    .padding(.vertical, 8)
                
                // MARK: - 伤害计算演示
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("伤害计算演示")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    
                    // 来袭伤害输入
                    VStack(alignment: .leading, spacing: 6) {
                        Text("来袭伤害: \(Int(testDamage))")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        
                        Slider(value: $testDamage, in: 10...200, step: 5)
                            .tint(ApocalypseTheme.primary)
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                    
                    // 计算结果
                    let actualDamage = territoryManager.calculateDefenseReduction(incomingDamage: testDamage)
                    let baseDamage = testDamage * 0.2 // 基础防御 20%
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("基础防御减免")
                                .foregroundColor(ApocalypseTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.1f", baseDamage))
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                        
                        HStack {
                            Text("Tier 倍数")
                                .foregroundColor(ApocalypseTheme.textSecondary)
                            Spacer()
                            Text(String(format: "x%.2f", territoryManager.defenseBonusMultiplier))
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.info)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("实际防御减免")
                                .foregroundColor(ApocalypseTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.1f", baseDamage * territoryManager.defenseBonusMultiplier))
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.success)
                        }
                        
                        HStack {
                            Text("实际受到伤害")
                                .foregroundColor(ApocalypseTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.1f", actualDamage))
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.danger)
                        }
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground.opacity(0.5))
                .cornerRadius(12)
                
                Spacer()
                
                // MARK: - 测试按钮

                VStack(spacing: 10) {
                    // 应用 Empire Tier 权益
                    Button {
                        if let empireBenefit = TierBenefit.getBenefit(for: .empire) {
                            territoryManager.applyTerritoryBenefit(empireBenefit)
                            LogDebug("✅ [测试] 应用 Empire Tier 防御权益 (15%)")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("应用 Empire Tier (+15% 防御)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ApocalypseTheme.success)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // 重置防御权益
                    Button {
                        territoryManager.resetTerritoryBenefit()
                        LogDebug("✅ [测试] 重置防御权益")
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置防御权益")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ApocalypseTheme.textMuted.opacity(0.3))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("防御系统测试")
            .navigationBarTitleDisplayMode(.inline)
            .background(ApocalypseTheme.background)
        }
    }
}

// MARK: - Preview

#Preview {
    DefenseTestView()
        .environment(\.colorScheme, .dark)
}

#endif
