import SwiftUI

@main
struct EarthLordApp: App {
    // 生产模式：正式上架时必须为 false
    private let skipAuthForTesting = false

    init() {
        LogDebug("🚀🚀🚀 [EarthLordApp] ========== App init 开始 ==========")

        // 🌐 设置应用语言（从 UserDefaults 读取用户选择）
        if let languageCode = UserDefaults.standard.string(forKey: "selected_language") {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            LogDebug("🌐 [EarthLordApp] 设置应用语言: \(languageCode)")
        }

        // ✅ 移除 StoreKitTransactionObserver - 应用使用 StoreKit 2，不需要旧的交易监听
        LogDebug("🚀🚀🚀 [EarthLordApp] ========== App init 完成 ==========")
    }

    var body: some Scene {
        WindowGroup {
            if skipAuthForTesting {
                MainTabView()
                    .environmentObject(AuthManager.shared)
            } else {
                AuthFlowView()
            }
        }
    }
}

// MARK: - 正式模式认证流程视图
struct AuthFlowView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var splashFinished = false
    @State private var hasStartedSessionCheck = false

    // ✅ 新手引导相关状态
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false
    @AppStorage("debug_force_show_onboarding") private var debugForceShowOnboarding = true  // 🔧 调试模式：强制显示引导

    var body: some View {
        ZStack {
            Group {
                if !splashFinished {
                    // 启动页（带视频）
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                } else if !authManager.isAuthenticated {
                    // 认证页面
                    AuthView()
                        .transition(.opacity)
                } else {
                    // 主界面（已登录）
                    MainTabView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                        .onAppear {
                            // 检查是否需要显示新手引导
                            checkAndShowOnboarding()
                        }
                }
            }

            // ✅ 新手引导覆盖层
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
        .task(id: splashFinished) {
            guard splashFinished, !hasStartedSessionCheck else { return }
            hasStartedSessionCheck = true
            if !authManager.isSessionChecked {
                LogDebug("🔐 [AuthFlowView] 后台启动会话检查")
                await authManager.checkSession()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isSessionChecked)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        // ✅ 监听登录状态变化
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

    // ✅ 检查并显示新手引导
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

// MARK: - 启动屏视图
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                Text("EarthLord")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(1.2)
            }
        }
    }
}
