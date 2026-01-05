import SwiftUI

struct ProfileTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject var langManager = LanguageManager.shared
    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""
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
                        Text("Survivor Profile").font(.caption).foregroundColor(brandOrange)
                        Text(authManager.currentUser?.email ?? "User Email").font(.title3).bold().foregroundColor(.white)
                        Text("ID: \(String(authManager.currentUser?.id.uuidString.prefix(8) ?? "--------"))").foregroundColor(.gray).font(.caption)
                    }.padding(.vertical, 30)

                    // 2. 数据行
                    HStack(spacing: 0) {
                        StatItem(icon: "flag.fill", value: "0", label: "領地")
                        StatItem(icon: "mappin.circle.fill", value: "0", label: "资源点")
                        StatItem(icon: "figure.walk", value: "0", label: "探索距离")
                    }.padding(.vertical, 20)

                    // 3. 菜单
                    VStack(spacing: 1) {
                        Divider().background(Color.white.opacity(0.1))
                        NavigationLink(destination: LanguageSettingsView()) {
                            MenuRow(icon: "globe", title: "Language Settings", value: langManager.currentLanguage == "en" ? "English" : "简体中文")
                        }
                        Divider().background(Color.white.opacity(0.1))
                        MenuRow(icon: "gearshape.fill", title: "System Settings", value: "")
                        MenuRow(icon: "bell.fill", title: "Notifications", value: "")
                        MenuRow(icon: "questionmark.circle.fill", title: "Help", value: "")
                        MenuRow(icon: "info.circle.fill", title: "About", value: "")
                        Divider().background(Color.white.opacity(0.1))
                    }.padding(.top, 10)

                    Spacer()

                    VStack(spacing: 15) {
                        Button(action: { Task { await authManager.signOut() } }) {
                            Text("Sign Out").frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }.padding(.horizontal, 25)

                        Button(action: { showDeleteAlert = true }) {
                            HStack { Image(systemName: "trash"); Text("Delete Account") }.font(.footnote).foregroundColor(.gray)
                        }
                    }.padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            TextField("Type DELETE to confirm", text: $deleteConfirmText)
            Button("Confirm Delete", role: .destructive) {
                if deleteConfirmText == "DELETE" { Task { await authManager.deleteAccount() } }
                deleteConfirmText = ""
            }
            Button("Cancel", role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text("WARNING: This action is irreversible. All your data will be permanently erased.")
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
