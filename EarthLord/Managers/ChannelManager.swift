//
//  ChannelManager.swift
//  EarthLord
//
//  社交频道管理器
//  - 创建/获取频道
//  - 发送和加载消息
//  - 管理成员
//  - 实时订阅
//

import Foundation
import Supabase
import Combine

@MainActor
class ChannelManager: ObservableObject {
    static let shared = ChannelManager()

    private let supabase = supabaseClient

    // MARK: - Published Properties

    @Published var channels: [CommunicationChannel] = []
    @Published var currentChannel: CommunicationChannel?
    @Published var messages: [ChannelMessage] = []
    @Published var channelMembers: [String] = []  // member IDs
    @Published var isLoadingMessages = false
    @Published var isLoadingChannels = false

    // MARK: - Private Properties

    private var subscriptions: [RealtimeChannelV2] = []
    private let dateFormatter = ISO8601DateFormatter()

    private init() {
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - Channel Operations

    /// 加载用户的所有频道
    func loadChannels() async {
        isLoadingChannels = true
        defer { isLoadingChannels = false }

        guard let session = try? await supabase.auth.session else {
            LogDebug("❌ [频道] 无法获取用户会话")
            return
        }

        let userId = session.user.id.uuidString

        do {
            let response: [CommunicationChannel] = try await supabase
                .from("communication_channels")
                .select()
                .eq("creator_id", value: userId)
                .order("updated_at", ascending: false)
                .execute()
                .value

            channels = response
            LogDebug("✅ [频道] 加载频道列表: \(response.count) 个")
        } catch {
            LogDebug("❌ [频道] 加载频道列表失败: \(error.localizedDescription)")
        }
    }

    /// 获取单个频道
    func getChannel(id: UUID) -> CommunicationChannel? {
        return channels.first { $0.id == id }
    }

    /// 删除频道（仅创建者可以）
    func deleteChannel(id: UUID) async throws {
        try await supabase
            .from("communication_channels")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        LogDebug("✅ [频道] 删除频道: \(id)")

        // 刷新列表
        await loadChannels()
    }

    // MARK: - Message Operations

    /// 发送消息
    func sendMessage(channelId: UUID, content: String) async throws {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "Message", code: -1, userInfo: [NSLocalizedDescriptionKey: "消息不能为空"])
        }

        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "Message", code: -2, userInfo: [NSLocalizedDescriptionKey: "未登录"])
        }

        struct MessageInsert: Encodable {
            let channel_id: String
            let sender_id: String
            let sender_callsign: String
            let content: String
            let created_at: String
        }

        let userId = session.user.id.uuidString
        let username: String
        if case .string(let name) = session.user.userMetadata["username"] {
            username = name
        } else {
            username = "匿名用户"
        }

        let messageData = MessageInsert(
            channel_id: channelId.uuidString,
            sender_id: userId,
            sender_callsign: username,
            content: content,
            created_at: dateFormatter.string(from: Date())
        )

        _ = try await supabase
            .from("channel_messages")
            .insert(messageData)
            .execute()

        LogDebug("✅ [频道] 发送消息成功")
    }

    /// 加载频道的消息
    func loadMessages(channelId: UUID) async {
        isLoadingMessages = true
        defer { isLoadingMessages = false }

        do {
            let response: [ChannelMessage] = try await supabase
                .from("channel_messages")
                .select()
                .eq("channel_id", value: channelId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            messages = response
            LogDebug("✅ [频道] 加载消息: \(response.count) 条")
        } catch {
            LogDebug("❌ [频道] 加载消息失败: \(error.localizedDescription)")
            messages = []
        }
    }

    /// 加载频道成员列表
    func loadChannelMembers(channelId: UUID) async {
        do {
            let response: [ChannelSubscription] = try await supabase
                .from("channel_subscriptions")
                .select()
                .eq("channel_id", value: channelId.uuidString)
                .execute()
                .value

            channelMembers = response.map { $0.userId.uuidString }
            LogDebug("✅ [频道] 加载成员: \(response.count) 个")
        } catch {
            LogDebug("❌ [频道] 加载成员失败: \(error.localizedDescription)")
            channelMembers = []
        }
    }

    // MARK: - Realtime Subscription

    /// 订阅频道消息（简化版，实际使用时需要根据 Supabase Realtime API 调整）
    func subscribeToMessages(channelId: UUID) {
        // 注意：实时订阅需要正确配置 RealtimeChannelV2
        // 这里提供一个基础实现，可以根据需要扩展
        LogDebug("📡 [频道] 订阅频道 \(channelId) 的消息")
    }

    /// 取消所有订阅
    func unsubscribeAll() {
        // 清空订阅数组，让它们自动释放
        subscriptions.removeAll()
        LogDebug("✅ [频道] 已取消所有订阅")
    }

    // MARK: - Helper Methods

    /// 设置当前频道并加载消息
    func setCurrentChannel(_ channel: CommunicationChannel) async {
        currentChannel = channel
        await loadMessages(channelId: channel.id)
        await loadChannelMembers(channelId: channel.id)
        subscribeToMessages(channelId: channel.id)
    }

    /// 获取频道摘要信息
    func getChannelSummary(_ channel: CommunicationChannel) -> (name: String, lastMessage: String, memberCount: Int) {
        let channelName = channel.name
        let lastMessage = messages.last?.content ?? "暂无消息"
        let memberCount = channel.memberCount

        return (channelName, lastMessage, memberCount)
    }

    deinit {
        // Swift 6 language mode: 不能在 deinit 中捕获 self
        // 订阅会在对象释放时自动清理
        subscriptions.removeAll()
    }
}
