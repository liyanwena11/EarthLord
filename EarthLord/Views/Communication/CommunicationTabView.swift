//
//  CommunicationTabView.swift
//  EarthLord
//
//  通讯中心 - 对讲机、频道、呼叫、设备管理
//

import SwiftUI
import Auth

struct CommunicationTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared
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
        .onAppear {
            if let userId = authManager.currentUser?.id {
                Task {
                    await communicationManager.fetchUserDevices()
                    if communicationManager.currentDevice == nil {
                        LogDebug("📡 [通讯] 没有当前设备，自动创建对讲机...")
                        await communicationManager.ensureDefaultDevice()
                        await communicationManager.fetchUserDevices()
                    }

                    await communicationManager.ensureOfficialChannelSubscribed(userId: userId)
                }
            }
        }
    }

    // MARK: - Device Status Bar

    private var deviceStatusBar: some View {
        HStack(spacing: 12) {
            // ✅ 修复：显示当前设备，而不是固定的 walkieTalkie
            let currentType = communicationManager.currentDevice?.deviceType ?? .walkieTalkie

            Image(systemName: currentType.iconName)
                .foregroundColor(ApocalypseTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(currentType.displayName)
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Text(currentType.rangeText)
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
            MessageCenterView()
                .environmentObject(authManager)
        case .channels:
            ChannelCenterView()
                .environmentObject(authManager)
        case .call:
            PTTCallView()
                .environmentObject(authManager)
        case .devices:
            DeviceManagementView()
                .environmentObject(authManager)
        }
    }
}
