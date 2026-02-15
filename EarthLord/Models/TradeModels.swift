//
//  TradeModels.swift
//  EarthLord
//
//  交易系统数据模型
//

import Foundation

// MARK: - TradeOfferStatus

enum TradeOfferStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .active: return "可交易"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .expired: return "已过期"
        }
    }
}

// MARK: - TradeItem

struct TradeItem: Codable, Equatable, Hashable {
    let itemId: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case quantity
    }

    func toDictionary() -> [String: Any] {
        return ["item_id": itemId, "quantity": quantity]
    }
}

// MARK: - TradeOffer

struct TradeOffer: Codable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let ownerUsername: String
    let offeringItems: [TradeItem]
    let requestingItems: [TradeItem]
    let status: TradeOfferStatus
    let message: String?
    let createdAt: Date
    let expiresAt: Date?
    let completedAt: Date?
    let completedByUserId: UUID?
    let completedByUsername: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case ownerUsername = "owner_username"
        case offeringItems = "offering_items"
        case requestingItems = "requesting_items"
        case status, message
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
        case completedByUserId = "completed_by_user_id"
        case completedByUsername = "completed_by_username"
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt <= Date()
    }

    var isActive: Bool { status == .active && !isExpired }

    var formattedCreatedAt: String {
        let f = DateFormatter(); f.dateFormat = "MM-dd HH:mm"
        return f.string(from: createdAt)
    }

    var remainingTime: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        let r = expiresAt.timeIntervalSince(Date())
        return r > 0 ? r : 0
    }

    var formattedRemainingTime: String {
        guard let r = remainingTime else { return "永久" }
        if r <= 0 { return "已过期" }
        let hours = Int(r) / 3600
        let minutes = (Int(r) % 3600) / 60
        return hours > 0 ? "\(hours)小时\(minutes)分" : "\(minutes)分钟"
    }
}

// MARK: - TradeExchangeInfo

struct TradeExchangeInfo: Codable {
    let sellerGave: [TradeItem]
    let buyerGave: [TradeItem]

    enum CodingKeys: String, CodingKey {
        case sellerGave = "seller_gave"
        case buyerGave = "buyer_gave"
    }
}

// MARK: - TradeHistory

struct TradeHistory: Codable, Identifiable {
    let id: UUID
    let offerId: UUID
    let sellerId: UUID
    let sellerUsername: String
    let buyerId: UUID
    let buyerUsername: String
    let itemsExchanged: TradeExchangeInfo
    let completedAt: Date
    var sellerRating: Int?
    var buyerRating: Int?
    var sellerComment: String?
    var buyerComment: String?

    enum CodingKeys: String, CodingKey {
        case id
        case offerId = "offer_id"
        case sellerId = "seller_id"
        case sellerUsername = "seller_username"
        case buyerId = "buyer_id"
        case buyerUsername = "buyer_username"
        case itemsExchanged = "items_exchanged"
        case completedAt = "completed_at"
        case sellerRating = "seller_rating"
        case buyerRating = "buyer_rating"
        case sellerComment = "seller_comment"
        case buyerComment = "buyer_comment"
    }

    var formattedCompletedAt: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: completedAt)
    }
}

// MARK: - TradeError

enum TradeError: LocalizedError {
    case notConfigured
    case insufficientItems([String: Int])
    case offerNotFound, offerNotActive, offerExpired
    case cannotAcceptOwnOffer, invalidQuantity
    case databaseError(Error), rpcError(String), inventoryError(Error)
    case historyNotFound, alreadyRated, invalidRating

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "交易系统未配置"
        case .insufficientItems(let m):
            return "物品不足，还需要: \(m.map { "\($0.key):\($0.value)" }.joined(separator: ", "))"
        case .offerNotFound: return "交易挂单不存在"
        case .offerNotActive: return "交易挂单已不可用"
        case .offerExpired: return "交易挂单已过期"
        case .cannotAcceptOwnOffer: return "不能接受自己的挂单"
        case .invalidQuantity: return "物品数量无效"
        case .databaseError(let e): return "数据库错误: \(e.localizedDescription)"
        case .rpcError(let m): return "交易失败: \(m)"
        case .inventoryError(let e): return "库存操作失败: \(e.localizedDescription)"
        case .historyNotFound: return "交易记录不存在"
        case .alreadyRated: return "已经评价过了"
        case .invalidRating: return "评分必须在1-5之间"
        }
    }
}

// MARK: - RPC Response Models

struct CreateTradeOfferResponse: Codable {
    let success: Bool
    let offerId: UUID?
    let error: String?
    enum CodingKeys: String, CodingKey {
        case success; case offerId = "offer_id"; case error
    }
}

struct AcceptTradeOfferResponse: Codable {
    let success: Bool
    let historyId: UUID?
    let error: String?
    enum CodingKeys: String, CodingKey {
        case success; case historyId = "history_id"; case error
    }
}

struct CancelTradeOfferResponse: Codable {
    let success: Bool
    let error: String?
}

struct ProcessExpiredOffersResponse: Codable {
    let processedCount: Int
    enum CodingKeys: String, CodingKey {
        case processedCount = "processed_count"
    }
}

// MARK: - PendingItem

struct PendingItem: Codable, Identifiable {
    let id: UUID
    let itemId: String
    let quantity: Int
    let sourceType: String
    let sourceDescription: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case itemId = "item_id"; case quantity
        case sourceType = "source_type"
        case sourceDescription = "source_description"
        case createdAt = "created_at"
    }

    var formattedCreatedAt: String {
        let f = DateFormatter(); f.dateFormat = "MM-dd HH:mm"
        return f.string(from: createdAt)
    }

    var sourceTypeDisplayName: String {
        switch sourceType {
        case "trade": return "交易"
        case "gift": return "赠送"
        case "reward": return "奖励"
        default: return sourceType
        }
    }
}

struct GetPendingItemsResponse: Codable {
    let success: Bool; let items: [PendingItem]?; let error: String?
}

struct ClaimPendingItemResponse: Codable {
    let success: Bool; let itemId: String?; let quantity: Int?; let error: String?
    enum CodingKeys: String, CodingKey {
        case success; case itemId = "item_id"; case quantity; case error
    }
}

struct ClaimAllPendingItemsResponse: Codable {
    let success: Bool; let items: [TradeItem]?; let claimedCount: Int?; let error: String?
    enum CodingKeys: String, CodingKey {
        case success; case items
        case claimedCount = "claimed_count"; case error
    }
}

// MARK: - Update Models

struct TradeOfferStatusUpdate: Encodable {
    let status: String
    let updated_at: Date
    init(status: TradeOfferStatus) {
        self.status = status.rawValue
        self.updated_at = Date()
    }
}

struct TradeRatingUpdate: Encodable {
    let seller_rating: Int?
    let buyer_rating: Int?
    let seller_comment: String?
    let buyer_comment: String?
}
