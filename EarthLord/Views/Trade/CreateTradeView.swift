//
//  CreateTradeView.swift
//  EarthLord
//
//  创建交易视图 - 发布新的交易交易所
//
//  Created by Claude on 2026-02-26
//

import SwiftUI

struct CreateTradeView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var tradeManager = TradeManager.shared
    @ObservedObject private var inventoryManager = InventoryManager.shared
    
    @State private var tradeMessage: String = ""
    @State private var offeringItems: [TradeItem] = []
    @State private var requestingItems: [TradeItem] = []
    @State private var selectedOfferingItem: String?
    @State private var selectedRequestingItem: String?
    @State private var offeringQuantity: String = "1"
    @State private var requestingQuantity: String = "1"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                    
                    Spacer()
                    
                    Text("发布交易")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                    
                    Spacer()
                    
                    Button("发布") {
                        createTrade()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                    .disabled(isCreating || !isFormValid)
                    .opacity(isFormValid && !isCreating ? 1.0 : 0.5)
                }
                .padding()
                .background(ApocalypseTheme.cardBackground)
                
                Divider()
                
                // MARK: - Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Trading Message
                        VStack(alignment: .leading, spacing: 10) {
                            Text("交易说明（可选）")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            
                            TextEditor(text: $tradeMessage)
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                                .frame(height: 60)
                                .padding(10)
                                .background(ApocalypseTheme.cardBackground)
                                .cornerRadius(8)
                        }
                        
                        // Offering Items
                        VStack(alignment: .leading, spacing: 10) {
                            Text("提供物品")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            
                            itemSelectionForm(
                                label: "选择物品",
                                selectedItem: $selectedOfferingItem,
                                quantity: $offeringQuantity,
                                onAdd: {
                                    if let item = selectedOfferingItem, let qty = Int(offeringQuantity), qty > 0 {
                                        offeringItems.append(TradeItem(itemId: item, quantity: qty))
                                        selectedOfferingItem = nil
                                        offeringQuantity = "1"
                                    }
                                }
                            )
                            
                            // Listed Items
                            ForEach(offeringItems, id: \.itemId) { item in
                                HStack {
                                    Text("\(item.itemId) ×\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(ApocalypseTheme.primary.opacity(0.15))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        offeringItems.removeAll { $0.itemId == item.itemId }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(ApocalypseTheme.danger)
                                    }
                                }
                            }
                        }
                        
                        // Requesting Items
                        VStack(alignment: .leading, spacing: 10) {
                            Text("需要物品")
                                .font(.subheadline.bold())
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            
                            itemSelectionForm(
                                label: "选择物品",
                                selectedItem: $selectedRequestingItem,
                                quantity: $requestingQuantity,
                                onAdd: {
                                    if let item = selectedRequestingItem, let qty = Int(requestingQuantity), qty > 0 {
                                        requestingItems.append(TradeItem(itemId: item, quantity: qty))
                                        selectedRequestingItem = nil
                                        requestingQuantity = "1"
                                    }
                                }
                            )
                            
                            // Listed Items
                            ForEach(requestingItems, id: \.itemId) { item in
                                HStack {
                                    Text("\(item.itemId) ×\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(ApocalypseTheme.primary.opacity(0.15))
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        requestingItems.removeAll { $0.itemId == item.itemId }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(ApocalypseTheme.danger)
                                    }
                                }
                            }
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(ApocalypseTheme.danger)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.danger)
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(ApocalypseTheme.danger.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .background(ApocalypseTheme.background)
            }
            .background(ApocalypseTheme.background)
        }
    }
    
    @ViewBuilder
    private func itemSelectionForm(
        label: String,
        selectedItem: Binding<String?>,
        quantity: Binding<String>,
        onAdd: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Picker(label, selection: selectedItem) {
                Text("--选择--").tag(nil as String?)
                
                ForEach(inventoryManager.items, id: \.itemId) { item in
                    Text("\(item.itemId) (×\(item.quantity))")
                        .tag(item.itemId as String?)
                }
            }
            .frame(maxWidth: .infinity)
            
            TextField("数量", text: quantity)
                .keyboardType(.numberPad)
                .frame(width: 50)
                .padding(8)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(6)
            
            Button("添加") {
                onAdd()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ApocalypseTheme.primary)
            .cornerRadius(6)
            .disabled(selectedItem.wrappedValue == nil || quantity.wrappedValue.isEmpty)
        }
        .padding(10)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(8)
    }
    
    private var isFormValid: Bool {
        !offeringItems.isEmpty && !requestingItems.isEmpty
    }
    
    private func createTrade() {
        guard isFormValid else {
            errorMessage = "请至少添加一个提供物品和需要物品"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await tradeManager.createOffer(
                    offeringItems: offeringItems,
                    requestingItems: requestingItems,
                    message: tradeMessage.isEmpty ? nil : tradeMessage,
                    expiresInHours: 24
                )
                
                LogDebug("✅ [交易] 创建交易成功")
                
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
                LogDebug("❌ [交易] 创建交易失败: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateTradeView_PreviewWrapper()
}

private struct CreateTradeView_PreviewWrapper: View {
    @State private var isPresented = true

    var body: some View {
        CreateTradeView(isPresented: $isPresented)
            .environment(\.colorScheme, .dark)
    }
}
