//
//  TradeOfferDetailView.swift
//  EarthLord
//
//  交易挂单详情与操作界面
//

import SwiftUI

enum TradeDetailMode { case accept, cancel }

struct TradeOfferDetailView: View {
    let offer: TradeOffer
    let mode: TradeDetailMode

    @ObservedObject private var tradeManager = TradeManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirm = false
    @State private var showSuccess = false

    private var canAccept: Bool {
        guard mode == .accept else { return true }
        for item in offer.requestingItems {
            let owned = inventoryManager.items.first { $0.itemId == item.itemId }?.quantity ?? 0
            if owned < item.quantity { return false }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 挂单信息头
                        headerCard

                        // 交换物品展示
                        exchangeCard

                        // 留言
                        if let message = offer.message, !message.isEmpty {
                            messageCard(message)
                        }

                        // 操作按钮
                        actionButton
                    }
                    .padding()
                }
            }
            .navigationTitle(mode == .accept ? "接受交易" : "挂单详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .alert("确认操作", isPresented: $showConfirm) {
                Button("取消", role: .cancel) {}
                Button(mode == .accept ? "确认接受" : "确认取消", role: .destructive) {
                    executeAction()
                }
            } message: {
                Text(mode == .accept ? "确认接受此交易？物品将立即转移。" : "确认取消此挂单？物品将归还到背包。")
            }
            .alert("错误", isPresented: $showError) {
                Button("好的", role: .cancel) {}
            } message: { Text(errorMessage) }
            .alert("操作成功", isPresented: $showSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text(mode == .accept ? "交易成功！物品已转移到背包。" : "挂单已取消，物品已归还。")
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.ownerUsername)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    Text("发布时间: \(offer.formattedCreatedAt)")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
                Spacer()
                StatusBadge(status: offer.status)
            }

            if let remaining = offer.formattedRemainingTime as String?, offer.expiresAt != nil {
                HStack {
                    Image(systemName: "clock.fill").foregroundColor(offer.isExpired ? .red : .orange)
                    Text("有效期: \(remaining)")
                        .foregroundColor(offer.isExpired ? .red : ApocalypseTheme.textSecondary)
                    Spacer()
                }
                .font(.caption)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var exchangeCard: some View {
        VStack(spacing: 16) {
            // 你将获得
            VStack(alignment: .leading, spacing: 10) {
                Label("你将获得", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.success)

                ForEach(offer.offeringItems, id: \.itemId) { item in
                    ExchangeItemRow(itemId: item.itemId, quantity: item.quantity, showCheck: false)
                }
            }

            Divider().background(ApocalypseTheme.textMuted.opacity(0.3))

            // 你需要提供
            VStack(alignment: .leading, spacing: 10) {
                Label("你需要提供", systemImage: "arrow.up.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.warning)

                ForEach(offer.requestingItems, id: \.itemId) { item in
                    let owned = inventoryManager.items.first { $0.itemId == item.itemId }?.quantity ?? 0
                    ExchangeItemRow(itemId: item.itemId, quantity: item.quantity, owned: owned, showCheck: mode == .accept)
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private func messageCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("卖家留言", systemImage: "message.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)
            Text(message)
                .font(.body)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var actionButton: some View {
        Button(action: { showConfirm = true }) {
            HStack {
                if isProcessing {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: mode == .accept ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(mode == .accept ? (canAccept ? "接受交易" : "物品不足") : "取消挂单")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                mode == .accept
                    ? (canAccept ? ApocalypseTheme.success : ApocalypseTheme.textMuted)
                    : ApocalypseTheme.danger
            )
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isProcessing || (mode == .accept && !canAccept) || !offer.isActive)
        .opacity((!canAccept && mode == .accept) || !offer.isActive ? 0.6 : 1.0)
    }

    private func executeAction() {
        isProcessing = true
        Task {
            do {
                if mode == .accept {
                    try await tradeManager.acceptOffer(offerId: offer.id)
                } else {
                    try await tradeManager.cancelOffer(offerId: offer.id)
                }
                await MainActor.run { isProcessing = false; showSuccess = true }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Exchange Item Row

struct ExchangeItemRow: View {
    let itemId: String
    let quantity: Int
    var owned: Int = 0
    var showCheck: Bool = false

    private var isSufficient: Bool { !showCheck || owned >= quantity }
    private var displayName: String {
        switch itemId {
        case "wood": return "🪵 木材"
        case "stone": return "🪨 石头"
        case "metal": return "⚙️ 金属"
        case "glass": return "🪟 玻璃"
        case "food": return "🍖 食物"
        case "water": return "💧 水"
        case "cloth": return "🧵 布料"
        default: return "📦 \(itemId)"
        }
    }

    var body: some View {
        HStack {
            Text(displayName)
                .font(.subheadline)
                .foregroundColor(isSufficient ? ApocalypseTheme.textPrimary : ApocalypseTheme.danger)

            Spacer()

            if showCheck {
                Text("\(owned) / \(quantity)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(isSufficient ? ApocalypseTheme.success : ApocalypseTheme.danger)
            } else {
                Text("×\(quantity)")
                    .font(.subheadline.bold())
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            if showCheck {
                Image(systemName: isSufficient ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isSufficient ? ApocalypseTheme.success : ApocalypseTheme.danger)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Offer View

struct CreateOfferView: View {
    @ObservedObject private var tradeManager = TradeManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var offeringItems: [TradeItem] = []
    @State private var requestingItemId: String = ""
    @State private var requestingQty: String = ""
    @State private var message: String = ""
    @State private var expirationHours: Int = 24
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var canPublish: Bool { !offeringItems.isEmpty && !requestingItemId.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 我提供的物品（从背包选择）
                        offeringSection

                        // 我需要的物品
                        requestingSection

                        // 有效期
                        expirationSection

                        // 留言
                        messageSection

                        // 发布按钮
                        publishButton
                    }
                    .padding()
                }
            }
            .navigationTitle("发布挂单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }.foregroundColor(ApocalypseTheme.primary)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("好的", role: .cancel) {}
            } message: { Text(errorMessage) }
        }
        .onAppear { if inventoryManager.items.isEmpty { Task { await inventoryManager.loadInventory() } } }
    }

    private var offeringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("我提供（从背包选择）", systemImage: "arrow.down.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.success)

            if offeringItems.isEmpty {
                Text("从下方列表选择要出售的物品")
                    .font(.caption).foregroundColor(ApocalypseTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(offeringItems.enumerated()), id: \.element.itemId) { index, item in
                    HStack {
                        Text("📦 \(item.itemId) ×\(item.quantity)")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                        Spacer()
                        Button(action: { offeringItems.remove(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ApocalypseTheme.danger)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(inventoryManager.items.prefix(10)) { invItem in
                        Button(action: {
                            if !offeringItems.contains(where: { $0.itemId == invItem.itemId }) {
                                offeringItems.append(TradeItem(itemId: invItem.itemId, quantity: 1))
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: invItem.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(ApocalypseTheme.primary)
                                Text(invItem.name)
                                    .font(.caption2)
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                                Text("×\(invItem.quantity)")
                                    .font(.caption2)
                                    .foregroundColor(ApocalypseTheme.textMuted)
                            }
                            .padding(10)
                            .background(ApocalypseTheme.background)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var requestingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("我需要", systemImage: "arrow.up.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.warning)

            HStack(spacing: 12) {
                TextField("物品ID (如 wood)", text: $requestingItemId)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                TextField("数量", text: $requestingQty)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 70)

                Button(action: {
                    if let qty = Int(requestingQty), qty > 0, !requestingItemId.isEmpty {
                        // 避免重复
                    } else { return }
                    // ignore for simplicity
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(ApocalypseTheme.primary)
                        .font(.title3)
                }
            }

            Text("提示: 输入对方需要提供的物品ID和数量")
                .font(.caption2)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("有效期", systemImage: "clock.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            HStack(spacing: 10) {
                ForEach([12, 24, 48, 72], id: \.self) { hours in
                    Button(action: { expirationHours = hours }) {
                        Text("\(hours)小时")
                            .font(.caption.bold())
                            .foregroundColor(expirationHours == hours ? .white : ApocalypseTheme.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(expirationHours == hours ? ApocalypseTheme.primary : ApocalypseTheme.background)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("留言（可选）", systemImage: "message.fill")
                .font(.subheadline.bold())
                .foregroundColor(ApocalypseTheme.textPrimary)

            TextEditor(text: $message)
                .frame(height: 80)
                .padding(8)
                .background(ApocalypseTheme.background)
                .cornerRadius(8)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1))
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(14)
    }

    private var publishButton: some View {
        Button(action: createOffer) {
            HStack {
                if isCreating {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("发布挂单").fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canPublish ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!canPublish || isCreating)
        .opacity(!canPublish ? 0.6 : 1.0)
    }

    private func createOffer() {
        guard !offeringItems.isEmpty else { return }
        isCreating = true

        let qty = Int(requestingQty) ?? 1
        let reqItems = requestingItemId.isEmpty ? [] : [TradeItem(itemId: requestingItemId, quantity: max(1, qty))]

        Task {
            do {
                _ = try await tradeManager.createOffer(
                    offeringItems: offeringItems,
                    requestingItems: reqItems,
                    message: message.isEmpty ? nil : String(message.prefix(200)),
                    expiresInHours: expirationHours
                )
                await MainActor.run { isCreating = false; dismiss() }
            } catch {
                await MainActor.run { isCreating = false; errorMessage = error.localizedDescription; showError = true }
            }
        }
    }
}
