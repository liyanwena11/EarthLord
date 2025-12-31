//
//  ProfileTabView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI
import Supabase

/// 个人中心页面
struct ProfileTabView: View {

    // MARK: - State Properties

    /// 认证管理器
    @StateObject private var authManager = AuthManager.shared

    /// 是否显示退出确认弹窗
    @State private var showSignOutAlert = false

    /// 是否正在退出
    @State private var isSigningOut = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 用户信息卡片
                        userInfoCard

                        // 功能列表
                        settingsSection

                        // 退出登录按钮
                        signOutButton

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("确认退出", isPresented: $showSignOutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                handleSignOut()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }

    // MARK: - View Components

    /// 用户信息卡片
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                // 头像背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10)

                // 头像图标或图片
                if let avatarUrl = authManager.currentUser?.userMetadata["avatar_url"] as? String,
                   !avatarUrl.isEmpty {
                    // TODO: 加载远程头像
                    Image(systemName: "person.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                }
            }

            // 用户名
            VStack(spacing: 4) {
                Text(getUserDisplayName())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                // 邮箱
                if let email = authManager.currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            // 用户ID（可选显示）
            if let userId = authManager.currentUser?.id {
                Text("ID: \(userId.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    /// 设置选项区域
    private var settingsSection: some View {
        VStack(spacing: 0) {
            // 编辑资料
            SettingRow(
                icon: "person.crop.circle",
                title: "编辑资料",
                action: {
                    // TODO: 跳转到编辑资料页面
                }
            )

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.horizontal, 16)

            // 账号与安全
            SettingRow(
                icon: "lock.shield",
                title: "账号与安全",
                action: {
                    // TODO: 跳转到账号安全页面
                }
            )

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.horizontal, 16)

            // 关于
            SettingRow(
                icon: "info.circle",
                title: "关于地球新主",
                action: {
                    // TODO: 跳转到关于页面
                }
            )
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 退出登录按钮
    private var signOutButton: some View {
        Button(action: { showSignOutAlert = true }) {
            HStack {
                if isSigningOut {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.danger))
                        .scaleEffect(0.8)
                }

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))

                Text("退出登录")
                    .font(.headline)
            }
            .foregroundColor(ApocalypseTheme.danger)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.danger.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isSigningOut)
    }

    // MARK: - Helper Methods

    /// 获取用户显示名称
    private func getUserDisplayName() -> String {
        // 优先显示用户名
        if let username = authManager.currentUser?.userMetadata["username"] as? String,
           !username.isEmpty {
            return username
        }

        // 其次显示邮箱前缀
        if let email = authManager.currentUser?.email {
            return email.components(separatedBy: "@").first ?? "未知用户"
        }

        return "未知用户"
    }

    /// 处理退出登录
    private func handleSignOut() {
        isSigningOut = true

        Task {
            await authManager.signOut()

            // 退出完成后，authStateChanges 会自动触发
            // isAuthenticated 变为 false，RootView 会自动跳转到 AuthView
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

// MARK: - Custom Components

/// 设置行组件
struct SettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(ApocalypseTheme.primary)
                    .frame(width: 30)

                // 标题
                Text(title)
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileTabView()
}
