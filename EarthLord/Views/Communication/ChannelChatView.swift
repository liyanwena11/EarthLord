//
//  ChannelChatView.swift
//  EarthLord
//
//  频道聊天界面 - 消息列表 + 输入栏 + Realtime
//

import SwiftUI
import Supabase
import CoreLocation

struct ChannelChatView: View {
    let channel: CommunicationChannel

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""
    @State private var isLoading = true

    private var messages: [ChannelMessage] {
        communicationManager.getMessages(for: channel.id)
    }

    private var currentUserId: UUID? {
        authManager.currentUser?.id
    }

    private var canSend: Bool {
        communicationManager.currentDevice?.deviceType.canSend ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 频道信息栏
                    channelHeader

                    // 消息列表
                    messageListView

                    // 底部输入栏
                    inputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .foregroundColor(ApocalypseTheme.primary)
                    }
                }
            }
        }
        .onAppear {
            communicationManager.subscribeToChannelMessages(channelId: channel.id)
            Task {
                await communicationManager.loadChannelMessages(channelId: channel.id)
                await MainActor.run { isLoading = false }
            }
        }
        .onDisappear {
            communicationManager.unsubscribeFromChannelMessages(channelId: channel.id)
        }
    }

    // MARK: - Channel Header

    private var channelHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: channel.channelType.iconName)
                .foregroundColor(ApocalypseTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Text(channel.channelCode)
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                Text("\(channel.memberCount)")
                    .font(.caption)
            }
            .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(ApocalypseTheme.cardBackground)
    }

    // MARK: - Message List

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if messages.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 60)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(ApocalypseTheme.primary.opacity(0.4))
                        Text("暂无消息")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        Text("发送第一条消息开始聊天")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isOwnMessage: message.senderId == currentUserId
                            )
                            .id(message.messageId)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .onChange(of: messages.count) { oldValue, newValue in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        Group {
            if canSend {
                HStack(spacing: 10) {
                    TextField("输入消息...", text: $messageText)
                        .padding(10)
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(20)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
                        )

                    Button(action: { sendMessage() }) {
                        Group {
                            if communicationManager.isSendingMessage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty || communicationManager.isSendingMessage
                                    ? ApocalypseTheme.primary.opacity(0.4)
                                    : ApocalypseTheme.primary)
                        .clipShape(Circle())
                        .foregroundColor(.white)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || communicationManager.isSendingMessage)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ApocalypseTheme.cardBackground)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "radio")
                        .foregroundColor(ApocalypseTheme.primary)
                    Text("收音机模式：只能收听，无法发送消息")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ApocalypseTheme.cardBackground)
            }
        }
    }

    // MARK: - Send

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }

        let deviceType = communicationManager.currentDevice?.deviceType.rawValue
        let location = LocationManager.shared.userLocation
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        messageText = ""

        Task {
            let success = await communicationManager.sendChannelMessage(
                channelId: channel.id,
                content: content,
                latitude: latitude,
                longitude: longitude,
                deviceType: deviceType
            )
            if !success {
                await MainActor.run { messageText = content }
            }
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubbleView: View {
    let message: ChannelMessage
    let isOwnMessage: Bool

    // Day 36: 音频播放
    @StateObject private var audioManager = AudioRecordManager.shared
    @State private var isPlayingAudio = false

    var body: some View {
        HStack {
            if isOwnMessage { Spacer(minLength: 60) }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                // 他人消息显示呼号
                if !isOwnMessage {
                    HStack(spacing: 4) {
                        Text(message.senderCallsign ?? "匿名")
                            .font(.caption2.bold())
                            .foregroundColor(ApocalypseTheme.primary)

                        if let dt = message.senderDeviceType {
                            Image(systemName: dt.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                    }
                }

                // Day 36: 消息内容（支持语音）
                if message.isVoiceMessage {
                    // 语音消息
                    voiceMessageBubble
                } else {
                    // 文字消息
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(isOwnMessage ? .white : ApocalypseTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isOwnMessage ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .cornerRadius(16)
                }

                // 时间
                Text(message.timeString)
                    .font(.system(size: 10))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            if !isOwnMessage { Spacer(minLength: 60) }
        }
    }

    // Day 36: 语音消息气泡
    private var voiceMessageBubble: some View {
        HStack(spacing: 8) {
            // 播放/停止按钮
            Button(action: toggleAudioPlayback) {
                ZStack {
                    Circle()
                        .fill(isPlayingAudio ? ApocalypseTheme.primary.opacity(0.8) : ApocalypseTheme.primary)
                        .frame(width: 40, height: 40)

                    Image(systemName: isPlayingAudio ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
            }

            // 波形动画 + 时长
            VStack(alignment: .leading, spacing: 2) {
                if isPlayingAudio {
                    // 播放中 - 模拟波形动画
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isOwnMessage ? .white : ApocalypseTheme.primary)
                                .frame(width: 3, height: CGFloat.random(in: 10...30))
                                .animation(.easeInOut(duration: 0.3).repeatForever(), value: isPlayingAudio)
                        }
                    }
                } else {
                    // 停止 - 直线波形
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isOwnMessage ? .white.opacity(0.6) : ApocalypseTheme.primary.opacity(0.4))
                                .frame(width: 3, height: CGFloat.random(in: 10...20))
                        }
                    }
                }

                // 时长和文件大小
                HStack(spacing: 4) {
                    Text(durationText)
                        .font(.caption2)
                        .foregroundColor(isOwnMessage ? .white.opacity(0.8) : ApocalypseTheme.textMuted)

                    if let fileSize = message.audioFileSize {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.textMuted)

                        Text(String(format: "%.1fMB", fileSize))
                            .font(.caption2)
                            .foregroundColor(isOwnMessage ? .white.opacity(0.8) : ApocalypseTheme.textMuted)
                    }
                }
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isOwnMessage ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // Day 36: 时长文本
    private var durationText: String {
        guard let duration = message.audioDuration else { return "0:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Day 36: 切换音频播放
    private func toggleAudioPlayback() {
        guard let urlString = message.audioURL,
              let url = URL(string: urlString) else {
            return
        }

        if audioManager.isPlaying && audioManager.currentPlayingURL == url {
            // 停止播放
            audioManager.stopPlayback()
        } else {
            // 先停止其他播放
            if audioManager.isPlaying {
                audioManager.stopPlayback()
            }

            // 下载并播放音频
            Task {
                do {
                    // 创建临时文件
                    let tempDir = FileManager.default.temporaryDirectory
                    let tempURL = tempDir.appendingPathComponent("voice_\(UUID().uuidString).m4a")

                    // 下载音频
                    let data = try Data(contentsOf: url)
                    try data.write(to: tempURL)

                    // 播放
                    let success = audioManager.playAudio(url: tempURL)
                    if !success {
                        await MainActor.run {
                            LogError("❌ [音频] 播放失败")
                        }
                    }
                } catch {
                    LogError("❌ [音频] 下载失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
