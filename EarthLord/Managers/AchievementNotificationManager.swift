//
//  AchievementNotificationManager.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就通知管理器 - 处理成就解锁通知、动画和反馈
//

import SwiftUI
import UserNotifications

/// 成就通知管理器（单例）
class AchievementNotificationManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AchievementNotificationManager()

    // MARK: - Published Properties
    @Published var pendingNotifications: [UnlockedAchievement] = []
    @Published var isShowingPopup = false
    @Published var currentPopupAchievement: UnlockedAchievement?

    // MARK: - Private Properties
    private var notificationQueue: [UnlockedAchievement] = []
    private var isProcessingQueue = false
    private let maxQueueSize = 5

    // MARK: - Initialization
    private override init() {
        super.init()
        setupNotificationDelegate()
        requestNotificationPermission()
    }

    // MARK: - Setup
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 请求通知权限
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ [AchievementNotification] 通知权限已授予")
            } else {
                print("⚠️ [AchievementNotification] 通知权限被拒绝")
            }
            if let error = error {
                print("❌ [AchievementNotification] 请求权限错误: \(error)")
            }
        }
    }

    // MARK: - Public Methods

    /// 显示成就解锁通知
    /// - Parameters:
    ///   - achievement: 解锁的成就
    ///   - autoDismiss: 是否自动消失（默认 true）
    func showAchievementUnlocked(_ achievement: Achievement, autoDismiss: Bool = true) {
        let unlockedAchievement = UnlockedAchievement(
            achievement: achievement,
            unlockedAt: Date()
        )

        DispatchQueue.main.async {
            // 添加到队列
            self.notificationQueue.append(unlockedAchievement)

            // 限制队列大小
            if self.notificationQueue.count > self.maxQueueSize {
                self.notificationQueue.removeFirst()
            }

            self.pendingNotifications = self.notificationQueue

            // 处理队列
            self.processQueue()
        }

        // 发送本地通知
        sendLocalNotification(for: achievement)

        // 触觉反馈
        triggerHapticFeedback()

        // 播放音效
        playUnlockSound()
    }

    /// 批量显示成就解锁通知
    /// - Parameter achievements: 解锁的成就数组
    func showMultipleAchievementsUnlocked(_ achievements: [Achievement]) {
        guard !achievements.isEmpty else { return }

        DispatchQueue.main.async {
            for achievement in achievements {
                let unlockedAchievement = UnlockedAchievement(
                    achievement: achievement,
                    unlockedAt: Date()
                )
                self.notificationQueue.append(unlockedAchievement)
            }

            // 限制队列大小
            if self.notificationQueue.count > self.maxQueueSize {
                self.notificationQueue = Array(self.notificationQueue.suffix(self.maxQueueSize))
            }

            self.pendingNotifications = self.notificationQueue
            self.processQueue()
        }

        // 触觉反馈（多次）
        for achievement in achievements {
            triggerHapticFeedback()
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(achievements.firstIndex(of: achievement) ?? 0) * 0.3) {
                self.sendLocalNotification(for: achievement)
            }
        }
    }

    /// 手动关闭当前弹窗
    func dismissPopup() {
        DispatchQueue.main.async {
            self.isShowingPopup = false
            self.currentPopupAchievement = nil
            self.isProcessingQueue = false

            // 继续处理队列
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.processQueue()
            }
        }
    }

    /// 清空通知队列
    func clearQueue() {
        DispatchQueue.main.async {
            self.notificationQueue.removeAll()
            self.pendingNotifications.removeAll()
            self.isProcessingQueue = false
            self.isShowingPopup = false
            self.currentPopupAchievement = nil
        }
    }

    // MARK: - Private Methods

    /// 处理通知队列
    private func processQueue() {
        guard !isProcessingQueue && !notificationQueue.isEmpty else { return }

        isProcessingQueue = true

        // 取出第一个通知
        let achievement = notificationQueue.removeFirst()
        pendingNotifications = notificationQueue

        // 显示弹窗
        DispatchQueue.main.async {
            self.currentPopupAchievement = achievement
            self.isShowingPopup = true

            // 3秒后自动关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.isShowingPopup {
                    self.dismissPopup()
                }
            }
        }
    }

    /// 发送本地通知
    private func sendLocalNotification(for achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 成就解锁！"
        content.body = "\(achievement.icon) \(achievement.title)"
        content.sound = .default

        // 添加徽章数量
        content.badge = NSNumber(value: pendingNotifications.count + 1)

        // 添加用户信息
        content.userInfo = [
            "achievementId": achievement.id,
            "type": "achievement_unlocked"
        ]

        // 立即触发
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [AchievementNotification] 发送通知失败: \(error)")
            }
        }
    }

    /// 触觉反馈
    private func triggerHapticFeedback() {
        // 使用通知类型的反馈（成功）
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // 额外的震动反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
        }
    }

    /// 播放解锁音效
    private func playUnlockSound() {
        // 使用系统音效
        AudioServicesPlaySystemSound(1520) // SystemSoundId for achievement unlock
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AchievementNotificationManager: UNUserNotificationCenterDelegate {

    /// 前台通知显示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 通知点击处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // 处理成就解锁通知点击
        if let achievementIdString = userInfo["achievementId"] as? String,
           let achievementId = UUID(uuidString: achievementIdString),
           userInfo["type"] as? String == "achievement_unlocked" {

            print("🎯 [AchievementNotification] 用户点击了成就通知: \(achievementId)")

            // TODO: 跳转到成就详情页面
            // NotificationCenter.default.post(name: .showAchievementDetail, object: achievementId)
        }

        completionHandler()
    }
}

// MARK: - Data Models

/// 解锁的成就数据模型
struct UnlockedAchievement: Identifiable {
    let id = UUID()
    let achievement: Achievement
    let unlockedAt: Date
}

// MARK: - Notification Names
extension Notification.Name {
    static let showAchievementDetail = Notification.Name("showAchievementDetail")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - External Audio Function
import AVFoundation

/// 播放系统音效
@_silgen_name("AudioServicesPlaySystemSound")
private func systemSoundPlay(_ inSystemSoundID: SystemSoundID)
