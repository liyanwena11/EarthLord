import SwiftUI

#if DEBUG

struct TestMenuView: View {
    var body: some View {
        List {
            Section(header: Text("基础测试")) {
                NavigationLink("领地轨迹日志") {
                    TerritoryTestView()
                }

                NavigationLink("🔥 位置调试 (GPS & 行走奖励)") {
                    LocationDebugView()
                }
            }
        }
        .navigationTitle("开发测试")
    }
}
#endif
