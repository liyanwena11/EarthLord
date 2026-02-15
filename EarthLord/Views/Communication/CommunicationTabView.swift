//
//  CommunicationTabView.swift
//  EarthLord
//
//  通讯中心 - 对讲机、频道、呼叫、设备管理
//

import SwiftUI

struct CommunicationTabView: View {
    @State private var selectedSection: CommunicationSection = .channels

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部设备状态栏
                    deviceStatusBar

                    // 导航选择器
                    sectionPicker

                    // 内容区域
                    contentArea
                }
            }
            .navigationTitle("通讯中心")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Device Status Bar

    private var deviceStatusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: DeviceType.walkieTalkie.iconName)
                .foregroundColor(ApocalypseTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(DeviceType.walkieTalkie.displayName)
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Text(DeviceType.walkieTalkie.rangeText)
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            Spacer()

            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("在线")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(ApocalypseTheme.cardBackground)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(CommunicationSection.allCases, id: \.self) { section in
                Button(action: { selectedSection = section }) {
                    VStack(spacing: 4) {
                        Image(systemName: section.iconName)
                            .font(.system(size: 16))
                        Text(section.displayName)
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(selectedSection == section ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                    .background(
                        selectedSection == section
                            ? ApocalypseTheme.primary.opacity(0.1)
                            : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .fill(selectedSection == section ? ApocalypseTheme.primary : Color.clear)
                            .frame(height: 2),
                        alignment: .bottom
                    )
                }
            }
        }
        .background(ApocalypseTheme.cardBackground)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch selectedSection {
        case .messages:
            MessageCenterPlaceholderView()
        case .channels:
            ChannelListPlaceholderView()
        case .call:
            PTTCallPlaceholderView()
        case .devices:
            DeviceManagementPlaceholderView()
        }
    }
}

// MARK: - Placeholder Views

struct MessageCenterPlaceholderView: View {
    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ApocalypseTheme.primary.opacity(0.6))
                Text("消息中心")
                    .font(.title2.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Text("暂无新消息\n订阅频道后，消息将显示在这里")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }
}

struct ChannelListPlaceholderView: View {
    let sampleChannels = [
        ("官方公告", "megaphone.fill", "官方频道", Color.orange),
        ("末日求生", "globe", "公开频道", Color.blue),
        ("本地玩家", "walkie.talkie.radio", "对讲频道", Color.green)
    ]

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    // 官方频道
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已订阅频道")
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.textSecondary)
                            .padding(.horizontal)

                        ForEach(sampleChannels, id: \.0) { name, icon, type, color in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(color.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: icon)
                                        .foregroundColor(color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.subheadline.bold())
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                    Text(type)
                                        .font(.caption)
                                        .foregroundColor(ApocalypseTheme.textMuted)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                            }
                            .padding()
                            .background(ApocalypseTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)

                    // 创建频道按钮
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("创建新频道")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ApocalypseTheme.primary.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ApocalypseTheme.primary.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct PTTCallPlaceholderView: View {
    @State private var isPressing = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()

                // PTT 按钮
                ZStack {
                    Circle()
                        .fill(isPressing ? ApocalypseTheme.danger : ApocalypseTheme.primary)
                        .frame(width: 140, height: 140)
                        .shadow(color: (isPressing ? ApocalypseTheme.danger : ApocalypseTheme.primary).opacity(0.5), radius: 20)
                        .scaleEffect(isPressing ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2), value: isPressing)

                    VStack(spacing: 8) {
                        Image(systemName: isPressing ? "mic.fill" : "mic")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text(isPressing ? "讲话中..." : "按住通话")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressing = true }
                        .onEnded { _ in isPressing = false }
                )

                VStack(spacing: 8) {
                    Text("对讲机模式")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    Text("范围: \(DeviceType.walkieTalkie.rangeText)")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()
            }
        }
    }
}

struct DeviceManagementPlaceholderView: View {
    let devices: [(DeviceType, Bool)] = [
        (.radio, true),
        (.walkieTalkie, true),
        (.campRadio, false),
        (.satellite, false)
    ]

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(devices, id: \.0) { device, isUnlocked in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(isUnlocked ? ApocalypseTheme.primary.opacity(0.15) : ApocalypseTheme.textMuted.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: device.iconName)
                                    .foregroundColor(isUnlocked ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(isUnlocked ? ApocalypseTheme.textPrimary : ApocalypseTheme.textMuted)
                                Text(device.description)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if isUnlocked {
                                Text("已解锁")
                                    .font(.caption2.bold())
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(6)
                            } else {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(ApocalypseTheme.textMuted)
                            }
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
    }
}
