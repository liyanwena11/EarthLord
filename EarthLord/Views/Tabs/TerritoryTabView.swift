import SwiftUI

struct TerritoryTabView: View {
    @StateObject private var engine = EarthLordEngine.shared

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
                            value: "\(engine.claimedTerritories.count)",
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

                        if engine.claimedTerritories.isEmpty {
                            EmptyTerritoryView()
                        } else {
                            ForEach(engine.claimedTerritories) { territory in
                                LocalTerritoryCard(territory: territory)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("领地管理")
        }
    }

    private var totalArea: Double {
        engine.claimedTerritories.reduce(0) { $0 + $1.area }
    }

    private func formatArea(_ area: Double) -> String {
        if area >= 10000 {
            return String(format: "%.1f万", area / 10000)
        } else {
            return String(format: "%.0f", area)
        }
    }
}

// MARK: - 实时领地卡片

struct LocalTerritoryCard: View {
    let territory: TerritoryModel

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

                    Text(territory.name)
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
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle").font(.caption)
                    Text("采样点: \(territory.pointCount) 个").font(.caption)
                }
                .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.caption)
                    Text(formatDate(territory.claimedAt)).font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
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
