#if DEBUG
import SwiftUI

// MARK: - 调试测试视图

#if DEBUG

struct DebugTestView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var mailbox = MailboxManager.shared
    @StateObject private var engine = EarthLordEngine.shared

    @State private var testResults: [String] = []
    @State private var isRunningTests = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 标题
                        VStack(spacing: 8) {
                            Text("🔧 调试测试面板")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("快速诊断所有功能")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // 认证状态
                        testCard(title: "认证状态", icon: "person.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                testResult("已登录", authManager.isAuthenticated)
                                testResult("Session 已检查", authManager.isSessionChecked)
                                if let user = authManager.currentUser {
                                    testResult("用户ID", String(user.id.uuidString.prefix(8)) + "...", isDetail: true)
                                    testResult("邮箱", user.email ?? "无", isDetail: true)
                                }
                            }
                        }

                        // 商城状态
                        testCard(title: "商城状态", icon: "cart.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                testResult("产品数量", !store.products.isEmpty, detail: "\(store.products.count) 个")
                                if store.products.isEmpty {
                                    Text("⚠️ 未加载到产品，请检查：\n1. App Store Connect 配置\n2. 沙盒账号登录\n3. Product ID 匹配")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.top, 4)
                                }
                            }
                        }

                        // 邮箱状态
                        testCard(title: "邮箱状态", icon: "tray.full.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                testResult("待领取物资", mailbox.hasPendingItems, detail: "\(mailbox.pendingCount) 件")
                            }
                        }

                        // 领地状态
                        testCard(title: "领地状态", icon: "map.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                testResult("正在圈地", engine.isTracking)
                                testResult("采样点", engine.pathPoints.count > 0, detail: "\(engine.pathPoints.count) 个")
                                testResult("已占领领地", !engine.claimedTerritories.isEmpty, detail: "\(engine.claimedTerritories.count) 个")
                            }
                        }

                        // GPS 状态
                        testCard(title: "GPS 状态", icon: "location.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                if let location = engine.userLocation {
                                    testResult("位置获取", true)
                                    Text("纬度: \(String(format: "%.5f", location.coordinate.latitude))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("经度: \(String(format: "%.5f", location.coordinate.longitude))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("精度: \(String(format: "%.1f", location.horizontalAccuracy))m")
                                        .font(.caption2)
                                        .foregroundColor(location.horizontalAccuracy < 50 ? .green : .orange)
                                } else {
                                    testResult("位置获取", false)
                                }
                            }
                        }

                        // 测试按钮
                        VStack(spacing: 12) {
                            testButton("🔄 刷新商城", color: .blue) {
                                await store.loadProducts()
                            }

                            testButton("📬 刷新邮箱", color: .green) {
                                await mailbox.loadPendingItems()
                            }

                            testButton("🗺️ 刷新领地", color: .orange) {
                                await testLoadTerritories()
                            }

                            testButton("🧪 运行完整诊断", color: .purple) {
                                await runFullDiagnostic()
                            }

                            testButton("🎯 测试新手引导", color: .blue) {
                                // 重置本地缓存，强制显示新手引导
                                UserDefaults.standard.set(false, forKey: "has_seen_onboarding")
                                UserDefaults.standard.set(true, forKey: "debug_force_show_onboarding")
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - 测试卡片

    private func testCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func testResult(_ label: String, _ passed: Bool, detail: String? = nil, isDetail: Bool = false) -> some View {
        HStack {
            if !isDetail {
                Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(passed ? .green : .red)
                    .font(.caption)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            if let detail = detail {
                Spacer()
                Text(detail)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
    }

    // 用于显示详细信息的版本（不需要 Bool 参数）
    private func testResult(_ label: String, _ value: String, isDetail: Bool) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }

    private func testButton(_ title: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button(action: {
            Task {
                await action()
            }
        }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(10)
        }
    }

    // MARK: - 测试方法

    private func testLoadTerritories() async {
        do {
            let territories = try await TerritoryManager.shared.loadAllTerritories()
            LogInfo("✅ [测试] 领地加载成功，共 \(territories.count) 个")
        } catch {
            LogError("❌ [测试] 领地加载失败: \(error)")
        }
    }

    private func runFullDiagnostic() async {
        isRunningTests = true
        testResults.removeAll()

        // 测试1: 认证
        if authManager.isAuthenticated {
            testResults.append("✅ 认证: 已登录")
        } else {
            testResults.append("❌ 认证: 未登录")
        }

        // 测试2: 商城
        if store.products.isEmpty {
            testResults.append("❌ 商城: 无产品")
        } else {
            testResults.append("✅ 商城: \(store.products.count) 个产品")
        }

        // 测试3: GPS
        if engine.userLocation != nil {
            testResults.append("✅ GPS: 位置正常")
        } else {
            testResults.append("❌ GPS: 无位置")
        }

        // 测试4: 领地数据库
        do {
            let territories = try await TerritoryManager.shared.loadAllTerritories()
            testResults.append("✅ 数据库: 领地查询成功 (\(territories.count) 个)")
        } catch {
            testResults.append("❌ 数据库: 领地查询失败 - \(error.localizedDescription)")
        }

        isRunningTests = false

        // 打印结果
        LogDebug("\n" + String(repeating: "=", count: 50))
        LogDebug("🧪 完整诊断结果")
        LogDebug(String(repeating: "=", count: 50))
        for result in testResults {
            LogDebug(result)
        }
        LogDebug(String(repeating: "=", count: 50) + "\n")
    }
}

#Preview {
    DebugTestView()
}

#endif


#endif
