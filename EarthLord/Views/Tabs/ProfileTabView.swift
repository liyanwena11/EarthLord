import SwiftUI
import PhotosUI
import UIKit

struct ProfileTabView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var langManager = LanguageManager.shared
    @StateObject private var engine = EarthLordEngine.shared
    @ObservedObject private var backpack = ExplorationManager.shared

    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""

    // 头像
    @State private var avatarItem: PhotosPickerItem?
    @AppStorage("profileAvatarData") private var avatarDataBase64: String = ""

    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    // 用户显示名（邮箱前缀）
    private var displayName: String {
        authManager.currentUser?.email?.components(separatedBy: "@").first ?? "幸存者"
    }

    // 注册天数
    private var daysSinceJoined: Int {
        guard let created = authManager.currentUser?.createdAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - 头部：头像 + 身份信息
                        VStack(spacing: 14) {
                            // 头像（可点击更换）
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    avatarCircle
                                    // 编辑角标
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(brandOrange)
                                        .background(Color.black)
                                        .clipShape(Circle())
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .onChange(of: avatarItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        avatarDataBase64 = data.base64EncodedString()
                                    }
                                }
                            }

                            // 标签 + 名字
                            VStack(spacing: 4) {
                                Text("幸存者档案")
                                    .font(.caption).foregroundColor(brandOrange)
                                    .padding(.horizontal, 10).padding(.vertical, 3)
                                    .background(brandOrange.opacity(0.12))
                                    .cornerRadius(6)

                                Text(displayName)
                                    .font(.title2).bold().foregroundColor(.white)

                                Text(authManager.currentUser?.email ?? "")
                                    .font(.caption).foregroundColor(.gray)

                                HStack(spacing: 6) {
                                    Image(systemName: "shield.fill").font(.caption2).foregroundColor(brandOrange)
                                    Text("ID: \(String(authManager.currentUser?.id.uuidString.prefix(8) ?? "--------"))")
                                        .font(.caption2).foregroundColor(.gray)
                                    Text("·").foregroundColor(.gray.opacity(0.5))
                                    Image(systemName: "calendar").font(.caption2).foregroundColor(.gray)
                                    Text("加入 \(daysSinceJoined) 天").font(.caption2).foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 30)

                        // MARK: - 数据统计（3 格）
                        HStack(spacing: 0) {
                            StatItem(icon: "flag.fill", value: "\(engine.claimedTerritories.count)", label: "领地")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatItem(icon: "scalemass.fill", value: "\(String(format: "%.1f", backpack.totalWeight))kg", label: "背包负重")
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatItem(icon: "person.2.fill", value: "\(engine.nearbyPlayerCount)", label: "附近幸存者")
                        }
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                        // MARK: - 背包详情
                        HStack(spacing: 12) {
                            MiniStatCard(icon: "archivebox.fill", color: .orange,
                                         label: "物品种类", value: "\(backpack.backpackItems.count) 种")
                            MiniStatCard(icon: "shippingbox.fill", color: .blue,
                                         label: "物品数量", value: "\(backpack.backpackItems.reduce(0) { $0 + $1.quantity }) 件")
                            MiniStatCard(icon: "mappin.circle.fill", color: .green,
                                         label: "附近资源", value: "\(engine.nearbyPOIs.count) 处")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // MARK: - 背包容量进度条
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scalemass.fill").foregroundColor(.orange).font(.caption)
                                Text("背包容量").font(.caption).foregroundColor(.gray)
                                Spacer()
                                Text("\(String(format: "%.1f", backpack.totalWeight)) / \(Int(backpack.maxCapacity)) kg")
                                    .font(.caption.bold()).foregroundColor(capacityColor)
                            }
                            ProgressView(value: min(backpack.totalWeight, backpack.maxCapacity),
                                         total: backpack.maxCapacity)
                                .tint(capacityColor)
                                .scaleEffect(x: 1, y: 1.4)
                                .animation(.easeInOut(duration: 0.3), value: backpack.totalWeight)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // MARK: - 菜单
                        VStack(spacing: 1) {
                            Divider().background(Color.white.opacity(0.08))

                            NavigationLink(destination: LanguageSettingsView()) {
                                MenuRow(icon: "globe", title: "语言设置",
                                        value: langManager.currentLanguage == "en" ? "English" : "简体中文")
                            }
                            Divider().background(Color.white.opacity(0.08))
                            NavigationLink(destination: MoreTabView()) {
                                MenuRow(icon: "gearshape.fill", title: "系统设置", value: "")
                            }
                            MenuRow(icon: "bell.fill", title: "通知", value: "")
                            MenuRow(icon: "questionmark.circle.fill", title: "帮助", value: "")
                            Button(action: {
                                if let url = URL(string: "https://liyanwena11.github.io/earthlord-support/privacy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                MenuRow(icon: "lock.fill", title: "隐私政策", value: "")
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: {
                                if let url = URL(string: "https://liyanwena11.github.io/earthlord-support/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                MenuRow(icon: "globe.fill", title: "技术支持", value: "")
                            }
                            .buttonStyle(PlainButtonStyle())
                            MenuRow(icon: "info.circle.fill", title: "关于", value: "v1.0.0")
                            Divider().background(Color.white.opacity(0.08))
                        }
                        .padding(.bottom, 20)

                    }
                } // ScrollView

                // 退出登录 — 固定在底部，始终可点击
                VStack(spacing: 12) {
                    Divider().background(Color.white.opacity(0.1))
                    Button(action: { Task { await authManager.signOut() } }) {
                        Text("退出登录")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.red).foregroundColor(.white).cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    Button(action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("删除账号")
                        }
                        .font(.footnote).foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)
                }
                .background(Color.black)

                } // VStack
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
    }

    // MARK: - 头像视图

    @ViewBuilder
    private var avatarCircle: some View {
        if let data = Data(base64Encoded: avatarDataBase64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable().scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(brandOrange, lineWidth: 2))
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(brandOrange)
                )
                .overlay(Circle().stroke(brandOrange.opacity(0.5), lineWidth: 2))
        }
    }

    private var capacityColor: Color {
        if backpack.totalWeight >= backpack.maxCapacity { return .red }
        if backpack.totalWeight > backpack.maxCapacity * 0.8 { return .orange }
        return .green
    }
}

// MARK: - 小型统计卡片

struct MiniStatCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(value).font(.system(.subheadline, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - 通用组件（保持原有）

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
