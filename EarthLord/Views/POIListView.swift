import SwiftUI
import CoreLocation

struct POIListView: View {
    @StateObject private var engine = EarthLordEngine.shared
    @State private var selectedPOI: POIModel?

    var body: some View {
        VStack(spacing: 0) {
            // 1. 扫描 POI 按钮
            Button(action: {
                // 触发 POI 发现（生产环境使用真实扫描）
                Task {
                    await engine.triggerPOIDiscovery()
                }
            }) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("扫描附近资源点")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()

            // 2. 结果展示
            if engine.nearbyPOIs.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "binoculars.fill").font(.system(size: 60)).foregroundColor(.gray)
                    Text("雷达未发现目标")
                    Text(String(localized: "请点击上方按钮开始扫描")).font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(engine.nearbyPOIs) { poi in
                    Button(action: {
                        selectedPOI = poi
                    }) {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(poi.rarity.color.opacity(0.2))
                                .frame(width: 45, height: 45)
                                .overlay(Image(systemName: "mappin.and.ellipse").foregroundColor(poi.rarity.color))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(poi.name).font(.headline)
                                Text(String(localized: "等级") + ": \(poi.rarity.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(poi.rarity.color)
                                if let userLoc = engine.userLocation {
                                    let dist = userLoc.distance(from: poi.location)
                                    Text(String(localized: "距离") + ": \(Int(dist))m")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(poi.isScavenged ? String(localized: "已搜刮") : String(localized: "可搜刮"))
                                .font(.system(size: 10))
                                .padding(5)
                                .background((poi.isScavenged ? Color.gray : Color.green).opacity(0.1))
                                .foregroundColor(poi.isScavenged ? .gray : .green)
                                .cornerRadius(5)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(poi: poi)
        }
    }
}

// MARK: - POI 详情 Sheet

struct POIDetailSheet: View {
    @StateObject private var engine = EarthLordEngine.shared
    let poi: POIModel
    @Environment(\.dismiss) private var dismiss
    @State private var isScavenging = false
    @State private var scavengedItems: [BackpackItem] = []
    @State private var showLootResult = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 图标和名称
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(poi.rarity.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 40))
                                .foregroundColor(poi.rarity.color)
                        }

                        Text(poi.name)
                            .font(.title2.bold())
                        Text(String(localized: "等级") + ": \(poi.rarity.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(poi.rarity.color)
                    }
                    .padding(.top, 20)

                    // 距离信息
                    if let userLoc = engine.userLocation {
                        let dist = userLoc.distance(from: poi.location)
                        HStack {
                            Image(systemName: "location.fill")
                            Text(String(localized: "距离") + ": \(Int(dist)) " + String(localized: "米"))
                        }
                        .foregroundColor(.secondary)
                    }

                    // 状态
                    HStack {
                        Circle()
                            .fill(poi.isScavenged ? Color.gray : Color.green)
                            .frame(width: 8, height: 8)
                        Text(poi.isScavenged ? String(localized: "已被搜刮") : String(localized: "尚未搜刮"))
                            .foregroundColor(poi.isScavenged ? .gray : .green)
                    }

                    Divider()

                    // 搜刮按钮
                    if !poi.isScavenged {
                        Button(action: {
                            isScavenging = true
                            // 设置 activePOI 并执行搜刮
                            engine.activePOI = poi
                            let items = engine.scavengeWithLoot()
                            scavengedItems = items
                            isScavenging = false

                            // 显示战利品结果
                            if !items.isEmpty {
                                showLootResult = true
                            }

                            // 延迟关闭以显示结果
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                if isScavenging {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "hand.tap.fill")
                                    Text(String(localized: "搜刮资源点"))
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isScavenging)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(String(localized: "已搜刮完毕"))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(String(localized: "资源点详情"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "关闭")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLootResult) {
                LootResultSheet(items: scavengedItems, poiName: poi.name)
            }
        }
    }
}

// MARK: - 战利品结果 Sheet

struct LootResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let items: [BackpackItem]
    let poiName: String

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 成功图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.top, 30)

                Text(String(localized: "搜刮成功!"))
                    .font(.title2.bold())
                Text(String(localized: "从 ") + "\(poiName) " + String(localized: "获得了物资"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // 物品列表
                if items.isEmpty {
                    Text(String(localized: "没有发现任何物品"))
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.icon)
                                    .foregroundColor(itemCategoryColor(item.category))
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("x\(item.quantity)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }

                Spacer()

                Button(String(localized: "收下")) {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle(String(localized: "搜刮结果"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func itemCategoryColor(_ category: ItemCategory) -> Color {
        switch category {
        case .water: return .cyan
        case .food: return .green
        case .medical: return .red
        case .material: return .brown
        case .tool: return .blue
        }
    }
}

