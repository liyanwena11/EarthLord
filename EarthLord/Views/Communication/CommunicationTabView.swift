//
//  CommunicationTabView.swift
//  EarthLord
//
//  通讯中心 - 对讲机、频道、呼叫、设备管理
//

import SwiftUI

struct CommunicationTabView: View {
    @State private var selectedSection: CommunicationSection = .devices

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
            ChannelCenterView()
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
    @StateObject private var communicationManager = CommunicationManager.shared
    @State private var isLoading = true

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    // 设备管理标题
                    VStack(alignment: .leading, spacing: 4) {
                        Text("设备管理")
                            .font(.headline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                        Text("选择通讯设备，不同设备有不同覆盖范围")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // 收音机（选中状态）
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.primary.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: DeviceType.radio.iconName)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(DeviceType.radio.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textPrimary)
                                Text("覆盖范围：无限制（仅接收）")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                Text("仅接收")
                                    .font(.caption2)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ApocalypseTheme.primary, lineWidth: 2)
                        )
                        .padding(.horizontal)

                        // 所有设备标题
                        VStack(alignment: .leading, spacing: 4) {
                            Text("所有设备")
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // 收音机
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.primary.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: DeviceType.radio.iconName)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(DeviceType.radio.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textPrimary)
                                Text(DeviceType.radio.description)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text("已解锁")
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // 对讲机
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.primary.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: DeviceType.walkieTalkie.iconName)
                                    .foregroundColor(ApocalypseTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(DeviceType.walkieTalkie.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textPrimary)
                                Text(DeviceType.walkieTalkie.description)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text("切换")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // 营地电台
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.textMuted.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: DeviceType.campRadio.iconName)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(DeviceType.campRadio.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                Text(DeviceType.campRadio.description)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "lock.fill")
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // 卫星通讯
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ApocalypseTheme.textMuted.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: DeviceType.satellite.iconName)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(DeviceType.satellite.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                Text(DeviceType.satellite.description)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "lock.fill")
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            Task {
                await communicationManager.fetchUserDevices()
                await MainActor.run { isLoading = false }
            }
        }
    }
}
