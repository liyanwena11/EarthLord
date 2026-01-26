//
//  LocationDebugView.swift
//  EarthLord
//
//  位置调试视图 - 用于测试 GPS、行走奖励和 POI 弹窗
//

import SwiftUI
import CoreLocation

struct LocationDebugView: View {
    @EnvironmentObject var locationManager: LocationManager
    @ObservedObject var walkingRewardManager = WalkingRewardManager.shared
    @ObservedObject var poiService = RealPOIService.shared  // ✅ Day 22：观察 POI 服务

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("位置调试面板")
                    .font(.title.bold())
                    .padding()

                // LocationManager 状态
                GroupBox(label: Label("LocationManager 状态", systemImage: "location.circle.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前位置: \(locationManager.userLocation?.coordinate.latitude ?? 0), \(locationManager.userLocation?.coordinate.longitude ?? 0)")
                            .font(.caption)

                        Text("是否追踪: \(locationManager.isTracking ? "是" : "否")")
                            .font(.caption)

                        Text("路径点数: \(locationManager.pathCoordinates.count)")
                            .font(.caption)
                    }
                    .padding(8)
                }

                // WalkingRewardManager 状态
                GroupBox(label: Label("行走奖励状态", systemImage: "figure.walk")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("累计距离: \(String(format: "%.2f", walkingRewardManager.totalWalkingDistance)) 米")
                            .font(.caption.bold())
                            .foregroundColor(.orange)

                        Text("已解锁等级: \(walkingRewardManager.unlockedTiers.count) 个")
                            .font(.caption)

                        if let nextTier = walkingRewardManager.nextTier {
                            Text("下一等级: \(nextTier.displayName) (\(Int(nextTier.distance))m)")
                                .font(.caption)
                        }
                    }
                    .padding(8)
                }

                // ✅ Day 22：POI 状态
                GroupBox(label: Label("POI 状态", systemImage: "mappin.circle.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已加载 POI: \(poiService.realPOIs.count) 个")
                            .font(.caption)

                        let lootable = poiService.realPOIs.filter { $0.isLootable }.count
                        Text("可搜刮: \(lootable) 个")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("冷却中: \(poiService.realPOIs.count - lootable) 个")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Text("弹窗状态: \(locationManager.showPOIPopup ? "显示中" : "隐藏")")
                            .font(.caption)
                            .foregroundColor(locationManager.showPOIPopup ? .green : .secondary)
                    }
                    .padding(8)
                }

                // 手动测试按钮
                Button(action: {
                    print("🧪 [调试] 手动触发位置读取")
                    if let loc = locationManager.userLocation {
                        print("🧪 [调试] 当前位置: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                        Task { @MainActor in
                            WalkingRewardManager.shared.updateDistance(newLocation: loc)
                        }
                    } else {
                        print("🧪 [调试] locationManager.userLocation 为 nil")
                    }
                }) {
                    Label("手动测试位置更新", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // ✅ Day 22：一键模拟进入 POI 范围
                Button(action: {
                    // 先确保有 POI 数据
                    if poiService.realPOIs.isEmpty {
                        print("🧪 [调试] POI 列表为空，先搜索附近 POI...")
                        poiService.searchNearbyRealPOI(userLocation: locationManager.userLocation?.coordinate)
                        // 延迟触发弹窗
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            locationManager.simulateEnterPOI()
                        }
                    } else {
                        locationManager.simulateEnterPOI()
                    }
                }) {
                    Label("一键模拟进入 POI 范围", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // ✅ Day 22：搜索附近 POI
                Button(action: {
                    print("🧪 [调试] 搜索附近 POI")
                    poiService.searchNearbyRealPOI(userLocation: locationManager.userLocation?.coordinate)
                }) {
                    Label("搜索附近 POI", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // 打印完整状态
                Button(action: {
                    print("📊📊📊 [调试] ========== 完整状态 ==========")
                    print("📍 userLocation: \(locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D())")
                    print("📊 totalWalkingDistance: \(walkingRewardManager.totalWalkingDistance)")
                    print("🏆 unlockedTiers: \(walkingRewardManager.unlockedTiers)")
                    print("🗺️ POI 数量: \(poiService.realPOIs.count)")
                    print("🎯 弹窗状态: \(locationManager.showPOIPopup)")
                }) {
                    Label("打印完整状态到 Console", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // 重置每日进度
                Button(action: {
                    walkingRewardManager.resetDailyProgress()
                    print("🔄 [调试] 每日进度已重置")
                }) {
                    Label("重置每日进度", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}
