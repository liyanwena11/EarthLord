import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showAccountSettings = false
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var showTerms = false
    @State private var showLogoutAlert = false

    @AppStorage("push_notifications") private var pushEnabled = true
    @AppStorage("game_audio") private var audioEnabled = true
    @AppStorage("haptic_feedback") private var hapticEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // 账号设置
                        SettingsSectionHeader(icon: "person.circle.fill", title: "账号设置", subtitle: "管理你的账号信息")

                        VStack(spacing: 1) {
                            Button(action: { showAccountSettings = true }) {
                                SettingsRow(icon: "person.fill", title: "账号管理", subtitle: "修改密码、绑定账号", iconColor: .blue)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { showLogoutAlert = true }) {
                                SettingsRow(icon: "arrow.right.square.fill", title: "退出登录", subtitle: "退出当前账号", iconColor: .orange)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 游戏设置
                        SettingsSectionHeader(icon: "gearshape.fill", title: "游戏设置", subtitle: "个性化你的游戏体验")

                        VStack(spacing: 1) {
                            SettingsToggleRow(icon: "bell.fill", title: "推送通知", subtitle: "接收领地和资源更新", isOn: $pushEnabled, iconColor: .orange)
                            SettingsToggleRow(icon: "speaker.wave.2.fill", title: "游戏音效", subtitle: "启用背景音乐和音效", isOn: $audioEnabled, iconColor: .blue)
                            SettingsToggleRow(icon: "iphone.radiowaves.left.and.right", title: "震动反馈", subtitle: "操作时震动反馈", isOn: $hapticEnabled, iconColor: .yellow)
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 语言设置
                        SettingsSectionHeader(icon: "globe.fill", title: "语言设置", subtitle: "选择应用语言")

                        VStack(spacing: 1) {
                            NavigationLink(destination: LanguageSettingsView()) {
                                SettingsRow(icon: "textformat.abc", title: "应用语言", subtitle: "中文/English", iconColor: .green)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 帮助与支持
                        SettingsSectionHeader(icon: "questionmark.circle.fill", title: "帮助与支持", subtitle: "获取帮助和更多信息")

                        VStack(spacing: 1) {
                            Button(action: { showHelp = true }) {
                                SettingsRow(icon: "book.fill", title: "帮助中心", subtitle: "常见问题和教程", iconColor: .purple)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Link(destination: URL(string: "https://liyanwena11.github.io/earthlord-support/")!) {
                                SettingsRow(icon: "wrench.and.screwdriver.fill", title: "技术支持", subtitle: "访问技术支持网站", iconColor: .blue)
                            }

                            Link(destination: URL(string: "https://liyanwena11.github.io/earthlord-support/privacy.html")!) {
                                SettingsRow(icon: "lock.shield.fill", title: "隐私政策", subtitle: "查看隐私政策", iconColor: .green)
                            }

                            Button(action: { showTerms = true }) {
                                SettingsRow(icon: "doc.text.fill", title: "用户协议", subtitle: "服务条款和使用规则", iconColor: .red)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { showAbout = true }) {
                                SettingsRow(icon: "info.circle.fill", title: "关于我们", subtitle: "应用信息和版本", iconColor: .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showHelp) {
            HelpCenterView()
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .alert("退出登录", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}

// MARK: - 设置行组件

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let iconColor: Color

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
}

struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.primary)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
