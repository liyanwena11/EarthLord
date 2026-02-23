import SwiftUI

// MARK: - 末日风翻盖开箱动画

struct SupplyBoxOpeningView: View {
    let items: [PackItem]
    let onDismiss: () -> Void

    @State private var phase: OpenPhase = .idle
    @State private var shakeOffset: CGFloat = 0
    @State private var lidAngle: Double = 0
    @State private var lidOpacity: Double = 1
    @State private var dustOpacity: Double = 0
    @State private var dustScale: CGFloat = 0.5
    @State private var revealedItems: [PackItem] = []
    @State private var itemOpacities: [UUID: Double] = [:]
    @State private var itemOffsets: [UUID: CGFloat] = [:]
    @State private var goldGlowItems: Set<UUID> = []

    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    enum OpenPhase {
        case idle, shaking, lidOpening, dustEffect, revealItems, done
    }

    var body: some View {
        ZStack {
            // 全屏暗背景
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: 箱子区域
                ZStack {
                    // 箱体
                    boxBody

                    // 箱盖（旋转动画）
                    boxLid
                        .rotation3DEffect(
                            .degrees(lidAngle),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .top
                        )
                        .opacity(lidOpacity)

                    // 灰尘粒子
                    dustEffect
                        .opacity(dustOpacity)
                        .scaleEffect(dustScale)
                }
                .frame(width: 160, height: 160)
                .offset(x: shakeOffset)

                Spacer().frame(height: 48)

                // MARK: 物品列表区域
                if phase == .revealItems || phase == .done {
                    itemsGrid
                        .transition(.opacity)
                }

                Spacer()

                // MARK: 完成按钮
                if phase == .done {
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("前往邮箱领取")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brandOrange)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { startAnimation() }
    }

    // MARK: - Box Views

    private var boxBody: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.25), Color(white: 0.15)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 140, height: 100)
            .offset(y: 30)
            .overlay(
                // 铁锁/铆钉装饰
                HStack(spacing: 20) {
                    rivet; rivet; rivet
                }
                .offset(y: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.4), lineWidth: 1.5)
                    .offset(y: 30)
            )
    }

    private var rivet: some View {
        Circle()
            .fill(Color(white: 0.5))
            .frame(width: 8, height: 8)
            .overlay(Circle().stroke(Color(white: 0.6), lineWidth: 0.5))
    }

    private var boxLid: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.35), Color(white: 0.22)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 50)
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.5), lineWidth: 1.5)
                .frame(width: 150, height: 50)
            // 锁扣
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.6))
                .frame(width: 24, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(white: 0.8), lineWidth: 1)
                )
        }
        .offset(y: -20)
    }

    private var dustEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color(white: 0.6).opacity(0.5))
                    .frame(width: CGFloat.random(in: 4...12))
                    .offset(
                        x: CGFloat.random(in: -60...60),
                        y: CGFloat.random(in: -40...20)
                    )
            }
        }
    }

    // MARK: - Items Grid

    private var itemsGrid: some View {
        VStack(spacing: 12) {
            Text("物资清单")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(revealedItems) { item in
                    itemCard(item)
                        .opacity(itemOpacities[item.id] ?? 0)
                        .offset(y: itemOffsets[item.id] ?? 20)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func itemCard(_ item: PackItem) -> some View {
        let rarityColor: Color = {
            switch item.rarity {
            case "rare":      return .blue
            case "epic":      return .purple
            case "legendary": return Color(red: 1, green: 0.8, blue: 0)
            default:          return Color(white: 0.4)
            }
        }()

        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rarityColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(rarityColor.opacity(goldGlowItems.contains(item.id) ? 0.9 : 0.3), lineWidth: 1.5)
                    )
                    .shadow(color: goldGlowItems.contains(item.id) ? rarityColor : .clear, radius: 8)

                Text(itemEmoji(item.itemId))
                    .font(.title3)
            }

            Text(item.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            Text("x\(item.quantity)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(rarityColor)
        }
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        phase = .shaking

        // 1. 铁锁震动
        withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)) {
            shakeOffset = 8
        }

        // 2. 箱盖弹开
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            phase = .lidOpening
            withAnimation(.easeIn(duration: 0.35)) {
                lidAngle = -110
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.2)) {
                lidOpacity = 0
                shakeOffset = 0
            }
        }

        // 3. 灰尘粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            phase = .dustEffect
            withAnimation(.easeOut(duration: 0.4)) {
                dustOpacity = 1
                dustScale = 1.4
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                dustOpacity = 0
            }
        }

        // 4. 物品逐个飞出
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            phase = .revealItems
            revealedItems = items

            for (index, item) in items.enumerated() {
                itemOpacities[item.id] = 0
                itemOffsets[item.id] = 20

                let delay = Double(index) * 0.12
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        itemOpacities[item.id] = 1
                        itemOffsets[item.id] = 0
                    }
                    // Gold glow for rare+
                    if item.rarity != "common" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeIn(duration: 0.2)) {
                                _ = goldGlowItems.insert(item.id)
                            }
                        }
                    }
                }
            }

            // 5. 完成按钮
            let totalDelay = Double(items.count) * 0.12 + 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.spring()) { phase = .done }
            }
        }
    }

    private func itemEmoji(_ itemId: String) -> String {
        let map: [String: String] = [
            "water":            "💧",
            "canned_food":      "🥫",
            "wood":             "🪵",
            "stone":            "🪨",
            "metal":            "⚙️",
            "glass":            "🪟",
            "cloth":            "🧵",
            "bandage":          "🩹",
            "first_aid_kit":    "🩺",
            "electronic_part":  "🔌",
            "mechanical_part":  "🔩",
            "solar_panel":      "🔋",
            "satellite_module": "📡",
            "ancient_tech":     "⚗️",
        ]
        return map[itemId] ?? "📦"
    }
}
