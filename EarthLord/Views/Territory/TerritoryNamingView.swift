//
//  TerritoryNamingView.swift
//  EarthLord
//
//  Created by Claude on 2026-02-23.
//  领地命名对话框 - 圈地完成后弹出
//

import SwiftUI

struct TerritoryNamingView: View {
    let territoryId: String
    let suggestedNames: [String]
    var onDismiss: (() -> Void)?
    var onNameConfirmed: ((String) -> Void)?

    @State private var customName: String = ""
    @State private var selectedSuggestion: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 图标
                ZStack {
                    Circle()
                        .fill(ApocalypseTheme.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "flag.fill")
                        .font(.system(size: 36))
                        .foregroundColor(ApocalypseTheme.primary)
                }

                Text("为你的领地命名")
                    .font(.title2.bold())
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text("一个好名字能让你在末日中更容易被记住")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // 建议名称
                if !suggestedNames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("推荐名称")
                            .font(.headline)
                            .foregroundColor(ApocalypseTheme.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(suggestedNames, id: \.self) { name in
                                Button {
                                    selectedSuggestion = name
                                    customName = name
                                } label: {
                                    Text(name)
                                        .font(.subheadline)
                                        .foregroundColor(selectedSuggestion == name ? .white : ApocalypseTheme.textPrimary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedSuggestion == name ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }

                // 自定义输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("或自定义名称")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    TextField("输入领地名称", text: $customName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }

                Spacer()

                // 确认按钮
                Button {
                    let finalName = customName.trimmingCharacters(in: .whitespaces)
                    if !finalName.isEmpty {
                        onNameConfirmed?(finalName)
                        dismiss()
                    }
                } label: {
                    Text("确认命名")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(customName.isEmpty ? ApocalypseTheme.textMuted : ApocalypseTheme.primary)
                        .cornerRadius(12)
                }
                .disabled(customName.isEmpty)
            }
            .padding()
            .background(ApocalypseTheme.background)
            .navigationTitle("领地命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("稍后") {
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
    }
}

// 预览
#Preview {
    TerritoryNamingView(
        territoryId: "test-id",
        suggestedNames: ["废弃工厂避难所", "河畔临时营地", "森林前哨站", "沙漠绿洲"]
    )
}
