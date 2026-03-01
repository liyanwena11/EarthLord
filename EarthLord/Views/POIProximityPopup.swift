//
//  POIProximityPopup.swift
//  EarthLord
//
//  Day 22：POI 接近时的底部弹窗
//

import SwiftUI

struct POIProximityPopup: View {
    let poi: POIPoint
    let onLoot: () -> Void
    let onDismiss: () -> Void

    @State private var isLooting = false
    @State private var showResult = false
    @State private var lootedItems: [BackpackItem] = []
    @State private var cooldownMessage: String? = nil

    // 主题色
    private let cardBackground = Color(red: 0.12, green: 0.1, blue: 0.14)
    private let primaryColor = Color.orange

    var body: some View {
        VStack(spacing: 0) {
            // 拖动指示器
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // 主内容区
            VStack(spacing: 16) {
                // 标题区
                HStack(spacing: 12) {
                    // POI 图标
                    Image(systemName: getPoiIcon(poi.type))
                        .font(.system(size: 28))
                        .foregroundColor(getPoiColor(poi.type))
                        .frame(width: 56, height: 56)
                        .background(getPoiColor(poi.type).opacity(0.15))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: String.LocalizationValue("发现废墟")))
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(poi.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // 关闭按钮
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }

                // 信息栏
                HStack(spacing: 0) {
                    // 危险等级
                    VStack(spacing: 4) {
                        Text(String(localized: String.LocalizationValue("危险等级")))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        HStack(spacing: 2) {
                            ForEach(0..<poi.dangerLevel, id: \.self) { _ in
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(dangerColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 30)
                        .background(Color.white.opacity(0.2))

                    // POI 类型
                    VStack(spacing: 4) {
                        Text(String(localized: String.LocalizationValue("类型")))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(poi.type.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 30)
                        .background(Color.white.opacity(0.2))

                    // 状态
                    VStack(spacing: 4) {
                        Text(String(localized: String.LocalizationValue("状态")))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(poi.status.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(statusColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // 冷却提示
                if let message = cooldownMessage {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // 按钮区
                HStack(spacing: 12) {
                    // 稍后再说
                    Button(action: onDismiss) {
                        Text(String(localized: String.LocalizationValue("稍后再说")))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // 立即搜刮
                    Button(action: performLoot) {
                        HStack {
                            if isLooting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isLooting ? String(localized: String.LocalizationValue("搜刮中...")) : String(localized: String.LocalizationValue("立即搜刮")))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canLoot ? primaryColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canLoot || isLooting)
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
        .sheet(isPresented: $showResult) {
            QuickLootResultView(lootItems: lootedItems)
        }
        .onAppear {
            // ✅ 修复：正确显示冷却状态
            if !poi.isLootable {
                cooldownMessage = poi.cooldownString
            } else {
                cooldownMessage = nil
            }
        }
    }

    // MARK: - Computed Properties

    private var canLoot: Bool {
        // ✅ 修复：移除 cooldownMessage 依赖，直接判断冷却时间
        poi.isLootable && poi.status != .looted
    }

    private var dangerColor: Color {
        switch poi.dangerLevel {
        case 1...2: return .green
        case 3: return .yellow
        case 4: return .orange
        default: return .red
        }
    }

    private var statusColor: Color {
        switch poi.status {
        case .discovered: return .green
        case .looted: return .gray
        case .undiscovered: return .blue
        }
    }

    // MARK: - Methods

    private func performLoot() {
        isLooting = true

        // 生成掉落物品
        lootedItems = ExplorationManager.shared.generateLoot(for: poi.type)

        // 模拟搜刮时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 添加到背包
            ExplorationManager.shared.addItems(items: lootedItems)

            // 标记 POI 已搜空
            RealPOIService.shared.markAsLooted(poiId: poi.id)

            // 记录搜刮到 Supabase
            Task {
                await ExplorationManager.shared.recordPOILoot(poiId: poi.id, items: lootedItems)
            }

            isLooting = false
            showResult = true

            LogDebug("🎲 [POI搜刮] 在「\(poi.name)」搜刮到：\(lootedItems.map { "\($0.name) x\($0.quantity)" }.joined(separator: ", "))")
            // 通知外部完成
            onLoot()
        }
    }

    // MARK: - Helper Methods

    private func getPoiIcon(_ type: POIType) -> String {
        switch type {
        case .hospital: return "cross.case.fill"
        case .supermarket: return "cart.fill"
        case .pharmacy: return "pills.fill"
        case .gasStation: return "fuelpump.fill"
        case .factory: return "hammer.fill"
        case .warehouse: return "shippingbox.fill"
        case .school: return "book.fill"
        }
    }

    private func getPoiColor(_ type: POIType) -> Color {
        switch type {
        case .hospital: return .red
        case .supermarket: return .green
        case .pharmacy: return .purple
        case .gasStation: return .orange
        case .factory: return .gray
        case .warehouse: return .brown
        case .school: return .blue
        }
    }
}
