//
//  TerritoryBuildingRow.swift
//  EarthLord
//
//  领地建筑行组件（在领地详情页显示建筑）
//

import SwiftUI

struct TerritoryBuildingRow: View {
    let building: PlayerBuilding
    let template: BuildingTemplate
    var onUpgrade: (() -> Void)?
    var onDemolish: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：分类图标
            ZStack {
                Circle()
                    .fill(template.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: template.icon)
                    .font(.title3)
                    .foregroundColor(template.category.color)
            }

            // 中间：名称 + 状态
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("Lv.\(building.level)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)

                    if building.level >= template.maxLevel {
                        Text("MAX")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Text(building.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(building.status.color)
                        .cornerRadius(4)

                    if building.status == .constructing || building.status == .upgrading {
                        Text(building.formattedRemainingTime)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // 右侧：操作菜单或进度环
            if building.status == .active {
                Menu {
                    if building.level >= template.maxLevel {
                        Button {} label: {
                            Label("已达最高等级", systemImage: "checkmark.circle.fill")
                        }
                        .disabled(true)
                    } else {
                        Button {
                            onUpgrade?()
                        } label: {
                            Label("升级", systemImage: "arrow.up.circle")
                        }
                    }

                    Button(role: .destructive) {
                        onDemolish?()
                    } label: {
                        Label("拆除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            } else if building.status == .constructing || building.status == .upgrading {
                CircularProgressView(progress: building.buildProgress)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

/// 圆形进度视图
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(ApocalypseTheme.background, lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }
}
