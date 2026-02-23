//
//  CreateChannelView.swift
//  EarthLord
//
//  创建频道表单
//

import SwiftUI
import Supabase

struct CreateChannelView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var channelName = ""
    @State private var channelDescription = ""
    @State private var channelType: ChannelType = .publicChannel
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var nameValidation: (isValid: Bool, message: String) {
        let trimmed = channelName.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return (false, "请输入频道名称")
        } else if trimmed.count < 2 {
            return (false, "名称至少2个字符")
        } else if trimmed.count > 50 {
            return (false, "名称最多50个字符")
        }
        return (true, "")
    }

    private var canCreate: Bool {
        nameValidation.isValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 频道类型选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("频道类型")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            VStack(spacing: 8) {
                                ForEach(ChannelType.creatableTypes, id: \.self) { type in
                                    Button(action: { channelType = type }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: type.iconName)
                                                .foregroundColor(ApocalypseTheme.primary)
                                                .frame(width: 24)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(type.displayName)
                                                    .font(.subheadline)
                                                    .foregroundColor(ApocalypseTheme.textPrimary)
                                                Text("范围: \(type.rangeText)")
                                                    .font(.caption)
                                                    .foregroundColor(ApocalypseTheme.textMuted)
                                            }

                                            Spacer()

                                            if channelType == type {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(ApocalypseTheme.primary)
                                            }
                                        }
                                        .padding()
                                        .contentShape(Rectangle()) // ✅ 修复 iPad 点击区域
                                        .background(ApocalypseTheme.cardBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(channelType == type ? ApocalypseTheme.primary : ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle()) // ✅ 避免手势冲突
                                }
                            }
                        }

                        // 频道名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("频道名称")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            TextField("请输入频道名称（2-50字符）", text: $channelName)
                                .padding()
                                .background(ApocalypseTheme.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
                                )

                            if !channelName.isEmpty && !nameValidation.isValid {
                                Text(nameValidation.message)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.danger)
                            }
                        }

                        // 频道描述
                        VStack(alignment: .leading, spacing: 8) {
                            Text("频道描述（可选）")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            TextField("简单介绍一下这个频道", text: $channelDescription, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(ApocalypseTheme.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // 创建按钮
                        Button(action: { createChannel() }) {
                            HStack {
                                if isCreating {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("创建频道")
                                }
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCreate && !isCreating ? ApocalypseTheme.primary : Color.gray.opacity(0.4))
                            .cornerRadius(12)
                        }
                        .disabled(!canCreate || isCreating)
                        .buttonStyle(PlainButtonStyle()) // ✅ 修复 iPad 手势冲突
                        .contentShape(Rectangle()) // ✅ 确保整个按钮区域可点击

                        // 验证提示
                        if !canCreate && !channelName.isEmpty {
                            Text(nameValidation.message)
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.danger)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if channelName.isEmpty {
                            Text("请输入频道名称后创建")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("创建新频道")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createChannel() {
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "未登录"
            showError = true
            return
        }

        isCreating = true
        let name = channelName.trimmingCharacters(in: .whitespaces)
        let desc: String? = channelDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : channelDescription.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                LogDebug("🔨 [创建频道] 开始创建频道: \(name)")
                let channelId = try await communicationManager.createChannel(
                    userId: userId,
                    type: channelType,
                    name: name,
                    description: desc
                )
                LogInfo("✅ [创建频道] 频道创建成功: \(channelId)")
                await MainActor.run {
                    isCreating = false

                    // ✅ 发送通知刷新频道列表
                    NotificationCenter.default.post(name: .channelUpdated, object: nil)
                    LogDebug("📡 [创建频道] 已发送 channelUpdated 通知")
                    dismiss()
                }
            } catch {
                LogError("❌ [创建频道] 创建失败: \(error.localizedDescription)")
                await MainActor.run {
                    isCreating = false
                    errorMessage = "创建失败: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
