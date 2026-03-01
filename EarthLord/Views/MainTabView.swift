import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MainMapView()
                .tabItem { Label("地图".localized, systemImage: "map.fill") }
                .tag(0)

            TerritoryTabView()
                .tabItem { Label("领地".localized, systemImage: "flag.fill") }
                .tag(1)

            ResourcesTabView()
                .tabItem { Label("资源".localized, systemImage: "bag.fill") }
                .tag(2)

            CommunicationTabView()
                .environmentObject(AuthManager.shared)
                .tabItem { Label("通讯".localized, systemImage: "antenna.radiowaves.left.and.right") }
                .tag(3)

            ProfileTabView()
                .environmentObject(AuthManager.shared)
                .environmentObject(TierManager.shared)
                .tabItem { Label("个人".localized, systemImage: "person.fill") }
                .tag(4)
        }
        .accentColor(ApocalypseTheme.primary)
        .onAppear {
            applyTabBarStyle()
            LogDebug("🧭 [MainTabView] 主界面已显示")
        }
    }

    private func applyTabBarStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ApocalypseTheme.background)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.45)

        let normalColor = UIColor.white.withAlphaComponent(0.45)
        let selectedColor = UIColor(ApocalypseTheme.primary)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = normalColor
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
