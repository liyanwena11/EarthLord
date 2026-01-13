import SwiftUI

struct TestMenuView: View {
    @State private var showSQLAlert = false
    
    var body: some View {
        List {
            Section(header: Text("基础测试")) {
                NavigationLink("领地轨迹日志") {
                    TerritoryTestView()
                }
            }
            
            Section(header: Text("Day 19 碰撞模拟准备")) {
                Button(action: {
                    showSQLAlert = true
                }) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                        Text("第一步：前往 Supabase 运行 SQL 脚本")
                    }
                }
                .foregroundColor(.blue)
                
                Text("说明：由于本地修复代码冲突，请务必在网页端执行我发给你的 SQL 脚本来制造‘敌军’领地。")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("开发测试")
        .alert("准备工作", isPresented: $showSQLAlert) {
            Button("我已运行 SQL", role: .cancel) { }
        } message: {
            Text("请在电脑浏览器打开 Supabase，运行那段名为‘敌军插旗’的脚本。运行成功后重启 App 即可在地图看到橙色块。")
        }
    }
}
