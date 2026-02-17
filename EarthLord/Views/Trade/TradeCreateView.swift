//
//  TradeCreateView.swift
//  EarthLord
//
//  发布挂单页面 - 创建新的交易挂单
//

import SwiftUI

struct TradeCreateView: View {
    @Binding var selectedTab: TradeMainView.TradeTab
    @State private var offeringItems: [TradeItem] = []
    @State private var requestingItems: [TradeItem] = []
    @State private var expiresInHours: Int = 24
    @State private var message: String = ""
    @State private var isLoading = false
    @State private var showItemSelector = false
    @State private var isSelectingOffering = false
    @State private var tempSelectedItems: [TradeItem] = []
    
    private let expirationOptions = [1, 6, 12, 24, 48, 72]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 我要出的物品
                        offeringItemsSection
                        
                        // 我想要的物品
                        requestingItemsSection
                        
                        // 有效期
                        expirationSection
                        
                        // 留言
                        messageSection
                        
                        // 发布按钮
                        publishButton
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("发布挂单")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showItemSelector) {
                TradeItemSelector(
                    selectedItems: $tempSelectedItems,
                    isPresented: $showItemSelector,
                    title: isSelectingOffering ? "选择要出售的物品" : "选择想要的物品"
                )
            }
            .onChange(of: showItemSelector) { isShowing in
                if !isShowing && !tempSelectedItems.isEmpty {
                    if isSelectingOffering {
                        offeringItems = tempSelectedItems
                    } else {
                        requestingItems = tempSelectedItems
                    }
                    tempSelectedItems = []
                }
            }
        }
    }
    
    // MARK: - 我要出的物品区域
    private var offeringItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我要出的物品")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
                Button(action: {
                    isSelectingOffering = true
                    showItemSelector = true
                }) {
                    Text("添加物品")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ApocalypseTheme.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if offeringItems.isEmpty {
                Text("点击添加物品按钮选择您要出售的物品")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(offeringItems.indices, id: \.self) { index in
                        let item = offeringItems[index]
                        let itemName = getItemName(itemId: item.itemId)
                        HStack(spacing: 8) {
                            Image(systemName: "bag.fill")
                                .foregroundColor(ApocalypseTheme.primary)
                            Text("\(itemName) ×\(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            Spacer()
                            Button(action: {
                                offeringItems.remove(at: index)
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(ApocalypseTheme.danger)
                            }
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - 我想要的物品区域
    private var requestingItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我想要的物品")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                Spacer()
                Button(action: {
                    isSelectingOffering = false
                    showItemSelector = true
                }) {
                    Text("添加物品")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ApocalypseTheme.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if requestingItems.isEmpty {
                Text("点击添加物品按钮选择您想要的物品")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textMuted)
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(requestingItems.indices, id: \.self) { index in
                        let item = requestingItems[index]
                        let itemName = getItemName(itemId: item.itemId)
                        HStack(spacing: 8) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(ApocalypseTheme.primary)
                            Text("\(itemName) ×\(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                            Spacer()
                            Button(action: {
                                requestingItems.remove(at: index)
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(ApocalypseTheme.danger)
                            }
                        }
                        .padding()
                        .background(ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - 有效期区域
    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("有效期")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            
            HStack(spacing: 8) {
                ForEach(expirationOptions, id: \.self) { hours in
                    Button(action: {
                        expiresInHours = hours
                    }) {
                        Text("\(hours)小时")
                            .font(.caption)
                            .foregroundColor(expiresInHours == hours ? .white : ApocalypseTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(expiresInHours == hours ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - 留言区域
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("留言（可选）")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
            
            TextField("添加留言，说明交易细节或其他信息...", text: $message, axis: .vertical)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .padding()
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(8)
                .lineLimit(3)
        }
    }
    
    // MARK: - 发布按钮
    private var publishButton: some View {
        Button(action: {
            Task {
                await publishOffer()
            }
        }) {
            Text("发布挂单")
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    (!offeringItems.isEmpty && !requestingItems.isEmpty) ? 
                    ApocalypseTheme.primary : 
                    ApocalypseTheme.textMuted
                )
                .cornerRadius(8)
        }
        .disabled(offeringItems.isEmpty || requestingItems.isEmpty || isLoading)
        .overlay {
            if isLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    // MARK: - 辅助方法
    private func getItemName(itemId: String) -> String {
        // 从物品定义中获取名称
        if let itemDef = InventoryManager.shared.itemDefinitions[itemId] {
            return itemDef.name
        }
        // 如果找不到定义，返回itemId
        return itemId
    }
    
    // MARK: - 发布挂单
    private func publishOffer() async {
        guard !offeringItems.isEmpty && !requestingItems.isEmpty else { return }
        
        await MainActor.run { isLoading = true }
        do {
            try await TradeManager.shared.createOffer(
                offeringItems: offeringItems,
                requestingItems: requestingItems,
                message: message.isEmpty ? nil : message,
                expiresInHours: expiresInHours
            )
            
            // 显示成功提示
            let alert = UIAlertController(title: "成功", message: "挂单发布成功！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
                // 重置表单
                offeringItems = []
                requestingItems = []
                expiresInHours = 24
                message = ""
                // 切换到我的挂单页面
                selectedTab = .myOffers
            }))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        } catch {
            print("❌ 发布挂单失败: \(error.localizedDescription)")
            // 显示失败提示
            let alert = UIAlertController(title: "失败", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
            await MainActor.run { isLoading = false }
        }
        await MainActor.run { isLoading = false }
    }
}

// MARK: - 预览
struct TradeCreateView_Previews: PreviewProvider {
    @State static var selectedTab: TradeMainView.TradeTab = .create
    static var previews: some View {
        TradeCreateView(selectedTab: $selectedTab)
    }
}