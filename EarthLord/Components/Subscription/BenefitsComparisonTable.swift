import SwiftUI

// MARK: - Benefits Comparison Table

/// 权益对比表组件 - 展示6项核心权益
struct BenefitsComparisonTable: View {
    let benefits: SubscriptionBenefits
    let showAllFeatures: Bool

    init(benefits: SubscriptionBenefits, showAllFeatures: Bool = true) {
        self.benefits = benefits
        self.showAllFeatures = showAllFeatures
    }

    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("权益")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                Spacer()

                Text("详情")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            Divider()

            // Core Benefits (6 items)
            benefitRow(icon: "hammer.fill", title: "建造加速", value: benefits.buildSpeedBonus)
            Divider()
            benefitRow(icon: "gearshape.fill", title: "生产加速", value: benefits.productionSpeedBonus)
            Divider()
            benefitRow(icon: "leaf.fill", title: "资源加成", value: benefits.resourceBonus)
            Divider()
            benefitRow(icon: "backpack.fill", title: "背包容量", value: benefits.backpackCapacity)
            Divider()
            benefitRow(icon: "percent", title: "商店折扣", value: benefits.shopDiscount)
            Divider()

            // Special Features
            if showAllFeatures && !benefits.specialFeatures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("特殊功能")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(benefits.specialFeatures, id: \.self) { feature in
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)

                                Text(feature)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }

    private func benefitRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            // Icon + Title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 20)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Value
            Text(value)
                .font(.caption.bold())
                .foregroundColor(value == "无" ? .secondary : .green)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Benefits Comparison Row (Compact)

/// 紧凑版权益行 - 用于卡片内部
struct BenefitRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    init(icon: String, title: String, value: String, color: Color = .blue) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.caption2.bold())
                .foregroundColor(value == "无" ? .secondary : color)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Full table for Empire
        BenefitsComparisonTable(
            benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier3),
            showAllFeatures: true
        )

        // Compact table for Support
        BenefitsComparisonTable(
            benefits: SubscriptionBenefits.from(tierBenefit: TierBenefitConfig.tier1),
            showAllFeatures: false
        )
    }
    .padding()
    .background(Color.black)
}
