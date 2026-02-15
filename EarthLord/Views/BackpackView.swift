import SwiftUI

struct BackpackView: View {
    @ObservedObject private var manager = ExplorationManager.shared
    @State private var usedItemName: String?
    @State private var showUsedToast = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. 实时负重显示卡
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "scalemass.fill").foregroundColor(.orange)
                    Text("背包负重").font(.headline)
                    Spacer()
                    Text("\(String(format: "%.1f", manager.totalWeight)) / \(Int(manager.maxCapacity)) kg")
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(weightColor)
                }

                ProgressView(value: min(manager.totalWeight, manager.maxCapacity), total: manager.maxCapacity)
                    .tint(weightColor)
                    .scaleEffect(x: 1, y: 1.5)
                    .animation(.easeInOut(duration: 0.3), value: manager.totalWeight)

                HStack(spacing: 12) {
                    Label("\(manager.backpackItems.count) 种", systemImage: "archivebox")
                    Label("\(totalQuantity) 件", systemImage: "number")
                    Spacer()
                    if manager.totalWeight >= manager.maxCapacity {
                        Text("已满载").font(.caption).bold()
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.red.opacity(0.2)).foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
                .font(.caption).foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .padding()

            // 2. 物品列表
            if manager.backpackItems.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "shippingbox").font(.system(size: 60)).foregroundColor(.gray)
                    Text("背包空空如也").foregroundColor(.gray)
                    Text("探索废墟搜刮物资吧").font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(manager.backpackItems) { item in
                        BackpackItemRow(item: item, onUse: {
                            withAnimation {
                                manager.useItem(item: item)
                                usedItemName = item.name
                                showUsedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    showUsedToast = false
                                }
                            }
                        })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("物资背包")
        .onAppear { manager.updateWeight() }
        .id(manager.backpackItems.count)
        // 使用提示 Toast
        .overlay(alignment: .top) {
            if showUsedToast, let name = usedItemName {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("已使用：\(name)").font(.subheadline.bold()).foregroundColor(.white)
                }
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .cornerRadius(20)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showUsedToast)
            }
        }
    }

    private var weightColor: Color {
        if manager.totalWeight >= manager.maxCapacity { return .red }
        if manager.totalWeight > manager.maxCapacity * 0.8 { return .orange }
        return .green
    }

    private var totalQuantity: Int {
        manager.backpackItems.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - 背包物品行（修复按钮可点击性）

struct BackpackItemRow: View {
    let item: BackpackItem
    let onUse: () -> Void
    @State private var showStory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // 左侧：图标 + 信息（可点击展开故事）
                Button(action: {
                    guard item.backstory != nil else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { showStory.toggle() }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(categoryColor(item.category).opacity(0.15))
                                .frame(width: 46, height: 46)
                            Image(systemName: item.icon)
                                .foregroundColor(categoryColor(item.category))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Text(item.name).font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.primary)
                                if item.isAIGenerated {
                                    Text("AI")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4).padding(.vertical, 1)
                                        .background(Color.purple.opacity(0.3))
                                        .foregroundColor(.purple).cornerRadius(3)
                                }
                                if let rarity = item.itemRarity {
                                    Text(rarity.rawValue)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(rarity.color)
                                }
                                if let quality = item.quality {
                                    Text(quality.rawValue)
                                        .font(.system(size: 9)).bold()
                                        .padding(.horizontal, 4).padding(.vertical, 1)
                                        .background(qualityColor(quality).opacity(0.15))
                                        .foregroundColor(qualityColor(quality)).cornerRadius(3)
                                }
                            }
                            HStack(spacing: 6) {
                                Text(item.category.rawValue).font(.caption2).foregroundColor(categoryColor(item.category))
                                Text("\(String(format: "%.1f", item.weight))kg/个").font(.caption2).foregroundColor(.secondary)
                                Text("共\(String(format: "%.1f", item.totalWeight))kg").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // 右侧：数量 + 使用按钮（独立点击区域）
                VStack(alignment: .trailing, spacing: 6) {
                    Text("x\(item.quantity)").font(.headline).foregroundColor(.orange)
                    Button(action: onUse) {
                        Text("使用")
                            .font(.caption2).bold()
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.vertical, 6)

            // 背景故事展开
            if showStory, let story = item.backstory {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(Color.orange.opacity(0.5)).frame(width: 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("物品档案").font(.system(size: 9, weight: .bold)).foregroundColor(.orange.opacity(0.7))
                        Text(story).font(.caption).foregroundColor(.secondary).italic()
                    }
                }
                .padding(.vertical, 8).padding(.horizontal, 4)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func categoryColor(_ category: ItemCategory) -> Color {
        switch category {
        case .water: return .cyan
        case .food: return .green
        case .medical: return .red
        case .material: return .brown
        case .tool: return .blue
        }
    }

    private func qualityColor(_ quality: ItemQuality) -> Color {
        switch quality {
        case .poor: return .gray
        case .normal: return .white
        case .good: return .green
        case .excellent: return .orange
        }
    }
}
