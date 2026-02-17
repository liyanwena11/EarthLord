//
//  ChannelDetailView.swift
//  EarthLord
//
//  频道详情页 - 信息展示、订阅/取消、删除
//

import SwiftUI
import Supabase

struct ChannelDetailView: View {
    let channel: CommunicationChannel

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false
    @State private var showDeleteConfirm = false
    @State private var showError = false
    @State private var errorText = ""
    @State private var showChat = false

    private var isCreator: Bool {
        authManager.currentUser?.id == channel.creatorId
    }

    private var isSubscribed: Bool {
        communicationManager.isSubscribed(channelId: channel.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 频道头像 + 名称
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.primary.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: channel.channelType.iconName)
                                    .font(.system(size: 32))
                                    .foregroundColor(ApocalypseTheme.primary)
                            }

                            Text(channel.name)
                                .font(.title2.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text(channel.channelCode)
                                .font(.subheadline.monospaced())
                                .foregroundColor(ApocalypseTheme.textSecondary)

                            if isSubscribed {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("已订阅")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 20)

                        // 频道描述
                        if let desc = channel.description, !desc.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("频道介绍")
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(ApocalypseTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(ApocalypseTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // 频道信息卡片
                        VStack(spacing: 12) {
                            infoRow(label: "频道类型", value: channel.channelType.displayName)
                            Divider().background(ApocalypseTheme.textMuted.opacity(0.3))
                            infoRow(label: "覆盖范围", value: channel.channelType.rangeText)
                            Divider().background(ApocalypseTheme.textMuted.opacity(0.3))
                            infoRow(label: "成员数量", value: "\(channel.memberCount) 人")
                            Divider().background(ApocalypseTheme.textMuted.opacity(0.3))
                            infoRow(label: "创建时间", value: formatDate(channel.createdAt))
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // 操作按钮
                        VStack(spacing: 12) {
                            // 进入聊天按钮（已订阅或创建者可见）
                            if isSubscribed || isCreator {
                                Button(action: { showChat = true }) {
                                    HStack {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                        Text("进入聊天")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(ApocalypseTheme.primary)
                                    .cornerRadius(12)
                                }
                            }

                            if !isCreator {
                                if isSubscribed {
                                    Button(action: { unsubscribe() }) {
                                        HStack {
                                            if isProcessing {
                                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Image(systemName: "xmark.circle")
                                                Text("取消订阅")
                                            }
                                        }
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(ApocalypseTheme.textSecondary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isProcessing)
                                } else {
                                    Button(action: { subscribe() }) {
                                        HStack {
                                            if isProcessing {
                                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Image(systemName: "plus.circle.fill")
                                                Text("订阅频道")
                                            }
                                        }
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(ApocalypseTheme.primary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isProcessing)
                                }
                            }

                            if isCreator {
                                Button(action: { showDeleteConfirm = true }) {
                                    Label("删除频道", systemImage: "trash.fill")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(ApocalypseTheme.danger)
                                        .cornerRadius(12)
                                }
                                .disabled(isProcessing)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("频道详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .alert("确认删除", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) { deleteChannel() }
            } message: {
                Text("删除后无法恢复，频道内所有消息也将被删除。确定要删除「\(channel.name)」吗？")
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorText)
            }
            .fullScreenCover(isPresented: $showChat) {
                ChannelChatView(channel: channel)
                    .environmentObject(authManager)
            }
        }
    }

    // MARK: - Info Row

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
    }

    // MARK: - Actions

    private func subscribe() {
        guard let userId = authManager.currentUser?.id else { return }
        isProcessing = true
        Task {
            do {
                try await communicationManager.subscribeToChannel(userId: userId, channelId: channel.id)
                await MainActor.run { isProcessing = false }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorText = "订阅失败: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func unsubscribe() {
        guard let userId = authManager.currentUser?.id else { return }
        isProcessing = true
        Task {
            do {
                try await communicationManager.unsubscribeFromChannel(userId: userId, channelId: channel.id)
                await MainActor.run { isProcessing = false }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorText = "取消订阅失败: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func deleteChannel() {
        isProcessing = true
        Task {
            do {
                try await communicationManager.deleteChannel(channelId: channel.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorText = "删除失败: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
