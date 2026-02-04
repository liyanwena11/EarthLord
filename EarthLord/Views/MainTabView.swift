import SwiftUI

struct MainTabView: View {
    @State var isReady: Bool = false
    @StateObject private var engine = EarthLordEngine.shared
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            if isReady {
                TabView(selection: $selectedTab) {
                    MainMapView()
                        .tabItem { Label("地图", systemImage: "map.fill") }
                        .tag(0)

                    TerritoryTabView()
                        .tabItem { Label("领地", systemImage: "flag.fill") }
                        .tag(1)

                    BackpackView()
                        .tabItem { Label("资源", systemImage: "bag.fill") }
                        .tag(2)

                    ProfileTabView()
                        .tabItem { Label("个人", systemImage: "person.fill") }
                        .tag(3)
                }
                .accentColor(.orange)
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.backgroundColor = UIColor.black
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            } else {
                // 直接使用我们自己的加载页，避免调用外部 SplashView 报错
                loadingView
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { self.isReady = true }
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .orange))
                Text("EARTH LORD 系统启动中...").foregroundColor(.orange).font(.caption)
            }
        }
    }
}
