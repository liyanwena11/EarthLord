import Foundation
import SwiftUI
import ObjectiveC

/// 语言管理类：负责全局语言状态和切换逻辑
/// 注意：现代 iOS (Xcode 15+) 使用 .xcstrings 格式，无需自定义 Bundle 实现
@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    // 使用 AppStorage 持久化存储用户选择，默认简体中文
    @AppStorage("selected_language") var currentLanguage: String = "zh-Hans" {
        didSet {
            // 通知所有监听者界面需要更新
            objectWillChange.send()
            LogDebug("🌐 [LanguageManager] 语言已切换至: \(currentLanguage)")
        }
    }

    private init() {
        LogDebug("🌐 [LanguageManager] 初始化完成，当前语言: \(currentLanguage)")
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
