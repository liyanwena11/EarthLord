import Foundation
import CoreLocation
import Combine

@MainActor
class WalkingRewardManager: ObservableObject {
    static let shared = WalkingRewardManager()

    // MARK: - Published Properties

    @Published var totalWalkingDistance: Double = 0.0  // 总行走距离（米）
    @Published var unlockedTiers: Set<Int> = []        // 已解锁的等级
    @Published var recentReward: WalkingRewardTier?    // 最近获得的奖励
    @Published var showRewardNotification = false      // 显示奖励通知

    // MARK: - Constants

    private let maxSpeed: Double = 30.0  // 30 km/h = 8.33 m/s
    private let maxSpeedMPS: Double = 8.33  // 米/秒

    // MARK: - Private Properties

    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?
    private var rewardRecords: [WalkingRewardRecord] = []

    // ✅ 连续超速检测
    private var speedingStartTime: Date?
    private let maxSpeedingDuration: TimeInterval = 10.0  // 10秒
    private var isSpeedViolationActive = false

    private init() {
        print("🚀 [奖励系统] WalkingRewardManager 初始化开始")
        loadProgress()
        print("✅ [奖励系统] WalkingRewardManager 初始化完成")
        print("📊 [奖励系统] 当前累计距离: \(String(format: "%.2f", totalWalkingDistance))m")
        print("🏆 [奖励系统] 已解锁等级: \(unlockedTiers.count) 个")
    }

    // MARK: - Distance Tracking

    /// 更新行走距离（由 LocationManager 调用）
    func updateDistance(newLocation: CLLocation) {
        print("🏃 [奖励系统] 正在计算距离... 新位置: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        print("🏃 [奖励系统] 当前累计距离: \(String(format: "%.2f", totalWalkingDistance))m")

        defer {
            lastLocation = newLocation
            lastUpdateTime = Date()
            print("💾 [奖励系统] 已保存当前位置为 lastLocation")
        }

        // 首次定位，不计算距离
        guard let lastLoc = lastLocation, let lastTime = lastUpdateTime else {
            print("⚪️ [奖励系统] 首次定位，初始化位置（不计算距离）")
            return
        }

        print("📏 [奖励系统] 上次位置: \(lastLoc.coordinate.latitude), \(lastLoc.coordinate.longitude)")
        print("⏱️ [奖励系统] 上次时间: \(lastTime)")

        // 计算时间间隔
        let timeInterval = Date().timeIntervalSince(lastTime)
        guard timeInterval > 0 else { return }

        // 计算距离
        let distanceMoved = newLocation.distance(from: lastLoc)

        // 速度检测：30 km/h 限制
        let speed = distanceMoved / timeInterval  // 米/秒
        let speedKmH = speed * 3.6  // 转换为 km/h

        print("🚶 [奖励系统] 本次移动距离: \(String(format: "%.2f", distanceMoved))m, 速度: \(String(format: "%.1f", speedKmH)) km/h")

        // ✅ 增强：连续超速检测
        if speed > maxSpeedMPS {
            if speedingStartTime == nil {
                speedingStartTime = Date()
                print("⚠️ [WalkingReward] 开始计时超速")
            } else {
                let speedingDuration = Date().timeIntervalSince(speedingStartTime!)
                if speedingDuration > maxSpeedingDuration {
                    if !isSpeedViolationActive {
                        isSpeedViolationActive = true
                        print("🛑 [WalkingReward] 连续超速 \(Int(maxSpeedingDuration)) 秒，系统自动终止距离累计")
                        // 可选：发送通知告知用户
                    }
                    return
                }
                print("⚠️ [WalkingReward] 超速持续 \(String(format: "%.1f", speedingDuration)) 秒 (速度: \(String(format: "%.1f", speedKmH)) km/h)")
            }
            return
        } else {
            // 恢复正常速度，重置超速计时
            if speedingStartTime != nil {
                print("✅ [WalkingReward] 速度恢复正常")
            }
            speedingStartTime = nil
            isSpeedViolationActive = false
        }

        // 距离过滤：忽略小于3米的移动（降低阈值以便测试）
        guard distanceMoved >= 3.0 else {
            print("⏭️ [奖励系统] 距离太小(< 3m)，忽略: \(String(format: "%.2f", distanceMoved))m")
            return
        }

        print("✅ [奖励系统] 距离检查通过！准备累加: \(String(format: "%.2f", distanceMoved))m")

        // 累加距离
        let previousDistance = totalWalkingDistance
        totalWalkingDistance += distanceMoved

        print("🎉🎉🎉 [奖励系统] 累计距离更新！")
        print("📊 [奖励系统] 之前: \(String(format: "%.2f", previousDistance))m")
        print("📊 [奖励系统] 现在: \(String(format: "%.2f", totalWalkingDistance))m")
        print("📊 [奖励系统] 新增: \(String(format: "%.2f", distanceMoved))m")
        print("🏆 [奖励系统] 已解锁等级数: \(unlockedTiers.count)")

        // 检查是否解锁新等级
        checkAndUnlockTiers(from: previousDistance, to: totalWalkingDistance)

        // 保存进度
        saveProgress()
    }

    // MARK: - Testing & Simulation

    /// 🧪 模拟行走（仅用于测试）
    func simulateWalking(distance: Double) {
        let oldDistance = totalWalkingDistance
        totalWalkingDistance += distance
        print("🧪 [测试] 模拟行走 +\(Int(distance))m，当前总距离：\(Int(totalWalkingDistance))m")

        // 触发奖励检查
        checkAndUnlockTiers(from: oldDistance, to: totalWalkingDistance)

        // 保存进度
        saveProgress()
    }

    // MARK: - Reward System

    /// 检查并解锁新等级
    private func checkAndUnlockTiers(from oldDistance: Double, to newDistance: Double) {
        for tier in WalkingRewardTier.allCases {
            let tierDistance = tier.distance

            // 检查是否跨越了这个等级的阈值
            if oldDistance < tierDistance && newDistance >= tierDistance {
                unlockTier(tier)
            }
        }
    }

    /// 解锁等级并发放奖励
    private func unlockTier(_ tier: WalkingRewardTier) {
        // 防止重复解锁
        guard !unlockedTiers.contains(tier.rawValue) else { return }

        print("🎉 [WalkingReward] 解锁等级: \(tier.displayName) (\(Int(tier.distance))m)")

        unlockedTiers.insert(tier.rawValue)
        recentReward = tier
        showRewardNotification = true

        // 发放奖励到背包
        let rewards = tier.rewards
        ExplorationManager.shared.addItems(items: rewards)

        // 记录奖励
        let record = WalkingRewardRecord(
            tier: tier.rawValue,
            distance: tier.distance,
            timestamp: Date(),
            itemsReceived: rewards.map { $0.itemId }
        )
        rewardRecords.append(record)

        print("🎁 [WalkingReward] 发放奖励: \(rewards.map { $0.name }.joined(separator: ", "))")
    }

    // MARK: - Reset & Save

    /// 重置每日进度
    func resetDailyProgress() {
        print("🔄 [WalkingReward] 重置每日进度")
        totalWalkingDistance = 0.0
        unlockedTiers.removeAll()
        rewardRecords.removeAll()
        saveProgress()
    }

    /// 保存进度到 UserDefaults
    private func saveProgress() {
        UserDefaults.standard.set(totalWalkingDistance, forKey: "WalkingReward_TotalDistance")
        UserDefaults.standard.set(Array(unlockedTiers), forKey: "WalkingReward_UnlockedTiers")

        if let encoded = try? JSONEncoder().encode(rewardRecords) {
            UserDefaults.standard.set(encoded, forKey: "WalkingReward_Records")
        }
    }

    /// 加载进度
    private func loadProgress() {
        totalWalkingDistance = UserDefaults.standard.double(forKey: "WalkingReward_TotalDistance")

        if let tiers = UserDefaults.standard.array(forKey: "WalkingReward_UnlockedTiers") as? [Int] {
            unlockedTiers = Set(tiers)
        }

        if let data = UserDefaults.standard.data(forKey: "WalkingReward_Records"),
           let records = try? JSONDecoder().decode([WalkingRewardRecord].self, from: data) {
            rewardRecords = records
        }

        print("📂 [WalkingReward] 加载进度: \(Int(totalWalkingDistance))m, 已解锁: \(unlockedTiers.count) 个等级")
    }

    // MARK: - Public Getters

    /// 获取下一个等级
    var nextTier: WalkingRewardTier? {
        return WalkingRewardTier.allCases.first { tier in
            !unlockedTiers.contains(tier.rawValue)
        }
    }

    /// 获取下一个等级还需要的距离
    var distanceToNextTier: Double {
        guard let next = nextTier else { return 0 }
        return max(0, next.distance - totalWalkingDistance)
    }
}
