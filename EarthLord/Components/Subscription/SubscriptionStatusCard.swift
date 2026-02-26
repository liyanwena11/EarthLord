import SwiftUI

// MARK: - Subscription Status Card

/// 订阅状态卡片 - 显示当前订阅状态
struct SubscriptionStatusCard: View {
    let currentTier: UserTier
    let remainingDays: Int
    let isAutoRenewalEnabled: Bool
    let onRestorePurchase: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("订阅中心")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 8) {
                    Button(action: onRestorePurchase) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                    }

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }

            // Status Info
            HStack(spacing: 12) {
                // Tier Badge
                HStack(spacing: 6) {
                    Text(currentTier.badgeEmoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentTier.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

                        if remainingDays > 0 && remainingDays < Int.max {
                            Text("剩余 \(remainingDays) 天")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        } else if remainingDays == 0 {
                            Text("已过期")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("永久有效")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                // Auto-renewal Status
                if isAutoRenewalEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("自动续费")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [currentTier.badgeColor.opacity(0.3), currentTier.badgeColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SubscriptionStatusCard(
            currentTier: .lordship,
            remainingDays: 28,
            isAutoRenewalEnabled: true,
            onRestorePurchase: {},
            onClose: {}
        )

        SubscriptionStatusCard(
            currentTier: .free,
            remainingDays: 0,
            isAutoRenewalEnabled: false,
            onRestorePurchase: {},
            onClose: {}
        )
    }
    .padding()
    .background(Color.black)
}
