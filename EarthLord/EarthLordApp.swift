import SwiftUI

@main
struct EarthLordApp: App {
    // 生产模式：正式上架时必须为 false
    private let skipAuthForTesting = false

    init() {
        LogDebug("🚀🚀🚀 [EarthLordApp] ========== App init 开始 ==========")
        // 预热 EarthLordEngine（确保 GPS 在 App 启动时就开始）
        _ = EarthLordEngine.shared
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

    var body: some View {
        Group {
            if !authManager.isSessionChecked {
                LaunchScreenView()
            } else if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isSessionChecked)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
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
