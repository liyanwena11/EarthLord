import SwiftUI

// MARK: - Subscription Benefits Comparison View

/// 订阅权益对比视图 - 展示所有等级的权益对比
struct SubscriptionBenefitsComparisonView: View {
    let tiers: [SubscriptionProductGroup]
    let selectedTier: UserTier

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("权益对比")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                Spacer()

                // Tier headers
                ForEach(tiers) { tier in
                    VStack(spacing: 2) {
                        Text(tier.icon)
                            .font(.caption)
                        Text(tier.displayNameShort)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(tier.tier == selectedTier ? tier.iconColor : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(tier.tier == .free ? 0.6 : 1.0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))

            Divider()

            // Benefits rows
            benefitRow(
                icon: "hammer.fill",
                title: "建造加速",
                values: tiers.map { $0.benefits.buildSpeedBonus }
            )
            Divider()
            benefitRow(
                icon: "gearshape.fill",
                title: "生产加速",
                values: tiers.map { $0.benefits.productionSpeedBonus }
            )
            Divider()
            benefitRow(
                icon: "leaf.fill",
                title: "资源加成",
                values: tiers.map { $0.benefits.resourceBonus }
            )
            Divider()
            benefitRow(
                icon: "backpack.fill",
                title: "背包容量",
                values: tiers.map { $0.benefits.backpackCapacity }
            )
            Divider()
            benefitRow(
                icon: "percent",
                title: "商店折扣",
                values: tiers.map { $0.benefits.shopDiscount }
            )
            Divider()
            benefitRow(
                icon: "location.fill",
                title: "每日传送",
                values: tiers.map { getTeleportLimit(for: $0.tier) }
            )
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }

    private func benefitRow(icon: String, title: String, values: [String]) -> some View {
        HStack(spacing: 0) {
            // Icon + Title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 16)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 100, alignment: .leading)

            Spacer()

            // Values for each tier
            ForEach(Array(tiers.enumerated()), id: \.offset) { index, tier in
                let value = values[index]
                let isSelected = tier.tier == selectedTier

                Text(value)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(valueColor(value, isSelected: isSelected))
                    .frame(maxWidth: .infinity)
                    .opacity(tier.tier == .free ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func valueColor(_ value: String, isSelected: Bool) -> Color {
        if value == "无" || value == "0次" {
            return .secondary
        }
        if isSelected {
            return .green
        }
        return .white
    }

    private func getTeleportLimit(for tier: UserTier) -> String {
        switch tier {
        case .free: return "0次"
        case .support, .lordship, .empire: return "3次"
        case .vip: return "5次"
        }
    }
}

// MARK: - Single Tier Benefits List

/// 单 tier 权益列表 - 用于卡片内展示
struct TierBenefitsList: View {
    let benefits: SubscriptionBenefits
    let tier: UserTier

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            benefitRow(icon: "hammer.fill", text: "建造加速 \(benefits.buildSpeedBonus)")
            benefitRow(icon: "gearshape.fill", text: "生产加速 \(benefits.productionSpeedBonus)")
            benefitRow(icon: "leaf.fill", text: "资源产出 \(benefits.resourceBonus)")
            benefitRow(icon: "backpack.fill", text: "背包容量 \(benefits.backpackCapacity)")

            if benefits.shopDiscount != "无" {
                benefitRow(icon: "tag.fill", text: "商店折扣 \(benefits.shopDiscount)")
            }

            // Special features
            ForEach(benefits.specialFeatures.prefix(3), id: \.self) { feature in
                benefitRow(icon: "star.fill", text: feature)
            }
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.green)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SubscriptionBenefitsComparisonView(
            tiers: SubscriptionProductGroups.all,
            selectedTier: .lordship
        )
        .padding(.horizontal)

        TierBenefitsList(
            benefits: SubscriptionProductGroups.lordPass.benefits,
            tier: .lordship
        )
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    .padding(.vertical)
    .background(Color.black)
}
