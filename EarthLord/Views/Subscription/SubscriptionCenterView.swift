import SwiftUI
import StoreKit

// MARK: - Subscription Center View

/// 订阅中心主视图 - 新的4产品订阅系统
struct SubscriptionCenterView: View {
    @EnvironmentObject var tierManager: TierManager
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var trialManager: TrialManager

    @State private var isLoading = false
    @State private var selectedGroup: String?
    @State private var showSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                statusCard

                // Product Cards
                ForEach(SubscriptionProductGroups.all) { group in
                    SubscriptionProductCard(
                        productGroup: group,
                        monthlyProduct: iapManager.getProduct(for: group.monthlyProductID),
                        yearlyProduct: iapManager.getProduct(for: group.yearlyProductID),
                        trialProduct: group.trialProductID.flatMap { iapManager.getProduct(for: $0) },
                        isCurrentSubscription: tierManager.currentTier == group.tier,
                        onSubscribe: { productID in
                            Task { await handleSubscribe(productID: productID) }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("订阅中心")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProducts()
        }
        .alert("订阅成功", isPresented: $showSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        SubscriptionStatusCard(
            currentTier: tierManager.currentTier,
            remainingDays: getRemainingDays(),
            isAutoRenewalEnabled: false, // TODO: 从 TierManager 获取
            onRestorePurchase: {
                Task { await restorePurchase() }
            },
            onClose: {
                // Handle close if presented as sheet
            }
        )
    }

    // MARK: - Helpers

    private func getRemainingDays() -> Int {
        // Get the active entitlement with the highest power level
        guard let activeEntitlement = tierManager.activeEntitlements.max(by: { $0.powerLevel < $1.powerLevel }) else {
            return 0
        }

        return activeEntitlement.remainingDays
    }

    // MARK: - Actions

    private func loadProducts() async {
        isLoading = true
        await iapManager.loadProducts()
        isLoading = false
    }

    private func handleSubscribe(productID: String) async {
        isLoading = true
        defer { isLoading = false }

        // Check if it's a trial
        if let group = SubscriptionProductGroups.group(for: productID),
           group.isTrialProduct(productID) {

            // Check trial eligibility
            guard trialManager.canStartTrial(for: group.id) else {
                // TODO: Show error alert
                return
            }

            // Start trial
            let success = await trialManager.startTrial(for: productID, trialDays: group.trialDays ?? 7)

            if success {
                successMessage = "试用已开始，\(group.displayName)权益已激活！"
                showSuccessAlert = true
            }
        } else {
            // Regular purchase
            guard let product = iapManager.getProduct(for: productID) else {
                return
            }

            let success = await iapManager.purchase(product)

            if success {
                if let group = SubscriptionProductGroups.group(for: productID) {
                    // Handle trial conversion if applicable
                    _ = await trialManager.convertTrial(
                        for: group.id,
                        purchasedProductID: productID
                    )
                }

                successMessage = "订阅成功！权益已激活。"
                showSuccessAlert = true
            }
        }
    }

    private func restorePurchase() async {
        isLoading = true
        let success = await iapManager.restorePurchases()
        isLoading = false

        if success {
            successMessage = "购买已恢复，权益已激活。"
            showSuccessAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SubscriptionCenterView()
            .environmentObject(TierManager.shared)
            .environmentObject(IAPManager.shared)
            .environmentObject(TrialManager.shared)
    }
    .preferredColorScheme(.dark)
}
