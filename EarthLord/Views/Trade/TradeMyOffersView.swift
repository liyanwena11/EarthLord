//
//  TradeMyOffersView.swift
//  EarthLord
//
//  我的挂单页面 - 管理自己发布的挂单
//

import SwiftUI

struct TradeMyOffersView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var isLoading = false
    @State private var showCreateView = false
    @State private var offerToCancel: TradeOffer?
    
    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                // 发布新挂单按钮
                createOfferButton
                
                // 挂单列表
                if isLoading {
                    loadingView
                } else if tradeManager.myOffers.isEmpty {
                    emptyStateView
                } else {
                    offerList
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showCreateView) {
            // 创建一个临时视图来处理参数传递
            CreateOfferWrapper()
        }
        .alert(item: $offerToCancel) { offer in
            Alert(
                title: Text("取消挂单"),
                message: Text("确定要取消这个挂单吗？物品将被退回您的背包。"),
                primaryButton: .destructive(Text("确定")) {
                    Task {
                        await cancelOffer(offer)
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .onAppear {
            Task {
                await refreshOffers()
            }
        }
    }
    
    // MARK: - 刷新挂单
    private func refreshOffers() async {
        await MainActor.run { isLoading = true }
        do {
            await tradeManager.fetchMyOffers()
        } catch {
            LogError("❌ 刷新我的挂单失败: \(error.localizedDescription)")
        }
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - 发布新挂单按钮
    private var createOfferButton: some View {
        Button(action: {
            showCreateView = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("发布新挂单")
            }
            .font(.subheadline.bold())
            .foregroundColor(ApocalypseTheme.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ApocalypseTheme.primary.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ApocalypseTheme.primary.opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal)
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .orange))
            Text("加载我的挂单中...").foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary.opacity(0.6))
            Text("还没有发布过挂单")
                .font(.title2.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text("点击上方按钮发布您的第一个挂单")
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
                ForEach(tradeManager.myOffers) { offer in
                    myOfferCard(offer: offer)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 我的挂单卡片
    private func myOfferCard(offer: TradeOffer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 状态和时间
            HStack(spacing: 8) {
                MyOfferStatusBadge(status: offer.status)
                Spacer()
                Text(offer.formattedRemainingTime)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            
            // 物品信息
            VStack(alignment: .leading, spacing: 8) {
                // 我出的物品
                HStack(spacing: 4) {
                    Text("我出：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(offer.offeringItems))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                
                // 我要的物品
                HStack(spacing: 4) {
                    Text("我要：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(offer.requestingItems))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
            
            // 完成信息
            if offer.status == .completed, let acceptor = offer.completedByUsername {
                HStack(spacing: 4) {
                    Text("被 ")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                    Text(acceptor)
                        .font(.caption.bold())
                        .foregroundColor(ApocalypseTheme.primary)
                    Text(" 接受")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }
            
            // 操作按钮
            if offer.status == .active {
                HStack {
                    Spacer()
                    Button(action: {
                        offerToCancel = offer
                    }) {
                        Text("取消挂单")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.danger)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ApocalypseTheme.danger.opacity(0.1))
                            .cornerRadius(8)
                    }
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
    
    // MARK: - 取消挂单
    private func cancelOffer(_ offer: TradeOffer) async {
        await MainActor.run { isLoading = true }
        do {
            try await tradeManager.cancelOffer(offerId: offer.id)
            await MainActor.run { isLoading = false }
            // 显示成功提示
            let alert = UIAlertController(title: "成功", message: "挂单已取消，物品已退回您的背包。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        } catch {
            LogError("❌ 取消挂单失败: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
            // 显示失败提示
            let alert = UIAlertController(title: "失败", message: "取消挂单失败，请重试。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - 状态标签组件
struct MyOfferStatusBadge: View {
    let status: TradeOfferStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return ApocalypseTheme.info
        case .completed: return ApocalypseTheme.success
        case .cancelled: return ApocalypseTheme.textMuted
        case .expired: return ApocalypseTheme.warning
        }
    }
}

// MARK: - TradeOffer 已经在 TradeModels.swift 中实现了 Identifiable 协议

// MARK: - CreateOfferWrapper
struct CreateOfferWrapper: View {
    @State private var selectedTab: TradeMainView.TradeTab = .create
    var body: some View {
        TradeCreateView(selectedTab: $selectedTab)
    }
}

// MARK: - 预览
struct TradeMyOffersView_Previews: PreviewProvider {
    static var previews: some View {
        TradeMyOffersView()
    }
}