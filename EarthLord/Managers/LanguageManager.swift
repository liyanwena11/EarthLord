import Foundation
import SwiftUI

/// 语言管理类：负责全局语言状态和切换逻辑
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // 使用 AppStorage 持久化存储用户选择，默认简体中文
    @AppStorage("selected_language") var currentLanguage: String = "zh-Hans" {
        didSet {
            // 核心：当语言改变时，强制改变主 Bundle 的语言路径
            Bundle.setLanguage(currentLanguage)
            // 通知所有监听者界面需要更新
            objectWillChange.send()
        }
    }
    
    private init() {
        // 初始化时应用存储的语言设置
        Bundle.setLanguage(currentLanguage)
    }
}

// MARK: - 运行时语言切换底层支持 (黑科技)

private var bundleKey: UInt8 = 0

/// 继承 Bundle 的类，用于重写语言查找逻辑
class BundleEx: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // 如果关联对象中有对应的语言包，则从语言包中取词
        if let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        // 否则走系统默认逻辑
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String) {
        // 1. 将主 Bundle 的类替换为我们自定义的 BundleEx
        object_setClass(Bundle.main, BundleEx.self)
        
        // 2. 获取对应语言文件的路径 (例如 en.lproj 或 zh-Hans.lproj)
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? ""
        let languageBundle = Bundle(path: path)
        
        // 3. 🛠 修复点：确保 objc_setAssociatedObject 传满了 4 个参数
        // 参数依次是：目标对象、Key、值、关联策略
        objc_setAssociatedObject(
            Bundle.main,
            &bundleKey,
            languageBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
