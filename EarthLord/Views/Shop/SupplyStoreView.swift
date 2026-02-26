import SwiftUI
import StoreKit

// MARK: - Supply Store View

/// 物资商城视图 - 仅显示消耗品补给包
/// 从 SubscriptionView 分离出来的独立视图
struct SupplyStoreView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var mailboxManager: MailboxManager

    @State private var selectedTab = 0
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Tabs
                pickerTabs

                // Content
                if selectedTab == 0 {
                    supplyPacksView
                } else {
                    mailboxView
                }
            }
            .padding()
        }
        .navigationTitle("物资商城")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProducts()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.title)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("物资商城")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("购买补给包，快速获取资源")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mailbox badge
            if mailboxManager.pendingCount > 0 {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "tray.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("\(mailboxManager.pendingCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    // MARK: - Picker Tabs

    private var pickerTabs: some View {
        Picker("", selection: $selectedTab) {
            Text("补给包").tag(0)
            Text("待领取").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Supply Packs

    private var supplyPacksView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(SupplyPackID.allCases, id: \.rawValue) { packID in
                SupplyStorePackCard(
                    packID: packID,
                    onPurchase: {
                        Task { await purchaseSupplyPack(packID) }
                    }
                )
            }
        }
    }

    // MARK: - Mailbox View

    private var mailboxView: some View {
        VStack(spacing: 12) {
            if mailboxManager.pendingItems.isEmpty {
                emptyMailboxView
            } else {
                ForEach(mailboxManager.pendingItems) { item in
                    DBMailboxItemRow(item: item) {
                        Task {
                            await claimItem(item)
                        }
                    }
                }
            }
        }
    }

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

    // MARK: - Actions

    private func loadProducts() async {
        isLoading = true
        await storeManager.loadProducts()
        isLoading = false
    }

    private func purchaseSupplyPack(_ packID: SupplyPackID) async {
        guard let product = storeManager.products.first(where: { $0.id == packID.rawValue }) else {
            return
        }

        isLoading = true
        let _ = await storeManager.purchase(product)
        isLoading = false
    }

    private func claimItem(_ item: DBMailboxItem) async {
        await mailboxManager.claimItem(item)
    }
}

// MARK: - Supply Pack Card (Reused)

/// 补给包卡片组件 - 采用订阅系统一致的深色卡片风格
struct SupplyStorePackCard: View {
    let packID: SupplyPackID
    let onPurchase: () -> Void

    @State private var isLoading = false
    @State private var showDetail = false
    @State private var showConfirmDialog = false
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：图标 + 标题 + 价格
            HStack(spacing: 12) {
                // 左侧图标
                ZStack {
                    Circle()
                        .fill(getPackGradient(packID))
                        .frame(width: 50, height: 50)

                    Image(systemName: packID.iconName)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                // 中间信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(packID.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(packID.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 右侧价格
                if let product = storeManager.products.first(where: { $0.id == packID.rawValue }) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundColor(.green)
                } else {
                    Text(formatYuan(packID.listPriceYuan))
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
            }

            // 详细描述
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.8))

                    Text(packID.recommendedFor)
                        .font(.caption2)
                        .foregroundColor(.blue.opacity(0.8))
                }

                Text(packID.detailedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)

            valueInsightView

            // 中部：稀有度标识 + 查看详情
            HStack(spacing: 8) {
                ForEach(getRarityBadges().prefix(3), id: \.self) { badge in
                    Text(badge)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(getRarityColor(badge).opacity(0.2))
                        .foregroundColor(getRarityColor(badge))
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: {
                    showDetail = true
                }) {
                    HStack(spacing: 4) {
                        Text("查看全部内容")
                            .font(.caption2)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }

            // 底部：购买按钮
            Button(action: {
                showConfirmDialog = true
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 20)
                    } else {
                        Text("立即购买")
                            .font(.subheadline.bold())
                        if let product = storeManager.products.first(where: { $0.id == packID.rawValue }) {
                            Text(product.displayPrice)
                                .font(.subheadline.bold())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [getPackColor(packID), getPackColor(packID).opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)
            .confirmationDialog(
                "确认购买",
                isPresented: $showConfirmDialog,
                titleVisibility: .visible
            ) {
                Button("取消", role: .cancel) { }
                Button("确认购买") {
                    isLoading = true
                    onPurchase()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isLoading = false
                    }
                }
            } message: {
                if let product = storeManager.products.first(where: { $0.id == packID.rawValue }) {
                    Text(
                        "确认花费 \(product.displayPrice) 购买 \(packID.displayName)？\n\n" +
                        "保底价值 \(formatYuan(packID.guaranteedValueYuan))，" +
                        "总期望价值 \(formatYuan(packID.totalExpectedValueYuan))（约 \(String(format: "%.1f", packID.valueRatio))x）。\n\n" +
                        "购买后物品将发送到待领取，请及时领取。"
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(getPackColor(packID).opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showDetail) {
            SupplyPackDetailSheetView(packID: packID, onPurchase: onPurchase)
        }
    }

    private func getPackColor(_ packID: SupplyPackID) -> Color {
        switch packID {
        case .survivor: return .green
        case .explorer: return .blue
        case .lord: return .purple
        case .overlord: return .orange
        }
    }

    private func getPackGradient(_ packID: SupplyPackID) -> LinearGradient {
        let color = getPackColor(packID)
        return LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.6)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func getRarityBadges() -> [String] {
        let rarities = Set(packID.contents.map { $0.rarity })
        var badges: [String] = []
        if rarities.contains("common") { badges.append("普通") }
        if rarities.contains("rare") { badges.append("稀有") }
        if rarities.contains("epic") { badges.append("史诗") }
        if rarities.contains("legendary") { badges.append("传说") }
        return badges.sorted { rarityPriority($0) > rarityPriority($1) }
    }

    private func rarityPriority(_ rarity: String) -> Int {
        switch rarity {
        case "传说": return 4
        case "史诗": return 3
        case "稀有": return 2
        case "普通": return 1
        default: return 0
        }
    }

    private func getRarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "传说": return .orange
        case "史诗": return .purple
        case "稀有": return .blue
        case "普通": return .gray
        default: return .gray
        }
    }

    private var valueInsightView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("保底价值", systemImage: "shield.checkered")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatYuan(packID.guaranteedValueYuan))
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }

            HStack {
                Label("总期望价值", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(formatYuan(packID.totalExpectedValueYuan))  (~\(String(format: "%.1f", packID.valueRatio))x)")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.22))
        .cornerRadius(8)
    }

    private func formatYuan(_ amount: Double) -> String {
        "¥\(Int(amount.rounded()))"
    }
}

// MARK: - DB Mailbox Item Row

/// 数据库邮箱物品行组件 - 统一深色卡片风格
struct DBMailboxItemRow: View {
    let item: DBMailboxItem
    let onClaim: () -> Void

    @State private var isClaiming = false

    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "box.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // 右侧信息
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Label("数量: \(item.quantity)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(item.created_at, style: .date)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // 领取按钮
            Button(action: {
                isClaiming = true
                onClaim()
            }) {
                if isClaiming {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 60, height: 35)
                } else {
                    Text("领取")
                        .font(.caption.bold())
                        .frame(width: 60)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isClaiming)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Mailbox Item Row (Reused)

/// 邮箱物品行组件 - 统一深色卡片风格
struct SupplyStoreMailboxItemRow: View {
    let item: MailboxItem
    let onClaim: () -> Void

    @State private var isClaiming = false

    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "box.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // 右侧信息
            VStack(alignment: .leading, spacing: 6) {
                Text(item.itemName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Label("数量: \(item.quantity)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(item.purchasedAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // 领取按钮
            Button(action: {
                isClaiming = true
                onClaim()
            }) {
                if isClaiming {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 60, height: 35)
                } else {
                    Text("领取")
                        .font(.caption.bold())
                        .frame(width: 60)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isClaiming)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supply Pack Detail Sheet View (Simple)

/// 补给包详情Sheet视图 - 显示完整内容列表（用于从商城卡片弹出）
struct SupplyPackDetailSheetView: View {
    let packID: SupplyPackID
    let onPurchase: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(getPackGradient(packID))
                                .frame(width: 80, height: 80)

                            Image(systemName: packID.iconName)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(packID.displayName)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(packID.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let product = storeManager.products.first(where: { $0.id == packID.rawValue }) {
                                Text(product.displayPrice)
                                    .font(.title.bold())
                                    .foregroundColor(.green)
                            } else {
                                Text(formatYuan(packID.listPriceYuan))
                                    .font(.title.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()

                    VStack(spacing: 10) {
                        valueMetricRow("补给包售价", value: formatYuan(packID.listPriceYuan), color: .green)
                        valueMetricRow("保底价值（必得）", value: formatYuan(packID.guaranteedValueYuan), color: .white)
                        valueMetricRow("随机期望价值", value: formatYuan(packID.randomExpectedValueYuan), color: .orange)
                        valueMetricRow(
                            "总期望价值",
                            value: "\(formatYuan(packID.totalExpectedValueYuan))  (~\(String(format: "%.1f", packID.valueRatio))x)",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.22))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Contents
                    VStack(alignment: .leading, spacing: 12) {
                        Text("包含物资")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(packID.contents, id: \.id) { item in
                                HStack {
                                    Circle()
                                        .fill(getRarityColor(item.rarity))
                                        .frame(width: 8, height: 8)

                                    Text(item.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.white)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        if item.guaranteed {
                                            Text("必得")
                                                .font(.caption2.bold())
                                                .foregroundColor(.green)
                                        } else {
                                            Text("\(Int(item.dropRate * 100))%")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }

                                        Text("x\(item.quantity)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.secondary)
                                    }

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("单价 \(formatYuan(item.unitValueYuan))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        Text(item.guaranteed
                                            ? "小计 \(formatYuan(item.totalValueYuan))"
                                            : "期望 \(formatYuan(item.expectedValueYuan))")
                                            .font(.caption.bold())
                                            .foregroundColor(item.guaranteed ? .white : .yellow)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }

                    // Purchase Button
                    Button(action: {
                        isPurchasing = true
                        onPurchase()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isPurchasing = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("立即购买")
                                    .font(.headline.bold())
                                if let product = storeManager.products.first(where: { $0.id == packID.rawValue }) {
                                    Text(product.displayPrice)
                                        .font(.headline.bold())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(getPackGradient(packID))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .disabled(isPurchasing)
                }
            }
            .navigationTitle("物资详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getPackColor(_ packID: SupplyPackID) -> Color {
        switch packID {
        case .survivor: return .green
        case .explorer: return .blue
        case .lord: return .purple
        case .overlord: return .orange
        }
    }

    private func getPackGradient(_ packID: SupplyPackID) -> LinearGradient {
        let color = getPackColor(packID)
        return LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.7)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func getRarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "rare": return .blue
        case "epic": return .purple
        case "legendary": return .orange
        default: return .gray
        }
    }

    private func valueMetricRow(_ title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }

    private func formatYuan(_ amount: Double) -> String {
        "¥\(Int(amount.rounded()))"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SupplyStoreView()
            .environmentObject(StoreManager.shared)
            .environmentObject(MailboxManager.shared)
    }
    .preferredColorScheme(.dark)
}
