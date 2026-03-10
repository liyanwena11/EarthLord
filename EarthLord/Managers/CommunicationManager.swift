//
//  CommunicationManager.swift
//  EarthLord
//
//  通讯管理器 - 管理通讯设备和频道
//

import Foundation
import Combine
import Supabase
import CoreLocation

class CommunicationManager: ObservableObject {

    static let shared = CommunicationManager()

    @Published var devices: [CommunicationDevice] = []
    @Published var currentDevice: CommunicationDevice?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Channel properties
    @Published var channels: [CommunicationChannel] = []
    @Published var subscribedChannels: [SubscribedChannel] = []
    @Published var mySubscriptions: [ChannelSubscription] = []

    // Message properties
    @Published var channelMessages: [UUID: [ChannelMessage]] = [:]
    @Published var isSendingMessage = false
    @Published var subscribedChannelIds: Set<UUID> = []

    // Realtime properties
    private var realtimeChannel: RealtimeChannelV2?
    private var messageSubscriptionTask: Task<Void, Never>?

    private let supabase = supabaseClient
    private var cancellables = Set<AnyCancellable>()

    private init() {
        LogDebug("📡 [通讯] CommunicationManager 初始化完成")
    }

    private func currentUserId() async -> UUID? {
        await MainActor.run { AuthManager.shared.currentUser?.id }
    }

    // MARK: - Device Management

    func fetchUserDevices() async {
        guard let userId = await currentUserId() else { return }

        await MainActor.run { self.isLoading = true }

        do {
            let devices: [CommunicationDevice] = try await supabase
                .from("communication_devices")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            await MainActor.run { 
                self.devices = devices
                self.currentDevice = devices.first(where: { $0.isCurrent })
                self.isLoading = false 
            }
        } catch {
            LogError("❌ [通讯] 获取设备失败: \(error.localizedDescription)")
            await MainActor.run { 
                self.isLoading = false 
                self.errorMessage = "获取设备失败"
            }
        }
    }

    func setCurrentDevice(deviceId: UUID) async throws {
        _ = await currentUserId()

        // 先将所有设备设置为非当前
        for device in devices {
            try await supabase
                .from("communication_devices")
                .update(["is_current": false])
                .eq("id", value: device.id.uuidString)
                .execute()
        }

        // 将选中的设备设置为当前
        try await supabase
            .from("communication_devices")
            .update(["is_current": true])
            .eq("id", value: deviceId.uuidString)
            .execute()

        await fetchUserDevices()
        LogInfo("📡 [通讯] ✅ 设置当前设备成功: \(deviceId)")
    }

    func unlockDevice(deviceType: DeviceType) async throws {
        guard let userId = await currentUserId() else { throw CommunicationError.notConfigured }

        let device = devices.first { $0.deviceType == deviceType }
        if let device = device {
            // 更新现有设备
            try await supabase
                .from("communication_devices")
                .update(["is_unlocked": true])
                .eq("id", value: device.id.uuidString)
                .execute()
        } else {
            // 创建新设备
            let newDevice = CommunicationDevice(
                id: UUID(),
                userId: userId,
                deviceType: deviceType,
                deviceLevel: 1,
                isUnlocked: true,
                isCurrent: devices.isEmpty,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await supabase
                .from("communication_devices")
                .insert(newDevice)
                .execute()
        }

        await fetchUserDevices()
        LogInfo("📡 [通讯] ✅ 解锁设备成功: \(deviceType.displayName)")
    }

    // MARK: - Initialize Devices

    /// 确保用户有默认设备（如果没有任何设备则创建）
    func ensureDefaultDevice() async {
        guard let userId = await currentUserId() else { return }

        // 检查用户是否已有设备
        let existingDevices: [CommunicationDevice]
        do {
            existingDevices = try await supabase
                .from("communication_devices")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
        } catch {
            LogError("❌ [通讯] 检查设备失败: \(error.localizedDescription)")
            return
        }

        if existingDevices.isEmpty {
            // 创建默认对讲机设备
            let defaultDevice = CommunicationDevice(
                id: UUID(),
                userId: userId,
                deviceType: .walkieTalkie,
                deviceLevel: 1,
                isUnlocked: true,
                isCurrent: true,
                createdAt: Date(),
                updatedAt: Date()
            )

            do {
                try await supabase
                    .from("communication_devices")
                    .insert(defaultDevice)
                    .execute()
                LogInfo("📡 [通讯] ✅ 创建默认对讲机设备成功")
            } catch {
                LogError("❌ [通讯] 创建默认设备失败: \(error.localizedDescription)")
            }
            await fetchUserDevices()
            return
        }

        // 用户已有设备时，归一化当前设备标记（处理 0 个或多个 is_current=true 的异常数据）
        let currentMarkedCount = existingDevices.filter(\.isCurrent).count
        if currentMarkedCount != 1 {
            guard let preferredDeviceId = preferredCurrentDeviceId(from: existingDevices) else {
                await fetchUserDevices()
                return
            }

            do {
                try await supabase
                    .from("communication_devices")
                    .update(["is_current": false])
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                try await supabase
                    .from("communication_devices")
                    .update(["is_current": true])
                    .eq("id", value: preferredDeviceId.uuidString)
                    .execute()

                LogInfo("📡 [通讯] ✅ 已修复当前设备标记，deviceId=\(preferredDeviceId.uuidString)")
            } catch {
                LogError("❌ [通讯] 修复当前设备失败: \(error.localizedDescription)")
            }
        }

        await fetchUserDevices()
    }

    func initializeUserDevices() async throws {
        guard let userId = await currentUserId() else { throw CommunicationError.notConfigured }

        // 检查用户是否已有设备
        let existingDevices: [CommunicationDevice] = try await supabase
            .from("communication_devices")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if existingDevices.isEmpty {
            // 创建默认设备
            let defaultDevices = [
                CommunicationDevice(
                    id: UUID(),
                    userId: userId,
                    deviceType: .radio,
                    deviceLevel: 1,
                    isUnlocked: true,
                    isCurrent: true,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                CommunicationDevice(
                    id: UUID(),
                    userId: userId,
                    deviceType: .walkieTalkie,
                    deviceLevel: 1,
                    isUnlocked: true,
                    isCurrent: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                CommunicationDevice(
                    id: UUID(),
                    userId: userId,
                    deviceType: .campRadio,
                    deviceLevel: 1,
                    isUnlocked: false,
                    isCurrent: false,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                CommunicationDevice(
                    id: UUID(),
                    userId: userId,
                    deviceType: .satellite,
                    deviceLevel: 1,
                    isUnlocked: false,
                    isCurrent: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]

            for device in defaultDevices {
                try await supabase
                    .from("communication_devices")
                    .insert(device)
                    .execute()
            }

            LogInfo("📡 [通讯] ✅ 初始化默认设备成功")
        }

        await fetchUserDevices()
    }

    // MARK: - Channel Methods

    func loadPublicChannels() async {
        LogDebug("📡 [频道] 开始加载公开频道...")
        do {
            let result: [CommunicationChannel] = try await supabase
                .from("communication_channels")
                .select()
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run { self.channels = result }
            LogInfo("📡 [频道] ✅ 加载公开频道: \(result.count) 个")

            // 详细日志
            for (index, channel) in result.prefix(5).enumerated() {
                LogDebug("  [\(index+1)] \(channel.name) - \(channel.channelType.displayName)")
            }
            if result.count > 5 {
                LogDebug("  ... 还有 \(result.count - 5) 个频道")
            }
        } catch {
            LogError("❌ [频道] 加载公开频道失败")
            LogError("  错误: \(error.localizedDescription)")

            // 详细错误诊断
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    LogError("  类型不匹配: 期望 \(type), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    LogError("  值未找到: 类型 \(type), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .keyNotFound(let key, let context):
                    LogError("  键未找到: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                default:
                    LogError("  其他解码错误: \(decodingError)")
                }
            }

            await MainActor.run {
                self.errorMessage = "加载频道失败: \(error.localizedDescription)"
            }
        }
    }

    func loadSubscribedChannels(userId: UUID) async {
        do {
            // 1. 查询用户的订阅
            let subscriptions: [ChannelSubscription] = try await supabase
                .from("channel_subscriptions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            await MainActor.run { self.mySubscriptions = subscriptions }

            guard !subscriptions.isEmpty else {
                await MainActor.run { self.subscribedChannels = [] }
                return
            }

            // 2. 查询对应的频道详情
            let channelIds = subscriptions.map { $0.channelId.uuidString }
            let channelList: [CommunicationChannel] = try await supabase
                .from("communication_channels")
                .select()
                .in("id", values: channelIds)
                .execute()
                .value

            // 3. 组合成 SubscribedChannel
            let combined = subscriptions.compactMap { sub in
                guard let channel = channelList.first(where: { $0.id == sub.channelId }) else { return nil as SubscribedChannel? }
                return SubscribedChannel(channel: channel, subscription: sub)
            }

            await MainActor.run { self.subscribedChannels = combined }
            LogInfo("📡 [频道] ✅ 加载已订阅频道: \(combined.count) 个")
        } catch {
            LogError("❌ [频道] 加载已订阅频道失败: \(error.localizedDescription)")
        }
    }

    func createChannel(userId: UUID, type: ChannelType, name: String, description: String?, latitude: Double? = nil, longitude: Double? = nil) async throws -> UUID {
        let params: [String: AnyJSON] = [
            "p_creator_id": .string(userId.uuidString),
            "p_channel_type": .string(type.rawValue),
            "p_name": .string(name),
            "p_description": description.map { .string($0) } ?? .null,
            "p_latitude": latitude.map { .double($0) } ?? .null,
            "p_longitude": longitude.map { .double($0) } ?? .null
        ]

        let channelId: UUID = try await supabase
            .rpc("create_channel_with_subscription", params: params)
            .execute()
            .value

        await loadPublicChannels()
        await loadSubscribedChannels(userId: userId)

        LogInfo("📡 [频道] ✅ 创建频道成功: \(name)")
        return channelId
    }

    func subscribeToChannel(userId: UUID, channelId: UUID) async throws {
        // 避免重复订阅请求（兼容后端旧函数 member_count +1 的历史问题）
        if isSubscribed(channelId: channelId) || subscribedChannels.contains(where: { $0.channel.id == channelId }) {
            LogDebug("ℹ️ [频道] 已订阅，跳过重复订阅请求: \(channelId.uuidString)")
            return
        }

        let params: [String: AnyJSON] = [
            "p_user_id": .string(userId.uuidString),
            "p_channel_id": .string(channelId.uuidString)
        ]

        try await supabase
            .rpc("subscribe_to_channel", params: params)
            .execute()

        await loadPublicChannels()
        await loadSubscribedChannels(userId: userId)

        // ✅ 发送通知刷新界面
        await MainActor.run {
            NotificationCenter.default.post(name: .channelSubscribed, object: channelId)
        }

        LogInfo("📡 [频道] ✅ 订阅频道成功")
    }

    func unsubscribeFromChannel(userId: UUID, channelId: UUID) async throws {
        let params: [String: AnyJSON] = [
            "p_user_id": .string(userId.uuidString),
            "p_channel_id": .string(channelId.uuidString)
        ]

        try await supabase
            .rpc("unsubscribe_from_channel", params: params)
            .execute()

        await loadPublicChannels()
        await loadSubscribedChannels(userId: userId)

        // ✅ 发送通知刷新界面
        await MainActor.run {
            NotificationCenter.default.post(name: .channelUnsubscribed, object: channelId)
        }

        LogInfo("📡 [频道] ✅ 取消订阅成功")
    }

    func deleteChannel(channelId: UUID) async throws {
        guard let userId = await currentUserId() else { throw CommunicationError.notConfigured }

        try await supabase
            .from("communication_channels")
            .delete()
            .eq("id", value: channelId.uuidString)
            .execute()

        await loadPublicChannels()
        await loadSubscribedChannels(userId: userId)
        LogInfo("📡 [频道] ✅ 删除频道成功")
    }

    func isSubscribed(channelId: UUID) -> Bool {
        mySubscriptions.contains { $0.channelId == channelId }
    }

    // MARK: - Message Methods

    // Day 36: 发送语音消息
    func sendVoiceMessage(
        channelId: UUID,
        audioURL: URL,
        audioDuration: TimeInterval,
        latitude: Double? = nil,
        longitude: Double? = nil,
        deviceType: String? = nil
    ) async -> Bool {
        guard await currentUserId() != nil else {
            await MainActor.run { self.errorMessage = "用户未登录" }
            return false
        }

        await MainActor.run { self.isSendingMessage = true }

        do {
            // 1. 获取音频数据
            let audioData = try Data(contentsOf: audioURL)
            let fileName = audioURL.lastPathComponent

            // 2. 计算文件大小
            let fileSizeMB = Double(audioData.count) / 1024.0 / 1024.0

            // 3. TODO: 上传到 Supabase Storage（暂时使用本地路径）
            // 由于 Supabase SDK API 变化，暂时使用占位符
            let audioPublicURL = "local://\(audioURL.path)"

            // 4. 发送消息（含音频 URL）
            let params: [String: AnyJSON] = [
                "p_channel_id": .string(channelId.uuidString),
                "p_content": .string("[语音消息]"),
                "p_latitude": latitude.map { .double($0) } ?? .null,
                "p_longitude": longitude.map { .double($0) } ?? .null,
                "p_device_type": deviceType.map { .string($0) } ?? .null,
                "p_message_type": .string("voice"),
                "p_audio_url": .string(audioPublicURL),
                "p_audio_duration": .double(audioDuration),
                "p_file_size": .double(fileSizeMB)
            ]

            // 尝试调用 RPC 函数
            let _: UUID = try await supabase
                .rpc("send_voice_message", params: params)
                .execute()
                .value

            await MainActor.run { self.isSendingMessage = false }
            LogInfo("🎤 [语音] 发送成功: \(fileName), \(String(format: "%.1f", audioDuration))s, \(String(format: "%.2f", fileSizeMB))MB")
            return true
        } catch {
            LogError("❌ [语音] 发送失败: \(error.localizedDescription)")

            // 回退：尝试直接写入数据库
            do {
                guard let senderId = await currentUserId() else {
                    throw CommunicationError.notConfigured
                }

                let audioData = try Data(contentsOf: audioURL)
                let fileSizeMB = Double(audioData.count) / 1024.0 / 1024.0
                let callsign = await fetchCurrentCallsign(userId: senderId) ?? "匿名幸存者"
                let audioPublicURL = "local://\(audioURL.path)"

                struct VoiceMessageInsert: Encodable {
                    let channel_id: String
                    let sender_id: String
                    let sender_callsign: String
                    let content: String
                    let sender_location: [String: Double]?
                    let metadata: [String: AnyJSON]
                }

                let metadata: [String: AnyJSON] = [
                    "device_type": .string(deviceType ?? "unknown"),
                    "message_type": .string("voice"),
                    "audio_url": .string(audioPublicURL),
                    "audio_duration": .double(audioDuration),
                    "file_size": .double(fileSizeMB)
                ]

                let payload = VoiceMessageInsert(
                    channel_id: channelId.uuidString,
                    sender_id: senderId.uuidString,
                    sender_callsign: callsign,
                    content: "[语音消息]",
                    sender_location: latitude.map { ["latitude": $0, "longitude": longitude ?? 0] },
                    metadata: metadata
                )

                try await supabase
                    .from("channel_messages")
                    .insert(payload)
                    .execute()

                await MainActor.run { self.isSendingMessage = false }
                LogInfo("🎤 [语音] 直接写入成功")
                return true
            } catch {
                await MainActor.run {
                    self.errorMessage = "发送失败: \(error.localizedDescription)"
                    self.isSendingMessage = false
                }
                LogError("❌ [语音] 直接写入也失败: \(error.localizedDescription)")
                return false
            }
        }
    }

    func loadChannelMessages(channelId: UUID) async {
        do {
            let messages: [ChannelMessage] = try await supabase
                .from("channel_messages")
                .select()
                .eq("channel_id", value: channelId.uuidString)
                .order("created_at", ascending: true)
                .limit(50)
                .execute()
                .value

            await MainActor.run {
                self.channelMessages[channelId] = messages
            }
            LogInfo("📡 [消息] ✅ 加载消息: \(messages.count) 条")
        } catch {
            LogError("❌ [消息] 加载消息失败: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "加载消息失败: \(error.localizedDescription)"
            }
        }
    }

    func sendChannelMessage(
        channelId: UUID,
        content: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        deviceType: String? = nil
    ) async -> Bool {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            await MainActor.run { self.errorMessage = "消息内容不能为空" }
            return false
        }

        await MainActor.run { self.isSendingMessage = true }

        do {
            let params: [String: AnyJSON] = [
                "p_channel_id": .string(channelId.uuidString),
                "p_content": .string(content),
                "p_latitude": latitude.map { .double($0) } ?? .null,
                "p_longitude": longitude.map { .double($0) } ?? .null,
                "p_device_type": deviceType.map { .string($0) } ?? .null
            ]

            let _: UUID = try await supabase
                .rpc("send_channel_message", params: params)
                .execute()
                .value

            await MainActor.run { self.isSendingMessage = false }
            LogInfo("📡 [消息] ✅ 发送成功")
            return true
        } catch {
            LogWarning("⚠️ [消息] RPC 发送失败，尝试直接写表: \(error.localizedDescription)")

            do {
                guard let senderId = await currentUserId() else {
                    throw CommunicationError.notConfigured
                }

                struct DirectMessageInsertRich: Encodable {
                    let channel_id: String
                    let sender_id: String
                    let sender_callsign: String
                    let content: String
                    let metadata: [String: String]
                }

                struct DirectMessageInsertMinimal: Encodable {
                    let channel_id: String
                    let sender_id: String
                    let content: String
                }

                let callsign = await fetchCurrentCallsign(userId: senderId) ?? "匿名幸存者"
                let metadata = ["device_type": deviceType ?? "unknown"]

                do {
                    let payload = DirectMessageInsertRich(
                        channel_id: channelId.uuidString,
                        sender_id: senderId.uuidString,
                        sender_callsign: callsign,
                        content: content,
                        metadata: metadata
                    )

                    try await supabase
                        .from("channel_messages")
                        .insert(payload)
                        .execute()

                    await MainActor.run { self.isSendingMessage = false }
                    LogInfo("📡 [消息] ✅ 直接写表发送成功（含 metadata）")
                    return true
                } catch {
                    let payload = DirectMessageInsertMinimal(
                        channel_id: channelId.uuidString,
                        sender_id: senderId.uuidString,
                        content: content
                    )

                    try await supabase
                        .from("channel_messages")
                        .insert(payload)
                        .execute()

                    await MainActor.run { self.isSendingMessage = false }
                    LogInfo("📡 [消息] ✅ 直接写表发送成功（最小字段）")
                    return true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "发送失败: \(error.localizedDescription)"
                    self.isSendingMessage = false
                }
                LogError("❌ [消息] 发送失败: \(error.localizedDescription)")
                return false
            }
        }
    }

    // MARK: - Realtime

    func startRealtimeSubscription() async {
        await stopRealtimeSubscription()

        realtimeChannel = supabase.realtimeV2.channel("channel_messages_realtime")

        guard let channel = realtimeChannel else { return }

        let insertions = channel.postgresChange(
            InsertAction.self,
            table: "channel_messages"
        )

        messageSubscriptionTask = Task { [weak self] in
            for await insertion in insertions {
                await self?.handleNewMessage(insertion: insertion)
            }
        }

        try? await channel.subscribeWithError()
        LogDebug("📡 [Realtime] 消息订阅已启动")
    }

    func stopRealtimeSubscription() async {
        messageSubscriptionTask?.cancel()
        messageSubscriptionTask = nil

        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
        }

        LogDebug("📡 [Realtime] 消息订阅已停止")
    }

    private func handleNewMessage(insertion: InsertAction) async {
        do {
            let message = try insertion.decodeRecord(as: ChannelMessage.self, decoder: JSONDecoder())

            guard subscribedChannelIds.contains(message.channelId) else {
                return
            }

            // Day 35: 距离过滤
            guard shouldReceiveMessage(message) else {
                return
            }

            await MainActor.run {
                if self.channelMessages[message.channelId] != nil {
                    self.channelMessages[message.channelId]?.append(message)
                } else {
                    self.channelMessages[message.channelId] = [message]
                }
            }
            LogDebug("📡 [Realtime] 收到新消息: \(message.content.prefix(20))...")
        } catch {
            LogError("❌ [Realtime] 解析消息失败: \(error)")
        }
    }

    func subscribeToChannelMessages(channelId: UUID) {
        subscribedChannelIds.insert(channelId)

        if realtimeChannel == nil {
            Task { await startRealtimeSubscription() }
        }
    }

    func unsubscribeFromChannelMessages(channelId: UUID) {
        subscribedChannelIds.remove(channelId)
        channelMessages.removeValue(forKey: channelId)

        if subscribedChannelIds.isEmpty {
            Task { await stopRealtimeSubscription() }
        }
    }

    func getMessages(for channelId: UUID) -> [ChannelMessage] {
        channelMessages[channelId] ?? []
    }

    // MARK: - 距离过滤

    /// 判断是否应该接收该消息（基于设备类型和距离）
    func shouldReceiveMessage(_ message: ChannelMessage) -> Bool {
        // 只对公共频道应用距离过滤
        let channel = channels.first(where: { $0.id == message.channelId })
            ?? subscribedChannels.first(where: { $0.channel.id == message.channelId })?.channel
        if let channelType = channel?.channelType, channelType != .publicChannel {
            return true  // 非公共频道不限制
        }

        guard let myDeviceType = currentDevice?.deviceType else {
            LogWarning("⚠️ [距离过滤] 无法获取当前设备，保守显示消息")
            return true
        }
        if myDeviceType == .radio {
            LogDebug("📻 [距离过滤] 收音机用户，接收所有消息")
            return true
        }
        guard let senderDevice = message.senderDeviceType else {
            LogWarning("⚠️ [距离过滤] 消息缺少设备类型，保守显示（向后兼容）")
            return true
        }
        if !senderDevice.canSend {
            LogDebug("🚫 [距离过滤] 收音机不能发送消息")
            return false
        }
        guard let senderLocation = message.senderLocation else {
            LogWarning("⚠️ [距离过滤] 消息缺少位置信息，保守显示")
            return true
        }
        guard let myLocation = getCurrentLocation() else {
            LogWarning("⚠️ [距离过滤] 无法获取当前位置，保守显示")
            return true
        }

        let distance = calculateDistance(
            from: CLLocationCoordinate2D(latitude: myLocation.latitude, longitude: myLocation.longitude),
            to: CLLocationCoordinate2D(latitude: senderLocation.latitude, longitude: senderLocation.longitude)
        )

        let maxRange = max(senderDevice.range, myDeviceType.range)
        let result = distance <= maxRange

        LogInfo(result
            ? "✅ [距离过滤] 通过: \(senderDevice.rawValue)→\(myDeviceType.rawValue), \(String(format: "%.1f", distance))km"
            : "🚫 [距离过滤] 丢弃: \(senderDevice.rawValue)→\(myDeviceType.rawValue), \(String(format: "%.1f", distance))km > \(maxRange)km")
        return result
    }

    /// 计算两个坐标之间的距离（公里）
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLoc = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLoc.distance(from: toLoc) / 1000.0
    }

    /// 获取当前用户位置（从 LocationManager 获取真实 GPS）
    private func getCurrentLocation() -> LocationPoint? {
        guard let location = LocationManager.shared.userLocation else {
            return nil
        }
        return LocationPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    // MARK: - 官方频道

    /// 官方频道固定 UUID
    static let officialChannelId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    /// 确保用户订阅了官方频道（强制订阅）
    func ensureOfficialChannelSubscribed(userId: UUID) async {
        // 先拉最新订阅状态，避免因本地状态滞后触发重复订阅请求
        await loadSubscribedChannels(userId: userId)

        // 先确保频道列表已加载，才能按 channelType 精准识别官方频道
        if channels.isEmpty {
            await loadPublicChannels()
        }

        var officialIds = Set(
            channels
                .filter { $0.channelType == .official }
                .map { $0.id }
        )

        for item in subscribedChannels where item.channel.channelType == .official {
            officialIds.insert(item.channel.id)
        }

        // 兼容旧数据：如果还没查到官方频道，回退固定 UUID 方案
        if officialIds.isEmpty {
            officialIds.insert(CommunicationManager.officialChannelId)
        }

        var subscribedCount = 0
        for channelId in officialIds {
            if isSubscribed(channelId: channelId) || subscribedChannels.contains(where: { $0.channel.id == channelId }) {
                subscribedCount += 1
                continue
            }

            do {
                try await subscribeToChannel(userId: userId, channelId: channelId)
                subscribedCount += 1
                LogInfo("✅ [官方频道] 已自动订阅: \(channelId.uuidString)")
            } catch {
                LogError("❌ [官方频道] 订阅失败: \(channelId.uuidString), error=\(error)")
            }
        }

        await loadSubscribedChannels(userId: userId)
        LogInfo("📡 [官方频道] 订阅完成，成功 \(subscribedCount) 个")
    }

    /// 判断是否为官方频道
    func isOfficialChannel(_ channelId: UUID) -> Bool {
        if channelId == CommunicationManager.officialChannelId {
            return true
        }
        if channels.contains(where: { $0.id == channelId && $0.channelType == .official }) {
            return true
        }
        if subscribedChannels.contains(where: { $0.channel.id == channelId && $0.channel.channelType == .official }) {
            return true
        }
        return false
    }

    /// 频道详情页使用：进入前自动补订阅（主要用于官方频道与异常状态恢复）
    @discardableResult
    func ensureChannelSubscribedIfNeeded(userId: UUID, channel: CommunicationChannel) async -> Bool {
        if isSubscribed(channelId: channel.id) || subscribedChannels.contains(where: { $0.channel.id == channel.id }) {
            return true
        }

        await loadSubscribedChannels(userId: userId)
        if isSubscribed(channelId: channel.id) || subscribedChannels.contains(where: { $0.channel.id == channel.id }) {
            return true
        }

        do {
            try await subscribeToChannel(userId: userId, channelId: channel.id)
            await loadSubscribedChannels(userId: userId)
            return true
        } catch {
            LogError("❌ [频道] 自动补订阅失败: \(channel.name), error=\(error)")
            return false
        }
    }

    // MARK: - 消息聚合

    /// 频道摘要（用于消息聚合页）
    struct ChannelSummary: Identifiable {
        let channel: CommunicationChannel
        let lastMessage: ChannelMessage?
        let unreadCount: Int
        var id: UUID { channel.id }
    }

    /// 获取所有订阅频道的摘要，官方频道置顶
    func getChannelSummaries() -> [ChannelSummary] {
        subscribedChannels.map { sc in
            let msgs = channelMessages[sc.channel.id] ?? []
            return ChannelSummary(channel: sc.channel, lastMessage: msgs.last, unreadCount: 0)
        }.sorted { a, b in
            if a.channel.channelType == .official && b.channel.channelType != .official { return true }
            if a.channel.channelType != .official && b.channel.channelType == .official { return false }
            let t1 = a.lastMessage?.createdAt ?? a.channel.createdAt
            let t2 = b.lastMessage?.createdAt ?? b.channel.createdAt
            return t1 > t2
        }
    }

    /// 加载所有订阅频道的最新一条消息（用于消息聚合页预览）
    func loadAllChannelLatestMessages() async {
        for sc in subscribedChannels {
            let channelId = sc.channel.id
            do {
                let messages: [ChannelMessage] = try await supabase
                    .from("channel_messages")
                    .select()
                    .eq("channel_id", value: channelId.uuidString)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                if let last = messages.first {
                    await MainActor.run {
                        if self.channelMessages[channelId] == nil {
                            self.channelMessages[channelId] = [last]
                        } else if !(self.channelMessages[channelId]!.contains(where: { $0.messageId == last.messageId })) {
                            self.channelMessages[channelId]?.append(last)
                        }
                    }
                }
            } catch {
                LogError("❌ [消息聚合] 加载频道 \(channelId) 失败: \(error)")
            }
        }
    }

    private func preferredCurrentDeviceId(from devices: [CommunicationDevice]) -> UUID? {
        devices.first(where: { $0.isUnlocked && $0.deviceType == .walkieTalkie })?.id
            ?? devices.first(where: { $0.isUnlocked && $0.deviceType.canSend })?.id
            ?? devices.first(where: { $0.isUnlocked })?.id
            ?? devices.first?.id
    }

    private func fetchCurrentCallsign(userId: UUID) async -> String? {
        struct UserProfileCallsign: Decodable { let callsign: String? }
        struct ProfileUsername: Decodable { let username: String? }

        do {
            let profiles: [UserProfileCallsign] = try await supabase
                .from("user_profiles")
                .select("callsign")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let callsign = profiles.first?.callsign?.trimmingCharacters(in: .whitespacesAndNewlines),
               !callsign.isEmpty {
                return callsign
            }
        } catch {
            LogDebug("ℹ️ [消息] user_profiles 呼号读取失败，回退 profiles.username")
        }

        do {
            let profiles: [ProfileUsername] = try await supabase
                .from("profiles")
                .select("username")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let username = profiles.first?.username?.trimmingCharacters(in: .whitespacesAndNewlines),
               !username.isEmpty {
                return username
            }
        } catch {
            LogDebug("ℹ️ [消息] profiles.username 读取失败")
        }

        return nil
    }
}

// MARK: - CommunicationError

enum CommunicationError: Error {
    case notConfigured
    case deviceNotFound
    case deviceNotUnlocked
    case operationFailed(String)
}

extension CommunicationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "通讯系统未配置"
        case .deviceNotFound:
            return "设备未找到"
        case .deviceNotUnlocked:
            return "设备未解锁"
        case .operationFailed(let message):
            return message
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let channelUpdated = Notification.Name("channelUpdated")
    static let channelSubscribed = Notification.Name("channelSubscribed")
    static let channelUnsubscribed = Notification.Name("channelUnsubscribed")
}
