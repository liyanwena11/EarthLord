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
                        Task {
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
    }
}

#Preview {
    RootView()
}
