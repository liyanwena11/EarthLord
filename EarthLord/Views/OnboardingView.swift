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
    let subtitle: String
    let description: String
    let iconName: String
    let iconColor: Color
    let gradientColors: [Color]
    let features: [String]
}

// MARK: - 引导页面数据

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "欢迎来到 EarthLord",
            subtitle: "末日后生存冒险游戏",
            description: "2048年，末日后的人类文明正在重建。成为新时代的开拓者，用脚步丈量废土，建立属于你的领地！",
            iconName: "globe.americas.fill",
            iconColor: ApocalypseTheme.primary,
            gradientColors: [ApocalypseTheme.primary, Color.orange],
            features: ["真实世界地图", "末日生存主题", "角色扮演冒险"]
        ),
        OnboardingPage(
            id: 1,
            title: "探索真实世界",
            subtitle: "基于真实地理位置的冒险",
            description: "走出避难所，在真实世界中探索POI地点。行走发现废墟、商场、医院等地点，搜刮珍贵生存物资！",
            iconName: "map.fill",
            iconColor: Color.green,
            gradientColors: [Color.green, Color.mint],
            features: ["发现POI地点", "行走搜刮物资", "真实地图导航"]
        ),
        OnboardingPage(
            id: 2,
            title: "圈地建领地",
            subtitle: "打造你的末日堡垒",
            description: "在地图上绘制封闭区域创建领地。圈地越大，防御加成越高。消耗资源建造避难所、农场、仓库！",
            iconName: "flag.fill",
            iconColor: Color.blue,
            gradientColors: [Color.blue, Color.cyan],
            features: ["绘制封闭区域", "建造多样建筑", "获得防御加成"]
        ),
        OnboardingPage(
            id: 3,
            title: "组队社交交易",
            subtitle: "与其他幸存者互动",
            description: "加入频道与全球玩家交流，与其他幸存者交易物资。最多4人组队联机，共同探索末日世界！",
            iconName: "person.2.fill",
            iconColor: Color.purple,
            gradientColors: [Color.purple, Color.pink],
            features: ["实时频道聊天", "玩家自由交易", "组队联机冒险"]
        ),
        OnboardingPage(
            id: 4,
            title: "每日挑战与成就",
            subtitle: "持续成长的动力",
            description: "完成每日任务获得丰厚奖励，解锁成就获得永久加成。提升领地等级，解锁更多建筑和功能！",
            iconName: "star.fill",
            iconColor: Color.yellow,
            gradientColors: [Color.yellow, Color.orange],
            features: ["每日任务奖励", "成就永久加成", "领地等级提升"]
        )
    ]
}

// MARK: - 主引导视图

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var appeared = false
    @Binding var isShown: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // 动态背景效果
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // 背景光晕动画
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(
                        x: CGFloat(index) * 100 - 100,
                        y: CGFloat(index) * 150 - 150
                    )
                    .animation(
                        Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                        value: appeared
                    )
            }

            // 主卡片
            VStack(spacing: 0) {
                // 顶部装饰条
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [ApocalypseTheme.primary, Color.white.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 4)
                    .padding(.top, 16)

                // 内容区域
                TabView(selection: $currentPage) {
                    ForEach(OnboardingPage.pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                // 底部指示器和按钮
                VStack(spacing: 28) {
                    // 页面指示器 - 带数字
                    HStack(spacing: 12) {
                        ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentPage = index
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(currentPage == index ? ApocalypseTheme.primary : Color.white.opacity(0.15))
                                        .frame(width: currentPage == index ? 32 : 28, height: currentPage == index ? 32 : 28)

                                    if currentPage == index {
                                        Circle()
                                            .stroke(ApocalypseTheme.primary.opacity(0.5), lineWidth: 2)
                                            .frame(width: 40, height: 40)
                                            .scaleEffect(appeared ? 1 : 0.5)
                                            .opacity(appeared ? 1 : 0)
                                    }

                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(currentPage == index ? .white : Color.white.opacity(0.5))
                                }
                            }
                            .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            // 进度
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (CGFloat(currentPage + 1) / CGFloat(OnboardingPage.pages.count)), height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 40)

                    // 按钮区域
                    HStack {
                        // 跳过按钮
                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("跳过")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                        }

                        Spacer()

                        // 下一步/开始按钮
                        Button(action: {
                            if currentPage < OnboardingPage.pages.count - 1 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage < OnboardingPage.pages.count - 1 ? "下一页" : "开始游戏")
                                    .font(.system(size: 16, weight: .bold))

                                Image(systemName: currentPage < OnboardingPage.pages.count - 1 ? "arrow.right" : "sparkles")
                                    .font(.system(size: 14, weight: .bold))
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
                            .shadow(color: ApocalypseTheme.primary.opacity(0.4), radius: 12, y: 4)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(ApocalypseTheme.cardBackground)
                    .shadow(color: .black.opacity(0.6), radius: 40, y: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary.opacity(0.6),
                                Color.white.opacity(0.15),
                                ApocalypseTheme.primary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 24)
            .scaleEffect(appeared ? 1 : 0.95)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
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
    @State private var isAppeared = false

    var body: some View {
        VStack(spacing: 20) {
            // 图标区域
            ZStack {
                // 背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.iconColor.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAppeared ? 1 : 0.8)
                    .opacity(isAppeared ? 1 : 0)

                // 图标背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.iconColor.opacity(0.3), page.iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAppeared ? 1 : 0.9)
                    .opacity(isAppeared ? 1 : 0)

                // 图标
                Image(systemName: page.iconName)
                    .font(.system(size: 55, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.iconColor, page.iconColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(isAppeared ? 1 : 0.5)
                    .opacity(isAppeared ? 1 : 0)
            }
            .padding(.top, 10)

            // 标题
            VStack(spacing: 4) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if !page.subtitle.isEmpty {
                    Text(page.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(page.iconColor)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)

            // 描述
            Text(page.description)
                .font(.system(size: 15))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 20)

            // 功能特点
            VStack(spacing: 10) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(page.iconColor)

                        Text(feature)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .opacity(isAppeared ? 1 : 0)
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - 预览

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isShown: .constant(true), onComplete: {})
            .background(ApocalypseTheme.background)
    }
}
