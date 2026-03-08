import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showChangePassword = false
    @State private var deleteConfirmText = ""
    @State private var isDeletingAccount = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // 用户信息卡片
                        VStack(spacing: 15) {
                            if let userEmail = authManager.currentUser?.email {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(ApocalypseTheme.primary)

                                    Text(userEmail)
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("免费用户")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 账号安全
                        AccountSectionHeader(icon: "lock.shield.fill", title: "账号安全", subtitle: "管理账号安全设置")

                        VStack(spacing: 1) {
                            Button(action: { showChangePassword = true }) {
                                AccountLinkRow(icon: "key.fill", title: "修改密码", subtitle: "更改登录密码", iconColor: .blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 绑定账号
                        AccountSectionHeader(icon: "link.circle.fill", title: "绑定账号", subtitle: "管理第三方账号绑定")

                        VStack(spacing: 1) {
                            // Google账号
                            HStack(spacing: 15) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(20)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Google账号")
                                        .font(.body)
                                        .foregroundColor(.white)

                                    Text("未绑定")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()

                                Text("绑定")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)

                            // Apple ID
                            HStack(spacing: 15) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(20)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Apple ID")
                                        .font(.body)
                                        .foregroundColor(.white)

                                    Text("未绑定")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()

                                Text("绑定")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 危险区域
                        AccountSectionHeader(icon: "exclamationmark.triangle.fill", title: "危险区域", subtitle: "不可恢复的操作")

                        VStack(spacing: 1) {
                            Button(action: { showDeleteAlert = true }) {
                                AccountLinkRow(icon: "trash.fill", title: "删除账号", subtitle: "永久删除账号和所有数据", iconColor: .red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.red.opacity(0.3), lineWidth: 1))

                        // 说明文字
                        VStack(alignment: .leading, spacing: 10) {
                            Text("重要提示")
                                .font(.headline)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("删除账号将永久删除所有数据，包括领地、建筑、物品等")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("删除后无法恢复，请谨慎操作")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("如有疑问，请联系客服")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(15)

                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("账号设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .alert("删除账号", isPresented: $showDeleteAlert) {
            TextField("", text: $deleteConfirmText, prompt: Text("输入DELETE确认"))
                .textInputAutocapitalization(.characters)

            Button("取消", role: .cancel) {
                deleteConfirmText = ""
            }

            Button("删除", role: .destructive) {
                if deleteConfirmText == "DELETE" {
                    Task {
                        isDeletingAccount = true
                        await authManager.deleteAccount()
                        isDeletingAccount = false
                    }
                }
            }
            .disabled(deleteConfirmText != "DELETE" || isDeletingAccount)
        } message: {
            Text("此操作不可恢复，请输入DELETE确认")
        }
    }
}

struct AccountSectionHeader: View {
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

struct AccountLinkRow: View {
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

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("当前密码", text: $currentPassword)
                    SecureField("新密码", text: $newPassword)
                    SecureField("确认新密码", text: $confirmPassword)
                } header: {
                    Text("修改密码")
                } footer: {
                    Text("密码至少包含8个字符")
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await changePassword()
                        }
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                }
            }
            .alert("成功", isPresented: $showSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("密码修改成功")
            }
        }
    }

    private func changePassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return
        }

        guard newPassword.count >= 8 else {
            errorMessage = "密码至少需要8个字符"
            return
        }

        isLoading = true
        // TODO: 实现修改密码API调用
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
        showSuccessAlert = true
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AuthManager.shared)
}
