import SwiftUI

struct ProfileTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject var langManager = LanguageManager.shared // 监听语言管理
    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""
    
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. 顶部头像信息
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white).font(.title))
                        
                        Text("幸存者档案".localized)
                            .font(.caption)
                            .foregroundColor(brandOrange)
                        
                        Text(authManager.currentUser?.email ?? "3446477057@qq.com")
                            .font(.title3).bold().foregroundColor(.white)
                        
                        Text("ID: \(String(authManager.currentUser?.id.uuidString.prefix(8) ?? "3C5BAAEA"))")
                            .font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)

                    // 2. 统计数据行
                    HStack(spacing: 0) {
                        StatItem(icon: "flag.fill", value: "0", label: "领地".localized)
                        StatItem(icon: "mappin.circle.fill", value: "0", label: "资源点".localized)
                        StatItem(icon: "figure.walk", value: "0", label: "探索距离".localized)
                    }
                    .padding(.vertical, 20)

                    // 3. 菜单列表
                    VStack(spacing: 1) {
                        Divider().background(Color.white.opacity(0.1))
                        
                        // 语言设置行 - 🛠 修复点：直接判断显示名称，不再调用不存在的 .displayName
                        NavigationLink(destination: LanguageSettingsView()) {
                            HStack {
                                Image(systemName: "globe").foregroundColor(.white).frame(width: 25)
                                Text("语言设置".localized).foregroundColor(.white)
                                Spacer()
                                Text(langManager.currentLanguage == "en" ? "English" : "简体中文")
                                    .foregroundColor(.gray).font(.caption)
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.black)
                        }

                        Divider().background(Color.white.opacity(0.1))
                        
                        MenuRow(icon: "gearshape.fill", title: "系统设置".localized)
                        MenuRow(icon: "bell.fill", title: "通知中心".localized)
                        MenuRow(icon: "questionmark.circle.fill", title: "获取帮助".localized)
                        MenuRow(icon: "info.circle.fill", title: "关于地球".localized)
                        
                        Divider().background(Color.white.opacity(0.1))
                    }
                    .padding(.top, 10)

                    Spacer()

                    // 4. 底部按钮
                    VStack(spacing: 15) {
                        Button(action: { Task { await authManager.signOut() } }) {
                            Text("退出系统".localized).frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }.padding(.horizontal, 25)

                        Button(action: { showDeleteAlert = true }) {
                            HStack { Image(systemName: "trash"); Text("注销档案".localized) }
                            .font(.footnote).foregroundColor(.gray)
                        }
                    }.padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("确定注销档案吗？".localized, isPresented: $showDeleteAlert) {
            TextField("输入 DELETE 确认".localized, text: $deleteConfirmText)
            Button("永久删除".localized, role: .destructive) {
                if deleteConfirmText == "DELETE" { Task { await authManager.deleteAccount() } }
            }
            Button("取消".localized, role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text("注意：此操作不可逆！您的所有存档和领地将被永久销毁。".localized)
        }
    }
}

// 辅助组件保持一致
struct StatItem: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.13)).font(.title2)
            Text(value).foregroundColor(.white).font(.title3).bold()
            Text(label).foregroundColor(.gray).font(.caption)
        }.frame(maxWidth: .infinity)
    }
}

struct MenuRow: View {
    let icon: String; let title: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white).frame(width: 25)
            Text(title).foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
        .background(Color.black)
    }
}
