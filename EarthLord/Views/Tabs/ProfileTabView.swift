import SwiftUI
import PhotosUI
import UIKit

struct ProfileTabView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var langManager = LanguageManager.shared
    @ObservedObject private var territoryManager = TerritoryManager.shared
    @ObservedObject private var engine = EarthLordEngine.shared
    @ObservedObject private var backpack = ExplorationManager.shared

    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""
    @State private var showSubscriptionCenter = false
    @State private var showSupplyStore = false
    @ObservedObject private var mailbox = MailboxManager.shared
    @ObservedObject private var tierManager = TierManager.shared

    // ✅ 添加详情弹窗状态
    @State private var showStatDetail: StatDetailType? = nil
    @State private var showMiniStatDetail: MiniStatDetailType? = nil
    @State private var showJoinDateDetail = false
    @State private var showAchievementDetail = false

    // 头像
    @State private var avatarItem: PhotosPickerItem?
    @AppStorage("profileAvatarData") private var avatarDataBase64: String = ""

    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    // 用户显示名（邮箱前缀）
    private var displayName: String {
        authManager.currentUser?.email?.components(separatedBy: "@").first ?? "幸存者"
    }

    // 注册天数
    private var daysSinceJoined: Int {
        guard let created = authManager.currentUser?.createdAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: created, to: Date()).day ?? 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        ApocalypseTheme.background,
                        Color(red: 0.14, green: 0.10, blue: 0.08),
                        ApocalypseTheme.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - 头部：头像 + 身份信息
                        VStack(spacing: 14) {
                            // 头像（可点击更换）
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    avatarCircle
                                    // 编辑角标
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(brandOrange)
                                        .background(Color.black)
                                        .clipShape(Circle())
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .onChange(of: avatarItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        avatarDataBase64 = data.base64EncodedString()
                                    }
                                }
                            }

                            // 标签 + 名字
                            VStack(spacing: 4) {
                                Text(String(localized: "幸存者档案"))
                                    .font(.caption).foregroundColor(brandOrange)
                                    .padding(.horizontal, 10).padding(.vertical, 3)
                                    .background(brandOrange.opacity(0.12))
                                    .cornerRadius(6)

                                Text(displayName)
                                    .font(.title2).bold().foregroundColor(.white)

                                Text(authManager.currentUser?.email ?? "")
                                    .font(.caption).foregroundColor(.gray)

                                HStack(spacing: 6) {
                                    Image(systemName: "shield.fill").font(.caption2).foregroundColor(brandOrange)
                                    // ✅ 使 ID 可复制
                                    Button(action: {
                                        if let userID = authManager.currentUser?.id.uuidString {
                                            UIPasteboard.general.string = userID
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        }
                                    }) {
                                        HStack(spacing: 2) {
                                            Text("ID: \(String(authManager.currentUser?.id.uuidString.prefix(8) ?? "--------"))")
                                                .font(.caption2).foregroundColor(.gray)
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                    }
                                    Text("·").foregroundColor(.gray.opacity(0.5))
                                    Image(systemName: "calendar").font(.caption2).foregroundColor(.gray)

                                    // ✅ 使加入天数可点击
                                    Button(action: {
                                        showJoinDateDetail = true
                                    }) {
                                        Text(String(format: NSLocalizedString("加入 %lld 天", comment: ""), daysSinceJoined))
                                            .font(.caption2).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 30)

                        // MARK: - 数据统计（3 格）
                        HStack(spacing: 0) {
                            StatItem(icon: "flag.fill", value: "\(territoryManager.myTerritories.count)", label: LocalizedStringKey("领地")) {
                                showStatDetail = .territories
                            }
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatItem(icon: "scalemass.fill", value: "\(String(format: "%.1f", backpack.totalWeight))kg", label: LocalizedStringKey("背包负重")) {
                                showStatDetail = .backpack
                            }
                            Divider().frame(height: 40).background(Color.white.opacity(0.1))
                            StatItem(icon: "person.2.fill", value: "\(engine.nearbyPlayerCount)", label: LocalizedStringKey("附近幸存者")) {
                                showStatDetail = .survivors
                            }
                        }
                        .padding(.vertical, 18)
                        .background(ApocalypseTheme.cardBackground.opacity(0.92))
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                        // MARK: - 背包详情
                        HStack(spacing: 12) {
                            MiniStatCard(icon: "archivebox.fill", color: .orange,
                                         label: String(localized: "物品种类"), value: "\(backpack.backpackItems.count) " + String(localized: "种")) {
                                showMiniStatDetail = .itemTypes
                            }
                            MiniStatCard(icon: "shippingbox.fill", color: .blue,
                                         label: String(localized: "物品数量"), value: "\(backpack.backpackItems.reduce(0) { $0 + $1.quantity }) " + String(localized: "件")) {
                                showMiniStatDetail = .itemCount
                            }
                            MiniStatCard(icon: "mappin.circle.fill", color: .green,
                                         label: String(localized: "附近资源"), value: "\(engine.nearbyPOIs.count) " + String(localized: "处")) {
                                showMiniStatDetail = .nearbyPOIs
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // MARK: - 背包容量进度条
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scalemass.fill").foregroundColor(.orange).font(.caption)
                                Text(String(localized: "背包容量")).font(.caption).foregroundColor(.gray)
                                Spacer()
                                Text("\(String(format: "%.1f", backpack.totalWeight)) / \(Int(backpack.maxCapacity)) kg")
                                    .font(.caption.bold()).foregroundColor(capacityColor)
                            }
                            ProgressView(value: min(backpack.totalWeight, backpack.maxCapacity),
                                         total: backpack.maxCapacity)
                                .tint(capacityColor)
                                .scaleEffect(x: 1, y: 1.4)
                                .animation(.easeInOut(duration: 0.3), value: backpack.totalWeight)
                        }
                        .padding(14)
                        .background(ApocalypseTheme.cardBackground.opacity(0.92))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // MARK: - 末日通行证入口
                        Button(action: { showSubscriptionCenter = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [ApocalypseTheme.primary.opacity(0.35), Color(red: 0.32, green: 0.24, blue: 0.16)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "gamecontroller.fill")
                                        .foregroundColor(ApocalypseTheme.primary)
                                        .font(.system(size: 20))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(String(localized: "末日通行证"))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)

                                    Text(tierManager.currentTier == .free ? "解锁背包扩容、探索增益与专属权益" : "权益生效中，点击管理通行证")
                                        .font(.caption)
                                        .foregroundColor(tierManager.currentTier == .free ? ApocalypseTheme.primary : ApocalypseTheme.success)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [ApocalypseTheme.cardBackground.opacity(0.96), Color(red: 0.20, green: 0.13, blue: 0.08).opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [ApocalypseTheme.primary.opacity(0.45), Color.white.opacity(0.10)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .sheet(isPresented: $showSubscriptionCenter) {
                            SubscriptionView()
                                .environmentObject(TierManager.shared)
                                .environmentObject(StoreManager.shared)
                        }

                        // MARK: - 物资商城入口 (调整)
                        Button(action: { showSupplyStore = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(brandOrange.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "cart.fill")
                                        .foregroundColor(brandOrange)
                                        .font(.system(size: 18))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "物资商城"))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text(mailbox.hasPendingItems ? "📬 \(mailbox.pendingCount) 件物资待领取" : "购买物资补给包")
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
                            .background(brandOrange.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(brandOrange.opacity(mailbox.hasPendingItems ? 0.5 : 0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .sheet(isPresented: $showSupplyStore) {
                            SupplyStoreView()
                                .environmentObject(StoreManager.shared)
                                .environmentObject(MailboxManager.shared)
                        }

                        // MARK: - 成就统计模块
                        AchievementStatsView(showFullLeaderboard: $showAchievementDetail)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // MARK: - 菜单
                        VStack(spacing: 1) {
                            Divider().background(Color.white.opacity(0.08))

                            NavigationLink(destination: LanguageSettingsView()) {
                                MenuRow(icon: "globe", title: LocalizedStringKey("语言设置"),
                                        value: langManager.currentLanguage == "en" ? "English" : "简体中文")
                            }
                            Divider().background(Color.white.opacity(0.08))
                            NavigationLink(destination: MoreTabView()) {
                                MenuRow(icon: "gearshape.fill", title: LocalizedStringKey("系统设置"), value: "")
                            }
                            MenuRow(icon: "bell.fill", title: LocalizedStringKey("通知"), value: "")
                            MenuRow(icon: "questionmark.circle.fill", title: LocalizedStringKey("帮助"), value: "")
                            Button(action: {
                                if let url = URL(string: "https://liyanwena11.github.io/earthlord-support/privacy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                MenuRow(icon: "lock.fill", title: LocalizedStringKey("隐私政策"), value: "")
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: {
                                if let url = URL(string: "https://liyanwena11.github.io/earthlord-support/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                MenuRow(icon: "globe.fill", title: LocalizedStringKey("技术支持"), value: "")
                            }
                            .buttonStyle(PlainButtonStyle())
                            MenuRow(icon: "info.circle.fill", title: LocalizedStringKey("关于"), value: "v1.0.0")
                            Divider().background(Color.white.opacity(0.08))
                        }
                        .padding(.bottom, 20)

                    }
                } // ScrollView

                // 退出登录 — 固定在底部，始终可点击
                VStack(spacing: 12) {
                    Divider().background(Color.white.opacity(0.1))
                    Button(action: { Task { await authManager.signOut() } }) {
                        Text(String(localized: "退出登录"))
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.red).foregroundColor(.white).cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    Button(action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text(String(localized: "删除账号"))
                        }
                        .font(.footnote).foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)
                }
                .background(ApocalypseTheme.background)

                } // VStack
            }
            .navigationBarHidden(true)
        }
        .task { await MailboxManager.shared.loadPendingItems() }
        .alert("删除账号？", isPresented: $showDeleteAlert) {
            TextField("输入 DELETE 确认", text: $deleteConfirmText)
            Button("确认删除", role: .destructive) {
                if deleteConfirmText == "DELETE" { Task { await authManager.deleteAccount() } }
                deleteConfirmText = ""
            }
            Button("取消", role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text(String(localized: "警告：此操作不可逆！您的所有数据将被永久删除。"))
        }
        // ✅ 添加详情弹窗
        .sheet(item: $showStatDetail) { detailType in
            StatDetailView(detailType: detailType, territoryManager: territoryManager, engine: engine, backpack: backpack)
        }
        .sheet(item: $showMiniStatDetail) { detailType in
            MiniStatDetailView(detailType: detailType, engine: engine, backpack: backpack)
        }
        .sheet(isPresented: $showJoinDateDetail) {
            JoinDateDetailView(daysSinceJoined: daysSinceJoined, joinedDate: authManager.currentUser?.createdAt ?? Date())
        }
        .sheet(isPresented: $showAchievementDetail) {
            CategoryAchievementStatsView()
        }
    }

    // MARK: - 头像视图

    @ViewBuilder
    private var avatarCircle: some View {
        if let data = Data(base64Encoded: avatarDataBase64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable().scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(brandOrange, lineWidth: 2))
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(brandOrange)
                )
                .overlay(Circle().stroke(brandOrange.opacity(0.5), lineWidth: 2))
        }
    }

    private var capacityColor: Color {
        if backpack.totalWeight >= backpack.maxCapacity { return .red }
        if backpack.totalWeight > backpack.maxCapacity * 0.8 { return .orange }
        return .green
    }
}

// MARK: - 小型统计卡片

struct MiniStatCard: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.caption).foregroundColor(color)
                Text(value).font(.system(.subheadline, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: 9)).foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(ApocalypseTheme.cardBackground.opacity(0.95))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.30), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 通用组件（保持原有）

struct StatItem: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.13)).font(.title2)
                Text(value).foregroundColor(.white).font(.title3).bold()
                Text(label).foregroundColor(.gray).font(.caption)
            }.frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuRow: View {
    let icon: String; let title: LocalizedStringKey; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white).frame(width: 25)
            Text(title).foregroundColor(.white)
            Spacer()
            if !value.isEmpty { Text(value).foregroundColor(.gray).font(.caption) }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }.padding().background(ApocalypseTheme.cardBackground.opacity(0.9))
    }
}

// MARK: - 统计详情类型

enum StatDetailType: String, Identifiable {
    case territories = "领地详情"
    case backpack = "背包详情"
    case survivors = "附近幸存者"
    var id: String { rawValue }

    var localizedDisplayName: String {
        switch self {
        case .territories: return String(localized: "领地详情")
        case .backpack: return String(localized: "背包详情")
        case .survivors: return String(localized: "附近幸存者")
        }
    }
}

enum MiniStatDetailType: String, Identifiable {
    case itemTypes = "物品种类"
    case itemCount = "物品数量"
    case nearbyPOIs = "附近资源"
    var id: String { rawValue }

    var localizedDisplayName: String {
        switch self {
        case .itemTypes: return String(localized: "物品种类")
        case .itemCount: return String(localized: "物品数量")
        case .nearbyPOIs: return String(localized: "附近资源")
        }
    }
}

// MARK: - 统计详情视图

struct StatDetailView: View {
    let detailType: StatDetailType
    @ObservedObject var territoryManager: TerritoryManager
    @ObservedObject var engine: EarthLordEngine
    @ObservedObject var backpack: ExplorationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    switch detailType {
                    case .territories:
                        TerritoryDetailContent(territoryManager: territoryManager)
                    case .backpack:
                        BackpackDetailContent(backpack: backpack)
                    case .survivors:
                        SurvivorsDetailContent(count: engine.nearbyPlayerCount)
                    }
                }
                .padding()
            }
            .navigationTitle(Text(LocalizedStringKey(detailType.rawValue)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct MiniStatDetailView: View {
    let detailType: MiniStatDetailType
    @ObservedObject var engine: EarthLordEngine
    @ObservedObject var backpack: ExplorationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    switch detailType {
                    case .itemTypes:
                        ItemTypesContent(backpack: backpack)
                    case .itemCount:
                        ItemCountContent(backpack: backpack)
                    case .nearbyPOIs:
                        NearbyPOIsContent(engine: engine)
                    }
                }
                .padding()
            }
            .navigationTitle(Text(LocalizedStringKey(detailType.rawValue)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

struct JoinDateDetailView: View {
    let daysSinceJoined: Int
    let joinedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text(String(localized: "加入 EarthLord"))
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    HStack {
                        Text(String(localized: "加入时间:"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(joinedDate))
                            .bold()
                    }
                    HStack {
                        Text(String(localized: "已生存:"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(daysSinceJoined) " + String(localized: "天"))
                            .bold()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("加入日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 详情内容视图

struct TerritoryDetailContent: View {
    @ObservedObject var territoryManager: TerritoryManager
    @ObservedObject var buildingManager = BuildingManager.shared
    @State private var selectedTerritory: Territory?
    @State private var showBuildingSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 总览卡片
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "已占领领地"))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text("\(territoryManager.myTerritories.count) " + String(localized: "个"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "可建造建筑"))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    Text("\(buildingManager.playerBuildings.count) " + String(localized: "个"))
                        .font(.title2.bold())
                        .foregroundColor(ApocalypseTheme.success)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
            }
            .padding(.bottom, 8)

            if territoryManager.myTerritories.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 48))
                        .foregroundColor(ApocalypseTheme.textMuted)

                    Text(String(localized: "尚未占领任何领地"))
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Text(String(localized: "前往地图页面开始圈地，占领你的第一块领地！"))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 领地列表
                ForEach(territoryManager.myTerritories) { territory in
                    ProfileTerritoryCard(
                        territory: territory,
                        buildingCount: buildingManager.playerBuildings.filter { $0.territoryId == territory.id }.count,
                        onTap: {
                            selectedTerritory = territory
                            showBuildingSheet = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showBuildingSheet) {
            if let territory = selectedTerritory {
                TerritoryBuildingSheet(territory: territory)
            }
        }
    }
}

// MARK: - 领地卡片

struct ProfileTerritoryCard: View {
    let territory: Territory
    let buildingCount: Int
    let onTap: () -> Void

    private var buildingStatusText: String {
        if buildingCount > 0 {
            return String(localized: "已建造") + " \(buildingCount) " + String(localized: "个") + String(localized: "建筑")
        } else {
            return String(localized: "暂无建筑")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 领地信息头部
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(territory.displayName)
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Label("\(Int(territory.area)) ㎡", systemImage: "square.grid.3x3")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)

                            Label("\(territory.displayPointCount) 点", systemImage: "mappin.circle")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }

                    Spacer()

                    // 等级徽章
                    if let level = territory.level {
                        Text("Lv.\(level)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ApocalypseTheme.warning)
                            .cornerRadius(6)
                    }
                }

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))

                // 建造状态
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(buildingCount > 0 ? ApocalypseTheme.success : ApocalypseTheme.textMuted)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(buildingStatusText)
                            .font(.caption)
                            .foregroundColor(buildingCount > 0 ? ApocalypseTheme.success : ApocalypseTheme.textSecondary)

                        if buildingCount == 0 {
                            Text(String(localized: "点击此处开始建造"))
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.warning)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 领地建造弹窗

struct TerritoryBuildingSheet: View {
    let territory: Territory
    @ObservedObject var buildingManager = BuildingManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 领地信息
                    VStack(spacing: 8) {
                        Text(territory.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        HStack(spacing: 16) {
                            Label("\(Int(territory.area)) ㎡", systemImage: "square.grid.3x3")
                            Label("\(territory.displayPointCount) 点", systemImage: "mappin.circle")
                            if let level = territory.level {
                                Label("Lv.\(level)", systemImage: "star.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                    .padding()
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(12)

                    // 建筑列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "可建造建筑"))
                            .font(.headline)
                            .foregroundColor(.white)

                        if buildingManager.buildingTemplates.isEmpty {
                            Text(String(localized: "暂无可建造建筑"))
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        } else {
                            ForEach(buildingManager.buildingTemplates, id: \.templateId) { template in
                                BuildingTemplateCard(
                                    template: template,
                                    territoryId: territory.id
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .background(ApocalypseTheme.background)
            .navigationTitle("领地管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 建筑模板卡片

struct BuildingTemplateCard: View {
    let template: BuildingTemplate
    let territoryId: String
    @ObservedObject var buildingManager = BuildingManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(ApocalypseTheme.warning)
                    .frame(width: 44, height: 44)
                    .background(ApocalypseTheme.warning.opacity(0.2))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()
            }

            // 资源需求
            if !template.requiredResources.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "cube.box.fill")
                        .font(.caption2)
                    Text(String(localized: "需要:") + " \(template.requiredResources.values.reduce(0, +)) " + String(localized: "资源"))
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            // 建造按钮
            Button(action: {
                Task {
                    // TODO: 实现建造逻辑
                }
            }) {
                HStack {
                    Image(systemName: "hammer.fill")
                    Text(String(localized: "建造"))
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(buildingManager.playerBuildings.filter({ $0.territoryId == territoryId && $0.templateId == template.templateId }).count >= template.maxPerTerritory ? ApocalypseTheme.textMuted : ApocalypseTheme.primary)
                .cornerRadius(10)
            }
            .disabled(buildingManager.playerBuildings.filter({ $0.territoryId == territoryId && $0.templateId == template.templateId }).count >= template.maxPerTerritory)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BackpackDetailContent: View {
    @ObservedObject var backpack: ExplorationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(String(localized: "背包容量使用情况"))
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text(String(localized: "当前负重"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f kg", backpack.totalWeight))
                        .font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(localized: "最大容量"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(backpack.maxCapacity)) kg")
                        .font(.title2.bold())
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Text(String(localized: "提示: 探索时可获得物资，请注意背包负重。"))
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}

struct SurvivorsDetailContent: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(String(localized: "附近幸存者说明"))
                .font(.headline)

            HStack(spacing: 15) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("附近幸存者: \(count) " + String(localized: "人"))
                        .font(.title2.bold())
                    Text(String(localized: "雷达扫描范围内的其他幸存者"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Text("幸存者数量每 30 秒更新一次，基于雷达探测范围计算。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ItemTypesContent: View {
    @ObservedObject var backpack: ExplorationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("物品种类统计")
                .font(.headline)

            // 简化版本：直接显示所有物品
            let uniqueCategories = Set(backpack.backpackItems.map { $0.category.rawValue })
            let sortedCategories = uniqueCategories.sorted()

            ForEach(Array(sortedCategories.enumerated()), id: \.offset) { _, categoryRaw in
                let itemsInCategory = backpack.backpackItems.filter { $0.category.rawValue == categoryRaw }

                HStack {
                    Text(categoryRaw)
                    Spacer()
                    Text("\(itemsInCategory.count) 种")
                        .bold()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct ItemCountContent: View {
    @ObservedObject var backpack: ExplorationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("物品数量详情")
                .font(.headline)

            Text("总物品数: \(backpack.backpackItems.reduce(0) { $0 + $1.quantity }) 件")
                .font(.headline)

            ForEach(backpack.backpackItems.prefix(10)) { item in
                HStack {
                    Image(systemName: item.icon)
                    Text(item.name)
                    Spacer()
                    Text("x\(item.quantity)")
                        .bold()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct NearbyPOIsContent: View {
    @ObservedObject var engine: EarthLordEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("附近资源点")
                .font(.headline)

            if engine.nearbyPOIs.isEmpty {
                Text("暂无资源点，点击\"扫描附近资源点\"开始探索")
                    .foregroundColor(.secondary)
            } else {
                ForEach(engine.nearbyPOIs) { poi in
                    HStack {
                        Circle()
                            .fill(poi.rarity.color.opacity(0.2))
                            .frame(width: 30, height: 30)
                        Text(poi.name)
                        Spacer()
                        Text(poi.rarity.rawValue)
                            .font(.caption)
                            .foregroundColor(poi.rarity.color)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}
