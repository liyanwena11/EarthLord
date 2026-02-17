//
//  TradeItemSelector.swift
//  EarthLord
//
//  交易物品选择器
//

import SwiftUI

struct TradeItemSelector: View {
    @Binding var selectedItems: [TradeItem]
    @Binding var isPresented: Bool
    let title: String
    let maxQuantityPerItem: Int = 99
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "全部"
    @State private var tempItems: [TradeItem] = []
    @State private var quantityInputs: [String: Int] = [:]
    
    private var inventoryItems: [InventoryDisplayItem] {
        InventoryManager.shared.items.filter { item in
            (searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())) &&
            (selectedCategory == "全部" || item.category == selectedCategory)
        }
    }
    
    private var categories: [String] {
        let allCategories = Set(inventoryItems.map { $0.category })
        return ["全部"] + Array(allCategories)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 搜索和筛选
                VStack(spacing: 12) {
                    HStack {
                        TextField("搜索物品...", text: $searchText)
                            .padding(10)
                            .background(ApocalypseTheme.background)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ApocalypseTheme.textMuted, lineWidth: 1)
                            )
                        
                        Menu {
                            ForEach(categories, id: \.self) {
                                category in Button(action: { selectedCategory = category }) {
                                    Text(category == "全部" ? "全部" : category)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCategory == "全部" ? "全部" : selectedCategory)
                                Image(systemName: "chevron.down")
                            }
                            .padding(10)
                            .background(ApocalypseTheme.background)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ApocalypseTheme.textMuted, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
                
                // 物品列表
                List {
                    ForEach(inventoryItems) {
                        item in HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(ApocalypseTheme.textPrimary)
                                Text("\(item.categoryDisplayName) · \(item.rarityDisplayName)")
                                    .font(.subheadline)
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                                Text("当前数量: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Button(action: { decreaseQuantity(for: item.itemId, maxAvailable: item.quantity) }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(ApocalypseTheme.primary)
                                            .font(.title2)
                                    }
                                    
                                    Text("\(quantityInputs[item.itemId] ?? 0)")
                                        .font(.headline)
                                        .foregroundColor(ApocalypseTheme.textPrimary)
                                        .frame(minWidth: 40, alignment: .center)
                                    
                                    Button(action: { increaseQuantity(for: item.itemId, maxAvailable: item.quantity) }) {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(ApocalypseTheme.primary)
                                            .font(.title2)
                                    }
                                }
                            }
                        }
                        .listRowBackground(ApocalypseTheme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(ApocalypseTheme.background)
                
                // 底部操作栏
                VStack {
                    HStack {
                        Text("已选择物品: \(tempItems.count)")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    HStack(spacing: 12) {
                        Button(action: { resetSelection() }) {
                            Text("重置")
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ApocalypseTheme.background)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ApocalypseTheme.textMuted, lineWidth: 2)
                                )
                        }
                        
                        Button(action: { confirmSelection() }) {
                            Text("确认")
                                .font(.headline)
                                .foregroundColor(ApocalypseTheme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ApocalypseTheme.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .background(ApocalypseTheme.background)
                .borderTop(color: ApocalypseTheme.textMuted, width: 2)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Text("取消")
                            .foregroundColor(ApocalypseTheme.primary)
                    }
                }
            }
            .onAppear {
                tempItems = selectedItems
                // 初始化数量输入
                for item in tempItems {
                    quantityInputs[item.itemId] = item.quantity
                }
            }
        }
    }
    
    private func increaseQuantity(for itemId: String, maxAvailable: Int) {
        let current = quantityInputs[itemId] ?? 0
        if current < min(maxQuantityPerItem, maxAvailable) {
            quantityInputs[itemId] = current + 1
            updateTempItems()
        }
    }
    
    private func decreaseQuantity(for itemId: String, maxAvailable: Int) {
        let current = quantityInputs[itemId] ?? 0
        if current > 0 {
            quantityInputs[itemId] = current - 1
            updateTempItems()
        }
    }
    
    private func updateTempItems() {
        tempItems = quantityInputs.filter { $0.value > 0 }
            .map { TradeItem(itemId: $0.key, quantity: $0.value) }
    }
    
    private func resetSelection() {
        quantityInputs.removeAll()
        tempItems.removeAll()
    }
    
    private func confirmSelection() {
        selectedItems = tempItems
        isPresented = false
    }
}

// 扩展View，添加顶部边框
private extension View {
    func borderTop(color: Color, width: CGFloat) -> some View {
        self
            .overlay(
                Rectangle()
                    .frame(height: width)
                    .foregroundColor(color)
                    .alignmentGuide(.top) { $0[.bottom] }
            )
    }
}
