import SwiftUI

struct MoreTabView: View {
    @AppStorage("push_notifications") private var pushEnabled = true
    @AppStorage("game_audio") private var audioEnabled = true
    @AppStorage("haptic_feedback") private var hapticEnabled = true

    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Control Center")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {

                            // 开发者测试入口
                            SectionHeader(icon: "wrench.and.screwdriver.fill", title: "Developer Tools", subtitle: "Test and debug features")

                            NavigationLink(destination: TestMenuView()) {
                                QuickAccessButton(icon: "testtube.2", title: "Development Tests", color: .purple)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // 快捷访问
                            SectionHeader(icon: "star.fill", title: "Quick Access", subtitle: "Quick access to common features")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                Button(action: { print("Data Statistics tapped") }) {
                                    QuickAccessButton(icon: "chart.bar.fill", title: "Data Statistics", color: .blue)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: { print("Achievement tapped") }) {
                                    QuickAccessButton(icon: "trophy.fill", title: "Achievement System", color: .yellow)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: { print("Friends tapped") }) {
                                    QuickAccessButton(icon: "person.2.fill", title: "Friends List", color: .green)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: { print("Messages tapped") }) {
                                    QuickAccessButton(icon: "envelope.fill", title: "Message Center", color: .red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // 游戏设置
                            SectionHeader(icon: "gearshape.fill", title: "Game Settings", subtitle: "Personalize your game experience")

                            VStack(spacing: 1) {
                                SettingSwitchRow(icon: "bell.fill", title: "Push Notifications", subtitle: "Receive territory and resource updates", isOn: $pushEnabled, iconColor: .orange)
                                SettingSwitchRow(icon: "speaker.wave.2.fill", title: "Game Audio", subtitle: "Enable background music and sound effects", isOn: $audioEnabled, iconColor: .blue)
                                SettingSwitchRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback", subtitle: "Vibration feedback during operations", isOn: $hapticEnabled, iconColor: .yellow)
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(brandOrange.opacity(0.2), lineWidth: 1))

                            // 数据与隐私
                            SectionHeader(icon: "shield.lefthalf.filled", title: "Data & Privacy", subtitle: "Manage your data and privacy settings")

                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
}

// MARK: - 子组件

struct SectionHeader: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct QuickAccessButton: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct SettingSwitchRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @Binding var isOn: Bool
    let iconColor: Color

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.orange)
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
}
