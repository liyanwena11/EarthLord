//
//  OnboardingManager.swift
//  EarthLord
//
//  新手引导管理器
//

import Foundation
import SwiftUI
import Supabase

// MARK: - 用户引导状态模型

struct UserOnboardingStatus: Codable {
    let hasSeenOnboarding: Bool?

    enum CodingKeys: String, CodingKey {
        case hasSeenOnboarding = "has_seen_onboarding"
    }
}

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var shouldShowOnboarding = false
    @Published var isLoading = true

    // 本地缓存Key
    private let onboardingShownKey = "has_seen_onboarding"

    private init() {}

    // MARK: - 检查是否需要显示引导

    func checkOnboardingStatus() async {
        isLoading = true

        // 首先检查本地缓存
        if UserDefaults.standard.bool(forKey: onboardingShownKey) {
            shouldShowOnboarding = false
            isLoading = false
            return
        }

        // 检查Supabase用户数据
        do {
            guard let userId = AuthManager.shared.currentUser?.id else {
                // 未登录用户，显示引导
                shouldShowOnboarding = true
                isLoading = false
                return
            }

            let response: UserOnboardingStatus = try await supabaseClient
                .from("profiles")
                .select("has_seen_onboarding")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            // 如果用户已看过引导，则不显示
            if let hasSeen = response.hasSeenOnboarding, hasSeen {
                UserDefaults.standard.set(true, forKey: onboardingShownKey)
                shouldShowOnboarding = false
            } else {
                shouldShowOnboarding = true
            }
        } catch {
            // 如果查询失败，默认显示引导
            print("Error checking onboarding status: \(error)")
            shouldShowOnboarding = true
        }

        isLoading = false
    }

    // MARK: - 标记引导已完成

    func markOnboardingCompleted() async {
        // 更新本地缓存
        UserDefaults.standard.set(true, forKey: onboardingShownKey)
        shouldShowOnboarding = false

        // 更新Supabase
        do {
            guard let userId = AuthManager.shared.currentUser?.id else { return }

            try await supabaseClient
                .from("profiles")
                .update(["has_seen_onboarding": true])
                .eq("id", value: userId)
                .execute()

            LogDebug("✅ [OnboardingManager] 引导状态已更新到服务器")
        } catch {
            print("Error updating onboarding status: \(error)")
        }
    }

    // MARK: - 重置引导（用于测试）

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: onboardingShownKey)
        shouldShowOnboarding = true
    }
}
