//
//  SupplyStationView.swift
//  EarthLord
//
//  末日物资站 - 商城主界面
//

import SwiftUI

struct SupplyStationView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var mailboxManager: MailboxManager
    @State private var selectedTab: SupplyTab = .shop

    enum SupplyTab: String, CaseIterable {
        case shop = "物资包"
        case mailbox = "邮箱"

        var iconName: String {
            switch self {
            case .shop: return "cube.box.fill"
            case .mailbox: return "envelope.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.08, blue: 0.12),
                    Color(red: 0.15, green: 0.12, blue: 0.18)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                headerView

                // Tab 切换栏
                tabBarView

                // 内容区域
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == .shop {
                            ShopContentView()
                        } else {
                            MailboxContentView()
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "storefront.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("末日物资站")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("补充物资，活下去")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 邮箱徽章
            if mailboxManager.unclaimedCount > 0 {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(.gray)

                    Text("\(mailboxManager.unclaimedCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .padding()
    }

    // MARK: - Tab Bar

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(SupplyTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.title3)
                            .foregroundColor(selectedTab == tab ? .orange : .gray)

                        Text(tab.rawValue)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.orange.opacity(0.1) : Color.clear)
                }
            }
        }
        .background(Color.white.opacity(0.05))
    }
}

// MARK: - Shop Content

struct ShopContentView: View {
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        VStack(spacing: 16) {
            // 欢迎标语
            welcomeBanner

            // 产品列表
            if storeManager.displayProducts.isEmpty {
                emptyProductsView
            } else {
                productsGrid
            }
        }
    }

    private var welcomeBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎒 需要更多物资？")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("购买物资包，快速获得生存必需品")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.05)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }

    private var emptyProductsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("暂无物资包")
                .font(.headline)
                .foregroundColor(.white)

            Text("商店正在补货中...")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("💡 提示：请在 App Store Connect 中配置内购产品")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var productsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(storeManager.displayProducts, id: \.id) { product in
                SupplyProductCard(product: product)
            }
        }
    }
}

// MARK: - Mailbox Content

struct MailboxContentView: View {
    @EnvironmentObject var mailboxManager: MailboxManager

    var body: some View {
        VStack(spacing: 16) {
            if mailboxManager.mailboxItems.isEmpty {
                emptyMailboxView
            } else {
                mailboxItemsList
            }
        }
        .onAppear {
            Task {
                await mailboxManager.fetchMailboxItems()
            }
        }
    }

    private var emptyMailboxView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("邮箱是空的")
                .font(.headline)
                .foregroundColor(.white)

            Text("购买的物资包会出现在这里")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Text("💡 提示：在「物资包」标签购买物资")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var mailboxItemsList: some View {
        VStack(spacing: 12) {
            ForEach(mailboxManager.mailboxItems) { item in
                MailboxItemCard(item: item)
            }
        }
    }
}

// MARK: - Supply Product Card

struct SupplyProductCard: View {
    let product: SupplyProductData
    @EnvironmentObject var storeManager: StoreManager
    @State private var isPurchasing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 产品图标
            HStack {
                ZStack {
                    Circle()
                        .fill(product.rarity.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: product.iconName)
                        .font(.title2)
                        .foregroundColor(product.rarity.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }

            // 物资预览
            VStack(alignment: .leading, spacing: 6) {
                Text("包含物资")
                    .font(.caption2)
                    .foregroundColor(.gray)

                HStack {
                    ForEach(product.previewItems.prefix(3), id: \.self) { item in
                        Text(item)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    if product.previewItems.count > 3 {
                        Text("+\(product.previewItems.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // 价格和购买按钮
            HStack {
                Text(product.price)
                    .font(.title3.bold())
                    .foregroundColor(.orange)

                Spacer()

                Button(action: purchaseProduct) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "cart.fill")
                            Text("购买")
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                .disabled(isPurchasing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(product.rarity.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func purchaseProduct() {
        isPurchasing = true
        Task {
            let success = await storeManager.purchaseProduct(product)
            await MainActor.run {
                isPurchasing = false
                if success {
                    // TODO: 显示购买成功提示
                }
            }
        }
    }
}

// MARK: - Mailbox Item Card

struct MailboxItemCard: View {
    let item: MailboxItem
    @EnvironmentObject var mailboxManager: MailboxManager
    @State private var isClaiming = false

    var body: some View {
        HStack(spacing: 12) {
            // 物品图标
            ZStack {
                Circle()
                    .fill(item.rarity.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "cube.fill")
                    .font(.title3)
                    .foregroundColor(item.rarity.color)
            }

            // 物品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text("x\(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("购买于 \(item.purchasedAt, style: .relative) 前")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 领取按钮
            Button(action: claimItem) {
                if isClaiming {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("领取")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green)
            .cornerRadius(8)
            .disabled(isClaiming)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func claimItem() {
        isClaiming = true
        Task {
            let success = await mailboxManager.claimItem(id: item.id)
            await MainActor.run {
                isClaiming = false
                if success {
                    // TODO: 显示领取成功提示
                }
            }
        }
    }
}

// MARK: - Preview


struct SupplyStationView_Previews: PreviewProvider {
    static var previews: some View {
        SupplyStationView()
            .environmentObject(StoreManager.shared)
            .environmentObject(MailboxManager.shared)
    }
}
