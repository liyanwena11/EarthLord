import SwiftUI

// MARK: - 核心修复：定义语言枚举，解决 "Cannot find AppLanguage in scope"
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: String.LocalizationValue("跟随系统"))
        case .chinese: return String(localized: String.LocalizationValue("简体中文"))
        case .english: return String(localized: String.LocalizationValue("English"))
        }
    }
}

struct LanguageSettingsView: View {
    @ObservedObject var langManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss

    // 品牌橙
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        ZStack {
            // 1. 纯黑背景
            Color.black.ignoresSafeArea()

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
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    } header: {
                        Text(String(localized: String.LocalizationValue("选择语言")))
                            .foregroundColor(.gray)
                    }

                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                            Text(String(localized: String.LocalizationValue("语言更改将立即生效")))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
        }
        .navigationTitle(String(localized: String.LocalizationValue("语言设置")))
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
        // 立即更新语言，无需重启
        langManager.currentLanguage = languageCode
        LogDebug("🌐 [LanguageSettings] 语言已更改至: \(languageCode)")
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
}
