import Foundation
import SwiftUI

// MARK: - Renewal Offer (续费优惠)

/// 续费优惠模型
struct RenewalOffer: Identifiable, Codable {
    let id: String                     // 优惠 ID
    let offerID: String                // 优惠代码 (用于 App Store)
    let discountPercentage: Int        // 折扣百分比 (20 = 8折)
    let validDays: Int                 // 有效天数 (过期后 N 天内有效)
    let originalProductID: String      // 原产品 ID
    let targetProductID: String        // 目标产品 ID (可以是同产品或更高等级)
    let message: String                // 优惠消息
    let terms: String                  // 条款说明
    let createdAt: Date                // 创建时间
    var expiresAt: Date                // 过期时间
    var isUsed: Bool                   // 是否已使用
    var usedAt: Date?                  // 使用时间

    /// 是否已过期
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// 是否有���
    var isValid: Bool {
        !isUsed && !isExpired
    }

    /// 计算折扣后价格
    /// - Parameter basePrice: 原价
    /// - Returns: 折扣后价格
    func applyDiscount(to basePrice: Int) -> Int {
        let discountAmount = Int(Double(basePrice) * Double(discountPercentage) / 100.0)
        return basePrice - discountAmount
    }

    /// 折扣显示文本
    var discountDisplayText: String {
        "\(discountPercentage)% OFF"
    }

    /// 创建优惠
    static func create(
        offerID: String,
        discountPercentage: Int,
        validDays: Int,
        originalProductID: String,
        targetProductID: String,
        message: String,
        terms: String
    ) -> RenewalOffer {
        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .day, value: validDays, to: now) ?? now

        return RenewalOffer(
            id: UUID().uuidString,
            offerID: offerID,
            discountPercentage: discountPercentage,
            validDays: validDays,
            originalProductID: originalProductID,
            targetProductID: targetProductID,
            message: message,
            terms: terms,
            createdAt: now,
            expiresAt: expiresAt,
            isUsed: false,
            usedAt: nil
        )
    }
}

// MARK: - Renewal Offer Manager (续费优惠管理器)

/// RenewalOfferManager - 续费优惠管理
/// 核心职责:
/// 1. 根据用户 Tier 和过期时间生成续费优惠
/// 2. 管理优惠的有效期和使用状态
/// 3. 计算折扣价格
/// 4. 持久化优惠记录
@MainActor
final class RenewalOfferManager: ObservableObject {
    static let shared = RenewalOfferManager()

    // MARK: - Published Properties

    @Published var availableOffers: [RenewalOffer] = []
    @Published var isLoading = false

    // MARK: - Private Properties

    private let userDefaultsKey = "RenewalOfferManager_offers"

    // MARK: - Init

    private init() {
        loadOffers()
        setupAutoSave()
        cleanExpiredOffers()

        print("✅ RenewalOfferManager 初始化完成")
    }

    deinit {
        // Cleanup if needed
    }

    // MARK: - Public Methods - Offer Generation (优惠生成)

    /// 获取续费优惠
    /// - Parameters:
    ///   - tier: 用户 Tier
    ///   - daysSinceExpiration: 过期天数
    ///   - productGroupID: 产品组 ID
    /// - Returns: 可用的续费优惠，如果没有则返回 nil
    func getRenewalOffer(
        for tier: UserTier,
        daysSinceExpiration: Int,
        productGroupID: String
    ) -> RenewalOffer? {
        // VIP 用户优惠更优厚
        let isVIP = tier == .vip

        // 检查是否在优惠期限内
        let isValidPeriod = isVIP ? daysSinceExpiration <= 14 : daysSinceExpiration <= 7

        guard isValidPeriod, let group = SubscriptionProductGroups.group(for: tier) else {
            return nil
        }

        // 检查是否已有未使用的优惠
        if let existingOffer = availableOffers.first(where: {
            $0.originalProductID == group.monthlyProductID &&
            $0.targetProductID == group.monthlyProductID &&
            $0.isValid
        }) {
            return existingOffer
        }

        // 生成新优惠
        let discountPercentage = isVIP ? 30 : 20  // VIP 7折，普通用户 8折
        let offer = createOfferForProduct(
            group: group,
            discountPercentage: discountPercentage,
            validDays: isVIP ? 14 : 7
        )

        availableOffers.append(offer)
        saveOffers()

        return offer
    }

    /// 为产品创建优惠
    private func createOfferForProduct(
        group: SubscriptionProductGroup,
        discountPercentage: Int,
        validDays: Int
    ) -> RenewalOffer {
        let message = "🎁 欢迎回来！限时 \(discountPercentage)% 折扣专属优惠"
        let terms = "仅限过期后 \(validDays) 天内使用"

        return RenewalOffer.create(
            offerID: "\(group.id)_renewal_\(Int(Date().timeIntervalSince1970))",
            discountPercentage: discountPercentage,
            validDays: validDays,
            originalProductID: group.monthlyProductID,
            targetProductID: group.monthlyProductID,
            message: message,
            terms: terms
        )
    }

    // MARK: - Public Methods - Offer Management (优惠管理)

    /// 使用优惠
    /// - Parameter offerID: 优惠 ID
    /// - Returns: 是否成功使用
    func useOffer(_ offerID: String) -> Bool {
        guard let index = availableOffers.firstIndex(where: { $0.id == offerID }) else {
            return false
        }

        let offer = availableOffers[index]
        guard offer.isValid else {
            return false
        }

        availableOffers[index].isUsed = true
        availableOffers[index].usedAt = Date()

        saveOffers()

        print("✅ [Offer] 优惠已使用: \(offer.offerID)")
        return true
    }

    /// 获取所有有效优惠
    /// - Returns: 有效优惠数组
    func getValidOffers() -> [RenewalOffer] {
        return availableOffers.filter { $0.isValid }
    }

    /// 获取针对特定产品的优惠
    /// - Parameter productID: 产品 ID
    /// - Returns: 有效优惠数组
    func getOffersForProduct(_ productID: String) -> [RenewalOffer] {
        return availableOffers.filter {
            ($0.originalProductID == productID || $0.targetProductID == productID) &&
            $0.isValid
        }
    }

    /// 清理过期优惠
    func cleanExpiredOffers() {
        let beforeCount = availableOffers.count
        availableOffers.removeAll { $0.isExpired && $0.isUsed }

        if availableOffers.count < beforeCount {
            saveOffers()
            print("🧹 [Offer] 清理了 \(beforeCount - availableOffers.count) 个过期优惠")
        }
    }

    // MARK: - Public Methods - Price Calculation (价格计算)

    /// 计算折扣后价格
    /// - Parameters:
    ///   - offer: 优惠
    ///   - basePrice: 原价
    /// - Returns: 折扣后价格
    func calculateDiscountedPrice(for offer: RenewalOffer, basePrice: Int) -> Int {
        return offer.applyDiscount(to: basePrice)
    }

    /// 获取优惠金额
    /// - Parameters:
    ///   - offer: 优惠
    ///   - basePrice: 原价
    /// - Returns: 优惠金额
    func getDiscountAmount(for offer: RenewalOffer, basePrice: Int) -> Int {
        return basePrice - offer.applyDiscount(to: basePrice)
    }

    // MARK: - Private Methods - Persistence (持久化)

    /// 加载优惠记录
    private func loadOffers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let offers = try? JSONDecoder().decode([RenewalOffer].self, from: data) else {
            print("📂 [Offer] 没有找到优惠记录")
            return
        }

        availableOffers = offers
        print("📂 [Offer] 加载了 \(offers.count) 条优惠记录")
    }

    /// 保存优惠记录
    private func saveOffers() {
        guard let data = try? JSONEncoder().encode(availableOffers) else {
            print("❌ [Offer] 保存优惠记录失败")
            return
        }

        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        print("💾 [Offer] 优惠记录已保存")
    }

    /// 设置自动保存
    private func setupAutoSave() {
        // Combine not available, use manual save
    }

    // MARK: - Public Methods - Reset (重置)

    /// 重置所有优惠 (用于测试)
    func resetAllOffers() {
        print("🔄 [Offer] 重置所有优惠记录")

        availableOffers.removeAll()
        saveOffers()

        print("✅ [Offer] 优惠记录已重置")
    }

    /// 标记所有优惠为已使用 (用于测试)
    func markAllAsUsed() {
        print("🔄 [Offer] 标记所有优惠为已使用")

        for index in availableOffers.indices {
            availableOffers[index].isUsed = true
            availableOffers[index].usedAt = Date()
        }

        saveOffers()

        print("✅ [Offer] 所有优惠已标记为使用")
    }

    // MARK: - Public Methods - Debug (调试)

    /// 打印调试信息
    func printDebugInfo() {
        print("📊 [Offer] ===== RenewalOfferManager 调试信息 =====")
        print("📊 [Offer] 优惠记录数: \(availableOffers.count)")

        for offer in availableOffers {
            print("📊 [Offer] - \(offer.offerID):")
            print("    折扣: \(offer.discountPercentage)%")
            print("    状态: \(offer.isUsed ? "已使用" : "未使用")")
            print("    过期: \(offer.isExpired ? "已过期" : "有效")")
            print("    创建: \(offer.createdAt)")
            print("    到期: \(offer.expiresAt)")
        }

        print("📊 [Offer] ===== 调试信息结束 =====")
    }
}

// MARK: - Predefined Offers (预定义优惠)

/// 预定义优惠类型
enum PredefinedOffer {
    case standardRenewal      // 标准续费优惠 (8折, 7天)
    case vipRenewal          // VIP 续费优惠 (7折, 14天)
    case welcomeBack         // 欢迎回归优惠 (5折, 3天)
    case loyaltyBonus        // 忠诚奖励优惠 (6折, 10天)

    var discountPercentage: Int {
        switch self {
        case .standardRenewal:
            return 20
        case .vipRenewal:
            return 30
        case .welcomeBack:
            return 50
        case .loyaltyBonus:
            return 40
        }
    }

    var validDays: Int {
        switch self {
        case .standardRenewal:
            return 7
        case .vipRenewal:
            return 14
        case .welcomeBack:
            return 3
        case .loyaltyBonus:
            return 10
        }
    }

    var displayName: String {
        switch self {
        case .standardRenewal:
            return "标准续费优惠"
        case .vipRenewal:
            return "VIP专属优惠"
        case .welcomeBack:
            return "欢迎回归优惠"
        case .loyaltyBonus:
            return "忠��奖励优惠"
        }
    }

    var message: String {
        switch self {
        case .standardRenewal:
            return "限时8折续费优惠"
        case .vipRenewal:
            return "VIP专属7折优惠"
        case .welcomeBack:
            return "欢迎回来！半价回归优惠"
        case .loyaltyBonus:
            return "老玩家专属6折优惠"
        }
    }
}

// MARK: - Offer Eligibility Checker (优惠资格检查)

/// 优惠资格检查器
struct OfferEligibilityChecker {
    /// 检查用户是否符合续费优惠资格
    /// - Parameters:
    ///   - tier: 用户 Tier
    ///   - daysSinceExpiration: 过期天数
    ///   - subscriptionHistory: 订阅历史 (累计订阅天数)
    /// - Returns: 符合的优惠类型，如果没有符合的返回 nil
    static func checkEligibility(
        tier: UserTier,
        daysSinceExpiration: Int,
        subscriptionHistory: Int
    ) -> PredefinedOffer? {
        // 检查欢迎回归优惠 (过期3天内，累计订阅少于30天)
        if daysSinceExpiration <= 3 && subscriptionHistory < 30 {
            return .welcomeBack
        }

        // 检查忠诚奖励优惠 (过期10天内，累计订阅超过90天)
        if daysSinceExpiration <= 10 && subscriptionHistory > 90 {
            return .loyaltyBonus
        }

        // 检查 VIP 优惠
        if tier == .vip && daysSinceExpiration <= 14 {
            return .vipRenewal
        }

        // 检查标准优惠 (过期7天内)
        if daysSinceExpiration <= 7 {
            return .standardRenewal
        }

        return nil
    }
}
