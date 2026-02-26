//
//  SubscriptionView.swift
//  EarthLord
//
//  末日通行证订阅系统 - 主视图
//  参考 APOCALYPSE PASS 设计风格
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var tierManager: TierManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: UserTier = .lordship
    @State private var selectedPeriod: SubscriptionPeriod = .yearly
    @State private var showSubscribeSuccess = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    headerView

                    // MARK: - Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Period toggle
                            PeriodToggleView(selectedPeriod: $selectedPeriod)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            // Subscription cards
                            subscriptionCardsSection
                                .padding(.horizontal, 20)

                            // Benefits comparison
                            benefitsComparisonSection
                                .padding(.horizontal, 20)

                            // Bottom button
                            subscribeButtonSection
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarColorScheme(.dark)
        }
        .task {
            await storeManager.loadProducts()
        }
        .alert("购买成功", isPresented: $showSubscribeSuccess) {
            Button("确定") { dismiss() }
        } message: {
            Text("感谢您的订阅！权益已立即生效。")
        }
        .alert("购买失败", isPresented: .constant(purchaseError != nil)) {
            Button("确定") { purchaseError = nil }
        } message: {
            if let error = purchaseError {
                Text(error)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            // Game controller icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("末日通行证")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("解锁终极游戏体验")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Current tier badge
            if tierManager.currentTier != .free {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text("当前订阅: \(tierManager.currentTier.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.15),
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Subscription Cards

    private var subscriptionCardsSection: some View {
        VStack(spacing: 12) {
            // Free tier
            SubscriptionCardView(
                productGroup: SubscriptionProductGroups.freePass,
                period: selectedPeriod,
                isSelected: selectedTier == .free,
                isRecommended: false,
                onTap: { selectedTier = .free }
            )

            // Explorer Pass
            SubscriptionCardView(
                productGroup: SubscriptionProductGroups.explorerPass,
                period: selectedPeriod,
                isSelected: selectedTier == .support,
                isRecommended: false,
                onTap: { selectedTier = .support }
            )

            // Lord Pass - Recommended
            SubscriptionCardView(
                productGroup: SubscriptionProductGroups.lordPass,
                period: selectedPeriod,
                isSelected: selectedTier == .lordship,
                isRecommended: true,
                onTap: { selectedTier = .lordship }
            )
        }
    }

    // MARK: - Benefits Comparison

    private var benefitsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(.blue)

                Text("权益详情对比")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            SubscriptionBenefitsComparisonView(
                tiers: SubscriptionProductGroups.all,
                selectedTier: selectedTier
            )
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButtonSection: some View {
        VStack(spacing: 12) {
            // Main subscribe button
            Button(action: {
                Task { await subscribe() }
            }) {
                HStack(spacing: 12) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.subheadline)

                        Text(subscribeButtonText)
                            .font(.headline.bold())

                        Spacer()

                        Text(subscribePriceText)
                            .font(.headline.bold())

                        if selectedPeriod == .yearly, let savings = yearlySavingsText {
                            Text(savings)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(6)
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: selectedTier == .free
                            ? [Color.gray, Color.gray.opacity(0.7)]
                            : [Color.purple, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: selectedTier == .free
                        ? Color.clear
                        : Color.purple.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(isPurchasing || selectedTier == .free)
            .opacity(selectedTier == .free ? 0.6 : 1.0)

            // Restore purchases
            Button(action: {
                Task { await restorePurchases() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("恢复购买")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .disabled(isPurchasing)

            // Terms
            Text("订阅会自动续费，可在设置中随时取消。")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Computed Properties

    private var subscribeButtonText: String {
        if selectedTier == .free {
            return "当前为免费版"
        }

        let group = SubscriptionProductGroups.group(for: selectedTier)
        let periodText = selectedPeriod == .monthly ? "月付" : "年付"
        return "订阅 \(group?.displayNameShort ?? "") - \(periodText)"
    }

    private var subscribePriceText: String {
        if selectedTier == .free {
            return ""
        }

        guard let group = SubscriptionProductGroups.group(for: selectedTier) else {
            return ""
        }

        let price = selectedPeriod == .monthly
            ? group.monthlyPrice
            : group.yearlyPrice

        return "¥\(price)"
    }

    private var yearlySavingsText: String? {
        guard selectedPeriod == .yearly,
              let group = SubscriptionProductGroups.group(for: selectedTier),
              group.yearlySavings > 0 else {
            return nil
        }

        return "省¥\(group.yearlySavings)"
    }

    // MARK: - Actions

    private func subscribe() async {
        guard selectedTier != .free else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        // Get product ID
        let productID: String
        switch selectedTier {
        case .support:
            productID = selectedPeriod == .monthly
                ? SubscriptionProductGroups.explorerPass.monthlyProductID
                : SubscriptionProductGroups.explorerPass.yearlyProductID
        case .lordship:
            productID = selectedPeriod == .monthly
                ? SubscriptionProductGroups.lordPass.monthlyProductID
                : SubscriptionProductGroups.lordPass.yearlyProductID
        default:
            return
        }

        // Find StoreKit product
        guard let product = storeManager.products.first(where: { $0.id == productID }) else {
            purchaseError = "产品暂不可用，请稍后重试"
            return
        }

        // Purchase
        await storeManager.purchase(product)

        if storeManager.purchaseError == nil {
            showSubscribeSuccess = true
        } else {
            purchaseError = storeManager.purchaseError
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        await storeManager.restorePurchases()
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
        .environmentObject(TierManager.shared)
        .environmentObject(AuthManager.shared)
        .environmentObject(StoreManager.shared)
}
