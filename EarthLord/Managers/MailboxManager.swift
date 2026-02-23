import Foundation
import Supabase
import SwiftUI

// MARK: - DB Model

struct DBMailboxItem: Codable, Identifiable {
    let id: UUID
    let user_id: UUID
    let item_id: String
    let quantity: Int
    let rarity: String
    let product_id: String
    let transaction_id: String?
    let created_at: Date
    let is_claimed: Bool
    let claimed_at: Date?

    // Display helper
    var displayName: String {
        PackItem(itemId: item_id, quantity: quantity, rarity: rarity, guaranteed: true).displayName
    }
}

// MARK: - MailboxManager

@MainActor
class MailboxManager: ObservableObject {

    static let shared = MailboxManager()

    @Published var pendingItems: [DBMailboxItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = supabaseClient

    private init() {}

    // MARK: - Load Pending

    func loadPendingItems() async {
        guard let userId = AuthManager.shared.currentUser?.id.uuidString else {
            LogWarning("⚠️ [邮箱] 用户未登录，无法加载邮箱")
            return
        }

        LogDebug("🔄 [邮箱] 开始加载待领取物资...")
        LogDebug("  - 用户ID: \(userId)")
        isLoading = true
        defer { isLoading = false }

        do {
            let items: [DBMailboxItem] = try await supabase
                .from("purchase_mailbox")
                .select()
                .eq("user_id", value: userId)
                .eq("is_claimed", value: false)
                .order("created_at", ascending: true)
                .execute()
                .value
            pendingItems = items
            LogInfo("✅ [邮箱] 待领取物资: \(items.count) 条")
            for item in items {
                LogDebug("  - \(item.displayName) x\(item.quantity)")
            }
        } catch {
            errorMessage = "加载邮箱失败"
            LogError("❌ [邮箱] 加载失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Add Items (called by StoreManager after purchase)

    func addItems(_ items: [PackItem], productID: String, transactionID: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw MailboxError.notLoggedIn
        }

        struct MailboxInsert: Encodable {
            let user_id: UUID
            let item_id: String
            let quantity: Int
            let rarity: String
            let product_id: String
            let transaction_id: String
        }

        let rows = items.map { item in
            MailboxInsert(
                user_id: userId,
                item_id: item.itemId,
                quantity: item.quantity,
                rarity: item.rarity,
                product_id: productID,
                transaction_id: transactionID
            )
        }

        try await supabase
            .from("purchase_mailbox")
            .insert(rows)
            .execute()

        await loadPendingItems()
    }

    // MARK: - Claim All

    func claimAll() async {
        guard !pendingItems.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        // Check inventory capacity first
        let inventoryManager = InventoryManager.shared
        let totalToClaim = pendingItems.reduce(0) { $0 + $1.quantity }
        let currentCount = inventoryManager.totalItemCount
        let available = inventoryManager.maxCapacity - currentCount

        guard available > 0 else {
            errorMessage = "背包已满，请先整理背包"
            return
        }

        // Determine which items can fit
        var itemsToAdd: [(id: UUID, itemId: String, quantity: Int)] = []
        var remaining = available

        for mailItem in pendingItems {
            guard remaining > 0 else { break }
            let qty = min(mailItem.quantity, remaining)
            itemsToAdd.append((id: mailItem.id, itemId: mailItem.item_id, quantity: qty))
            remaining -= qty
        }

        // Add to inventory + mark claimed
        do {
            for entry in itemsToAdd {
                try await inventoryManager.addItem(itemId: entry.itemId, quantity: entry.quantity)
                try await markClaimed(id: entry.id)
            }

            let claimed = itemsToAdd.count
            let skipped = pendingItems.count - claimed
            if skipped > 0 {
                errorMessage = "背包不足，已领取 \(claimed) 种，\(skipped) 种等待空间"
            }

            await loadPendingItems()
            LogInfo("✅ [邮箱] 领取完成，共 \(claimed) 种")
        } catch {
            errorMessage = "领取失败，请重试"
            LogError("❌ [邮箱] 领取失败: \(error)")
        }
    }

    // MARK: - Claim Single Item

    func claimItem(_ item: DBMailboxItem) async {
        let inventoryManager = InventoryManager.shared
        let available = inventoryManager.maxCapacity - inventoryManager.totalItemCount

        guard available > 0 else {
            errorMessage = "背包已满，无法领取"
            return
        }

        let qty = min(item.quantity, available)
        do {
            try await inventoryManager.addItem(itemId: item.item_id, quantity: qty)
            try await markClaimed(id: item.id)
            await loadPendingItems()
        } catch {
            errorMessage = "领取失败，请重试"
            LogError("❌ [邮箱] 单件领取失败: \(error)")
        }
    }

    // MARK: - Helpers

    private func markClaimed(id: UUID) async throws {
        struct ClaimedUpdate: Encodable {
            let is_claimed: Bool
            let claimed_at: Date
        }
        try await supabase
            .from("purchase_mailbox")
            .update(ClaimedUpdate(is_claimed: true, claimed_at: Date()))
            .eq("id", value: id.uuidString)
            .execute()
    }

    var hasPendingItems: Bool { !pendingItems.isEmpty }
    var pendingCount: Int { pendingItems.count }

    // ✅ 新增：支持 SupplyStationView
    var mailboxItems: [MailboxItem] {
        pendingItems.map { item in
            // 映射 rarity 字符串到 SupplyRarity
            let rarity: SupplyRarity
            switch item.rarity {
            case "common": rarity = .common
            case "rare": rarity = .good
            case "epic": rarity = .excellent
            case "legendary": rarity = .legendary
            default: rarity = .common
            }

            return MailboxItem(
                id: item.id,
                itemName: item.displayName,
                quantity: item.quantity,
                rarity: rarity,
                purchasedAt: item.created_at
            )
        }
    }

    var unclaimedCount: Int { pendingItems.count }

    // ✅ 新增：公共方法
    func fetchMailboxItems() async {
        await loadPendingItems()
    }

    func claimItem(id: UUID) async -> Bool {
        guard let item = pendingItems.first(where: { $0.id == id }) else {
            return false
        }
        await claimItem(item)
        return true
    }
}

// 注意：MailboxItem 和 ItemRarity 已移至 StoreModels.swift 共享文件

enum MailboxError: Error {
    case notLoggedIn
    case capacityFull
}
