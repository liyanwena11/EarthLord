//
//  TradeMarketView.swift
//  EarthLord
//
//  交易市场页面 - 浏览其他用户的挂单
//

import SwiftUI

struct TradeMarketView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var isLoading = false
    @State private var selectedOffer: TradeOffer?
    
    // 模拟数据 - 用于展示
    private var mockOffers: [TradeOffer] {
        let currentDate = Date()
        let hourLater = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let twoHoursLater = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        
        return [
            TradeOffer(
                id: UUID(),
                ownerId: UUID(),
                ownerUsername: "幸存者_001",
                offeringItems: [
                    TradeItem(itemId: "wood", quantity: 5)
                ],
                requestingItems: [
                    TradeItem(itemId: "glass", quantity: 3)
                ],
                status: .active,
                message: "急需玻璃，用木材交换",
                createdAt: currentDate,
                expiresAt: hourLater,
                completedAt: nil,
                completedByUserId: nil,
                completedByUsername: nil
            ),
            TradeOffer(
                id: UUID(),
                ownerId: UUID(),
                ownerUsername: "幸存者_002",
                offeringItems: [
                    TradeItem(itemId: "stone", quantity: 10)
                ],
                requestingItems: [
                    TradeItem(itemId: "metal", quantity: 5)
                ],
                status: .active,
                message: "石头换金属，比例2:1",
                createdAt: currentDate,
                expiresAt: twoHoursLater,
                completedAt: nil,
                completedByUserId: nil,
                completedByUsername: nil
            )
        ]
    }
    
    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                // 刷新按钮
                HStack {
                    Spacer()
                    refreshButton
                }
                .padding(.horizontal)
                
                // 挂单列表
                if isLoading {
                    loadingView
                } else {
                    // 如果没有真实数据，使用模拟数据
                    let offersToDisplay = tradeManager.marketOffers.isEmpty ? mockOffers : tradeManager.marketOffers
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(offersToDisplay) { offer in
                                TradeOfferCard(offer: offer) {
                                    selectedOffer = offer
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .sheet(item: $selectedOffer) { offer in
            TradeOfferDetailView(offer: offer)
        }
        .onAppear {
            Task {
                await refreshOffers()
            }
        }
    }
    
    // MARK: - 刷新按钮
    private var refreshButton: some View {
        Button(action: {
            Task {
                await refreshOffers()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                Text("刷新")
                    .font(.caption)
            }
            .foregroundColor(ApocalypseTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ApocalypseTheme.primary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .orange))
            Text("加载市场挂单中...").foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bag.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary.opacity(0.6))
            Text("暂无可用的交易挂单")
                .font(.title2.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text("成为第一个发布挂单的幸存者吧")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    // MARK: - 挂单列表
    private var offerList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(tradeManager.marketOffers) { offer in
                    TradeOfferCard(offer: offer) {
                        selectedOffer = offer
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 刷新挂单
    private func refreshOffers() async {
        await MainActor.run { isLoading = true }
        do {
            await tradeManager.fetchMarketOffers()
        } catch {
            LogError("❌ 刷新市场挂单失败: \(error.localizedDescription)")
        }
        await MainActor.run { isLoading = false }
    }
}

// MARK: - 挂单卡片组件
struct TradeOfferCard: View {
    let offer: TradeOffer
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 发布者信息
            HStack(spacing: 8) {
                Image(systemName: "person.circle")
                    .foregroundColor(ApocalypseTheme.primary)
                Text(offer.ownerUsername)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
                Text(offer.formattedRemainingTime)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            
            // 物品信息
            VStack(alignment: .leading, spacing: 8) {
                // 他出的物品
                HStack(spacing: 4) {
                    Text("他出：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(offer.offeringItems))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                
                // 他要的物品
                HStack(spacing: 4) {
                    Text("他要：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(offer.requestingItems))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
            
            // 留言预览
            if let message = offer.message, !message.isEmpty {
                Text("留言：\(message)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .lineLimit(2)
            }
            
            // 查看详情按钮
            HStack {
                Spacer()
                Button(action: onTap) {
                    Text("查看详情")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ApocalypseTheme.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 获取物品名称
    private func getItemName(itemId: String) -> String {
        if let itemDef = InventoryManager.shared.itemDefinitions[itemId] {
            return itemDef.name
        }
        return itemId
    }
    
    // MARK: - 格式化物品列表
    private func formatItems(_ items: [TradeItem]) -> String {
        return items.map { "\(getItemName(itemId: $0.itemId)) ×\($0.quantity)" }.joined(separator: ", ")
    }
}

// MARK: - 预览
struct TradeMarketView_Previews: PreviewProvider {
    static var previews: some View {
        TradeMarketView()
    }
}