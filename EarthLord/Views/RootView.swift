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

    /// 认证管理器
    @StateObject private var authManager = AuthManager.shared

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
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
}
