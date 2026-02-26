//
//  TradeListView.swift
//  EarthLord
//
//  交易列表视图 - 显示市场中所有活跃交易
//
//  Created by Claude on 2026-02-26
//

import SwiftUI

struct TradeListView: View {
    @ObservedObject private var tradeManager = TradeManager.shared
    @State private var selectedFilter: TradeFilter = .all
    @State private var selectedTrade: TradeOffer?
    
    enum TradeFilter: String, CaseIterable {
        case all = "全部"
        case pending = "待处理"
        case completed = "已完成"
        
        var displayName: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Text("交易市场")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { refreshTrades() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(ApocalypseTheme.primary)
                    }
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                
                Divider()
                
                // MARK: - Filter Tabs
                HStack(spacing: 12) {
                    ForEach(TradeFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter.displayName)
                                .font(.subheadline)
                                .foregroundColor(selectedFilter == filter ? .white : ApocalypseTheme.textSecondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedFilter == filter ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(ApocalypseTheme.background)
                
                Divider()
                
                // MARK: - Content
                if tradeManager.isLoading {
                    loadingView
                } else if filteredTrades.isEmpty {
                    emptyStateView
                } else {
                    tradeListView
                }
            }
            .background(ApocalypseTheme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filteredTrades: [TradeOffer] {
        let allOffers = tradeManager.marketOffers

        switch selectedFilter {
        case .all:
            return allOffers
        case .pending:
            return allOffers.filter { $0.status == .active }
        case .completed:
            return allOffers.filter { $0.status == .completed || $0.status == .cancelled }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
            
            Text("加载中...")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(ApocalypseTheme.textSecondary)
            
            Text("暂无交易")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            
            Text("市场中没有\(selectedFilter.displayName)的交易")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ApocalypseTheme.background)
    }
    
    private var tradeListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredTrades, id: \.id) { trade in
                    NavigationLink(destination: TradeOfferDetailView(offer: trade)) {
                        TradeRowView(offer: trade)
                    }
                }
            }
            .padding()
        }
        .background(ApocalypseTheme.background)
    }
    
    private func refreshTrades() {
        Task {
            await tradeManager.fetchAllData()
        }
    }
}

// MARK: - Trade Row Component

struct TradeRowView: View {
    let offer: TradeOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.ownerUsername)
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text(formatTime(offer.createdAt))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: offer.status.systemIcon)
                    Text(offer.status.displayName)
                }
                .font(.caption.bold())
                .foregroundColor(offer.status == .active ? ApocalypseTheme.primary : ApocalypseTheme.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(offer.status == .active ? ApocalypseTheme.primary.opacity(0.15) : ApocalypseTheme.success.opacity(0.15))
                .cornerRadius(4)
            }

            Divider()

            // Resources
            VStack(alignment: .leading, spacing: 8) {
                Text("提供资源：")
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.textSecondary)

                HStack(spacing: 8) {
                    ForEach(offer.offeringItems.prefix(3), id: \.itemId) { item in
                        HStack(spacing: 4) {
                            Text(item.itemId)
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text("×\(item.quantity)")
                                .font(.caption.bold())
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(4)
                    }

                    if offer.offeringItems.count > 3 {
                        Text("+\(offer.offeringItems.count - 3)")
                            .font(.caption.bold())
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Functions

private func formatTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Preview

#Preview {
    TradeListView()
        .environment(\.colorScheme, .dark)
}
