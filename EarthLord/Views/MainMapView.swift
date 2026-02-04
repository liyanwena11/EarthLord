import SwiftUI
import MapKit
import Combine

struct MainMapView: View {
    @StateObject private var engine = EarthLordEngine.shared
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var hasInitiallyLocated = false
    @State private var showLootResult = false
    @State private var lastLootItems: [BackpackItem] = []

    var body: some View {
        ZStack {
            // 1. iOS 17 Map + 标注 + 轨迹线
            Map(position: $cameraPosition) {
                // 用户位置
                UserAnnotation()

                // POI 标注
                ForEach(engine.nearbyPOIs) { poi in
                    Annotation(poi.name, coordinate: poi.location.coordinate) {
                        POIAnnotationView(poi: poi)
                    }
                }

                // 领地标注
                ForEach(engine.claimedTerritories) { territory in
                    Annotation(territory.name, coordinate: territory.location.coordinate) {
                        TerritoryAnnotationView()
                    }
                }

                // 采样轨迹点
                if engine.isTracking {
                    ForEach(Array(engine.pathPoints.enumerated()), id: \.offset) { index, point in
                        Annotation("", coordinate: point.coordinate) {
                            TrackingPointView(index: "\(index + 1)")
                        }
                    }

                    // MapPolyline 轨迹线
                    if engine.pathPoints.count >= 2 {
                        MapPolyline(coordinates: engine.pathPoints.map { $0.coordinate })
                            .stroke(.blue.opacity(0.6), lineWidth: 3)
                    }
                }

                // 已完成领地的多边形轮廓
                ForEach(engine.claimedTerritories) { territory in
                    if !territory.pathCoordinates.isEmpty {
                        MapPolygon(coordinates: territory.pathCoordinates)
                            .stroke(.blue.opacity(0.5), lineWidth: 2)
                            .foregroundStyle(.blue.opacity(0.1))
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls { MapCompass() }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.dark)

            // 2. 顶部：雷达 + 圈地状态
            VStack(spacing: 0) {
                RadarView(count: engine.nearbyPlayerCount, isExploring: engine.isExploring)

                if engine.isTracking || !engine.trackingStatusText.isEmpty {
                    TrackingStatusBar(engine: engine)
                }

                Spacer()
            }

            // 3. 底部按钮区
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Spacer()

                    // 圈地按钮
                    Button(action: {
                        if engine.isTracking {
                            engine.stopTracking()
                        } else {
                            engine.startTracking()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: engine.isTracking ? "stop.fill" : "flag.2.crossed.fill")
                                .font(.title2)
                            Text(engine.isTracking ? "停止" : "圈地")
                                .font(.caption2).bold()
                        }
                        .frame(width: 70, height: 70)
                        .background(engine.isTracking ? Color.orange : Color.red.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(color: (engine.isTracking ? Color.orange : Color.red).opacity(0.4), radius: 10)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120)
                }
            }

            // 4. 搜刮弹窗（AI 版）
            if engine.showProximityAlert, let poi = engine.activePOI {
                VStack {
                    Spacer()
                    ScavengePopup(poi: poi) {
                        Task {
                            let items = await engine.scavengeWithAI()
                            if !items.isEmpty {
                                lastLootItems = items
                                showLootResult = true
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom))
            }

            // 5. 搜刮中 loading
            if engine.isScavenging {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                        Text("AI 正在分析废墟物资...")
                            .font(.subheadline).foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color(white: 0.12))
                    .cornerRadius(20)
                }
            }

            // 6. 搜刮结果弹窗
            if showLootResult {
                LootResultOverlay(items: lastLootItems) {
                    showLootResult = false
                    lastLootItems = []
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            if engine.nearbyPOIs.isEmpty {
                engine.createMultipleTestPOIs(count: 3)
            }
        }
    }
}

// MARK: - 采样轨迹点

struct TrackingPointView: View {
    let index: String
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 20, height: 20)
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: .green, radius: 4)
            Text(index)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .offset(y: -14)
        }
    }
}

// MARK: - 领地标注

struct TerritoryAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 60, height: 60)
            Circle()
                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                .frame(width: 60, height: 60)
            Image(systemName: "flag.fill")
                .foregroundColor(.blue)
                .font(.caption)
        }
    }
}

// MARK: - POI 标注

struct POIAnnotationView: View {
    let poi: POIModel
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(poi.isScavenged ? Color.gray.opacity(0.5) : poi.rarity.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: poi.isScavenged ? "checkmark.circle.fill" : "mappin.circle.fill")
                    .font(.title3)
                    .foregroundColor(poi.isScavenged ? .gray : poi.rarity.color)
            }
            Text(poi.name)
                .font(.system(size: 8))
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(4)
            Text(poi.rarity.rawValue)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(poi.rarity.color)
        }
    }
}

// MARK: - 采样实时悬浮窗

struct TrackingStatusBar: View {
    @ObservedObject var engine: EarthLordEngine

    var body: some View {
        HStack(spacing: 12) {
            if engine.isTracking {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(engine.isTracking ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: engine.isTracking)
            }

            VStack(alignment: .leading, spacing: 2) {
                if engine.isTracking {
                    let needed = engine.requiredSamplingPoints
                    let penalty = needed > GameConfig.SAMPLING_MIN_POINTS
                    HStack(spacing: 4) {
                        Text("采样 \(engine.pathPoints.count)/\(needed)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        if penalty {
                            Text("负重")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.red.opacity(0.3))
                                .foregroundColor(.red)
                                .cornerRadius(3)
                        }
                    }
                    HStack(spacing: 8) {
                        Text("距离 \(Int(engine.trackingDistance))m")
                        Text("面积 \(Int(engine.estimatedArea))㎡")
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.green)
                } else {
                    Text(engine.trackingStatusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            Spacer()

            if engine.isTracking && engine.pathPoints.count >= 3 {
                Button("完成") {
                    engine.forceFinishTracking()
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 雷达

struct RadarView: View {
    let count: Int
    let isExploring: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isExploring ? "📡 正在探索周边..." : "SURVIVAL RADAR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isExploring ? .yellow : .gray)
                Text("附近幸存者: \(count) 人")
                    .font(.callout).bold()
                    .foregroundColor(.white)
            }
            Spacer()
            Circle()
                .fill(isExploring ? Color.yellow : Color.green)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

// MARK: - 搜刮弹窗

struct ScavengePopup: View {
    let poi: POIModel
    let action: () -> Void
    @ObservedObject private var backpack = ExplorationManager.shared

    var body: some View {
        VStack(spacing: 15) {
            VStack(spacing: 5) {
                Text("发现目标").font(.caption).foregroundColor(.gray)
                Text(poi.name).font(.headline).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text("物资等级：\(poi.rarity.rawValue)")
                        .foregroundColor(poi.rarity.color).bold()
                    Text("[AI]")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.purple.opacity(0.3))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }

            HStack {
                Image(systemName: "scalemass.fill").font(.caption).foregroundColor(.orange)
                Text("负重 \(String(format: "%.1f", backpack.totalWeight))/\(Int(backpack.maxCapacity)) kg")
                    .font(.caption).foregroundColor(.gray)
            }

            Button(action: action) {
                Text("开始搜刮")
                    .bold().frame(maxWidth: .infinity).padding()
                    .background(poi.rarity.color).foregroundColor(.black).cornerRadius(12)
            }
            .disabled(backpack.totalWeight >= backpack.maxCapacity)
        }
        .padding(25)
        .background(Color(white: 0.12))
        .cornerRadius(25)
        .padding(.horizontal)
        .shadow(radius: 20)
    }
}

// MARK: - 搜刮结果弹窗（含 AI 标签 + 背景故事）

struct LootResultOverlay: View {
    let items: [BackpackItem]
    let onDismiss: () -> Void
    @State private var expandedItemId: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                .onTapGesture { onDismiss() }

            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("搜刮成功").font(.title2.bold()).foregroundColor(.white)

                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            VStack(spacing: 0) {
                                // 物品行
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedItemId = expandedItemId == item.id ? nil : item.id
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: item.icon)
                                            .foregroundColor(rarityColor(item.itemRarity))
                                            .frame(width: 30)
                                        Text(item.name).foregroundColor(.white)
                                        if item.isAIGenerated {
                                            Text("AI")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 4).padding(.vertical, 1)
                                                .background(Color.purple.opacity(0.4))
                                                .foregroundColor(.purple)
                                                .cornerRadius(3)
                                        }
                                        if let rarity = item.itemRarity {
                                            Text(rarity.rawValue)
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(rarity.color)
                                        }
                                        Spacer()
                                        Text("x\(item.quantity)").bold().foregroundColor(.orange)
                                        Text("\(String(format: "%.1f", item.weight * Double(item.quantity)))kg")
                                            .font(.caption).foregroundColor(.gray)
                                        if item.backstory != nil {
                                            Image(systemName: expandedItemId == item.id ? "chevron.up" : "chevron.down")
                                                .font(.caption2).foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 10)
                                }

                                // 背景故事展开区
                                if expandedItemId == item.id, let story = item.backstory {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.orange.opacity(0.6))
                                            .frame(width: 3)
                                        Text(story)
                                            .font(.caption)
                                            .foregroundColor(.orange.opacity(0.9))
                                            .italic()
                                            .padding(.vertical, 8)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                    .background(Color.orange.opacity(0.05))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                if item.id != items.last?.id {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // 当前负重
                    let backpack = ExplorationManager.shared
                    HStack {
                        Image(systemName: "scalemass.fill").foregroundColor(.orange)
                        Text("背包负重：\(String(format: "%.1f", backpack.totalWeight)) / \(Int(backpack.maxCapacity)) kg")
                            .foregroundColor(.gray)
                    }
                    .font(.caption)

                    Button(action: onDismiss) {
                        Text("收下物资")
                            .bold().frame(maxWidth: .infinity).padding()
                            .background(Color.orange).foregroundColor(.black).cornerRadius(12)
                    }
                }
                .padding(30)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .background(Color(white: 0.12))
            .cornerRadius(25)
            .padding(.horizontal, 20)
            .shadow(radius: 20)
        }
    }

    private func rarityColor(_ rarity: POIRarity?) -> Color {
        rarity?.color ?? .blue
    }
}
