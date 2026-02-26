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
    @State private var showRestartAlert = false

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
                        Text("选择语言".localized)
                            .foregroundColor(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
        }
        .navigationTitle("语言设置".localized)
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
        .alert("需要重启应用", isPresented: $showRestartAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("语言更改需要重启应用才能生效。请关闭并重新打开应用。")
        }
    }

    private func changeLanguage(_ languageCode: String) {
        // 保存到 UserDefaults
        UserDefaults.standard.set(languageCode, forKey: "selected_language")
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")

        LogDebug("🌐 [LanguageSettings] 语言已更改至: \(languageCode)，需要重启应用")

        // 显示重启提示
        showRestartAlert = true
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
}
