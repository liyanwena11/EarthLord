//
//  TradeManager.swift
//  EarthLord
//
//  交易管理器 - 单例模式
//

import Foundation
import Supabase
import Combine

class TradeManager: ObservableObject {

    static let shared = TradeManager()

    @Published var marketOffers: [TradeOffer] = []
    @Published var myOffers: [TradeOffer] = []
    @Published var tradeHistory: [TradeHistory] = []
    @Published var pendingItems: [PendingItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient
    private var expirationCheckTimer: Timer?

    private init() {
        startExpirationCheck()
        print("💰 [交易] TradeManager 初始化完成")
    }

    private func currentUserId() async -> UUID? {
        await MainActor.run { AuthManager.shared.currentUser?.id }
    }
    private func currentUsername() async -> String {
        await MainActor.run {
            AuthManager.shared.currentUser?.email?.components(separatedBy: "@").first ?? "幸存者"
        }
    }

    // MARK: - Validation

    func canCreateOffer(offeringItems: [TradeItem]) -> (canCreate: Bool, error: TradeError?) {
        let inventory = InventoryManager.shared
        var missingItems: [String: Int] = [:]
        for item in offeringItems {
            guard item.quantity > 0 else { return (false, .invalidQuantity) }
            let available = inventory.items.first { $0.itemId == item.itemId }?.quantity ?? 0
            if available < item.quantity { missingItems[item.itemId] = item.quantity - available }
        }
        if !missingItems.isEmpty { return (false, .insufficientItems(missingItems)) }
        return (true, nil)
    }

    // MARK: - Create Offer

    func createOffer(offeringItems: [TradeItem], requestingItems: [TradeItem], message: String?, expiresInHours: Int?) async throws -> UUID {
        guard let userId = await currentUserId() else { throw TradeError.notConfigured }
        let username = await currentUsername()

        // 锁定背包物品
        for item in offeringItems {
            try await InventoryManager.shared.removeItem(itemId: item.itemId, quantity: item.quantity)
        }

        let offeringJSON = offeringItems.map { ["item_id": $0.itemId, "quantity": $0.quantity] as [String: Any] }
        let requestingJSON = requestingItems.map { ["item_id": $0.itemId, "quantity": $0.quantity] as [String: Any] }

        struct CreateOfferParams: Encodable {
            let p_owner_id: String
            let p_owner_username: String
            let p_offering_items: String
            let p_requesting_items: String
            let p_message: String?
            let p_expires_in_hours: Int?
        }

        let offeringData = try JSONSerialization.data(withJSONObject: offeringJSON)
        let requestingData = try JSONSerialization.data(withJSONObject: requestingJSON)

        let params = CreateOfferParams(
            p_owner_id: userId.uuidString,
            p_owner_username: username,
            p_offering_items: String(data: offeringData, encoding: .utf8) ?? "[]",
            p_requesting_items: String(data: requestingData, encoding: .utf8) ?? "[]",
            p_message: message,
            p_expires_in_hours: expiresInHours
        )

        let response: CreateTradeOfferResponse = try await supabase
            .rpc("create_trade_offer", params: params)
            .execute()
            .value

        guard response.success, let offerId = response.offerId else {
            // 回滚：归还物品
            for item in offeringItems {
                try? await InventoryManager.shared.addItem(itemId: item.itemId, quantity: item.quantity)
            }
            throw TradeError.rpcError(response.error ?? "创建挂单失败")
        }

        await fetchMyOffers()
        print("💰 [交易] ✅ 创建挂单成功: \(offerId)")
        return offerId
    }

    // MARK: - Accept Offer

    func acceptOffer(offerId: UUID) async throws {
        guard let userId = await currentUserId() else { throw TradeError.notConfigured }
        let username = await currentUsername()

        guard let offer = marketOffers.first(where: { $0.id == offerId }) else {
            throw TradeError.offerNotFound
        }
        guard offer.isActive else { throw TradeError.offerNotActive }
        guard offer.ownerId != userId else { throw TradeError.cannotAcceptOwnOffer }

        // 验证并锁定请求物品
        for item in offer.requestingItems {
            let available = InventoryManager.shared.items.first { $0.itemId == item.itemId }?.quantity ?? 0
            if available < item.quantity {
                throw TradeError.insufficientItems([item.itemId: item.quantity - available])
            }
        }
        for item in offer.requestingItems {
            try await InventoryManager.shared.removeItem(itemId: item.itemId, quantity: item.quantity)
        }

        struct AcceptParams: Encodable {
            let p_offer_id: String
            let p_buyer_id: String
            let p_buyer_username: String
        }

        let params = AcceptParams(
            p_offer_id: offerId.uuidString,
            p_buyer_id: userId.uuidString,
            p_buyer_username: username
        )

        let response: AcceptTradeOfferResponse = try await supabase
            .rpc("accept_trade_offer", params: params)
            .execute()
            .value

        guard response.success else {
            for item in offer.requestingItems {
                try? await InventoryManager.shared.addItem(itemId: item.itemId, quantity: item.quantity)
            }
            throw TradeError.rpcError(response.error ?? "接受挂单失败")
        }

        // 领取获得的物品
        for item in offer.offeringItems {
            try? await InventoryManager.shared.addItem(itemId: item.itemId, quantity: item.quantity)
        }

        await fetchMarketOffers()
        await fetchMyOffers()
        print("💰 [交易] ✅ 接受挂单成功")
    }

    // MARK: - Cancel Offer

    func cancelOffer(offerId: UUID) async throws {
        guard let offer = myOffers.first(where: { $0.id == offerId }) else {
            throw TradeError.offerNotFound
        }

        struct CancelParams: Encodable { let p_offer_id: String }
        let response: CancelTradeOfferResponse = try await supabase
            .rpc("cancel_trade_offer", params: CancelParams(p_offer_id: offerId.uuidString))
            .execute()
            .value

        guard response.success else {
            throw TradeError.rpcError(response.error ?? "取消挂单失败")
        }

        // 归还物品
        for item in offer.offeringItems {
            try? await InventoryManager.shared.addItem(itemId: item.itemId, quantity: item.quantity)
        }

        await fetchMyOffers()
        print("💰 [交易] ✅ 取消挂单成功")
    }

    // MARK: - Fetch Methods

    func fetchMarketOffers() async {
        guard let userId = await currentUserId() else { return }

        await MainActor.run { self.isLoading = true }

        do {
            let offers: [TradeOffer] = try await supabase
                .from("trade_offers")
                .select()
                .eq("status", value: "active")
                .neq("owner_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run { self.marketOffers = offers.filter { $0.isActive }; self.isLoading = false }
        } catch {
            print("❌ [交易] 获取市场挂单失败: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false }
        }
    }

    func fetchMyOffers() async {
        guard let userId = await currentUserId() else { return }

        do {
            let offers: [TradeOffer] = try await supabase
                .from("trade_offers")
                .select()
                .eq("owner_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run { self.myOffers = offers }
        } catch {
            print("❌ [交易] 获取我的挂单失败: \(error.localizedDescription)")
        }
    }

    func fetchTradeHistory() async {
        guard let userId = await currentUserId() else { return }

        do {
            let history: [TradeHistory] = try await supabase
                .from("trade_history")
                .select()
                .or("seller_id.eq.\(userId.uuidString),buyer_id.eq.\(userId.uuidString)")
                .order("completed_at", ascending: false)
                .execute()
                .value

            await MainActor.run { self.tradeHistory = history }
        } catch {
            print("❌ [交易] 获取交易历史失败: \(error.localizedDescription)")
        }
    }

    func fetchAllData() async {
        await fetchMarketOffers()
        await fetchMyOffers()
        await fetchTradeHistory()
    }

    // MARK: - Rating

    func addRating(historyId: UUID, rating: Int, comment: String?) async throws {
        guard let userId = await currentUserId() else { throw TradeError.notConfigured }
        guard rating >= 1 && rating <= 5 else { throw TradeError.invalidRating }

        guard let history = tradeHistory.first(where: { $0.id == historyId }) else {
            throw TradeError.historyNotFound
        }

        let isSeller = history.sellerId == userId
        if isSeller && history.sellerRating != nil { throw TradeError.alreadyRated }
        if !isSeller && history.buyerRating != nil { throw TradeError.alreadyRated }

        let update = TradeRatingUpdate(
            seller_rating: isSeller ? rating : nil,
            buyer_rating: !isSeller ? rating : nil,
            seller_comment: isSeller ? comment : nil,
            buyer_comment: !isSeller ? comment : nil
        )

        try await supabase
            .from("trade_history")
            .update(update)
            .eq("id", value: historyId.uuidString)
            .execute()

        await fetchTradeHistory()
    }

    // MARK: - Expiration Check

    private func startExpirationCheck() {
        expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task {
                try? await self?.processExpiredOffers()
                await self?.fetchMarketOffers()
            }
        }
    }

    private func processExpiredOffers() async throws {
        try await supabase.rpc("process_expired_trade_offers").execute()
    }

    deinit { expirationCheckTimer?.invalidate() }
}
