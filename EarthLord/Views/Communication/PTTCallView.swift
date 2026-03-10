//
//  PTTCallView.swift
//  EarthLord
//
//  PTT 通话界面 - 选择频道 + 输入内容 + 长按发送
//

import SwiftUI
import Auth
import CoreLocation
import AVFoundation

struct PTTCallView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
    @StateObject private var audioManager = AudioRecordManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChannelId: UUID?
    @State private var messageContent: String = ""
    @State private var isPressingPTT: Bool = false
    @State private var showingSuccess: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorText: String = ""

    // Day 36: 语音录制状态
    @State private var isVoiceMode: Bool = true  // 默认语音模式
    @State private var recordedAudioURL: URL?
    @State private var recordedAudioDuration: TimeInterval = 0
    @State private var showingPermissionAlert: Bool = false

    private var sendableChannels: [SubscribedChannel] {
        communicationManager.subscribedChannels.filter {
            !communicationManager.isOfficialChannel($0.channel.id)
        }
    }

    private var selectedChannel: CommunicationChannel? {
        sendableChannels.first { $0.channel.id == selectedChannelId }?.channel
    }

    private var sendableDevices: [CommunicationDevice] {
        communicationManager.devices.filter { $0.isUnlocked && $0.deviceType.canSend }
    }

    private var canSend: Bool {
        let deviceCanSend = communicationManager.currentDevice?.deviceType.canSend ?? false
        let hasChannel = selectedChannel != nil

        // 语音模式：不需要文字内容
        // 文字模式：需要文字内容
        let hasContent = isVoiceMode ? true : !messageContent.trimmingCharacters(in: .whitespaces).isEmpty

        if !deviceCanSend || !hasChannel || !hasContent {
            LogDebug("⚠️ [PTT] canSend 检查失败:")
            LogDebug("  - 设备可发送: \(deviceCanSend)")
            LogDebug("  - 已选频道: \(hasChannel)")
            LogDebug("  - 模式: \(isVoiceMode ? "语音" : "文字")")
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

                deviceSwitcherBar

                channelTabBar

                Spacer()

                messageInputArea

                pttButton

                Spacer()

                Text(isVoiceMode
                    ? (canSend ? "长按按钮开始录音，松开发送" : "请先选择一个频道")
                    : "长按按钮发送呼叫，松开结束")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            Task { await initializePTTData() }
            // Day 36: 检查麦克风权限
            if isVoiceMode && !audioManager.hasMicrophonePermission {
                Task {
                    let granted = await audioManager.requestMicrophonePermission()
                    if !granted {
                        await MainActor.run {
                            showingPermissionAlert = true
                        }
                    }
                }
            }
        }
        .overlay(successToast)
        .onTapGesture {
            // ✅ 点击空白区域关闭键盘
            hideKeyboard()
        }
        .alert("提示", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorText)
        }
        .alert("需要麦克风权限", isPresented: $showingPermissionAlert) {
            Button("去设置", action: openSettings)
            Button("取消", role: .cancel) {
                isVoiceMode = false  // 切换到文字模式
            }
        } message: {
            Text("语音消息需要访问麦克风。请在设置中允许访问。")
        }
    }

    // MARK: - 辅助方法

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - 辅助方法

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func initializePTTData() async {
        await communicationManager.fetchUserDevices()

        if communicationManager.currentDevice == nil {
            await communicationManager.ensureDefaultDevice()
            await communicationManager.fetchUserDevices()
        }

        if communicationManager.currentDevice?.deviceType.canSend != true {
            do {
                if let fallbackDevice = communicationManager.devices.first(where: { $0.isUnlocked && $0.deviceType.canSend }) {
                    try await communicationManager.setCurrentDevice(deviceId: fallbackDevice.id)
                } else {
                    try await communicationManager.unlockDevice(deviceType: .walkieTalkie)
                    guard let walkie = communicationManager.devices.first(where: { $0.deviceType == .walkieTalkie }) else {
                        throw CommunicationError.operationFailed("对讲机初始化失败")
                    }
                    try await communicationManager.setCurrentDevice(deviceId: walkie.id)
                }
            } catch {
                await MainActor.run {
                    errorText = "初始化发送设备失败：\(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }

        if let userId = authManager.currentUser?.id {
            await communicationManager.loadSubscribedChannels(userId: userId)
        }

        await MainActor.run {
            if let selected = selectedChannelId,
               !sendableChannels.contains(where: { $0.channel.id == selected }) {
                selectedChannelId = nil
            }
            if selectedChannelId == nil {
                selectedChannelId = sendableChannels.first?.channel.id
            }
        }
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

    // MARK: - 呼叫设备切换

    private var deviceSwitcherBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sendableDevices) { device in
                    let isCurrent = communicationManager.currentDevice?.id == device.id

                    Button(action: {
                        guard !isCurrent else { return }
                        Task {
                            do {
                                try await communicationManager.setCurrentDevice(deviceId: device.id)
                            } catch {
                                await MainActor.run {
                                    errorText = "切换设备失败：\(error.localizedDescription)"
                                    showErrorAlert = true
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: device.deviceType.iconName)
                                .font(.caption)
                            Text(device.deviceType.displayName)
                                .font(.caption.bold())
                            Text(device.deviceType.rangeText)
                                .font(.caption2)
                                .foregroundColor(isCurrent ? .white.opacity(0.85) : ApocalypseTheme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(isCurrent ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .foregroundColor(isCurrent ? .white : ApocalypseTheme.textPrimary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 2)
        }
    }

    // MARK: - 频道切换标签栏

    private var channelTabBar: some View {
        Group {
            if sendableChannels.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("暂无可呼叫频道，请先在“频道”页订阅非官方频道")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            } else {
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
        }
    }

    // MARK: - 消息输入区

    private var messageInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("呼叫内容")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // Day 36: 模式切换按钮
                HStack(spacing: 4) {
                    Button(action: { isVoiceMode = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                            Text("语音")
                        }
                        .font(.caption)
                        .foregroundColor(isVoiceMode ? .white : ApocalypseTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isVoiceMode ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }

                    Button(action: { isVoiceMode = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                            Text("文字")
                        }
                        .font(.caption)
                        .foregroundColor(!isVoiceMode ? .white : ApocalypseTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(!isVoiceMode ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }

            // 没有可用频道的提示
            if sendableChannels.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("没有可发送消息的频道")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(12)

                    Text("请先在「通讯」标签页订阅非官方频道")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if isVoiceMode {
                // 语音模式提示
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .foregroundColor(ApocalypseTheme.primary)
                        Text("长按下方按钮开始录音，松开发送")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)

                        Spacer()

                        if audioManager.isRecording {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(audioManager.recordingDuration.truncatingRemainder(dividingBy: 1) == 0 ? 1 : 0.5)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: audioManager.recordingDuration)
                                Text(audioManager.formatDuration(audioManager.recordingDuration))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(12)
                }
            } else {
                // 文字模式输入框
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
                        colors: isPressingPTT || audioManager.isRecording
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
                    color: isPressingPTT || audioManager.isRecording
                        ? Color.gray.opacity(0.4)
                        : ApocalypseTheme.primary.opacity(0.4),
                    radius: 12
                )
                .scaleEffect(isPressingPTT || audioManager.isRecording ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressingPTT)
                .animation(.easeInOut(duration: 0.1), value: audioManager.isRecording)

            VStack(spacing: 8) {
                Image(systemName: audioManager.isRecording ? "waveform" : (isVoiceMode ? "mic.fill" : "paperplane.fill"))
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    guard canSend else {
                        if !isPressingPTT {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                        return
                    }
                    guard !isPressingPTT else { return }
                    isPressingPTT = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    // Day 36: 语音模式开始录音
                    if isVoiceMode {
                        startRecording()
                    } else {
                        LogDebug("📡 [PTT] 准备发送文字...")
                    }
                }
                .onEnded { _ in
                    guard isPressingPTT else { return }
                    isPressingPTT = false

                    // Day 36: 语音模式停止录音并发送
                    if isVoiceMode {
                        stopRecordingAndSend()
                    } else {
                        LogDebug("✅ [PTT] 发送完成")
                        sendPTTMessage()
                    }
                }
        )
    }

    // Day 36: 按钮文字
    private var buttonText: String {
        if audioManager.isRecording {
            return "录音中..."
        } else if isPressingPTT {
            return "发送中..."
        } else {
            return isVoiceMode ? "按住说话" : "按住发送"
        }
    }

    // Day 36: 开始录音
    private func startRecording() {
        guard audioManager.hasMicrophonePermission else {
            showingPermissionAlert = true
            isPressingPTT = false
            return
        }

        let success = audioManager.startRecording()
        if !success {
            errorText = "录音启动失败"
            showErrorAlert = true
            isPressingPTT = false
        } else {
            LogDebug("🎤 [PTT] 开始录音...")
        }
    }

    // Day 36: 停止录音并发送
    private func stopRecordingAndSend() {
        guard let result = audioManager.stopRecording() else {
            errorText = "录音失败"
            showErrorAlert = true
            return
        }

        recordedAudioURL = result.url
        recordedAudioDuration = result.duration

        LogDebug("✅ [PTT] 录音完成: \(audioManager.formatDuration(result.duration))")

        // 自动发送语音消息
        sendVoiceMessage()
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

    // Day 36: 发送语音消息
    private func sendVoiceMessage() {
        guard let channelId = selectedChannelId,
              let audioURL = recordedAudioURL else {
            errorText = "语音录制���败"
            showErrorAlert = true
            return
        }

        let deviceType = communicationManager.currentDevice?.deviceType.rawValue

        Task {
            let success = await communicationManager.sendVoiceMessage(
                channelId: channelId,
                audioURL: audioURL,
                audioDuration: recordedAudioDuration,
                latitude: nil,
                longitude: nil,
                deviceType: deviceType
            )

            if success {
                await MainActor.run {
                    recordedAudioURL = nil
                    recordedAudioDuration = 0
                    withAnimation { showingSuccess = true }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showingSuccess = false }
                    }
                }
            } else {
                await MainActor.run {
                    errorText = communicationManager.errorMessage ?? "发送失败，请稍后重试"
                    showErrorAlert = true
                }
            }
        }
    }

    private func sendPTTMessage() {
        guard let channelId = selectedChannelId,
              !messageContent.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let content = messageContent
        let deviceType = communicationManager.currentDevice?.deviceType.rawValue

        Task {
            let success = await communicationManager.sendChannelMessage(
                channelId: channelId,
                content: content,
                latitude: nil, // Day 36: PTT 不依赖实时定位
                longitude: nil,
                deviceType: deviceType
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
            } else {
                await MainActor.run {
                    errorText = communicationManager.errorMessage ?? "PTT 发送失败，请稍后重试"
                    showErrorAlert = true
                }
            }
        }
    }
}
