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
    @State private var activeSheet: ChannelSheet?
    @State private var showErrorAlert = false
    @State private var errorText = ""

    enum ChannelSheet: Identifiable {
        case create
        case detail(CommunicationChannel)
        case official(CommunicationChannel)

        var id: String {
            switch self {
            case .create: return "create"
            case .detail(let c): return "detail-\(c.id)"
            case .official(let c): return "official-\(c.id)"
            }
        }
    }

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

                    Button(action: { activeSheet = .create }) {
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                CreateChannelView()
                    .environmentObject(authManager)
            case .detail(let channel):
                ChannelDetailView(channel: channel)
                    .environmentObject(authManager)
            case .official(let channel):
                OfficialChannelDetailView(channel: channel)
            }
        }
        .onAppear { loadData() }
        .onReceive(NotificationCenter.default.publisher(for: .channelUpdated)) { _ in
            LogDebug("📡 [频道中心] 收到 channelUpdated 通知，刷新数据")
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .channelSubscribed)) { _ in
            LogDebug("📡 [频道中心] 收到 channelSubscribed 通知，刷新数据")
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .channelUnsubscribed)) { _ in
            LogDebug("📡 [频道中心] 收到 channelUnsubscribed 通知，刷新数据")
            loadData()
        }
        .alert("提示", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorText)
        }
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
        Button(action: {
            if channel.channelType == .official {
                Task {
                    await openOfficialChannel(channel)
                }
            } else {
                activeSheet = .detail(channel)
            }
        }) {
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
            activeSheet = .official(channel)
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
        LogDebug("🔄 [频道中心] 开始加载频道数据...")
        Task {
            guard let userId = authManager.currentUser?.id else {
                LogWarning("⚠️ [频道中心] 用户未登录，无法加载数据")
                return
            }
            LogDebug("📡 [频道中心] 用户ID: \(userId)")
            await communicationManager.loadPublicChannels()
            await communicationManager.ensureOfficialChannelSubscribed(userId: userId)
            await communicationManager.loadSubscribedChannels(userId: userId)

            await MainActor.run {
                LogDebug("📊 [频道中心] 数据加载完成:")
                LogDebug("  - 公开频道: \(communicationManager.channels.count) 个")
                LogDebug("  - 已订阅频道: \(communicationManager.subscribedChannels.count) 个")
            }
        }
    }
}
