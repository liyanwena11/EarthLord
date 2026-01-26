import SwiftUI

@main
struct EarthLordApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationManager = LocationManager()

    init() {
        print("🚀🚀🚀 [EarthLordApp] ========== App 正在启动 ==========")
        print("✅ [EarthLordApp] LocationManager 将在 @StateObject 初始化时创建")
        // ✅ 移除了阻塞性的初始化代码
    }

    // ⚠️ 开发模式开关：设为 true 跳过登录，直接进入主界面
    private let skipAuthForTesting = true

    var body: some Scene {
        WindowGroup {
            if skipAuthForTesting {
                // 🧪 开发模式：跳过登录，直接进入主界面
                MainTabView()
                    .environmentObject(locationManager)
                    .onAppear {
                        print("🧪 [开发模式] 跳过登录，直接进入 MainTabView")
                    }
            } else {
                // 正式模式：检查登录状态
                Group {
                    if !authManager.isSessionChecked {
                        LaunchScreenView()
                    } else if authManager.isAuthenticated {
                        MainTabView()
                            .environmentObject(locationManager)
                            .onAppear {
                                print("✅ [EarthLordApp] MainTabView 已显示，LocationManager 已注入")
                            }
                    } else {
                        AuthView()
                            .environmentObject(locationManager)
                            .onAppear {
                                print("⚠️ [EarthLordApp] AuthView 已显示，LocationManager 已注入")
                            }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: authManager.isSessionChecked)
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            }
        }
    }
}

// MARK: - 启动屏视图（避免空视图导致 Metal 0x0 错误）
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
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
