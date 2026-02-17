//
//  ChannelCenterView.swift
//  EarthLord
//
//  频道中心 - 我的频道 + 发现频道
//

import SwiftUI
import Supabase

struct ChannelCenterView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared

    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showCreateSheet = false
    @State private var selectedChannel: CommunicationChannel?

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部操作栏
                HStack {
                    Text("频道中心")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Spacer()

                    Button(action: { showCreateSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("创建")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                // Tab 切换栏
                HStack(spacing: 0) {
                    tabButton(title: "我的频道", index: 0)
                    tabButton(title: "发现频道", index: 1)
                }
                .background(ApocalypseTheme.cardBackground)

                // 搜索栏（仅发现页面）
                if selectedTab == 1 {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ApocalypseTheme.textMuted)
                        TextField("搜索频道", text: $searchText)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    .padding(10)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // 内容区域
                ScrollView {
                    if selectedTab == 0 {
                        myChannelsView
                    } else {
                        discoverChannelsView
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateChannelView()
                .environmentObject(authManager)
        }
        .sheet(item: $selectedChannel) { channel in
            ChannelDetailView(channel: channel)
                .environmentObject(authManager)
        }
        .onAppear { loadData() }
    }

    // MARK: - Tab Button

    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(selectedTab == index ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)

                Rectangle()
                    .fill(selectedTab == index ? ApocalypseTheme.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - My Channels

    private var myChannelsView: some View {
        VStack(spacing: 12) {
            if communicationManager.subscribedChannels.isEmpty {
                emptyStateView(
                    icon: "dot.radiowaves.left.and.right",
                    title: "还没有订阅频道",
                    subtitle: "去「发现频道」浏览并订阅感兴趣的频道"
                )
            } else {
                ForEach(communicationManager.subscribedChannels) { item in
                    channelRow(channel: item.channel, isSubscribed: true)
                }
            }
        }
        .padding()
    }

    // MARK: - Discover Channels

    private var filteredChannels: [CommunicationChannel] {
        if searchText.isEmpty {
            return communicationManager.channels
        }
        return communicationManager.channels.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var discoverChannelsView: some View {
        VStack(spacing: 12) {
            if filteredChannels.isEmpty {
                emptyStateView(
                    icon: "globe",
                    title: "暂无频道",
                    subtitle: "点击右上角创建第一个频道"
                )
            } else {
                ForEach(filteredChannels) { channel in
                    let subscribed = communicationManager.isSubscribed(channelId: channel.id)
                    channelRow(channel: channel, isSubscribed: subscribed)
                }
            }
        }
        .padding()
    }

    // MARK: - Channel Row

    private func channelRow(channel: CommunicationChannel, isSubscribed: Bool) -> some View {
        Button(action: { selectedChannel = channel }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ApocalypseTheme.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: channel.channelType.iconName)
                        .foregroundColor(ApocalypseTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(channel.name)
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.textPrimary)

                        if isSubscribed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }

                    Text("\(channel.channelType.displayName) · \(channel.channelCode)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(channel.memberCount) 人")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(ApocalypseTheme.primary.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        Task {
            guard let userId = authManager.currentUser?.id else { return }
            await communicationManager.loadPublicChannels()
            await communicationManager.loadSubscribedChannels(userId: userId)
        }
    }
}
