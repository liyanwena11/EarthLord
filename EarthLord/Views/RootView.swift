//
//  RootView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI

/// 根视图：控制启动页、认证页与主界面的切换
struct RootView: View {
    /// 启动页是否完成
    @State private var splashFinished = false

    /// 认证管理器（✅ 修复：shared 单例用 @ObservedObject）
    @ObservedObject private var authManager = AuthManager.shared

    /// 新手引导管理器
    @StateObject private var onboardingManager = OnboardingManager.shared

    /// 是否显示新手引导
    @State private var showOnboarding = false
    /// 调试：强制显示新手引导
    @AppStorage("debug_force_show_onboarding") private var debugForceShowOnboarding = false
    /// 是否已检查过引导
    @State private var hasCheckedOnboarding = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 启动页
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else if !authManager.isAuthenticated {
                // 认证页面
                AuthView()
                    .transition(.opacity)
            } else {
                // 主界面（已登录）
                MainTabView()
                    .transition(.opacity)
                    .onAppear {
                        // 检查是否需要显示新手引导
                        checkAndShowOnboarding()
                    }
            }

            // 新手引导覆盖层
            if showOnboarding {
                OnboardingView(isShown: $showOnboarding) {
                    Task {
                        await onboardingManager.markOnboardingCompleted()
                    }
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        // 监听登录状态变化
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                // 用户刚刚登录，重置检查标志并检查引导
                hasCheckedOnboarding = false
                checkAndShowOnboarding()
            } else {
                // 用户退出登录，重置状态
                hasCheckedOnboarding = false
                showOnboarding = false
            }
        }
    }

    private func checkAndShowOnboarding() {
        Task {
            // 防止重复检查
            if hasCheckedOnboarding { return }
            hasCheckedOnboarding = true

            // 调试模式：强制显示引导
            if debugForceShowOnboarding {
                await MainActor.run {
                    withAnimation {
                        showOnboarding = true
                    }
                }
                return
            }

            await onboardingManager.checkOnboardingStatus()
            if onboardingManager.shouldShowOnboarding {
                await MainActor.run {
                    withAnimation {
                        showOnboarding = true
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
