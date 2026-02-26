import SwiftUI
import StoreKit

// MARK: - SubscriptionStoreViewModel

@MainActor
class SubscriptionStoreViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var showPurchaseConfirmation = false
    @Published var purchasingProduct: Product?
    @Published var purchaseMessage: String?
    
    init() {
        self.selectedTab = 0
    }
}

// MARK: - TierHeaderView

struct TierHeaderView: View {
    @ObservedObject var tierManager: TierManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("订阅商店")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button(action: { /* 帮助页面 */ }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // 当前 Tier 卡片
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前等级")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text(tierManager.currentTier.displayName)
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(tierManager.currentTier.badgeEmoji)
                                .font(.system(size: 24))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("权力等级")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                            Text("\(tierManager.currentTier.powerLevel)%")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // 过期时间显示
                if let expiration = tierManager.tierExpiration {
                    if expiration > Date() {
                        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.blue)
                            Text("有效期: \(daysLeft) 天 (\(expiration.formatted(date: .abbreviated, time: .omitted)))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("等级已过期，立即续费!")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else if tierManager.currentTier != .free {
                    HStack {
                        Image(systemName: "infinity")
                            .foregroundColor(.green)
                        Text("永久有效")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(tierManager.currentTier.badgeColor.opacity(0.1))
                    .stroke(tierManager.currentTier.badgeColor, lineWidth: 2)
            )
            .padding()
        }
    }
}

// MARK: - ProductRowView

struct ProductRowView: View {
    let product: Product
    let iapProduct: IAPProduct
    let isLoading: Bool
    let isPurchased: Bool
    let onPurchase: () async -> Void
    
    @State private var isLocalLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // 左侧内容
                VStack(alignment: .leading, spacing: 6) {
                    Text(iapProduct.displayName)
                        .font(.system(size: 16, weight: .semibold))

                    // 使用 tier 的 displayName 作为描述
                    Text(iapProduct.tier.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    // 订阅时长标签
                    if let duration = iapProduct.duration {
                        Label("有效期: \(duration.rawValue) 天", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // 右侧价格和按钮
                VStack(alignment: .trailing, spacing: 8) {
                    if isPurchased {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("已拥有")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(product.displayPrice)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Button(action: {
                                Task {
                                    isLocalLoading = true
                                    await onPurchase()
                                    isLocalLoading = false
                                }
                            }) {
                                if isLocalLoading || isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(height: 32)
                                } else {
                                    Text("购买")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                            }
                            .disabled(isLocalLoading || isLoading)
                        }
                    }
                }
            }
            
            // 权益预览
            let benefits = getBenefitStrings(for: iapProduct.tier)
            if !benefits.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("权益预览")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(benefits.prefix(4), id: \.self) { benefit in
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(benefit)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if benefits.count > 4 {
                            HStack(spacing: 6) {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("还有 \(benefits.count - 4) 项权益")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // Helper function to get benefit strings for a tier
    private func getBenefitStrings(for tier: UserTier) -> [String] {
        guard let benefit = TierBenefit.getBenefit(for: tier) else {
            return []
        }

        var benefits: [String] = []
        if benefit.buildSpeedBonus > 0 {
            benefits.append("建造速度 +\(Int(benefit.buildSpeedBonus * 100))%")
        }
        if benefit.productionSpeedBonus > 0 {
            benefits.append("生产速度 +\(Int(benefit.productionSpeedBonus * 100))%")
        }
        if benefit.resourceOutputBonus > 0 {
            benefits.append("资源产出 +\(Int(benefit.resourceOutputBonus * 100))%")
        }
        if benefit.backpackCapacityBonus > 0 {
            benefits.append("背包 +\(benefit.backpackCapacityBonus)kg")
        }
        if benefit.shopDiscountPercentage > 0 {
            benefits.append("商店折扣 \(Int(benefit.shopDiscountPercentage))%")
        }
        if benefit.defenseBonus > 0 {
            benefits.append("防御 +\(Int(benefit.defenseBonus * 100))%")
        }
        if benefit.hasVIPBadge {
            benefits.append("VIP 名牌")
        }
        if benefit.hasWeeklyChallenge {
            benefits.append("每周挑战")
        }
        if benefit.hasMonthlyChallenge {
            benefits.append("每月挑战")
        }
        if benefit.hasMonthlyLootBox {
            benefits.append("月度物资箱")
        }
        if benefit.teleportDailyLimit > 0 {
            benefits.append("每日传送 \(benefit.teleportDailyLimit) 次")
        }

        return benefits
    }
}

// MARK: - ProductTabView

struct ProductTabView: View {
    let products: [Product]
    @ObservedObject var iapManager: IAPManager
    @ObservedObject var tierManager: TierManager
    let onPurchase: (Product) async -> Void
    
    var body: some View {
        if products.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bag")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("暂无可用产品")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(products, id: \.id) { product in
                        if let iapProduct = iapManager.getProductInfo(for: product.id) {
                            ProductRowView(
                                product: product,
                                iapProduct: iapProduct,
                                isLoading: iapManager.purchaseInProgress,
                                isPurchased: iapManager.hasProduct(product.id),
                                onPurchase: {
                                    await onPurchase(product)
                                }
                            )
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - SubscriptionStoreView

struct SubscriptionStoreView: View {
    @ObservedObject var iapManager = IAPManager.shared
    @ObservedObject var tierManager = TierManager.shared
    @StateObject var viewModel = SubscriptionStoreViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部
                TierHeaderView(tierManager: tierManager)
                
                // 加载状态
                if iapManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("正在加载产品...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else if iapManager.availableProducts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("未能加载产品")
                            .font(.system(size: 16, weight: .semibold))
                        Text("请检查网络连接后重试")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // TabView
                    TabView(selection: $viewModel.selectedTab) {
                        // Tab 1: 消耗品
                        ProductTabView(
                            products: getConsumableProducts(),
                            iapManager: iapManager,
                            tierManager: tierManager,
                            onPurchase: handlePurchase
                        )
                        .tabItem {
                            Label("消耗品", systemImage: "bag.fill")
                        }
                        .tag(0)
                        
                        // Tab 2: Support Tier
                        ProductTabView(
                            products: getTierProducts(.support),
                            iapManager: iapManager,
                            tierManager: tierManager,
                            onPurchase: handlePurchase
                        )
                        .tabItem {
                            Label("支持者", systemImage: "heart.fill")
                        }
                        .tag(1)
                        
                        // Tab 3: Lordship Tier
                        ProductTabView(
                            products: getTierProducts(.lordship),
                            iapManager: iapManager,
                            tierManager: tierManager,
                            onPurchase: handlePurchase
                        )
                        .tabItem {
                            Label("领主", systemImage: "crown.fill")
                        }
                        .tag(2)
                        
                        // Tab 4: Empire Tier
                        ProductTabView(
                            products: getTierProducts(.empire),
                            iapManager: iapManager,
                            tierManager: tierManager,
                            onPurchase: handlePurchase
                        )
                        .tabItem {
                            Label("帝国", systemImage: "star.fill")
                        }
                        .tag(3)
                        
                        // Tab 5: VIP 自动续费
                        ProductTabView(
                            products: getAutoRenewableProducts(),
                            iapManager: iapManager,
                            tierManager: tierManager,
                            onPurchase: handlePurchase
                        )
                        .tabItem {
                            Label("VIP", systemImage: "sparkles")
                        }
                        .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    
                    // 底部按钮
                    HStack(spacing: 12) {
                        Button(action: restorePurchases) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("恢复购买")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("关闭")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await iapManager.initialize()
            }
        }
    }
    
    // MARK: - 过滤方法
    
    private func getConsumableProducts() -> [Product] {
        let typeProducts = iapManager.getProductsByType()
        return (typeProducts[.consumable] ?? []).sorted { p1, p2 in
            let info1 = iapManager.getProductInfo(for: p1.id)?.displayName ?? ""
            let info2 = iapManager.getProductInfo(for: p2.id)?.displayName ?? ""
            return info1 < info2
        }
    }
    
    private func getTierProducts(_ tier: UserTier) -> [Product] {
        let tierProducts = iapManager.getProductsByTier()
        return (tierProducts[tier] ?? []).sorted { p1, p2 in
            let info1 = iapManager.getProductInfo(for: p1.id)?.duration?.rawValue ?? 0
            let info2 = iapManager.getProductInfo(for: p2.id)?.duration?.rawValue ?? 0
            return info1 < info2
        }
    }
    
    private func getAutoRenewableProducts() -> [Product] {
        let typeProducts = iapManager.getProductsByType()
        return (typeProducts[.autoRenewable] ?? []).sorted { p1, p2 in
            let info1 = iapManager.getProductInfo(for: p1.id)?.displayName ?? ""
            let info2 = iapManager.getProductInfo(for: p2.id)?.displayName ?? ""
            return info1 < info2
        }
    }
    
    // MARK: - 购买处理
    
    private func handlePurchase(_ product: Product) async {
        let success = await iapManager.purchase(product)
        
        if success {
            alertTitle = "购买成功"
            alertMessage = "感谢您的购买！权益已应用到您的账户。"
            print("✅ 购买成功: \(product.displayName)")
        } else if let error = iapManager.errorMessage {
            alertTitle = "购买失败"
            alertMessage = error
            print("❌ 购买失败: \(error)")
        } else {
            alertTitle = "已取消"
            alertMessage = "购买已取消"
            print("👤 用户取消购买")
        }
        
        showAlert = true
    }
    
    private func restorePurchases() {
        Task {
            let success = await iapManager.restorePurchases()
            
            if success {
                alertTitle = "恢复成功"
                alertMessage = "您的购买已恢复。权益已应用到账户。"
                print("✅ 购买恢复成功")
            } else {
                alertTitle = "恢复失败"
                alertMessage = iapManager.errorMessage ?? "无法恢复购买，请重试"
                print("❌ 恢复购买失败")
            }
            
            showAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionStoreView()
}
