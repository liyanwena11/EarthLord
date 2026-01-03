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

    var body: some View {
        ZStack {
            // 1. 纯黑背景
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach(AppLanguage.allCases) { language in
                            Button(action: {
                                langManager.currentLanguage = language.rawValue
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
    }
}

// MARK: - 核心修复：解决 "Value of type 'String' has no member 'localized'"
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
}
