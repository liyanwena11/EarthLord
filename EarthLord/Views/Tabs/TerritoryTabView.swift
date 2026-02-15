import SwiftUI

struct TerritoryTabView: View {
    @State private var myTerritories: [Territory] = []
    @State private var isLoading = false
    @State private var selectedTerritory: Territory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 顶部统计
                    HStack(spacing: 15) {
                        StatCard(
                            icon: "flag.fill",
                            iconColor: .green,
                            title: "领地数量",
                            value: "\(myTerritories.count)",
                            unit: "块"
                        )
                        StatCard(
                            icon: "map.fill",
                            iconColor: .blue,
                            title: "总面积",
                            value: formatArea(totalArea),
                            unit: "㎡"
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - 领地列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text("我的领地")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        if myTerritories.isEmpty {
                            EmptyTerritoryView()
                        } else {
                            ForEach(myTerritories) { territory in
                                TerritoryCard(territory: territory)
                                    .onTapGesture {
                                        selectedTerritory = territory
                                    }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("领地管理")
            .task {
                await loadMyTerritories()
            }
            .onReceive(NotificationCenter.default.publisher(for: .territoryUpdated)) { _ in
                Task { await loadMyTerritories() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .territoryDeleted)) { _ in
                Task { await loadMyTerritories() }
            }
            .fullScreenCover(item: $selectedTerritory) { territory in
                TerritoryDetailView(
                    territory: territory,
                    onDelete: {
                        Task { await loadMyTerritories() }
                    }
                )
            }
        }
    }

    private var totalArea: Double {
        myTerritories.reduce(0) { $0 + $1.area }
    }

    private func loadMyTerritories() async {
        isLoading = true
        do {
            let territories = try await TerritoryManager.shared.loadMyTerritories()
            await MainActor.run {
                self.myTerritories = territories
                self.isLoading = false
            }
        } catch {
            print("[TerritoryTabView] 加载领地失败: \(error.localizedDescription)")
            await MainActor.run { self.isLoading = false }
        }
    }

    private func formatArea(_ area: Double) -> String {
        if area >= 10000 {
            return String(format: "%.1f万", area / 10000)
        } else {
            return String(format: "%.0f", area)
        }
    }
}

// MARK: - 领地卡片

struct TerritoryCard: View {
    let territory: Territory

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)

                    Text(territory.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(Int(territory.area)) ㎡")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            Divider()
                .padding(.vertical, 10)

            HStack {
                if let pointCount = territory.pointCount {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle").font(.caption)
                        Text("采样点: \(pointCount) 个").font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if let createdAt = territory.createdAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.caption)
                        Text(createdAt.prefix(10)).font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .cornerRadius(10)

            Text(title).font(.caption).foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title).fontWeight(.bold).foregroundColor(.primary)
                Text(unit).font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 空状态

struct EmptyTerritoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无领地").font(.title3).fontWeight(.medium).foregroundColor(.secondary)
            Text("前往地图页面，点击「圈地」按钮开始行走采样！")
                .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
