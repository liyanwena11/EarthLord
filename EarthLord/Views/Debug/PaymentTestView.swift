//
//  PaymentTestView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-28.
//  支付测试界面 - 沙盒环境测试末日通行证和物资商城
//

import SwiftUI
import StoreKit

// MARK: - Payment Test View

/// 支付测试主视图 - 用于沙盒环境测试末日通行证和物资商城
struct PaymentTestView: View {
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var tierManager: TierManager

    @State private var selectedTab: PaymentTestTab = .subscription
    @State private var testLogs: [TestLog] = []
    @State private var showSandboxSetupAlert = false

    /// 当前环境（从 IAPManager 获取）
    private var currentEnvironment: PaymentEnvironment {
        iapManager.isSandboxEnvironment ? .sandbox : .production
    }

    enum PaymentTestTab: String, CaseIterable {
        case subscription = "末日通行证"
        case store = "物资商城"
        case mailbox = "邮箱测试"
    }

    enum PaymentEnvironment: String, CaseIterable {
        case sandbox = "沙盒"
        case production = "生产"

        var displayName: String {
            switch self {
            case .sandbox: return "沙盒环境"
            case .production: return "生产环境"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 环境指示器
                    environmentIndicator

                    // 标签页选择
                    tabPicker

                    // 内容区域
                    ScrollView {
                        switch selectedTab {
                        case .subscription:
                            subscriptionTestView
                        case .store:
                            storeTestView
                        case .mailbox:
                            mailboxTestView
                        }
                    }

                    Spacer()

                    // 测试日志
                    testLogsSection
                }
            }
            .navigationTitle("支付测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSandboxSetupAlert = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .alert("沙盒环境设置", isPresented: $showSandboxSetupAlert) {
                sandboxSetupAlert
            }
        }
    }

    // MARK: - Environment Indicator

    private var environmentIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(currentEnvironment == .sandbox ? .blue : .red)
                    .frame(width: 8, height: 8)

                Text(iapManager.environmentName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("StoreKit \(storeKitVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 显示产品加载状态
            HStack {
                Text("已加载产品: \(iapManager.availableProducts.count)")
                    .font(.caption2)
                    .foregroundColor(iapManager.availableProducts.isEmpty ? .orange : .green)

                Spacer()

                if iapManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.6)
                }
            }

            // 本地测试提示
            #if DEBUG
            if iapManager.isLocalStoreKitTesting {
                Text("🧪 本地 StoreKit 测试模式")
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else if iapManager.availableProducts.isEmpty {
                Text("💡 提示: 在 Xcode Scheme 中启用 StoreKit Configuration 进行本地测试")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .lineLimit(2)
            }
            #endif
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var storeKitVersion: String {
        if #available(iOS 16.0, *) {
            return "2.0"
        } else {
            return "1.0"
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(PaymentTestTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Subscription Test View

    private var subscriptionTestView: some View {
        VStack(spacing: 20) {
            // 测试说明
            testInstructionCard(
                title: "末日通行证测试",
                description: "测试订阅产品的购买、试用、恢复购买等功能。购买会使用沙盒测试账号。"
            )

            // 当前订阅状态
            currentSubscriptionCard

            // 可测试产品
            availableProductsSection

            // 快速测试按钮
            quickTestButtonsSection
        }
        .padding()
    }

    // MARK: - Store Test View

    private var storeTestView: some View {
        VStack(spacing: 20) {
            // 测试说明
            testInstructionCard(
                title: "物资商城测试",
                description: "测试补给包的购买功能。购买成功后，物资会发送到邮箱。"
            )

            // 可购买产品
            availableSupplyPacksSection

            // 邮箱状态
            mailboxStatusCard
        }
        .padding()
    }

    // MARK: - Mailbox Test View

    private var mailboxTestView: some View {
        VStack(spacing: 20) {
            testInstructionCard(
                title: "邮箱测试",
                description: "测试从邮箱领取物资的功能。"
            )

            // 待领取物品
            if mailboxManager.mailboxItems.isEmpty {
                emptyMailboxView
            } else {
                ForEach(mailboxManager.mailboxItems) { item in
                    mailboxTestItemRow(item: item)
                }
            }
        }
        .padding()
    }

    // MARK: - Test Instruction Card

    private func testInstructionCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    // MARK: - Current Subscription Card

    private var currentSubscriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前订阅状态")
                .font(.headline)
                .foregroundColor(.white)

            Divider().background(Color.gray)

            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(tierManager.currentTier.badgeColor)

                VStack(alignment: .leading) {
                    Text("当前等级: \(tierManager.currentTier.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    if let activeEntitlement = tierManager.activeEntitlements.first {
                        Text("剩余时间: \(activeEntitlement.remainingDays) 天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    // MARK: - Available Products Section

    private var availableProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可测试产品")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(SubscriptionProductGroups.purchasable) { group in
                SubscriptionTestProductCard(
                    group: group,
                    monthlyProduct: iapManager.getProduct(for: group.monthlyProductID),
                    yearlyProduct: iapManager.getProduct(for: group.yearlyProductID),
                    trialProduct: group.trialProductID.flatMap { iapManager.getProduct(for: $0) },
                    onPurchase: { productID in
                        Task { await testPurchase(productID) }
                    }
                )
            }
        }
    }

    // MARK: - Available Supply Packs Section

    private var availableSupplyPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可购买补给包")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(SupplyPackID.allCases, id: \.rawValue) { packID in
                    SupplyStoreTestPackCard(
                        packID: packID,
                        onPurchase: {
                            Task { await testPurchaseSupplyPack(packID) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Mailbox Status Card

    private var mailboxStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("邮箱状态")
                .font(.headline)
                .foregroundColor(.white)

            Divider().background(Color.gray)

            HStack {
                Image(systemName: "tray.fill")
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("待领取: \(mailboxManager.pendingCount) 件")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text("背包容量: \(InventoryManager.shared.totalItemCount)/\(InventoryManager.shared.maxCapacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    // MARK: - Quick Test Buttons

    private var quickTestButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速测试")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 8) {
                TestButton(
                    title: "恢复购买",
                    subtitle: "测试恢复之前的购买",
                    icon: "arrow.clockwise",
                    color: .blue
                ) {
                    Task { await testRestorePurchase() }
                }

                TestButton(
                    title: "刷新产品",
                    subtitle: "重新从 App Store 加载产品",
                    icon: "arrow.clockwise",
                    color: .green
                ) {
                    Task { await testRefreshProducts() }
                }

                TestButton(
                    title: "清除邮箱",
                    subtitle: "清空所有待领取物品",
                    icon: "trash",
                    color: .red
                ) {
                    testClearMailbox()
                }

                TestButton(
                    title: "查看日志",
                    subtitle: "显示所有测试日志",
                    icon: "doc.text",
                    color: .purple
                ) {
                    // Log display is already shown below
                }
            }
        }
    }

    // MARK: - Test Logs Section

    private var testLogsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("测试日志")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button("清除") {
                    testLogs.removeAll()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if testLogs.isEmpty {
                        Text("暂无测试日志")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(testLogs.reversed()) { log in
                            TestLogRow(log: log)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    // MARK: - Empty Mailbox View

    private var emptyMailboxView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("邮箱为空")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("购买的补给包将在这里领取")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Mailbox Test Item Row

    private func mailboxTestItemRow(item: MailboxItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "box.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("数量: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("领取") {
                Task { await testClaimItem(item) }
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    // MARK: - Sandbox Setup Alert

    private var sandboxSetupAlert: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("沙盒环境设置步骤：")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. 设置 → Apple ID → 沙盒与测试")
                        .font(.subheadline)
                    Text("   登录你的沙盒测试账号")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("2. 在 App Store Connect 中配置产品")
                        .font(.subheadline)
                    Text("   使用提供的 Product ID 配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("3. 确保设备网络连接正常")
                        .font(.subheadline)
                    Text("   沙盒环境需要网络验证")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("4. 点击产品进行测试购买")
                        .font(.subheadline)
                    Text("   使用测试账号，不会扣费")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("了解") {
                    showSandboxSetupAlert = false
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }

    // MARK: - Test Methods

    private func testPurchase(_ productID: String) async {
        addLog("开始购买: \(productID)")

        // Check if it's a trial
        if let group = SubscriptionProductGroups.group(for: productID),
           group.isTrialProduct(productID) {
            addLog("这是试用产品，跳过沙盒测试")
            return
        }

        guard let product = iapManager.getProduct(for: productID) else {
            addLog("错误: 产品未找到 - \(productID)", type: .error)
            return
        }

        addLog("产品已找到: \(product.displayName)")
        addLog("价格: \(product.displayPrice)")
        addLog("开始沙盒购买流程...")

        let success = await iapManager.purchase(product)

        if success {
            addLog("✅ 购买成功!", type: .success)
            addLog("产品: \(product.displayName)")

            // 订阅产品会自动生效
            if let group = SubscriptionProductGroups.group(for: productID) {
                addLog("权益等级: \(group.tier.displayName)")
            }
        } else {
            addLog("❌ 购买失败", type: .error)
            if let error = iapManager.errorMessage {
                addLog("错误信息: \(error)", type: .error)
            }
        }
    }

    private func testRestorePurchase() async {
        addLog("开始恢复购买...")

        let success = await iapManager.restorePurchases()

        if success {
            addLog("✅ 恢复购买成功!", type: .success)
            addLog("当前等级: \(tierManager.currentTier.displayName)")

            if let active = tierManager.activeEntitlements.first {
                addLog("剩余天数: \(active.remainingDays) 天")
            }
        } else {
            addLog("❌ 恢复购买失败", type: .error)
        }
    }

    private func testRefreshProducts() async {
        addLog("开始刷新产品...")

        await iapManager.loadProducts()

        addLog("✅ 产品刷新完成")
        addLog("已加载产品数: \(iapManager.availableProducts.count)")

        for product in iapManager.availableProducts {
            addLog("  - \(product.id): \(product.displayPrice)")
        }
    }

    private func testPurchaseSupplyPack(_ packID: SupplyPackID) async {
        addLog("开始购买补给包: \(packID.displayName)")

        // Find the real product
        guard let product = iapManager.availableProducts.first(where: { $0.id == packID.rawValue }) else {
            addLog("错误: 产品未找到 - \(packID.rawValue)", type: .error)
            addLog("请先刷新产品列表")
            return
        }

        addLog("产品: \(product.displayName)")
        addLog("价格: \(product.displayPrice)")

        // Purchase through StoreManager
        await storeManager.purchase(product)

        // Check if there was an error
        if storeManager.purchaseError == nil {
            addLog("✅ 购买成功!", type: .success)
            addLog("物资已发送到邮箱")
            addLog("待领取数量: \(mailboxManager.pendingCount)")
        } else {
            addLog("❌ 购买失败", type: .error)
            if let error = storeManager.purchaseError {
                addLog("错误信息: \(error)", type: .error)
            }
        }
    }

    private func testClaimItem(_ item: MailboxItem) async {
        addLog("开始领取物品: \(item.itemName)")

        let success = await MailboxManager.shared.claimItem(id: item.id)

        if success {
            addLog("✅ 领取成功!", type: .success)
            addLog("已添加到背包: \(item.itemName) x\(item.quantity)")
        } else {
            addLog("❌ 领取失败", type: .error)
        }
    }

    private func testClearMailbox() {
        addLog("清空邮箱...")
        mailboxManager.pendingItems.removeAll()
        addLog("✅ 邮箱已清空")
    }

    // MARK: - Helper Methods

    private func addLog(_ message: String, type: TestLogType = .info) {
        let log = TestLog(
            timestamp: Date(),
            message: message,
            type: type
        )
        testLogs.append(log)

        // Print to console for debugging
        let icon: String
        switch type {
        case .success: icon = "✅"
        case .error: icon = "❌"
        case .warning: icon = "⚠️"
        case .info: icon = "ℹ️"
        }
        print("\(icon) [PaymentTest] \(message)")
    }
}

// MARK: - Test Log

struct TestLog: Identifiable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: TestLogType

    init(timestamp: Date, message: String, type: TestLogType = .info) {
        self.id = UUID()
        self.timestamp = timestamp
        self.message = message
        self.type = type
    }
}

enum TestLogType {
    case info
    case success
    case error
    case warning
}

// MARK: - Test Log Row

struct TestLogRow: View {
    let log: TestLog

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)

            Text(log.type.icon)
                .font(.caption)

            Text(log.message)
                .font(.caption)
                .foregroundColor(log.type.color)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

extension TestLogType {
    var icon: String {
        switch self {
        case .info: return "ℹ️"
        case .success: return "✅"
        case .error: return "❌"
        case .warning: return "⚠️"
        }
    }

    var color: Color {
        switch self {
        case .info: return .white
        case .success: return .green
        case .error: return .red
        case .warning: return .yellow
        }
    }
}

// MARK: - Subscription Test Product Card

struct SubscriptionTestProductCard: View {
    let group: SubscriptionProductGroup
    let monthlyProduct: Product?
    let yearlyProduct: Product?
    let trialProduct: Product?
    let onPurchase: (String) -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: group.icon)
                    .font(.largeTitle)

                VStack(alignment: .leading) {
                    Text(group.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(group.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Products
            VStack(spacing: 8) {
                if let trial = trialProduct {
                    ProductTestButton(
                        title: "\(group.displayNameShort) 试用",
                        subtitle: "\(group.trialDays ?? 0)天免费",
                        product: trial,
                        isLoading: isLoading,
                        onTap: { onPurchase(trial.id) }
                    )
                }

                if let monthly = monthlyProduct {
                    ProductTestButton(
                        title: "\(group.displayNameShort) 月付",
                        subtitle: monthly.displayPrice,
                        product: monthly,
                        isLoading: isLoading,
                        onTap: { onPurchase(monthly.id) }
                    )
                }

                if let yearly = yearlyProduct {
                    ProductTestButton(
                        title: "\(group.displayNameShort) 年付",
                        subtitle: yearly.displayPrice + " - 省\(group.yearlyDiscountPercentage)%",
                        product: yearly,
                        isLoading: isLoading,
                        onTap: { onPurchase(yearly.id) }
                    )
                }
            }

            // Benefits Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("核心权益:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("• 建造加速: \(group.benefits.buildSpeedBonus)")
                    Text("• 生产加速: \(group.benefits.productionSpeedBonus)")
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                HStack {
                    Text("• 背包容量: \(group.benefits.backpackCapacity)")
                    Text("• 资源加成: \(group.benefits.resourceBonus)")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }
}

// MARK: - Product Test Button

struct ProductTestButton: View {
    let title: String
    let subtitle: String
    let product: Product
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            .background(isLoading ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Supply Store Test Pack Card

struct SupplyStoreTestPackCard: View {
    let packID: SupplyPackID
    let onPurchase: () -> Void

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: packID.iconName)
                    .font(.title)
                    .foregroundColor(getColor(for: packID))

                VStack(alignment: .leading, spacing: 4) {
                    Text(packID.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(packID.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(getPrice(for: packID))
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            // Contents Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("包含物资:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(packID.contents.prefix(5).map { "\($0.displayName) x\($0.quantity)" }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Test Button
            Button {
                onPurchase()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 16, height: 16)
                        Text("购买中...")
                    } else {
                        Image(systemName: "cart.fill")
                        Text("沙盒测试购买")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.blue)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255))
        .cornerRadius(12)
    }

    private func getPrice(for packID: SupplyPackID) -> String {
        switch packID {
        case .survivor: return "¥6"
        case .explorer: return "¥18"
        case .lord: return "¥38"
        case .overlord: return "¥68"
        }
    }

    private func getIconName(for packID: SupplyPackID) -> String {
        switch packID {
        case .survivor: return "leaf.fill"
        case .explorer: return "compass.fill"
        case .lord: return "castle.fill"
        case .overlord: return "crown.fill"
        }
    }

    private func getColor(for packID: SupplyPackID) -> Color {
        switch packID {
        case .survivor: return .green
        case .explorer: return .blue
        case .lord: return .purple
        case .overlord: return .orange
        }
    }
}

// MARK: - Test Button Component

struct TestButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    PaymentTestView()
        .environmentObject(IAPManager.shared)
        .environmentObject(StoreManager.shared)
        .environmentObject(MailboxManager.shared)
        .environmentObject(TierManager.shared)
}
