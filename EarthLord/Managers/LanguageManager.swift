import Foundation

/// 语言管理类
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            Bundle.setLanguage(currentLanguage)
        }
    }
    
    private init() {
        self.currentLanguage = (UserDefaults.standard.object(forKey: "AppleLanguages") as? [String])?.first ?? "zh-Hans"
    }
}

// MARK: - 核心修复：添加 @unchecked Sendable
private var bundleKey: UInt8 = 0

/// 扩展 Bundle 以支持运行时切换语言
class BundleEx: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String) {
        object_setClass(Bundle.main, BundleEx.self)
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? ""
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: path), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
