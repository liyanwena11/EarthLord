import SwiftUI

struct ProfileTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var langManager = LanguageManager.shared
    @StateObject private var walkingRewardManager = WalkingRewardManager.shared
    @StateObject private var poiService = RealPOIService.shared
    @EnvironmentObject var locationManager: LocationManager
    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""
    @State private var territoryCount = 0
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 1. 顶部信息
                    VStack(spacing: 12) {
                        Circle().fill(Color.gray.opacity(0.3)).frame(width: 70, height: 70)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white).font(.title))
                        Text("幸存者档案").font(.caption).foregroundColor(brandOrange)
                        Text(authManager.currentUser?.email ?? "用户邮箱").font(.title3).bold().foregroundColor(.white)
                        Text("ID: \(String(authManager.currentUser?.id.uuidString.prefix(8) ?? "--------"))").foregroundColor(.gray).font(.caption)
                    }.padding(.vertical, 30)

                    // 2. 数据行
                    HStack(spacing: 0) {
                        StatItem(icon: "flag.fill", value: "\(territoryCount)", label: "领地")
                        StatItem(icon: "mappin.circle.fill", value: "\(poiService.realPOIs.count)", label: "资源点")
                        StatItem(icon: "figure.walk", value: "\(Int(walkingRewardManager.totalWalkingDistance))", label: "探索距离")
                    }.padding(.vertical, 20)

                    // 3. 菜单
                    VStack(spacing: 1) {
                        Divider().background(Color.white.opacity(0.1))
                        NavigationLink(destination: LanguageSettingsView()) {
                            MenuRow(icon: "globe", title: "语言设置", value: langManager.currentLanguage == "en" ? "English" : "简体中文")
                        }
                        NavigationLink(destination: LocationDebugView()) {
                            MenuRow(icon: "hammer.fill", title: "开发测试", value: "")
                        }
                        Divider().background(Color.white.opacity(0.1))
                        MenuRow(icon: "gearshape.fill", title: "系统设置", value: "")
                        MenuRow(icon: "bell.fill", title: "通知", value: "")
                        MenuRow(icon: "questionmark.circle.fill", title: "帮助", value: "")
                        MenuRow(icon: "info.circle.fill", title: "关于", value: "")
                        Divider().background(Color.white.opacity(0.1))
                    }.padding(.top, 10)

                    Spacer()

                    VStack(spacing: 15) {
                        Button(action: { Task { await authManager.signOut() } }) {
                            Text("退出登录").frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }.padding(.horizontal, 25)

                        Button(action: { showDeleteAlert = true }) {
                            HStack { Image(systemName: "trash"); Text("删除账号") }.font(.footnote).foregroundColor(.gray)
                        }
                    }.padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("删除账号？", isPresented: $showDeleteAlert) {
            TextField("输入 DELETE 确认", text: $deleteConfirmText)
            Button("确认删除", role: .destructive) {
                if deleteConfirmText == "DELETE" { Task { await authManager.deleteAccount() } }
                deleteConfirmText = ""
            }
            Button("取消", role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text("警告：此操作不可逆！您的所有数据将被永久删除。")
        }
        .onAppear {
            // 加载领地数量
            Task {
                if let territories = try? await TerritoryManager.shared.loadMyTerritories() {
                    territoryCount = territories.count
                }
            }
            // 触发 POI 搜索（如果尚未搜索）
            if poiService.realPOIs.isEmpty {
                poiService.searchNearbyRealPOI(userLocation: locationManager.userLocation?.coordinate)
            }
        }
    }
}

// --- 补全下方组件 ---
struct StatItem: View {
    let icon: String; let value: String; let label: LocalizedStringKey
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.13)).font(.title2)
            Text(value).foregroundColor(.white).font(.title3).bold()
            Text(label).foregroundColor(.gray).font(.caption)
        }.frame(maxWidth: .infinity)
    }
}

struct MenuRow: View {
    let icon: String; let title: LocalizedStringKey; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white).frame(width: 25)
            Text(title).foregroundColor(.white)
            Spacer()
            if !value.isEmpty { Text(value).foregroundColor(.gray).font(.caption) }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }.padding().background(Color.black)
    }
}
