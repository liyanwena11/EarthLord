//
//  SupabaseTestView.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/30.
//

import SwiftUI
import Supabase

// MARK: - Supabase Client 配置
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://lkekxzssfrspkyxtqysx.supabase.co")!,
    supabaseKey: "sb_publishable_8Gg8z5XRTOkupYVm6MbACg_Lc9CXU4I"
)

// MARK: - Supabase 测试视图
struct SupabaseTestView: View {
    // MARK: - State Properties

    /// 连接状态：nil=未测试, true=成功, false=失败
    @State private var connectionStatus: Bool? = nil

    /// 详细日志信息
    @State private var logMessage: String = "点击按钮开始测试连接..."

    /// 是否正在测试
    @State private var isTesting: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    // 状态图标
                    statusIcon

                    // 日志信息区域
                    logArea

                    // 测试按钮
                    testButton

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Supabase 连接测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - View Components

    /// 状态图标
    private var statusIcon: some View {
        Group {
            if let status = connectionStatus {
                Image(systemName: status ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(status ? ApocalypseTheme.success : ApocalypseTheme.danger)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "network")
                    .font(.system(size: 80))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: connectionStatus)
    }

    /// 日志信息区域
    private var logArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("测试日志")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            ScrollView {
                Text(logMessage)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
            }
            .frame(height: 200)
        }
    }

    /// 测试按钮
    private var testButton: some View {
        Button(action: testConnection) {
            HStack {
                if isTesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(isTesting ? "测试中..." : "测试连接")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isTesting ? ApocalypseTheme.textMuted : ApocalypseTheme.primary)
            .cornerRadius(12)
        }
        .disabled(isTesting)
    }

    // MARK: - Test Logic

    /// 测试 Supabase 连接
    private func testConnection() {
        // 重置状态
        connectionStatus = nil
        isTesting = true
        logMessage = "正在测试连接...\n"

        Task {
            do {
                // 记录开始时间
                let startTime = Date()
                logMessage += "[\(formatTime(startTime))] 发送请求到 Supabase...\n"

                // 故意查询一个不存在的表来测试连接
                let _: [EmptyResponse] = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()
                    .value

                // 如果执行到这里，说明表存在（不应该发生）
                await MainActor.run {
                    connectionStatus = true
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    logMessage += "[\(formatTime(endTime))] ⚠️ 意外：表存在\n"
                    logMessage += "响应时间: \(String(format: "%.2f", duration))秒\n"
                    isTesting = false
                }

            } catch {
                // 分析错误类型
                await MainActor.run {
                    analyzeError(error, startTime: Date())
                }
            }
        }
    }

    /// 分析错误并更新状态
    private func analyzeError(_ error: Error, startTime: Date) {
        let errorString = error.localizedDescription
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        logMessage += "[\(formatTime(endTime))] 收到响应\n"
        logMessage += "响应时间: \(String(format: "%.2f", duration))秒\n"
        logMessage += "错误信息: \(errorString)\n\n"

        // 判断错误类型
        if errorString.contains("PGRST") ||
           errorString.contains("Could not find the table") ||
           errorString.contains("relation") && errorString.contains("does not exist") {
            // 这些错误说明连接成功，只是表不存在
            connectionStatus = true
            logMessage += "✅ 连接成功（服务器已响应）\n"
            logMessage += "✓ Supabase URL: 正确\n"
            logMessage += "✓ API Key: 有效\n"
            logMessage += "✓ 网络连接: 正常\n"
            logMessage += "\n说明：收到了 PostgreSQL 错误响应，\n这证明已成功连接到 Supabase 数据库。"

        } else if errorString.contains("hostname") ||
                  errorString.contains("URL") ||
                  errorString.contains("NSURLErrorDomain") {
            // URL 错误或网络问题
            connectionStatus = false
            logMessage += "❌ 连接失败：URL 错误或无网络\n\n"
            logMessage += "可能原因：\n"
            logMessage += "• 检查网络连接\n"
            logMessage += "• 确认 Supabase URL 是否正确\n"
            logMessage += "• 检查防火墙设置\n"

        } else {
            // 其他未知错误
            connectionStatus = false
            logMessage += "❌ 连接失败：未知错误\n\n"
            logMessage += "详细错误：\n\(errorString)\n"
        }

        isTesting = false
    }

    // MARK: - Helper Methods

    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Empty Response Model
/// 空响应模型（用于测试）
struct EmptyResponse: Codable {
    // 空结构体，仅用于类型推断
}

// MARK: - Preview
#Preview {
    SupabaseTestView()
}
