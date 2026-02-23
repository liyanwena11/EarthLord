//
//  PlayerLocationManager.swift
//  EarthLord
//
//  玩家位置上报 & 附近玩家查询
//

import Foundation
import CoreLocation
import Combine
import Supabase
import UIKit

enum PlayerDensityLevel: String, CaseIterable {
    case alone, low, medium, high

    var maxPOICount: Int {
        switch self { case .alone: return 1; case .low: return 3; case .medium: return 6; case .high: return 15 }
    }

    var displayName: String {
        switch self { case .alone: return "独行者"; case .low: return "低密度"; case .medium: return "中密度"; case .high: return "高密度" }
    }

    static func fromPlayerCount(_ count: Int) -> PlayerDensityLevel {
        switch count { case 0: return .alone; case 1...5: return .low; case 6...20: return .medium; default: return .high }
    }
}

class PlayerLocationManager: ObservableObject {

    static let shared = PlayerLocationManager()

    @Published var nearbyPlayerCount: Int = 0
    @Published var currentDensityLevel: PlayerDensityLevel = .alone
    @Published var lastReportTime: Date?
    @Published var isReporting: Bool = false

    private let supabase = supabaseClient
    private var lastReportedLocation: CLLocation?
    private var lastKnownLocation: CLLocation?
    private var locationCancellable: AnyCancellable?
    private var reportTimer: Timer?
    private var appStateCancellable: AnyCancellable?

    private let reportInterval: TimeInterval = 30.0
    private let movementThreshold: CLLocationDistance = 50.0
    private let queryRadius: Int = 1000

    private init() {}

    func startReporting() {
        guard !isReporting else { return }
        isReporting = true
        LogDebug("🚀 [位置上报] 开始位置上报")
        Task { await reportCurrentLocation(isOnline: true) }

        reportTimer = Timer.scheduledTimer(withTimeInterval: reportInterval, repeats: true) { [weak self] _ in
            Task { await self?.reportCurrentLocation(isOnline: true) }
        }

        appStateCancellable = NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in Task { await self?.reportCurrentLocation(isOnline: false) } }
    }

    func stopReporting() {
        isReporting = false
        reportTimer?.invalidate(); reportTimer = nil
        locationCancellable?.cancel(); locationCancellable = nil
        appStateCancellable?.cancel(); appStateCancellable = nil
        Task { await reportCurrentLocation(isOnline: false) }
        LogDebug("🛑 [位置上报] 停止上报")
    }

    func reportCurrentLocation(isOnline: Bool = true) async {
        guard let location = lastKnownLocation ?? lastReportedLocation else { return }

        do {
            try await supabase.rpc(
                "report_player_location",
                params: [
                    "p_latitude": AnyJSON(location.coordinate.latitude),
                    "p_longitude": AnyJSON(location.coordinate.longitude),
                    "p_is_online": AnyJSON(isOnline)
                ]
            ).execute()
            lastReportTime = Date()
            lastReportedLocation = location
        } catch {
            LogError("❌ [位置上报] 上报失败: \(error.localizedDescription)")
        }
    }

    /// 由外部（LocationManager/ExplorationManager）调用，更新当前位置
    func updateLocation(_ location: CLLocation) {
        lastKnownLocation = location
        checkMovementAndReport(location: location)
    }

    /// 检测移动距离是否超过阈值，超过则立即上报
    private func checkMovementAndReport(location: CLLocation) {
        guard let last = lastReportedLocation else { return }
        if location.distance(from: last) >= movementThreshold {
            LogDebug("📍 [位置上报] 移动超过\(movementThreshold)米，立即上报")
            Task { await reportCurrentLocation(isOnline: true) }
        }
    }

    func queryNearbyPlayerCount() async -> Int {
        guard let location = lastKnownLocation ?? lastReportedLocation else { return 0 }

        do {
            let response: Int = try await supabase.rpc(
                "get_nearby_player_count",
                params: [
                    "p_latitude": AnyJSON(location.coordinate.latitude),
                    "p_longitude": AnyJSON(location.coordinate.longitude),
                    "p_radius_meters": AnyJSON(queryRadius)
                ]
            ).execute().value

            await MainActor.run {
                self.nearbyPlayerCount = response
                self.currentDensityLevel = PlayerDensityLevel.fromPlayerCount(response)
            }
            return response
        } catch {
            LogError("❌ [位置上报] 查询附近玩家失败: \(error.localizedDescription)")
            return 0
        }
    }

    func getMaxPOICount() -> Int { currentDensityLevel.maxPOICount }
}
