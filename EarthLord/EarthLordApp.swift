import SwiftUI

@main
struct EarthLordApp: App {
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // 👈 已登录：必须进入 MainTabView，才能看到“个人”标签
                MainTabView()
            } else {
                // 👈 未登录：显示登录页
                AuthView()
            }
        }
    }
}
