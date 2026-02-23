//
//  CreateListingView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  创建交易挂单视图
//

import SwiftUI

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var inventoryManager = InventoryManager.shared

    @State private var selectedOfferItems: Set<String> = []
    @State private var offerAmounts: [String: Int] = [:]
    @State private var selectedRequestItems: Set<String> = []
    @State private var requestAmounts: [String: Int] = [:]
    @State private var message: String = ""
    @State private var expiryHours: Int = 24
    @State private var isCreating = false
    @State private var errorMessage: String?

    let availableResources = [
        ("food", "食物", "leaf.fill", Color.green),
        ("water", "水", "drop.fill", Color.blue),
        ("wood", "木材", "square.stack.fill", Color.brown),
        ("metal", "金属", "cube.fill", Color.gray),
        ("medical", "医疗", "cross.fill", Color.red),
        ("energy", "能量", "bolt.fill", Color.yellow)
    ]

    var body: some View {
        NavigationStack {
            Form {
                // 我提供的物品
                Section {
                    ForEach(availableResources, id: \.0) { resource in
                        MarketResourceRow(
                            resourceId: resource.0,
                            name: resource.1,
                            icon: resource.2,
                            color: resource.3,
                            isSelected: selectedOfferItems.contains(resource.0),
                            amount: offerAmounts[resource.0, default: 1],
                            onAmountChange: { newAmount in
                                offerAmounts[resource.0] = newAmount
                            },
                            onToggle: {
                                if selectedOfferItems.contains(resource.0) {
                                    selectedOfferItems.remove(resource.0)
                                    offerAmounts.removeValue(forKey: resource.0)
                                } else {
                                    selectedOfferItems.insert(resource.0)
                                    offerAmounts[resource.0] = 1
                                }
                            }
                        )
                    }
                } header: {
                    Text("我提供的物品")
                } footer: {
                    Text("选择你想要交换出去的物品")
                }

                // 我需要的物品
                Section {
                    ForEach(availableResources, id: \.0) { resource in
                        MarketResourceRow(
                            resourceId: resource.0,
                            name: resource.1,
                            icon: resource.2,
                            color: resource.3,
                            isSelected: selectedRequestItems.contains(resource.0),
                            amount: requestAmounts[resource.0, default: 1],
                            onAmountChange: { newAmount in
                                requestAmounts[resource.0] = newAmount
                            },
                            onToggle: {
                                if selectedRequestItems.contains(resource.0) {
                                    selectedRequestItems.remove(resource.0)
                                    requestAmounts.removeValue(forKey: resource.0)
                                } else {
                                    selectedRequestItems.insert(resource.0)
                                    requestAmounts[resource.0] = 1
                                }
                            }
                        )
                    }
                } header: {
                    Text("我需要的物品")
                } footer: {
                    Text("选择你希望交换得到的物品")
                }

                // 留言
                Section {
                    TextField("添加留言（可选）", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("留言")
                } footer: {
                    Text("向交易对象说明交易详情")
                }

                // 有效期
                Section {
                    Picker("有效期", selection: $expiryHours) {
                        Text("1小时").tag(1)
                        Text("6小时").tag(6)
                        Text("12小时").tag(12)
                        Text("24小时").tag(24)
                        Text("48小时").tag(48)
                        Text("永久").tag(0)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("交易有效期")
                }
            }
            .navigationTitle("发布交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createListing()
                    } label: {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("发布")
                        }
                    }
                    .disabled(selectedOfferItems.isEmpty || selectedRequestItems.isEmpty || isCreating)
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

    private func createListing() {
        guard !selectedOfferItems.isEmpty, !selectedRequestItems.isEmpty else { return }

        isCreating = true

        Task {
            do {
                // TODO: 实现创建交易挂单逻辑
                let offeringItems = selectedOfferItems.map { itemId in
                    TradeItem(itemId: itemId, quantity: offerAmounts[itemId, default: 1])
                }

                let requestingItems = selectedRequestItems.map { itemId in
                    TradeItem(itemId: itemId, quantity: requestAmounts[itemId, default: 1])
                }

                // 调用 TradeManager 创建挂单
                try await TradeManager.shared.createOffer(
                    offeringItems: offeringItems,
                    requestingItems: requestingItems,
                    message: message.isEmpty ? nil : message,
                    expiresInHours: expiryHours == 0 ? nil : expiryHours
                )

                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isCreating = false
                }
            }
        }
    }
}

// MARK: - MarketResourceRow

struct MarketResourceRow: View {
    let resourceId: String
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let amount: Int
    let onAmountChange: (Int) -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button {
                onToggle()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: isSelected ? icon : "circle")
                            .foregroundColor(isSelected ? color : .gray)
                    }

                    Text(name)
                        .foregroundColor(.primary)

                    Spacer()

                    if isSelected {
                        HStack(spacing: 8) {
                            Button {
                                onAmountChange(max(1, amount - 1))
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.gray)
                            }

                            Text("\(amount)")
                                .font(.body)
                                .frame(width: 30)

                            Button {
                                onAmountChange(amount + 1)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(color)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// 预览
#Preview {
    CreateListingView()
}
