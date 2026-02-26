//
//  TradeHistoryView.swift
//  EarthLord
//
//  交易历史页面 - 查看已完成的交易并评价
//

import SwiftUI

struct TradeHistoryView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var isLoading = false
    @State private var historyToRate: TradeHistory?
    @State private var rating: Int = 5
    @State private var comment: String = ""
    
    // 模拟数据 - 用于展示
    private var mockHistory: [TradeHistory] {
        let currentDate = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: currentDate)!
        let currentUserId = AuthManager.shared.currentUser?.id ?? UUID()
        
        return [
            TradeHistory(
                id: UUID(),
                offerId: UUID(),
                sellerId: UUID(), // 卖家是幸存者_001
                sellerUsername: "幸存者_001",
                buyerId: currentUserId, // 买家是当前用户
                buyerUsername: "我",
                itemsExchanged: TradeExchangeInfo(
                    sellerGave: [TradeItem(itemId: "wood", quantity: 5)],
                    buyerGave: [TradeItem(itemId: "glass", quantity: 3)]
                ),
                completedAt: yesterday,
                sellerRating: 5,
                buyerRating: nil,
                sellerComment: "交易很顺利",
                buyerComment: nil
            ),
            TradeHistory(
                id: UUID(),
                offerId: UUID(),
                sellerId: currentUserId, // 卖家是当前用户
                sellerUsername: "我",
                buyerId: UUID(), // 买家是幸存者_002
                buyerUsername: "幸存者_002",
                itemsExchanged: TradeExchangeInfo(
                    sellerGave: [TradeItem(itemId: "stone", quantity: 10)],
                    buyerGave: [TradeItem(itemId: "metal", quantity: 5)]
                ),
                completedAt: twoDaysAgo,
                sellerRating: nil,
                buyerRating: 4,
                sellerComment: nil,
                buyerComment: "物品质量不错"
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
                
                // 交易历史列表
                if isLoading {
                    loadingView
                } else {
                    // 如果没有真实数据，使用模拟数据
                    let historyToDisplay = tradeManager.tradeHistory.isEmpty ? mockHistory : tradeManager.tradeHistory
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(historyToDisplay) { history in
                                historyCard(history)
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
        .sheet(item: $historyToRate) {
            ratingSheet($0)
        }
        .onAppear {
            Task {
                await refreshHistory()
            }
        }
    }
    
    // MARK: - 刷新按钮
    private var refreshButton: some View {
        Button(action: {
            Task {
                await refreshHistory()
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
            Text("加载交易历史中...").foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary.opacity(0.6))
            Text("还没有交易记录")
                .font(.title2.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text("完成第一笔交易后，记录将显示在这里")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    // MARK: - 交易历史列表
    private var historyList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(tradeManager.tradeHistory) { history in
                    historyCard(history)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 交易历史卡片
    private func historyCard(_ history: TradeHistory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 交易对象和时间
            HStack(spacing: 8) {
                Text("与 ")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textMuted)
                Text(getOtherPartyUsername(history))
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.primary)
                Text(" 的交易")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textMuted)
                Spacer()
                Text(history.formattedCompletedAt)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            
            // 物品交换信息
            VStack(alignment: .leading, spacing: 8) {
                // 我给出的物品
                HStack(spacing: 4) {
                    Text("我给出：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(getMyOfferingItems(history)))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                
                // 我获得的物品
                HStack(spacing: 4) {
                    Text("我获得：")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text(formatItems(getMyReceivedItems(history)))
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
            
            // 评价信息
            VStack(alignment: .leading, spacing: 8) {
                // 我的评价
                if getMyRating(history) != nil {
                    HStack(spacing: 4) {
                        Text("我的评价：")
                            .font(.caption.bold())
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) {
                                Image(systemName: $0 <= getMyRating(history) ?? 0 ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        if let myComment = getMyComment(history), !myComment.isEmpty {
                            Text(" \"\(myComment)\"")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                    }
                }
                
                // 对方评价
                if getOtherPartyRating(history) != nil {
                    HStack(spacing: 4) {
                        Text("对方评价：")
                            .font(.caption.bold())
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) {
                                Image(systemName: $0 <= getOtherPartyRating(history) ?? 0 ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        if let otherComment = getOtherPartyComment(history), !otherComment.isEmpty {
                            Text(" \"\(otherComment)\"")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                    }
                }
                
                // 未评价按钮
                if getMyRating(history) == nil {
                    HStack {
                        Spacer()
                        Button(action: {
                            historyToRate = history
                        }) {
                            Text("去评价")
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(ApocalypseTheme.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 评价弹窗
    private func ratingSheet(_ history: TradeHistory) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 交易对象信息
                HStack(spacing: 8) {
                    Image(systemName: "person.circle")
                        .foregroundColor(ApocalypseTheme.primary)
                    Text("与 \(getOtherPartyUsername(history)) 的交易")
                        .font(.subheadline.bold())
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
                
                // 评分提示
                Text("请给这次交易打分：")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                
                // 星级评分
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            rating = star
                        }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(star <= rating ? .yellow : ApocalypseTheme.textMuted)
                        }
                    }
                }
                
                // 评语输入
                Text("评语（可选）：")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("输入您的评价...", text: $comment, axis: .vertical)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
                    .lineLimit(3)
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: {
                        historyToRate = nil
                        rating = 5
                        comment = ""
                    }) {
                        Text("取消")
                            .font(.subheadline.bold())
                            .foregroundColor(ApocalypseTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ApocalypseTheme.cardBackground)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        Task {
                            await submitRating(history)
                        }
                    }) {
                        Text("提交评价")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ApocalypseTheme.primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("评价交易")
            .navigationBarTitleDisplayMode(.inline)
            .background(ApocalypseTheme.background)
        }
    }
    
    // MARK: - 辅助方法
    private func getOtherPartyUsername(_ history: TradeHistory) -> String {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.buyerUsername : history.sellerUsername
    }
    
    private func getMyOfferingItems(_ history: TradeHistory) -> [TradeItem] {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.itemsExchanged.sellerGave : history.itemsExchanged.buyerGave
    }
    
    private func getMyReceivedItems(_ history: TradeHistory) -> [TradeItem] {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.itemsExchanged.buyerGave : history.itemsExchanged.sellerGave
    }
    
    private func getMyRating(_ history: TradeHistory) -> Int? {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.sellerRating : history.buyerRating
    }
    
    private func getMyComment(_ history: TradeHistory) -> String? {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.sellerComment : history.buyerComment
    }
    
    private func getOtherPartyRating(_ history: TradeHistory) -> Int? {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.buyerRating : history.sellerRating
    }
    
    private func getOtherPartyComment(_ history: TradeHistory) -> String? {
        let currentUserId = AuthManager.shared.currentUser?.id
        return history.sellerId == currentUserId ? history.buyerComment : history.sellerComment
    }
    
    // MARK: - 获取物品名称
    private func getItemName(itemId: String) -> String {
        if let itemDef = InventoryManager.shared.itemDefinitions[itemId] {
            return itemDef.name
        }
        return itemId
    }
    
    private func formatItems(_ items: [TradeItem]) -> String {
        return items.map { "\(getItemName(itemId: $0.itemId)) ×\($0.quantity)" }.joined(separator: ", ")
    }
    
    // MARK: - 刷新交易历史
    private func refreshHistory() async {
        await MainActor.run { isLoading = true }
        await tradeManager.fetchTradeHistory()
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - 提交评价
    private func submitRating(_ history: TradeHistory) async {
        do {
            try await tradeManager.addRating(historyId: history.id, rating: rating, comment: comment.isEmpty ? nil : comment)
            await MainActor.run {
                historyToRate = nil
                rating = 5
                comment = ""
            }
            // 显示成功提示
            let alert = UIAlertController(title: "成功", message: "评价提交成功！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            presentAlert(alert)
        } catch {
            LogError("❌ 提交评价失败: \(error.localizedDescription)")
            // 显示失败提示
            let alert = UIAlertController(title: "失败", message: "评价提交失败，请重试。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            presentAlert(alert)
        }
    }
}

// MARK: - TradeHistory 已经在 TradeModels.swift 中实现了 Identifiable 协议

// MARK: - 预览
struct TradeHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TradeHistoryView()
    }
}