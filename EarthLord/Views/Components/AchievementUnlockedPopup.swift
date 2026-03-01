//
//  AchievementUnlockedPopup.swift
//  EarthLord
//
//  Created by Claude on 2026-02-26.
//  成就解锁弹窗组件
//

import SwiftUI

/// 成就解锁弹窗视图
struct AchievementUnlockedPopup: View {

    // MARK: - Properties
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var particleOffset: CGFloat = 0

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景遮罩
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                // 弹窗内容
                VStack(spacing: 0) {
                    Spacer()
                        .frame(maxHeight: geometry.size.height * 0.3)

                    popupContent
                }
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Popup Content
    private var popupContent: some View {
        VStack(spacing: 0) {
            // 成就卡片
            VStack(spacing: 16) {
                // 光晕效果
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.yellow.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0 : 1)

                // 成就图标
                ZStack {
                    // 外圈光晕
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 3)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )

                    // 图标背景
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255), Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)

                    // 图标
                    Text(achievement.icon)
                        .font(.system(size: 40))
                        .scaleEffect(scale)
                }

                // 解锁标题
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))

                    Text("成就解锁！")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)

                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }

                // 成就信息
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    // 积分奖励
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))

                        Text("+\(achievement.reward.points) 积分")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                }

                // 按钮
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("稍后")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 40)
                            .background(Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255))
                            .cornerRadius(8)
                    }

                    Button {
                        // TODO: 跳转到详情
                        dismiss()
                    } label: {
                        Text("查看详情")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 100, height: 40)
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0x1E/255, green: 0x24/255, blue: 0x33/255))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)

            Spacer()
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }

        withAnimation(.linear(duration: 0.3).delay(0.3)) {
            isAnimating = true
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            scale = 0.5
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

/// 粒子特效视图
struct ParticleEffectView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(0..<12) { index in
                Particle(
                    angle: .degrees(Double(index) * 30),
                    isAnimating: isAnimating
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

/// 单个粒子
struct Particle: View {
    let angle: Angle
    let isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
                .offset(
                    x: cos(angle.radians) * (isAnimating ? 100 : 0),
                    y: sin(angle.radians) * (isAnimating ? 100 : 0)
                )
                .opacity(isAnimating ? 0 : 1)
        }
    }
}

// MARK: - Preview
#Preview {
    AchievementUnlockedPopup(
        achievement: Achievement(
            id: UUID().uuidString,
            category: .exploration,
            title: "探索先锋",
            description: "搜刮100个不同的地点",
            icon: "🗺️",
            requirement: .poiScavenged(count: 100),
            reward: AchievementReward(
                points: 500,
                badge: nil,
                title: "探索家",
                resources: [],
                experience: 100,
                emblemId: nil,
                bonusResources: [:]
            ),
            difficulty: .rare,
            isUnlocked: true,
            unlockedAt: Date(),
            progress: 1.0,
            wasUnlocked: false
        ),
        onDismiss: {}
    )
}
