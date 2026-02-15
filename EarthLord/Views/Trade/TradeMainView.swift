//
//  TradeMainView.swift
//  EarthLord
//
//  交易系统主界面
//

import SwiftUI

enum TradeTab: String, CaseIterable {
    case market = "市场"
    case myOffers = "我的挂单"
    case history = "交易记录"
}

struct TradeMainView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var selectedTab: TradeTab = .market

    var body: some View {
        VStack(spacing: 0) {
            // Tab 选择器
            Picker("", selection: $selectedTab) {
                ForEach(TradeTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(ApocalypseTheme.cardBackground)

            // 内容区
            switch selectedTab {
            case .market:
                MarketOffersListView()
            case .myOffers:
                MyOffersListView()
            case .history:
                TradeHistoryListView()
            }
        }
        .onAppear {
            Task { await tradeManager.fetchAllData() }
        }
    }
}

// MARK: - Market Offers List

struct MarketOffersListView: View {
    @ObservedObject private var tradeManager = TradeManager.shared
    @State private var selectedOffer: TradeOffer?
    @State private var showCreateOffer = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()
                if tradeManager.isLoading {
                    ProgressView("加载中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                } else if tradeManager.marketOffers.isEmpty {
                    TradeEmptyView(icon: "cart", title: "市场空空如也", subtitle: "还没有玩家发布交易挂单")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tradeManager.marketOffers) { offer in
                                TradeOfferCard(offer: offer) { selectedOffer = offer }
                            }
                        }
                        .padding()
                    }
                    .refreshable { await tradeManager.fetchMarketOffers() }
                }
            }

            Button(action: { showCreateOffer = true }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(ApocalypseTheme.primary)
                    .clipShape(Circle())
                    .shadow(color: ApocalypseTheme.primary.opacity(0.4), radius: 8, y: 4)
            }
            .padding(20)
        }
        .sheet(item: $selectedOffer) { offer in
            TradeOfferDetailView(offer: offer, mode: .accept)
        }
        .sheet(isPresented: $showCreateOffer) {
            CreateOfferView()
        }
    }
}

// MARK: - My Offers List

struct MyOffersListView: View {
    @ObservedObject private var tradeManager = TradeManager.shared
    @State private var selectedOffer: TradeOffer?

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            if tradeManager.myOffers.isEmpty {
                TradeEmptyView(icon: "tray", title: "暂无挂单", subtitle: "去市场发布你的第一个交易挂单吧")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tradeManager.myOffers) { offer in
                            TradeOfferCard(offer: offer) { selectedOffer = offer }
                        }
                    }
                    .padding()
                }
                .refreshable { await tradeManager.fetchMyOffers() }
            }
        }
        .sheet(item: $selectedOffer) { offer in
            TradeOfferDetailView(offer: offer, mode: .cancel)
        }
    }
}

// MARK: - Trade History List

struct TradeHistoryListView: View {
    @ObservedObject private var tradeManager = TradeManager.shared

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            if tradeManager.tradeHistory.isEmpty {
                TradeEmptyView(icon: "clock", title: "暂无记录", subtitle: "完成交易后记录会显示在这里")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tradeManager.tradeHistory) { history in
                            TradeHistoryCard(history: history)
                        }
                    }
                    .padding()
                }
                .refreshable { await tradeManager.fetchTradeHistory() }
            }
        }
    }
}

// MARK: - Trade Offer Card

struct TradeOfferCard: View {
    let offer: TradeOffer
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(offer.ownerUsername)
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.textPrimary)
                        Text(offer.formattedCreatedAt)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textMuted)
                    }
                    Spacer()
                    StatusBadge(status: offer.status)
                }

                Divider().background(ApocalypseTheme.textMuted.opacity(0.3))

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("提供").font(.caption).foregroundColor(ApocalypseTheme.success)
                        ForEach(offer.offeringItems, id: \.itemId) { item in
                            Text("\(item.itemId) ×\(item.quantity)")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }

                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(ApocalypseTheme.primary)
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("需要").font(.caption).foregroundColor(ApocalypseTheme.warning)
                        ForEach(offer.requestingItems, id: \.itemId) { item in
                            Text("\(item.itemId) ×\(item.quantity)")
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }

                    Spacer()
                }

                if let remaining = offer.formattedRemainingTime as String?, offer.expiresAt != nil {
                    Text("剩余: \(remaining)")
                        .font(.caption2)
                        .foregroundColor(offer.isExpired ? ApocalypseTheme.danger : ApocalypseTheme.textMuted)
                }
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trade History Card

struct TradeHistoryCard: View {
    let history: TradeHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(history.formattedCompletedAt)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                Spacer()
                Text("完成")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.success)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(ApocalypseTheme.success.opacity(0.15))
                    .cornerRadius(6)
            }

            HStack(spacing: 8) {
                Text(history.sellerUsername)
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.primary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)
                Text(history.buyerUsername)
                    .font(.caption.bold())
                    .foregroundColor(ApocalypseTheme.info)
            }

            // 物品详情
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("卖出").font(.caption2).foregroundColor(ApocalypseTheme.textMuted)
                    ForEach(history.itemsExchanged.sellerGave, id: \.itemId) { item in
                        Text("\(item.itemId) ×\(item.quantity)").font(.caption2).foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
                Image(systemName: "arrow.left.arrow.right").font(.caption2).foregroundColor(ApocalypseTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("买入").font(.caption2).foregroundColor(ApocalypseTheme.textMuted)
                    ForEach(history.itemsExchanged.buyerGave, id: \.itemId) { item in
                        Text("\(item.itemId) ×\(item.quantity)").font(.caption2).foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: TradeOfferStatus

    private var color: Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .gray
        case .expired: return .red
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

// MARK: - Trade Empty View

struct TradeEmptyView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
