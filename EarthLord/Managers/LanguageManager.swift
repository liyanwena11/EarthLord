import Foundation
import SwiftUI
import ObjectiveC

/// 语言管理类：负责全局语言状态和切换逻辑
/// 注意：现代 iOS (Xcode 15+) 使用 .xcstrings 格式，无需自定义 Bundle 实现
@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    // 使用 AppStorage 持久化存储用户选择
    // "system" = 跟随系统, "zh-Hans" = 简体中文, "en" = English
    @AppStorage("selected_language") var currentLanguage: String = "system" {
        didSet {
            // 通知所有监听者界面需要更新
            objectWillChange.send()
            LogDebug("🌐 [LanguageManager] 语言已切换至: \(currentLanguage)")

            // 立即应用语言变更
            applyLanguageChange()
        }
    }

    private init() {
        LogDebug("🌐 [LanguageManager] 初始化完成，当前语言: \(currentLanguage)")
        // 立即应用当前设置
        applyLanguageChange()
    }

    /// 根据当前设置应用语言变更
    private func applyLanguageChange() {
        let languageCode: String
        switch currentLanguage {
        case "system":
            if let languageCode_ = Locale.current.language.languageCode?.identifier {
                languageCode = languageCode_
            } else {
                languageCode = "zh-Hans"
            }
        default:
            languageCode = currentLanguage
        }

        // 设置应用语言（会立即更新所有 String(localized:) 调用）
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")

        LogDebug("🌐 [LanguageManager] 应用语言: \(languageCode)")
    }

    /// 获取实际使用的语言代码
    var effectiveLanguageCode: String {
        switch currentLanguage {
        case "system":
            if let languageCode = Locale.current.language.languageCode?.identifier {
                return languageCode
            }
            return "zh-Hans"
        default:
            return currentLanguage
        }
    }
}

// MARK: - String 本地化扩展

extension String {
    /// 获取本地化字符串（使用��统默认的 .xcstrings 支持）
    var localized: String {
        // 直接使用 NSLocalizedString，系统会自动从 .xcstrings 加载
        return NSLocalizedString(self, comment: "")
    }

    /// 获取本地化字符串，支持参数替换
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - 调试日志辅助

func LogDebug(_ message: String) {
    #if DEBUG
    print("[DEBUG] \(message)")
    #endif
}

func LogInfo(_ message: String) {
    print("[INFO] \(message)")
}

func LogWarning(_ message: String) {
    print("[WARNING] ⚠️ \(message)")
}

func LogError(_ message: String) {
    print("[ERROR] ❌ \(message)")
}
