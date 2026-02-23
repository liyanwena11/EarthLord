import SwiftUI
import StoreKit

struct ShopView: View {
    @StateObject private var store = StoreManager.shared
    @StateObject private var mailbox = MailboxManager.shared
    @State private var showMailbox = false
    @State private var showOpeningAnimation = false
    @Environment(\.dismiss) private var dismiss
    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                // ✅ 添加关闭按钮
                VStack(spacing: 0) {
                    // 关闭按钮栏
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    ScrollView {
                        VStack(spacing: 0) {
                            // Banner
                            shopBanner
                                .padding(.bottom, 20)

                            // Mailbox shortcut
                            mailboxShortcut
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)

                            // Products
                            sectionTitle("物资补给包")
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            // ✅ 使用 displayProducts（包含模拟数据回退）
                            if store.displayProducts.isEmpty {
                                if store.isPurchasing {
                                    loadingOrEmpty
                                } else {
                                    emptyStateView
                                }
                            } else {
                                VStack(spacing: 14) {
                                    ForEach(store.displayProducts, id: \.id) { productData in
                                        DisplayProductCard(productData: productData, store: store)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Restore
                            Button(action: { Task { await store.restorePurchases() } }) {
                                Text("恢复购买")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // Error alert
        .alert("购买提示", isPresented: .constant(store.purchaseError != nil)) {
            Button("确定") { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
        // Opening animation overlay
        .fullScreenCover(isPresented: $store.showOpeningAnimation) {
            SupplyBoxOpeningView(items: store.lastPurchasedItems) {
                store.showOpeningAnimation = false
                showMailbox = true
            }
        }
        // Navigate to mailbox after animation
        .background(
            NavigationLink(destination: MailboxView(), isActive: $showMailbox) { EmptyView() }
                .hidden()
        )
        .task {
            await mailbox.loadPendingItems()
            await store.loadProducts()

            // 调试信息
            LogDebug("🔍 [ShopView] ===== 商城加载完成 =====")
            LogDebug("🔍 [ShopView] StoreKit 产品数量: \(store.products.count)")
            LogDebug("🔍 [ShopView] DisplayProducts 数量: \(store.displayProducts.count)")
            LogDebug("🔍 [ShopView] 是否使用模拟数据: \(store.products.isEmpty && !store.displayProducts.isEmpty)")

            for product in store.displayProducts {
                LogDebug("  - \(product.id): \(product.name) - \(product.price)")
            }
            LogDebug("🔍 [ShopView] 邮箱待领取: \(mailbox.pendingCount) 件")
        }
    }

    // MARK: - Banner

    private var shopBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.8, green: 0.3, blue: 0.1), Color(red: 0.6, green: 0.2, blue: 0), Color.black],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 160)

            VStack(spacing: 8) {
                Text("物资商城")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("末日物资站")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("获取珍贵物资，在末日中生存")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
            }
        }
    }

    // MARK: - Mailbox Shortcut

    private var mailboxShortcut: some View {
        NavigationLink(destination: MailboxView()) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(brandOrange.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: "tray.full.fill")
                        .foregroundColor(brandOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("我的邮箱")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(mailbox.hasPendingItems ? "\(mailbox.pendingCount) 件物资待领取" : "暂无待领取物资")
                        .font(.caption)
                        .foregroundColor(mailbox.hasPendingItems ? brandOrange : .gray)
                }
                Spacer()
                if mailbox.hasPendingItems {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(mailbox.hasPendingItems ? brandOrange.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Rectangle().fill(brandOrange).frame(width: 3, height: 16).cornerRadius(2)
            Text(title).font(.subheadline.bold()).foregroundColor(.white)
            Spacer()
        }
    }

    private var loadingOrEmpty: some View {
        VStack(spacing: 12) {
            ProgressView().tint(brandOrange)
            Text("加载商品中...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 40)
    }

    // ✅ 新增：空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("暂时无法连接商城")
                .font(.headline)
                .foregroundColor(.white)

            Text("商店可能正在维护或网络不稳定")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await store.loadProducts()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重新加载")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    @ObservedObject var store: StoreManager

    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    private var pack: SupplyPackID? { SupplyPackID(rawValue: product.id) }
    
    private var cardColor: Color {
        switch pack {
        case .survivor:
            return .gray
        case .explorer:
            return .green
        case .lord:
            return .blue
        case .overlord:
            return .orange
        default:
            return brandOrange
        }
    }
    
    private var tagText: String {
        switch pack {
        case .survivor:
            return "STARTER"
        case .explorer:
            return "POPULAR"
        case .lord:
            return "VALUE"
        case .overlord:
            return "BEST"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card
            VStack(spacing: 12) {
                // Tag and name
                HStack(spacing: 8) {
                    if !tagText.isEmpty {
                        Text(tagText)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(cardColor.opacity(0.8))
                            .cornerRadius(4)
                    }
                    Text(pack?.displayName ?? product.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                
                // Description
                Text(pack?.subtitle ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Items
                if let pack {
                    HStack(spacing: 12) {
                        ForEach(pack.contents.prefix(4)) {
                            item in
                            itemIcon(item)
                        }
                    }
                }
                
                // Price and buy button
                HStack(spacing: 12) {
                    Spacer()
                    Text(store.formattedPrice(product))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Button(action: {
                        Task { await store.purchase(product) }
                    }) {
                        if store.isPurchasing {
                            ProgressView().tint(.black).frame(width: 80, height: 36)
                        } else {
                            Text("购买")
                                .font(.subheadline.bold())
                                .foregroundColor(.black)
                                .frame(width: 80, height: 36)
                                .background(cardColor)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(store.isPurchasing)
                }
            }
            .padding(16)
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardColor.opacity(0.8), lineWidth: 2)
        )
    }
    
    private func itemIcon(_ item: PackItem) -> some View {
        HStack(spacing: 4) {
            Text(itemIconForId(item.itemId))
                .font(.caption)
            Text("x\(item.quantity)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func itemIconForId(_ itemId: String) -> String {
        let icons: [String: String] = [
            "water": "💧",
            "canned_food": "🍱",
            "food": "🍖",
            "bandage": "🩹",
            "first_aid_kit": "🩺",
            "medical_kit": "🏥",
            "flashlight": "🔦",
            "wood": "🪵",
            "stone": "🪨",
            "metal": "🔩"
        ]
        return icons[itemId] ?? "📦"
    }
}

// MARK: - DisplayProductCard (支持 SupplyProductData)

struct DisplayProductCard: View {
    let productData: SupplyProductData
    @ObservedObject var store: StoreManager

    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    private var pack: SupplyPackID? { SupplyPackID(rawValue: productData.id) }

    private var cardColor: Color {
        productData.rarity.color
    }

    private var tagText: String {
        switch pack {
        case .survivor:
            return "STARTER"
        case .explorer:
            return "POPULAR"
        case .lord:
            return "VALUE"
        case .overlord:
            return "BEST"
        default:
            return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card
            VStack(spacing: 12) {
                // Tag and name
                HStack(spacing: 8) {
                    if !tagText.isEmpty {
                        Text(tagText)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(cardColor.opacity(0.8))
                            .cornerRadius(4)
                    }
                    Text(productData.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }

                // Description
                Text(productData.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Items preview
                HStack(spacing: 12) {
                    ForEach(productData.previewItems.prefix(4), id: \.self) { itemStr in
                        HStack(spacing: 4) {
                            Text(itemIconForItemString(itemStr))
                                .font(.caption)
                            Text(itemStr.components(separatedBy: " x").last ?? "1")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Price and buy button
                HStack(spacing: 12) {
                    Spacer()
                    Text(productData.price)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Button(action: {
                        Task { await store.purchaseProduct(productData) }
                    }) {
                        if store.isPurchasing {
                            ProgressView().tint(.black).frame(width: 80, height: 36)
                        } else {
                            Text("购买")
                                .font(.subheadline.bold())
                                .foregroundColor(.black)
                                .frame(width: 80, height: 36)
                                .background(cardColor)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(store.isPurchasing)
                }
            }
            .padding(16)
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardColor.opacity(0.8), lineWidth: 2)
        )
    }

    private func itemIconForItemString(_ itemStr: String) -> String {
        let itemName = itemStr.components(separatedBy: " x").first ?? ""
        let icons: [String: String] = [
            "饮用水": "💧",
            "罐头食品": "🍱",
            "食物": "🍖",
            "绷带": "🩹",
            "急救包": "🩺",
            "医疗包": "🏥",
            "手电筒": "🔦",
            "木材": "🪵",
            "石头": "🪨",
            "废金属": "🔩",
            "玻璃": "🧊",
            "布料": "🧵",
            "电子元件": "📱",
            "机械组件": "⚙️",
            "太阳能电板": "☀️",
            "卫星模块": "📡",
            "古代科技残骸": "🏺"
        ]
        return icons[itemName] ?? "📦"
    }
}

