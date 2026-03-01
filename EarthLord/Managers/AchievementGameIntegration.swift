//
//  AchievementGameIntegration.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就系统集成 - 在游���事件中触发成就检查
//

import Foundation
import SwiftUI

/// 成就游戏事件集成器
class AchievementGameIntegration {

    // MARK: - Singleton
    static let shared = AchievementGameIntegration()

    private init() {}

    // MARK: - 触发成就刷新（简化实现）

    /// 触发领地占领成就检查
    func checkTerritoryAchievements(territoryCount: Int) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] 领地成就进度已更新，总数: \(territoryCount)")
        }
    }

    /// 触发领地面积成就检查
    func checkTerritoryAreaAchievements(area: Double) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] 领地面积成就进度已更新，面积: \(Int(area))㎡")
        }
    }

    /// 触发POI发现成就检查
    func checkPOIDiscoveryAchievements(discoveredCount: Int) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] POI发现成就进度已更新，总数: \(discoveredCount)")
        }
    }

    /// 触发POI搜刮成就检查
    func checkScavengeAchievements(scavengedCount: Int, rarity: String? = nil) {
        Task {
            await AchievementManager.shared.refreshData()
            if let rarity = rarity {
                LogDebug("🏆 [成就] 搜刮成就进度已更新，总数: \(scavengedCount)，稀有度: \(rarity)")
            }
        }
    }

    /// 触发资源收集成就检查
    func checkResourceCollectionAchievements(itemType: String, count: Int) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] 资源收集成就进度已更新，类型: \(itemType)，数量: \(count)")
        }
    }

    /// 触发背包容量成就检查
    func checkBackpackCapacityAchievements(capacity: Int) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] 背包容量成就进度已更新，容量: \(capacity)")
        }
    }

    /// 触发移动距离成就检查
    func checkTravelDistanceAchievements(distance: Double) {
        Task {
            await AchievementManager.shared.refreshData()
            LogDebug("🏆 [成就] 移动距离成就进度已更新，距离: \(Int(distance))m")
        }
    }
}
