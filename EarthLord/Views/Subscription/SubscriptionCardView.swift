import SwiftUI

// MARK: - Subscription Card View

/// 订阅卡片组件 - 末日通行证风格设计
/// 左侧: Tier 图标 + 名称 + 价格
/// 右侧: 功能列表 + 选择标记
struct SubscriptionCardView: View {
    let productGroup: SubscriptionProductGroup
    let period: SubscriptionPeriod
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left side: Tier info
                tierInfoSection

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                // Right side: Features + Checkmark
                featuresSection
            }
            .background(cardBackground)
            .overlay(cardBorder)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Tier Info Section (Left)

    private var tierInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(productGroup.iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(productGroup.icon)
                    .font(.title2)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(productGroup.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                if isRecommended {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("推荐")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
                }
            }

            Spacer()

            // Price
            VStack(alignment: .leading, spacing: 2) {
                if productGroup.monthlyPrice > 0 {
                    Text(priceText)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(periodText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if period == .yearly, let savings = savingsText {
                        Text(savings)
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                    }
                } else {
                    Text("免费")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 120, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    productGroup.iconColor.opacity(isSelected ? 0.3 : 0.15),
                    productGroup.iconColor.opacity(isSelected ? 0.15 : 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16, corners: [.topLeft, .bottomLeft])
    }

    // MARK: - Features Section (Right)

    private var featuresSection: some View {
        HStack(spacing: 0) {
            // Features list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getFeatures(for: productGroup.tier), id: \.self) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .green : .secondary)
                            .frame(width: 16)

                        Text(feature)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Selection indicator
            VStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.clear)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }

                Spacer()
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Card Styling

    private var cardBackground: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [productGroup.iconColor, productGroup.iconColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }

    private var cardBorder: some View {
        Group {
            if isRecommended && !isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
        }
    }

    // MARK: - Computed Properties

    private var priceText: String {
        switch period {
        case .monthly:
            return "¥\(productGroup.monthlyPrice)"
        case .yearly:
            return "¥\(productGroup.yearlyPrice)"
        }
    }

    private var periodText: String {
        switch period {
        case .monthly:
            return "/月"
        case .yearly:
            return "/年"
        }
    }

    private var savingsText: String? {
        guard period == .yearly else { return nil }
        let savings = productGroup.yearlySavings
        guard savings > 0 else { return nil }
        return "省 ¥\(savings)"
    }

    // MARK: - Helper Methods

    private func getFeatures(for tier: UserTier) -> [String] {
        switch tier {
        case .free:
            return [
                "基础游戏体验",
                "标准建造速度",
                "标准背包容量"
            ]
        case .support:
            return [
                "建造加速 +20%",
                "生产加速 +15%",
                "背包容量 +25kg",
                "每日传送 3次",
                "商店折扣 10%"
            ]
        case .lordship:
            return [
                "建造加速 +40%",
                "生产加速 +30%",
                "资源产出 +20%",
                "背包容量 +50kg",
                "每周挑战解锁",
                "VIP 称号"
            ]
        case .empire:
            return [
                "建造加速 +60%",
                "生产加速 +50%",
                "资源产出 +40%",
                "背包容量 +100kg",
                "月度宝箱",
                "无限建造队列",
                "24/7 专属客服"
            ]
        case .vip:
            return [
                "建造加速 +20%",
                "交易费减免 20%",
                "月度宝箱",
                "VIP 称号"
            ]
        }
    }
}

// MARK: - Period Toggle

/// 月付/年付切换器
struct PeriodToggleView: View {
    @Binding var selectedPeriod: SubscriptionPeriod

    var body: some View {
        HStack(spacing: 4) {
            ForEach([SubscriptionPeriod.monthly, .yearly], id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(period.displayName)
                            .font(.subheadline.bold())

                        if period == .yearly {
                            Text("省33%")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    .foregroundColor(selectedPeriod == period ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedPeriod == period ?
                        Color.white.opacity(0.15) :
                        Color.clear
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        PeriodToggleView(selectedPeriod: .constant(.monthly))
            .padding(.horizontal)

        SubscriptionCardView(
            productGroup: SubscriptionProductGroups.freePass,
            period: .monthly,
            isSelected: false,
            isRecommended: false,
            onTap: {}
        )
        .padding(.horizontal)

        SubscriptionCardView(
            productGroup: SubscriptionProductGroups.explorerPass,
            period: .monthly,
            isSelected: false,
            isRecommended: false,
            onTap: {}
        )
        .padding(.horizontal)

        SubscriptionCardView(
            productGroup: SubscriptionProductGroups.lordPass,
            period: .yearly,
            isSelected: true,
            isRecommended: true,
            onTap: {}
        )
        .padding(.horizontal)
    }
    .padding(.vertical)
    .background(Color.black)
}
