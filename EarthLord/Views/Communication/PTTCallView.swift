//
//  PTTCallView.swift
//  EarthLord
//
//  PTT 通话界面 - 选择频道 + 输入内容 + 长按发送
//

import SwiftUI
import Auth
import CoreLocation

struct PTTCallView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChannelId: UUID?
    @State private var messageContent: String = ""
    @State private var isPressingPTT: Bool = false
    @State private var showingSuccess: Bool = false

    private var sendableChannels: [SubscribedChannel] {
        communicationManager.subscribedChannels.filter {
            !communicationManager.isOfficialChannel($0.channel.id)
        }
    }

    private var selectedChannel: CommunicationChannel? {
        sendableChannels.first { $0.channel.id == selectedChannelId }?.channel
    }

    private var canSend: Bool {
        let deviceCanSend = communicationManager.currentDevice?.deviceType.canSend ?? false
        let hasChannel = selectedChannel != nil
        let hasContent = !messageContent.trimmingCharacters(in: .whitespaces).isEmpty

        if !deviceCanSend || !hasChannel || !hasContent {
            LogDebug("⚠️ [PTT] canSend 检查失败:")
            LogDebug("  - 设备可发送: \(deviceCanSend)")
            LogDebug("  - 已选频道: \(hasChannel)")
            LogDebug("  - 有内容: \(hasContent)")
        }

        return deviceCanSend && hasChannel && hasContent
    }

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ✅ 添加返回按钮
                backButtonBar

                headerView

                if let channel = selectedChannel {
                    frequencyCard(channel: channel)
                }

                channelTabBar

                Spacer()

                messageInputArea

                pttButton

                Spacer()

                Text("长按按钮发送呼叫，松开结束")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            if selectedChannelId == nil {
                selectedChannelId = sendableChannels.first?.channel.id
            }
        }
        .overlay(successToast)
        .onTapGesture {
            // ✅ 点击空白区域关闭键盘
            hideKeyboard()
        }
    }

    // MARK: - 辅助方法

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - 返回按钮栏

    private var backButtonBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .foregroundColor(ApocalypseTheme.primary)
                .font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Text("PTT 呼叫")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            Spacer()
            if let deviceType = communicationManager.currentDevice?.deviceType {
                HStack(spacing: 4) {
                    Image(systemName: deviceType.iconName)
                    Text(deviceType.displayName)
                        .font(.caption)
                }
                .foregroundColor(ApocalypseTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ApocalypseTheme.primary.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - 频率卡片

    private func frequencyCard(channel: CommunicationChannel) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(ApocalypseTheme.primary)
                Spacer()
                HStack(spacing: 4) {
                    Text(channel.channelType.rangeText)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
            }

            Text(channel.channelCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(channel.name)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - 频道切换标签栏

    private var channelTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sendableChannels) { sc in
                    let isSelected = sc.channel.id == selectedChannelId
                    Button(action: { selectedChannelId = sc.channel.id }) {
                        HStack(spacing: 4) {
                            Text(sc.channel.channelCode)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(sc.channel.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? .white : ApocalypseTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - 消息输入区

    private var messageInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("呼叫内容")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ApocalypseTheme.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $messageContent)
                    .frame(height: 80)
                    .padding(8)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(12)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                if messageContent.isEmpty {
                    Text("输入呼叫内容，按住 PTT 按钮发送")
                        .foregroundColor(ApocalypseTheme.textMuted)
                        .font(.subheadline)
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - PTT 按钮

    private var pttButton: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isPressingPTT
                            ? [Color.gray, Color.gray.opacity(0.7)]
                            : (canSend
                                ? [ApocalypseTheme.primary, ApocalypseTheme.primary.opacity(0.7)]
                                : [Color.gray, Color.gray.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(
                    color: isPressingPTT
                        ? Color.gray.opacity(0.4)
                        : ApocalypseTheme.primary.opacity(0.4),
                    radius: 12
                )
                .scaleEffect(isPressingPTT ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressingPTT)

            VStack(spacing: 8) {
                Image(systemName: isPressingPTT ? "waveform" : "mic.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                Text(isPressingPTT ? "发送中..." : "按住发送")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: 0)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { phase in
                    switch phase {
                    case .first(true):
                        // 长按开始
                        guard canSend else {
                            LogWarning("⚠️ [PTT] 无法发送：canSend=\(canSend)")
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            return
                        }
                        guard !isPressingPTT else { return }

                        isPressingPTT = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        LogDebug("📡 [PTT] 开始发送...")

                    case .second(true, _):
                        // 继续按住
                        break

                    default:
                        break
                    }
                }
                .onEnded { phase in
                    guard isPressingPTT else { return }
                    isPressingPTT = false

                    if case .second(true, _) = phase {
                        LogDebug("✅ [PTT] 发送完成")
                        sendPTTMessage()
                    } else {
                        LogDebug("❌ [PTT] 发送取消")
                    }
                }
        )
    }

    // MARK: - 成功提示

    private var successToast: some View {
        Group {
            if showingSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("消息已发送")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(20)
                    .shadow(radius: 8)
                    Spacer().frame(height: 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showingSuccess)
    }

    // MARK: - 发送

    private func sendPTTMessage() {
        guard let channelId = selectedChannelId,
              !messageContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let content = messageContent
        let location = LocationManager.shared.userLocation

        Task {
            let success = await communicationManager.sendChannelMessage(
                channelId: channelId,
                content: content,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            )
            if success {
                await MainActor.run {
                    messageContent = ""
                    withAnimation { showingSuccess = true }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showingSuccess = false }
                    }
                }
            }
        }
    }
}
