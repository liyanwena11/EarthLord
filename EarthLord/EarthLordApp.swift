import SwiftUI

@main
struct EarthLordApp: App {
    // ⚠️ 开发模式开关：设为 true 跳过登录，直接进入主界面
    private let skipAuthForTesting = true

    init() {
        print("🚀🚀🚀 [EarthLordApp] ========== App init 开始 ==========")
        // 预热 EarthLordEngine（确保 GPS 在 App 启动时就开始）
        _ = EarthLordEngine.shared
        print("🚀🚀🚀 [EarthLordApp] ========== App init 完成 ==========")
    }

    var body: some Scene {
        WindowGroup {
            if skipAuthForTesting {
                MainTabView()
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
