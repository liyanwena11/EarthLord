//
//  DeviceManagementView.swift
//  EarthLord
//
//  设备管理 - 选择通讯设备 + 呼号设置
//

import SwiftUI
import Auth

struct DeviceManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var communicationManager = CommunicationManager.shared

    @State private var isLoading = true
    @State private var showingCallsignSettings = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // 标题
                    VStack(alignment: .leading, spacing: 4) {
                        Text("设备管理")
                            .font(.headline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                        Text("选择通讯设备，不同设备有不同覆盖范围")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        deviceListSection
                    }

                    Divider()
                        .background(ApocalypseTheme.textMuted.opacity(0.3))
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    callsignEntryButton
                        .padding(.horizontal)
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
        .sheet(isPresented: $showingCallsignSettings) {
            CallsignSettingsSheet()
                .environmentObject(authManager)
        }
    }

    // MARK: - 设备列表

    private var deviceListSection: some View {
        VStack(spacing: 12) {
            // 当前设备
            if let current = communicationManager.currentDevice {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前设备")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .padding(.horizontal)
                }

                deviceRow(type: current.deviceType, isSelected: true, isUnlocked: true, isCurrent: true)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("所有设备")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            ForEach(DeviceType.allCases, id: \.self) { type in
                let device = communicationManager.devices.first(where: { $0.deviceType == type })
                let isUnlocked = device?.isUnlocked ?? (type == .radio || type == .walkieTalkie)
                let isCurrent = communicationManager.currentDevice?.deviceType == type

                Button(action: {
                    if isUnlocked && !isCurrent, let d = device {
                        Task { try? await communicationManager.setCurrentDevice(deviceId: d.id) }
                    }
                }) {
                    deviceRow(type: type, isSelected: isCurrent, isUnlocked: isUnlocked, isCurrent: isCurrent)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isUnlocked || isCurrent)
                .padding(.horizontal)
            }
        }
    }

    private func deviceRow(type: DeviceType, isSelected: Bool, isUnlocked: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? ApocalypseTheme.primary.opacity(0.15) : ApocalypseTheme.textMuted.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: type.iconName)
                    .foregroundColor(isUnlocked ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(isUnlocked ? ApocalypseTheme.textPrimary : ApocalypseTheme.textMuted)
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(ApocalypseTheme.textMuted)
            } else if isCurrent {
                Text("使用中")
                    .font(.caption2.bold())
                    .foregroundColor(ApocalypseTheme.primary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(ApocalypseTheme.primary.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Text("切换")
                    .font(.caption2.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? ApocalypseTheme.primary : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - 呼号设置入口

    private var callsignEntryButton: some View {
        Button(action: { showingCallsignSettings = true }) {
            HStack {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 20))
                    .foregroundColor(ApocalypseTheme.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("呼号设置")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    Text("设置您的电台身份标识")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            .padding(16)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
