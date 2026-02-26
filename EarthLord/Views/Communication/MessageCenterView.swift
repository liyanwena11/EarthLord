//
//  MessageCenterView.swift
//  EarthLord
//
//  消息中心 - 聚合所有订阅频道的最新消息
//

import SwiftUI
import Auth

struct MessageCenterView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared

    @State private var isLoading = true
    @State private var selectedChannel: CommunicationChannel?
    @State private var showingChat = false
    @State private var showingOfficialChannel = false
    @State private var showErrorAlert = false
    @State private var errorText = ""

    private var summaries: [CommunicationManager.ChannelSummary] {
        communicationManager.getChannelSummaries()
    }

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if isLoading {
                    loadingView
                } else if summaries.isEmpty {
                    emptyStateView
                } else {
                    messageListView
                }
            }
        }
        .onAppear { loadData() }
        .sheet(isPresented: $showingOfficialChannel) {
            if let channel = selectedChannel {
                OfficialChannelDetailView(channel: channel)
            }
        }
        .sheet(isPresented: $showingChat) {
            if let channel = selectedChannel {
                ChannelChatView(channel: channel)
                    .environmentObject(authManager)
            }
        }
        .alert("提示", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorText)
        }
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Text("消息中心")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            Spacer()
            Button(action: { loadData() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(ApocalypseTheme.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - 加载中

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textMuted)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundColor(ApocalypseTheme.primary.opacity(0.5))
            Text("暂无消息")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text("订阅频道后，消息将显示在这里")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - 消息列表

    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(summaries) { summary in
                    Button(action: {
                        if summary.channel.channelType == .official {
                            Task {
                                await openOfficialChannel(summary.channel)
                            }
                        } else {
                            selectedChannel = summary.channel
                            showingChat = true
                        }
                    }) {
                        MessageRowView(summary: summary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func openOfficialChannel(_ channel: CommunicationChannel) async {
        guard let userId = authManager.currentUser?.id else {
            await MainActor.run {
                errorText = "请先登录后访问官方频道"
                showErrorAlert = true
            }
            return
        }

        let subscribed = await communicationManager.ensureChannelSubscribedIfNeeded(userId: userId, channel: channel)
        if !subscribed {
            await MainActor.run {
                errorText = "官方频道订阅失败，请检查网络后重试"
                showErrorAlert = true
            }
            return
        }

        await MainActor.run {
            selectedChannel = channel
            showingOfficialChannel = true
        }
    }

    // MARK: - 数据加载

    private func loadData() {
        isLoading = true
        Task {
            if let userId = authManager.currentUser?.id {
                await communicationManager.ensureOfficialChannelSubscribed(userId: userId)
                await communicationManager.loadSubscribedChannels(userId: userId)
                await communicationManager.loadAllChannelLatestMessages()
            }
            await MainActor.run { isLoading = false }
        }
    }
}
