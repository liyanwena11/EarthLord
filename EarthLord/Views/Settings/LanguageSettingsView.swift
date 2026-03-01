import SwiftUI

// MARK: - 核心修复：定义语言枚举，解决 "Cannot find AppLanguage in scope"
enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }
}

struct LanguageSettingsView: View {
    @ObservedObject var langManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss

    // 品牌橙
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    @State private var isRestarting = false

    var body: some View {
        ZStack {
            // 1. 纯黑背景
            Color.black.ignoresSafeArea()

            if isRestarting {
                // 重启加载界面
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(brandOrange)
                    Text("正在重启应用...".localized)
                        .foregroundColor(.white)
                        .font(.caption)
                }
            } else {
                VStack(spacing: 0) {
                    List {
                        Section {
                            ForEach(AppLanguage.allCases) { language in
                                Button(action: {
                                    // 如果选择的是当前语言，不做任何操作
                                    if langManager.currentLanguage != language.rawValue {
                                        changeLanguage(language.rawValue)
                                    }
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if langManager.currentLanguage == language.rawValue {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(brandOrange)
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                }
                                .disabled(isRestarting)
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        } header: {
                            Text(String(localized: "选择语言"))
                                .foregroundColor(.gray)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
        }
        .navigationTitle(String(localized: "语言设置"))
        .navigationBarTitleDisplayMode(.inline)
        // 顶部返回按钮颜色
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(brandOrange)
                }
            }
        }
    }

    private func changeLanguage(_ languageCode: String) {
        // 显示重启界面
        isRestarting = true

        // 保存到 UserDefaults
        UserDefaults.standard.set(languageCode, forKey: "selected_language")
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // 同步更新 LanguageManager，确保界面立即更新
        langManager.currentLanguage = languageCode

        LogDebug("🌐 [LanguageSettings] 语言已更改至: \(languageCode)，准备重启应用")

        // 延迟后重启应用，给用户视觉反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 使用 exit(0) 重启应用（iOS 会自动重新启动）
            exit(0)
        }
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
}
