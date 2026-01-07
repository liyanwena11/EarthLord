import SwiftUI

@main
struct EarthLordApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // Logged in: Enter MainTabView
                MainTabView()
                    .environmentObject(locationManager)
            } else {
                // Not logged in: Show login page
                AuthView()
            }
        }
    }
}
