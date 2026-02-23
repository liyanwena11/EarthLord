//
//  MarketView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  实时交易市场视图
//

import SwiftUI
import Supabase

struct MarketView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var marketListings: [MarketListing] = []
    @State private var isLoading = false
    @State private var selectedCategory: MarketCategory? = nil
    @State private var showCreateListing = false
    @State private var selectedListing: MarketListing?
    @State private var showTradeDetail = false
    @State private var errorMessage: String?

    enum MarketCategory: String, CaseIterable {
        case all = "全部"
        case food = "食物"
        case water = "水"
        case material = "材料"
        case medical = "医疗"
        case tool = "工具"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .food: return "leaf.fill"
            case .water: return "drop.fill"
            case .material: return "cube.fill"
            case .medical: return "cross.fill"
            case .tool: return "wrench.fill"
            }
        }
    }

    var filteredListings: [MarketListing] {
        if let category = selectedCategory {
            return marketListings.filter { listing in
                listing.offer.keys.contains(category.rawValue)
            }
        }
        return marketListings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MarketCategory.allCases, id: \.self) { category in
                            MarketCategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(ApocalypseTheme.cardBackground)

                Divider()

                // 市场列表
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if filteredListings.isEmpty {
                    EmptyMarketView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredListings) { listing in
                                MarketListingCard(listing: listing) {
                                    selectedListing = listing
                                    showTradeDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("全球交易市场")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateListing = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await loadMarketListings()
                setupRealtimeSubscription()
            }
            .sheet(isPresented: $showCreateListing) {
                CreateListingView()
            }
            .sheet(isPresented: $showTradeDetail) {
                if let listing = selectedListing {
                    TradeDetailView(listing: listing)
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func loadMarketListings() async {
        isLoading = true

        // 调用 TradeManager 获取市场挂单
        await TradeManager.shared.fetchMarketOffers()

        // 等待一下让数据加载完成
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 从 TradeManager 获取已加载的市场挂单
        let offers = TradeManager.shared.marketOffers
        var listings: [MarketListing] = []
        for offer in offers {
            listings.append(convertToMarketListing(offer))
        }

        await MainActor.run {
            self.marketListings = listings
            self.isLoading = false
        }
    }

    private func convertToMarketListing(_ offer: TradeOffer) -> MarketListing {
        var offerDict: [String: Int] = [:]
        for item in offer.offeringItems {
            offerDict[item.itemId, default: 0] += item.quantity
        }

        var requestDict: [String: Int] = [:]
        for item in offer.requestingItems {
            requestDict[item.itemId, default: 0] += item.quantity
        }

        return MarketListing(
            id: offer.id.uuidString,
            sellerId: offer.ownerId.uuidString,
            sellerName: offer.ownerUsername,
            offer: offerDict,
            request: requestDict,
            createdAt: offer.createdAt,
            expiresAt: offer.expiresAt,
            isActive: offer.isActive
        )
    }

    private func setupRealtimeSubscription() {
        // 注意: Supabase实时订阅功能已禁用，改用定时刷新
        // 如果需要启用实时功能，请参考Supabase文档正确配置RealtimeChannel
        Task {
            // 定期刷新市场数据（每30秒）
            while true {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await loadMarketListings()
            }
        }
    }
}

// MARK: - MarketListing

struct MarketListing: Identifiable, Codable {
    let id: String
    let sellerId: String
    let sellerName: String
    let offer: [String: Int]
    let request: [String: Int]
    let createdAt: Date
    let expiresAt: Date?
    let isActive: Bool

    var isExpired: Bool {
        guard let expiry = expiresAt else { return false }
        return Date() > expiry
    }

    var formattedTimeRemaining: String {
        guard let expiry = expiresAt else { return "永久" }
        let remaining = max(expiry.timeIntervalSince(Date()), 0)
        if remaining <= 0 { return "已过期" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - MarketCategoryButton

struct MarketCategoryButton: View {
    let category: MarketView.MarketCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.background)
            .cornerRadius(8)
        }
    }
}

// MARK: - MarketListingCard

struct MarketListingCard: View {
    let listing: MarketListing
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(ApocalypseTheme.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.primary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.sellerName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                        Text(listing.formattedTimeRemaining)
                            .font(.caption2)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }

                Spacer()

                if listing.isExpired {
                    MarketStatusBadge(text: "已过期", color: ApocalypseTheme.textMuted)
                } else if !listing.isActive {
                    MarketStatusBadge(text: "已交易", color: ApocalypseTheme.info)
                }
            }

            Divider()

            // 交易内容
            HStack(alignment: .center, spacing: 12) {
                // 我提供
                VStack(alignment: .leading, spacing: 6) {
                    Text("提供")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    ForEach(listing.offer.keys.sorted(), id: \.self) { resource in
                        HStack(spacing: 4) {
                            Image(systemName: "square.fill")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.success)
                            Text("\(resource) x\(listing.offer[resource]!)")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                        }
                    }
                }

                // 交换箭头
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(ApocalypseTheme.primary)

                // 我需要
                VStack(alignment: .leading, spacing: 6) {
                    Text("需求")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    ForEach(listing.request.keys.sorted(), id: \.self) { resource in
                        HStack(spacing: 4) {
                            Image(systemName: "square.fill")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.warning)
                            Text("\(resource) x\(listing.request[resource]!)")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(listing.isExpired ? ApocalypseTheme.textMuted.opacity(0.3) : ApocalypseTheme.primary.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !listing.isExpired && listing.isActive {
                onTap()
            }
        }
    }
}

// MARK: - MarketStatusBadge

struct MarketStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - EmptyMarketView

struct EmptyMarketView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "storefront")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textMuted)
            Text("暂无交易")
                .font(.title3)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text("发布你的第一个交易吧")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - TradeDetailView

struct TradeDetailView: View {
    let listing: MarketListing
    @Environment(\.dismiss) private var dismiss
    @State private var isAccepting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 交易详情
                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(ApocalypseTheme.primary.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(ApocalypseTheme.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.sellerName)
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            Text("发布于 \(listing.createdAt, style: .relative)")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }

                        Spacer()
                    }

                    Divider()

                    // 交易详情
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("你将提供")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)

                            ForEach(listing.request.keys.sorted(), id: \.self) { resource in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ApocalypseTheme.warning)
                                    Text("\(resource) x\(listing.request[resource]!)")
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("你将获得")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)

                            ForEach(listing.offer.keys.sorted(), id: \.self) { resource in
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ApocalypseTheme.success)
                                    Text("\(resource) x\(listing.offer[resource]!)")
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)

                Spacer()

                // 接受交易按钮
                if isAccepting {
                    ProgressView()
                } else {
                    Button {
                        acceptTrade()
                    } label: {
                        Text("接受交易")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(ApocalypseTheme.primary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(ApocalypseTheme.background)
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func acceptTrade() {
        isAccepting = true
        Task {
            do {
                // TODO: 实现接受交易逻辑
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    isAccepting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAccepting = false
                }
            }
        }
    }
}

// 预览
#Preview {
    MarketView()
}
