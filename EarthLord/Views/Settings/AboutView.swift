import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    // 从Bundle获取应用版本信息
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // 应用图标和名称
                        VStack(spacing: 20) {
                            // 应用Logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [ApocalypseTheme.primary, ApocalypseTheme.primary.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "globe.asia.australia.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: ApocalypseTheme.primary.opacity(0.5), radius: 10)

                            VStack(spacing: 8) {
                                Text("EarthLord")
                                    .font(.title.bold())
                                    .foregroundColor(.white)

                                Text("地球新主")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            // 版本信息
                            VStack(spacing: 5) {
                                HStack(spacing: 5) {
                                    Text("版本")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(appVersion)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }

                                HStack(spacing: 5) {
                                    Text("构建")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(buildNumber)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }

                        // 应用简介
                        VStack(alignment: .leading, spacing: 15) {
                            Text("应用简介")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("《地球新主》是一款基于GPS定位的LBS生存游戏。在2051年的末日世界中，你作为一名开拓者，通过真实世界行走来圈占领地、探索资源、建造家园，并与其他玩家进行交易和社交。")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(5)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 核心功能
                        VStack(alignment: .leading, spacing: 15) {
                            Text("核心功能")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 12) {
                                AboutFeatureRow(icon: "flag.fill", title: "GPS圈地", description: "通过真实行走圈占领地")
                                AboutFeatureRow(icon: "magnifyingglass.fill", title: "探索搜刮", description: "基于真实POI的资源探索")
                                AboutFeatureRow(icon: "building.2.fill", title: "建造系统", description: "在领地上建造建筑")
                                AboutFeatureRow(icon: "arrow.left.arrow.right", title: "交易系统", description: "玩家间物品交易")
                                AboutFeatureRow(icon: "antenna.radiowaves.left.and.right", title: "通讯系统", description: "基于距离的社交通讯")
                                AboutFeatureRow(icon: "figure.walk", title: "行走奖励", description: "Walk to Earn机制")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 官方链接
                        VStack(alignment: .leading, spacing: 15) {
                            Text("官方链接")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(spacing: 1) {
                                Link(destination: URL(string: "https://liyanwena11.github.io/earthlord-support/")!) {
                                    AboutLinkRow(icon: "globe", title: "官方网站", subtitle: "访问官网获取更多信息", iconColor: .blue)
                                }

                                Link(destination: URL(string: "https://liyanwena11.github.io/earthlord-support/privacy.html")!) {
                                    AboutLinkRow(icon: "lock.shield.fill", title: "隐私政策", subtitle: "查看隐私政策", iconColor: .green)
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))
                        }

                        // 开发信息
                        VStack(alignment: .leading, spacing: 15) {
                            Text("开发信息")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                AboutInfoRow(label: "开发商", value: "EarthLord Team")
                                AboutInfoRow(label: "发布日期", value: "2025")
                                AboutInfoRow(label: "平台", value: "iOS 15.0+")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))

                        // 版权信息
                        VStack(spacing: 10) {
                            Text("© 2025 EarthLord Team. All rights reserved.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)

                            Text("Made with ❤️ for survivors")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                        .padding(.bottom, 50)

                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.primary)
                .font(.system(size: 16))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct AboutLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }
}

struct AboutInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    AboutView()
}
