//
//  StatusCardView.swift
//  EarthLord
//
//  状态提示卡��组件
//

import SwiftUI

// MARK: - 状态卡片类型

enum StatusCardType {
    case exploration  // 探索
    case territory    // 圈地
    case building     // 建造
}

// MARK: - 状态卡片视图

struct StatusCardView: View {
    let type: StatusCardType
    let isVisible: Bool
    let progress: Double
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 顶部拖动条
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // 卡片内容
            VStack(spacing: 20) {
                // 图标和标题
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(cardColor.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: iconName)
                            .font(.system(size: 28))
                            .foregroundColor(cardColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }

                    Spacer()
                }

                // 进度条
                if progress > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("进度")
                                .font(.caption)
                                .foregroundColor(ApocalypseTheme.textSecondary)

                            Spacer()

                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(cardColor)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cardColor)
                                    .frame(width: geometry.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }

                // 提示信息
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(cardColor)
                            .font(.caption)

                        Text(message)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // 额外提示
                    ForEach(tips, id: \.self) { tip in
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(ApocalypseTheme.warning)
                                .font(.caption2)

                            Text(tip)
                                .font(.caption2)
                                .foregroundColor(ApocalypseTheme.textMuted)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)

                // 关闭按钮
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("关闭")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(cardColor.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ApocalypseTheme.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 计算属性

    private var cardColor: Color {
        switch type {
        case .exploration:
            return .green
        case .territory:
            return .orange
        case .building:
            return .blue
        }
    }

    private var iconName: String {
        switch type {
        case .exploration:
            return "figure.walk"
        case .territory:
            return "map.fill"
        case .building:
            return "hammer.fill"
        }
    }

    private var title: String {
        switch type {
        case .exploration:
            return "探索中"
        case .territory:
            return "圈地中"
        case .building:
            return "建造中"
        }
    }

    private var subtitle: String {
        switch type {
        case .exploration:
            return "正在搜刮资源..."
        case .territory:
            return "正在标记领地..."
        case .building:
            return "正在建造建筑..."
        }
    }

    private var tips: [String] {
        switch type {
        case .exploration:
            return [
                "探索会消耗行走距离",
                "可以搜刮到各种稀有资源",
                "注意体力值管理"
            ]
        case .territory:
            return [
                "保持移动以采样更多点",
                "采样点越多，领地面积越大",
                "圈地完成后可建造建筑"
            ]
        case .building:
            return [
                "建筑需要消耗资源",
                "建筑等级影响产出效率",
                "可在领地中升级建筑"
            ]
        }
    }
}

// MARK: - 预览

struct StatusCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StatusCardView(
                type: .exploration,
                isVisible: true,
                progress: 0.65,
                message: "正在搜索附近的资源点...",
                onDismiss: {}
            )

            StatusCardView(
                type: .territory,
                isVisible: true,
                progress: 0.4,
                message: "已记录3个采样点，还需2个点完成圈地",
                onDismiss: {}
            )
        }
        .padding()
        .background(ApocalypseTheme.background)
    }
}
