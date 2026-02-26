// ✅ 快速调试辅助脚本
// 在 Xcode Console 中执行以下命令来测试引导系统

import Foundation

// MARK: - 清除引导状态
func resetOnboardingStatus() {
    UserDefaults.standard.removeObject(forKey: "has_seen_onboarding")
    print("✅ 已清除本地引导缓存，下次启动将显示引导")
}

// MARK: - 强制显示引导（通过 UserDefaults）
func forceShowOnboarding() {
    UserDefaults.standard.set(false, forKey: "has_seen_onboarding")
    print("✅ 已设置强制显示引导")
}

// MARK: - 检查当前引导状态
func checkOnboardingStatus() {
    let status = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
    print("📊 当前引导状态: \(status ? "已显示" : "未显示")")
}

// MARK: - 在 EarthLordApp.swift 中添加调试代码

/*
 在 EarthLordApp.swift 的 init() 中添加以下代码来重置引导：

 init() {
     // 🔧 调试模式：每次启动都重置引导状态
     #if DEBUG
     UserDefaults.standard.removeObject(forKey: "has_seen_onboarding")
     print("🔧 [DEBUG] 已重置引导状态")
     #endif

     LogDebug("🚀🚀🚀 [EarthLordApp] ========== App init开始 ==========")
     // ... 其他 init 代码
 }
*/

// MARK: - 在 Console 中执行（LLDB）

/*
 在 Xcode 运行 App 时，暂停执行并在 Console 中输入：

 e UserDefaults.standard.removeObject(forKey: "has_seen_onboarding")

 然后继续执行（continue），引导应该会显示
*/

// MARK: - 数据库重置引导状态

/*
 在 Supabase SQL Editor 中执行：

 -- 重置所有用户的引导状态
 UPDATE profiles
 SET has_seen_onboarding = false;

 -- 重置特定用户
 UPDATE profiles
 SET has_seen_onboarding = false
 WHERE email = 'your-email@example.com';

 -- 查看当前状态
 SELECT id, email, has_seen_onboarding
 FROM profiles;
*/

// MARK: - 完整的测试流程

/*
 1. 完全退出 App
 2. 在 Xcode 中执行以下命令之一：
    - 方案A: 修改代码中的 debugForceShowOnboarding = true
    - 方案B: 在 init() 中添加 UserDefaults 重置代码
    - 方案C: 在数据库中重置引导状态
 3. 重新编译运行
 4. 应该看到引导覆盖层
 5. 完成引导
 6. 退出登录
 7. 重新登录
 8. 确认引导不再显示
*/
