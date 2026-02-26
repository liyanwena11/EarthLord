import SwiftUI
import StoreKit

// MARK: - Subscription Purchase Button

/// 订阅购买按钮组件 - 支持试用/月付/年付
struct SubscriptionPurchaseButton: View {
    let productGroup: SubscriptionProductGroup
    let type: SubscriptionButtonType
    let product: Product?
    let onTap: () -> Void

    @State private var isLoading = false

    enum SubscriptionButtonType {
        case trial
        case monthly
        case yearly

        var displayName: String {
            switch self {
            case .trial:
                return "试用7天"
            case .monthly:
                return "月付"
            case .yearly:
                return "年付"
            }
        }
    }

    var body: some View {
        Button(action: {
            isLoading = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    // Label
                    Text(type.displayName)
                        .font(.caption.bold())

                    // Price or Badge
                    if type == .trial {
                        Text("免费")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(4)
                    } else if type == .yearly {
                        // Savings badge
                        if productGroup.yearlySavings > 0 {
                            Text("省¥\(productGroup.yearlySavings)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.5))
                                .cornerRadius(4)
                        }
                    }

                    // Price
                    if let product = product, type != .trial {
                        Text(product.displayPrice)
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading || product == nil)
    }

    private var buttonColor: Color {
        switch type {
        case .trial:
            return .green
        case .monthly:
            return .orange
        case .yearly:
            return .purple
        }
    }
}

// MARK: - Product Card (Full)

/// 完整的产品卡片 - 包含权益表和购买按钮
struct SubscriptionProductCard: View {
    let productGroup: SubscriptionProductGroup
    let monthlyProduct: Product?
    let yearlyProduct: Product?
    let trialProduct: Product?
    let isCurrentSubscription: Bool
    let onSubscribe: (String) -> Void

    @State private var showBenefits = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon
                Text(productGroup.icon)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(productGroup.displayName)
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    Text(productGroup.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Current badge
                if isCurrentSubscription {
                    Text("当前")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(productGroup.iconColor.opacity(0.5))
                        .cornerRadius(6)
                }
            }

            // Price Comparison
            HStack(spacing: 12) {
                // Monthly
                priceColumn(
                    title: "月付",
                    price: monthlyProduct?.displayPrice ?? "¥\(productGroup.monthlyPrice)",
                    period: "/月"
                )

                Spacer()

                // Yearly with savings
                priceColumn(
                    title: "年付",
                    price: yearlyProduct?.displayPrice ?? "¥\(productGroup.yearlyPrice)",
                    period: "/年",
                    savings: productGroup.yearlySavings > 0 ? "省¥\(productGroup.yearlySavings)" : nil,
                    isRecommended: true
                )
            }
            .padding(.vertical, 8)

            // Benefits Preview (expandable)
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showBenefits.toggle()
                    }
                }) {
                    HStack {
                        Text("专属权益")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Image(systemName: showBenefits ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if showBenefits {
                    BenefitsComparisonTable(
                        benefits: productGroup.benefits,
                        showAllFeatures: false
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }

            // Purchase Buttons
            VStack(spacing: 8) {
                // Trial Button (if available)
                if productGroup.hasTrial {
                    SubscriptionPurchaseButton(
                        productGroup: productGroup,
                        type: .trial,
                        product: trialProduct,
                        onTap: {
                            if let productID = productGroup.trialProductID {
                                onSubscribe(productID)
                            }
                        }
                    )
                }

                HStack(spacing: 8) {
                    // Monthly
                    SubscriptionPurchaseButton(
                        productGroup: productGroup,
                        type: .monthly,
                        product: monthlyProduct,
                        onTap: {
                            onSubscribe(productGroup.monthlyProductID)
                        }
                    )

                    // Yearly
                    SubscriptionPurchaseButton(
                        productGroup: productGroup,
                        type: .yearly,
                        product: yearlyProduct,
                        onTap: {
                            onSubscribe(productGroup.yearlyProductID)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentSubscription ? productGroup.iconColor : Color.clear, lineWidth: 2)
        )
    }

    private func priceColumn(
        title: String,
        price: String,
        period: String,
        savings: String? = nil,
        isRecommended: Bool = false
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isRecommended {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }

            HStack(spacing: 2) {
                Text(price)
                    .font(.subheadline.bold())
                    .foregroundColor(isRecommended ? .purple : .white)

                Text(period)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let savings = savings {
                Text(savings)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isRecommended ? Color.purple.opacity(0.1) : Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Compact Product Card

/// 紧凑产品卡片 - 用于快速浏览
struct CompactProductCard: View {
    let productGroup: SubscriptionProductGroup
    let product: Product?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(productGroup.icon)
                        .font(.title2)

                    Text(productGroup.displayNameShort)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Spacer()

                    if let product = product {
                        Text(product.displayPrice)
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }

                // Top 3 benefits
                VStack(alignment: .leading, spacing: 4) {
                    BenefitRow(
                        icon: "hammer.fill",
                        title: "建造",
                        value: productGroup.benefits.buildSpeedBonus,
                        color: productGroup.iconColor
                    )
                    BenefitRow(
                        icon: "gearshape.fill",
                        title: "生产",
                        value: productGroup.benefits.productionSpeedBonus,
                        color: productGroup.iconColor
                    )
                    BenefitRow(
                        icon: "backpack.fill",
                        title: "背包",
                        value: productGroup.benefits.backpackCapacity,
                        color: productGroup.iconColor
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SubscriptionProductCard(
            productGroup: SubscriptionProductGroups.lordPass,
            monthlyProduct: nil,
            yearlyProduct: nil,
            trialProduct: nil,
            isCurrentSubscription: false,
            onSubscribe: { _ in }
        )

        HStack(spacing: 12) {
            CompactProductCard(
                productGroup: SubscriptionProductGroups.explorerPass,
                product: nil,
                onTap: {}
            )

            CompactProductCard(
                productGroup: SubscriptionProductGroups.apocalypsePass,
                product: nil,
                onTap: {}
            )
        }
    }
    .padding()
    .background(Color.black)
}
