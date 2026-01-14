import SwiftUI

struct TerritoryTabView: View {
    @State private var territories: [Territory] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 顶部统计区（两个横向卡片）
                    HStack(spacing: 15) {
                        // 左侧：领地数量
                        StatCard(
                            icon: "flag.fill",
                            iconColor: .green,
                            title: "领地数量",
                            value: "\(territories.count)",
                            unit: "块"
                        )

                        // 右侧：总面积
                        StatCard(
                            icon: "map.fill",
                            iconColor: .blue,
                            title: "总面积",
                            value: formatArea(totalArea),
                            unit: "㎡"
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - 列表区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("我的领地")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        if isLoading {
                            // 加载中
                            ProgressView("加载中...")
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if territories.isEmpty {
                            // 空状态
                            EmptyTerritoryView()
                        } else {
                            // 领地列表
                            ForEach(territories) { territory in
                                NavigationLink(destination: TerritoryDetailView(territory: territory)) {
                                    TerritoryCard(territory: territory)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("领地管理")
            .refreshable {
                await loadTerritories()
            }
            .task {
                await loadTerritories()
            }
        }
    }

    // MARK: - 计算属性

    private var totalArea: Double {
        territories.reduce(0) { $0 + $1.area }
    }

    // MARK: - 方法

    private func loadTerritories() async {
        isLoading = true
        territories = (try? await TerritoryManager.shared.loadMyTerritories()) ?? []
        isLoading = false
    }

    private func formatArea(_ area: Double) -> String {
        if area >= 10000 {
            return String(format: "%.1f万", area / 10000)
        } else {
            return String(format: "%.0f", area)
        }
    }
}

// MARK: - 统计卡片组件

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .cornerRadius(10)

            // 标题
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            // 数值
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 领地卡片组件

struct TerritoryCard: View {
    let territory: Territory

    var body: some View {
        VStack(spacing: 0) {
            // 上半部分：标题 + 面积
            HStack {
                // 左侧：图标 + 标题
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)

                    Text(territory.name ?? "未命名领地")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // 右侧：面积
                Text("\(Int(territory.area)) ㎡")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            Divider()
                .padding(.vertical, 10)

            // 下半部分：点数 + 日期
            HStack {
                // 左下角：采样点数
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.caption)
                    Text("采样点: \(territory.pointCount ?? 0) 个")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Spacer()

                // 右下角：日期时间
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(formatDate())
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func formatDate() -> String {
        // Territory 模型暂无日期字段，显示模拟日期
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - 空状态视图

struct EmptyTerritoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("暂无领地")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("快去地图页面圈地吧！")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    TerritoryTabView()
}
