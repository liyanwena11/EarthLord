import SwiftUI
import StoreKit

struct SupplyPackDetailView: View {
    let supplyPack: SupplyPack
    let storeProduct: StoreProduct
    @ObservedObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmDialog = false
    @State private var isPurchasing = false

    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Guarantee badge
                    if supplyPack.guaranteedItems.count > 0 {
                        guaranteeBadge
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    
                    // Contents
                    contentsSection
                    
                    // Buy button
                    buyButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
            }
        }
        // Error alert
        .alert("购买提示", isPresented: .constant(storeManager.purchaseError != nil)) {
            Button("确定") { storeManager.purchaseError = nil }
        } message: {
            Text(storeManager.purchaseError ?? "")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Banner
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.1, blue: 0), brandOrange.opacity(0.7), Color.black],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .cornerRadius(0)
                
                VStack(spacing: 8) {
                    Text(supplyPack.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text(supplyPack.description)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Price
            Text(storeProduct.price)
                .font(.title2.bold())
                .foregroundColor(brandOrange)
        }
    }
    
    // MARK: - Guarantee Badge
    
    private var guaranteeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "shield.checkmark")
                .font(.caption)
                .foregroundColor(.green)
            Text("包含以下固定物资，额外随机掉落稀有物品")
                .font(.caption)
                .foregroundColor(.green)
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Contents Section
    
    private var contentsSection: some View {
        VStack(spacing: 16) {
            // Guaranteed items
            if !supplyPack.guaranteedItems.isEmpty {
                sectionTitle("固定物资")
                
                VStack(spacing: 10) {
                    ForEach(supplyPack.guaranteedItems) { item in
                        itemRow(item, isGuaranteed: true)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Random items
            let randomItems = supplyPack.items.filter { !$0.guaranteed }
            if !randomItems.isEmpty {
                sectionTitle("随机物资")
                
                VStack(spacing: 10) {
                    ForEach(randomItems) { item in
                        itemRow(item, isGuaranteed: false)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Buy Button

    private var buyButton: some View {
        Button(action: {
            showConfirmDialog = true
        }) {
            if isPurchasing {
                ProgressView()
                    .tint(.black)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [brandOrange, brandOrange.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
            } else {
                HStack {
                    Text("立即购买")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Text(storeProduct.price)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [brandOrange, brandOrange.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
            }
        }
        .disabled(isPurchasing)
        .confirmationDialog(
            "确认购买",
            isPresented: $showConfirmDialog,
            titleVisibility: .visible
        ) {
            Button("取消", role: .cancel) { }
            Button("确认购买") {
                isPurchasing = true
                Task {
                    await storeManager.purchase(storeProduct.product)
                    isPurchasing = false
                }
            }
        } message: {
            Text("确认花费 \(storeProduct.price) 购买 \(supplyPack.name)？\n\n购买后物品将发送到待领取，请及时领取。")
        }
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Rectangle().fill(brandOrange).frame(width: 3, height: 16).cornerRadius(2)
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func itemRow(_ item: PackItem, isGuaranteed: Bool) -> some View {
        HStack(spacing: 14) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [rarityColor(item.rarity), rarityColor(item.rarity).opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Text(itemIcon(item.itemId))
                    .font(.title3)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    if isGuaranteed {
                        Label("必得", systemImage: "checkmark.seal.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.green)
                    } else if !item.guaranteed {
                        Label("概率 \(Int(item.dropRate * 100))%", systemImage: "dice.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Rarity and quantity
            VStack(alignment: .trailing, spacing: 4) {
                Text("x\(item.quantity)")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(rarityText(item.rarity))
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(rarityColor(item.rarity).opacity(0.2))
                    .foregroundColor(rarityColor(item.rarity))
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(rarityColor(item.rarity).opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func rarityText(_ rarity: String) -> String {
        switch rarity {
        case "common": return "普通"
        case "rare": return "稀有"
        case "epic": return "史诗"
        case "legendary": return "传说"
        default: return "普通"
        }
    }
    
    private func itemIcon(_ itemId: String) -> String {
        let icons: [String: String] = [
            "water": "💧",
            "canned_food": "🍱",
            "wood": "🪵",
            "stone": "🪨",
            "metal": "🔩",
            "glass": "🔍",
            "cloth": "🧶",
            "bandage": "🩹",
            "first_aid_kit": "🩺",
            "electronic_part": "⚡",
            "mechanical_part": "🔧",
            "solar_panel": "☀️",
            "satellite_module": "🛰️",
            "ancient_tech": "🔮",
            "rifle": "🔫",
            "armor": "🛡️"
        ]
        return icons[itemId] ?? "📦"
    }
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "common":
            return .gray
        case "rare":
            return .blue
        case "epic":
            return .purple
        case "legendary":
            return Color(red: 1, green: 0.8, blue: 0)
        default:
            return .gray
        }
    }
    
    private func rarityBadge(_ rarity: String) -> some View {
        let color = rarityColor(rarity)
        let text: String
        
        switch rarity {
        case "common":
            text = "普通"
        case "rare":
            text = "稀有"
        case "epic":
            text = "史诗"
        case "legendary":
            text = "传说"
        default:
            text = "普通"
        }
        
        return Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(10)
    }
}

// MARK: - Preview Helper View

struct PreviewSupplyPackDetailView: View {
    let supplyPack: SupplyPack
    @Environment(\.dismiss) private var dismiss
    
    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.1, blue: 0), brandOrange.opacity(0.7), Color.black],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .cornerRadius(0)
                            
                            VStack(spacing: 8) {
                                Text(supplyPack.name)
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                Text(supplyPack.description)
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        Text(supplyPack.price)
                            .font(.title2.bold())
                            .foregroundColor(brandOrange)
                    }
                    
                    // Guarantee badge
                    if supplyPack.guaranteedItems.count > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("包含以下固定物资，额外随机掉落稀有物品")
                                .font(.caption)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // Contents
                    VStack(spacing: 16) {
                        // Guaranteed items
                        if !supplyPack.guaranteedItems.isEmpty {
                            HStack {
                                Rectangle().fill(brandOrange).frame(width: 3, height: 16).cornerRadius(2)
                                Text("固定物资")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                ForEach(supplyPack.guaranteedItems) { item in
                                    itemRow(item, isGuaranteed: true)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Random items
                        let randomItems = supplyPack.items.filter { !$0.guaranteed }
                        if !randomItems.isEmpty {
                            HStack {
                                Rectangle().fill(brandOrange).frame(width: 3, height: 16).cornerRadius(2)
                                Text("随机物资")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                ForEach(randomItems) { item in
                                    itemRow(item, isGuaranteed: false)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Buy button
                    Button(action: {})
                    {
                        HStack {
                            Text("立即购买")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            Text(supplyPack.price)
                                .font(.headline.bold())
                                .foregroundColor(.black)
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(brandOrange)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func itemRow(_ item: PackItem, isGuaranteed: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rarityColor(item.rarity).opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(itemIcon(item.itemId))
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                if isGuaranteed {
                    Text("必得")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("随机掉落")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("x\(item.quantity)")
                    .font(.subheadline.bold())
                    .foregroundColor(rarityColor(item.rarity))
                rarityBadge(item.rarity)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }
    
    private func itemIcon(_ itemId: String) -> String {
        let icons: [String: String] = [
            "water": "💧",
            "canned_food": "🍱",
            "wood": "🪵",
            "stone": "🪨",
            "metal": "🔩",
            "glass": "🔍",
            "cloth": "🧶",
            "bandage": "🩹",
            "first_aid_kit": "🩺",
            "electronic_part": "⚡",
            "mechanical_part": "🔧",
            "solar_panel": "☀️",
            "satellite_module": "🛰️",
            "ancient_tech": "🔮",
            "rifle": "🔫",
            "armor": "🛡️",
            "water_bottle": "💧"
        ]
        return icons[itemId] ?? "📦"
    }
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "common":
            return .gray
        case "rare":
            return .blue
        case "epic":
            return .purple
        case "legendary":
            return Color(red: 1, green: 0.8, blue: 0)
        default:
            return .gray
        }
    }
    
    private func rarityBadge(_ rarity: String) -> some View {
        let color = rarityColor(rarity)
        let text: String
        
        switch rarity {
        case "common":
            text = "普通"
        case "rare":
            text = "稀有"
        case "epic":
            text = "史诗"
        case "legendary":
            text = "传说"
        default:
            text = "普通"
        }
        
        return Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(10)
    }
}

// MARK: - Preview

struct SupplyPackDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock supply pack
        let mockSupplyPack = SupplyPack(
            id: "com.liyanwen.EarthLord.supply.survivor",
            name: "幸存者物资包",
            description: "基础生存物资，包含食物和水",
            price: "¥6",
            productId: "com.liyanwen.EarthLord.supply.survivor",
            rarity: "common",
            items: [
                PackItem(itemId: "canned_food", quantity: 3, rarity: "common", guaranteed: true),
                PackItem(itemId: "water_bottle", quantity: 5, rarity: "common", guaranteed: true),
                PackItem(itemId: "first_aid_kit", quantity: 1, rarity: "rare", guaranteed: false)
            ],
            guaranteedItems: [
                PackItem(itemId: "canned_food", quantity: 3, rarity: "common", guaranteed: true),
                PackItem(itemId: "water_bottle", quantity: 5, rarity: "common", guaranteed: true)
            ]
        )
        
        // Return preview view
        PreviewSupplyPackDetailView(supplyPack: mockSupplyPack)
    }
}
