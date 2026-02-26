//
//  AchievementIntegrationExamples.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就系统集成示例 - 展示如何在游戏事件中触发成就
//

import Foundation

/**
 ========================================
 成就系统集成指南
 ========================================

 在以下游戏事件中调用 AchievementManager 来更新成就进度：

 1. 建筑相关事件
 2. 资源收集事件
 3. 领地管理事件
 4. 探索事件
 5. 交易事件
 6. 社交事件

 ========================================
*/

// MARK: - 1. 建筑相关事件示例

extension EarthLordEngine {
    /// 当玩家建造建筑时调用
    func onBuildingBuilt(buildingType: String) async {
        // 更新成就进度
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "build_\(buildingType)",
            currentValue: getBuildingCount(type: buildingType)
        )

        // 同时检查 "任意建筑" 成就
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "build_any",
            currentValue: getTotalBuildingCount()
        )
    }

    private func getBuildingCount(type: String) -> Int {
        // 返回指定类型建筑的数量
        return 0 // 实际实现
    }

    private func getTotalBuildingCount() -> Int {
        // 返回所有建筑的总数
        return 0 // 实际实现
    }
}

// MARK: - 2. 资源收集事件示例

extension ExplorationManager {
    /// 当玩家收集资源时调用
    func onResourceCollected(resourceType: String, amount: Int) async {
        let totalCollected = getTotalResourceCollected(resourceType: resourceType)

        // 更新特定资源成就
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "resource_\(resourceType)",
            currentValue: totalCollected
        )

        // 更新总资源成就
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "resource_any",
            currentValue: getTotalAllResources()
        )
    }

    private func getTotalResourceCollected(resourceType: String) -> Int {
        // 返回收集的指定资源总量
        return 0 // 实际实现
    }

    private func getTotalAllResources() -> Int {
        // 返回所有资源的总量
        return 0 // 实际实现
    }
}

// MARK: - 3. 领地管理事件示例

extension TerritoryManager {
    /// 当玩家占领新领地时调用
    func onTerritoryClaimed() async {
        let territoryCount = territories.count

        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "territory_count",
            currentValue: territoryCount
        )
    }

    /// 当领地升级时调用
    func onTerritoryLevelUp(territoryId: UUID, newLevel: Int) async {
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "territory_level",
            currentValue: newLevel
        )
    }
}

// MARK: - 4. 探索事件示例

extension ExplorationManager {
    /// 当玩家探索POI时调用
    func onPOIScavenged(poiId: String) async {
        let scavengedCount = getScavengedPOICount()

        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "poi_scavenged",
            currentValue: scavengedCount
        )
    }

    private func getScavengedPOICount() -> Int {
        // 返回已探索的POI数量
        return 0 // 实际实现
    }
}

// MARK: - 5. 交易事件示例

extension TradeManager {
    /// 当玩家完成交易时调用
    func onTradeCompleted() async {
        let tradeCount = getCompletedTradeCount()

        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "trade_completed",
            currentValue: tradeCount
        )
    }

    private func getCompletedTradeCount() -> Int {
        // 返回完成的交易次数
        return 0 // 实际实现
    }
}

// MARK: - 6. 社交事件示例

class SocialManager {
    static let shared = SocialManager()

    /// 当添加好友时调用
    func onFriendAdded() async {
        let friendCount = getFriendCount()

        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "social_friend",
            currentValue: friendCount
        )
    }

    /// 当帮助好友时调用
    func onHelpedFriend() async {
        let helpCount = getHelpCount()

        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "social_help",
            currentValue: helpCount
        )
    }

    /// 当加入公会时调用
    func onGuildJoined() async {
        await AchievementManager.shared.checkAndUnlockAchievements(
            requirementType: "social_guild",
            currentValue: 1
        )
    }

    private func getFriendCount() -> Int { return 0 }
    private func getHelpCount() -> Int { return 0 }
}

// MARK: - 集成检查清单

/**
 ✅ 集成检查清单：

 1. 数据库迁移
    □ 执行 supabase_migration_009_tasks_achievements.sql
    □ 执行 supabase_migration_010_achievement_leaderboard.sql
    □ 执行 supabase_migration_011_achievement_data.sql

 2. 在游戏引擎中添加事件触发
    □ EarthLordEngine - 建筑事件
    □ ExplorationManager - 资源收集事件
    □ TerritoryManager - 领地事件
    □ ExplorationManager - 探索事件
    □ TradeManager - 交易事件
    □ SocialManager - 社交事件（如果有的话）

 3. 在应用启动时初始化
    □ 在 EarthLordApp.swift 中添加 AchievementManager.shared
    □ 在用户登录后调用 refreshData()

 4. 测试
    □ 手动测试每个成就是否可以正确解锁
    □ 检查排行榜是否正确更新
    □ 验证个人界面的成就统计显示

 ========================================
 测试方法
 ========================================

 可以在测试视图中添加以下代码来手动触发成就：

 ```swift
 // 测试解锁建筑成就
 Button("测试建筑成就") {
     Task {
         try? await AchievementManager.shared.updateProgress(
             achievementId: "build_first",
             progress: 1.0
         )
     }
 }

 // 测试解锁资源成就
 Button("测试资源成就") {
     Task {
         try? await AchievementManager.shared.updateProgress(
             achievementId: "resource_1000",
             progress: 1.0
         )
     }
 }

 // 测试刷新排行榜
 Button("刷新排行榜") {
     Task {
         try? await LeaderboardManager.shared.recalculateAllRankings()
     }
 }
 ```

 ========================================
 故障排查
 ========================================

 问题：成就没有显示
 解决：
 1. 检查数据库中是否有成就数据
    ```sql
    SELECT COUNT(*) FROM achievements;
    ```
 2. 确认用户已登录
 3. 查看 Xcode 控制台是否有错误信息

 问题：排行榜没有更新
 解决：
 1. 检查数据库触发器是否正常工作
    ```sql
    -- 手动更新排行榜
    SELECT update_user_achievement_leaderboard('user-id');
    ```
 2. 查看触发器日志
 3. 手动重新计算排名
    ```sql
    SELECT recalculate_leaderboard_rankings();
    ```

 问题：成就进度没有保存
 解决：
 1. 检查 RLS 策略是否正确
 2. 确认 Supabase 连接正常
 3. 查看数据库日志

 ========================================
 性能优化建议
 ========================================

 1. 缓存成就数据
    - AchievementManager 已使用 @Published 属性自动缓存

 2. 批量更新
    - 使用 checkAndUnlockAchievements 批量检查多个成就
    - 避免频繁调用 updateProgress

 3. 后台更新
    - 排行榜更新由数据库触发器自动完成
    - 不需要在应用层手动更新排行榜

 4. 懒加载
    - 在用户打开成就界面时才加载详细数据
    - 避免在启动时加载所有成就

 ========================================
*/