//
//  OnboardingView.swift
//  EarthLord
//
//  新手引导视图
//

import SwiftUI

// MARK: - 引导页面数据模型

struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]
}

// MARK: - 引导页面数据

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "欢迎来到新世界",
            description: "2048年，末日后的人类文明正在重建。成为新时代的开拓者，用脚步丈量废土，建立属于你的领地！",
            iconName: "globe.americas.fill",
            iconColor: ApocalypseTheme.primary,
            gradientColors: [ApocalypseTheme.primary, Color.orange]
        ),
        OnboardingPage(
            id: 1,
            title: "探索废土",
            description: "走出避难所，在真实世界中探索POI地点。行走发现废墟、商场、医院等地点，搜刮珍贵生存资源！",
            iconName: "figure.walk",
            iconColor: Color.green,
            gradientColors: [Color.green, Color.mint]
        ),
        OnboardingPage(
            id: 2,
            title: "建造领地",
            description: "圈占土地后，消耗资源建造避难所、农场、仓库等建筑。升级设施，打造你的末日生存堡垒！",
            iconName: "hammer.fill",
            iconColor: Color.blue,
            gradientColors: [Color.blue, Color.cyan]
        ),
        OnboardingPage(
            id: 3,
            title: "交易与社交",
            description: "与其他幸存者交易物资、组建联盟。加入频道与全球玩家交流，共同在末日中生存下去！",
            iconName: "person.2.fill",
            iconColor: Color.purple,
            gradientColors: [Color.purple, Color.pink]
        )
    ]
}

// MARK: - 主引导视图

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isShown: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景不关闭
                }

            // 主卡片
            VStack(spacing: 0) {
                // 顶部装饰条
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                // 内容区域
                TabView(selection: $currentPage) {
                    ForEach(OnboardingPage.pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // 底部指示器和按钮
                VStack(spacing: 24) {
                    // 页面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? ApocalypseTheme.primary : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // 按钮区域
                    HStack {
                        // 跳过按钮
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("跳过")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.5))
                        }

                        Spacer()

                        // 下一步/开始按钮
                        Button(action: {
                            if currentPage < OnboardingPage.pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage < OnboardingPage.pages.count - 1 ? "下一步" : "开始游戏")
                                    .font(.system(size: 16, weight: .bold))

                                if currentPage < OnboardingPage.pages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: ApocalypseTheme.primary.opacity(0.4), radius: 10, y: 4)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ApocalypseTheme.cardBackground)
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary.opacity(0.5),
                                Color.white.opacity(0.1),
                                ApocalypseTheme.primary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 24)
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShown = false
        }
        onComplete()
    }
}

// MARK: - 单页引导视图

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            // 图标区域
            ZStack {
                // 背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.iconColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // 图标背景
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)

                // 图标
                Image(systemName: page.iconName)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.iconColor, page.iconColor.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.top, 20)

            // 标题
            Text(page.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // 描述
            Text(page.description)
                .font(.system(size: 15))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - 预览

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isShown: .constant(true), onComplete: {})
            .background(ApocalypseTheme.background)
    }
}
