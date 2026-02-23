//
//  StoreModels.swift
//  EarthLord
//
//  商城系统共享模型
//

import Foundation
import SwiftUI

// MARK: - SupplyRarity 枚举（商城专用）

enum SupplyRarity {
    case common, good, excellent, legendary

    var color: Color {
        switch self {
        case .common: return .gray
        case .good: return .green
        case .excellent: return .blue
        case .legendary: return .orange
        }
    }
}

// MARK: - MailboxItem 模型（共享）

struct MailboxItem: Identifiable {
    let id: UUID
    let itemName: String
    let quantity: Int
    let rarity: SupplyRarity
    let purchasedAt: Date
}

// MARK: - SupplyProductData 模型（共享）

struct SupplyProductData: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: String
    let iconName: String
    let rarity: SupplyRarity
    let previewItems: [String]
}
