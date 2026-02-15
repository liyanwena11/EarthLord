import Foundation
import Supabase

// Supabase 配置
let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://lkekxzssfrspkyxtqysx.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxrZWt4enNzZnJzcGt5eHRxeXN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxMDAwNjUsImV4cCI6MjA4MjY3NjA2NX0.cqQjlAIdQIcRjXvRUtjc02h3CsdxV383WE9PofNc6iM",
    options: SupabaseClientOptions(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)

// 测试账号信息
let testEmail = "appstore-review@test.com"
let testPassword = "AppleReview2026!"

// 创建测试账号
Task {
    do {
        print("正在创建测试账号...")
        print("邮箱: \(testEmail)")
        print("密码: \(testPassword)")
        
        let response = try await supabaseClient.auth.signUp(email: testEmail, password: testPassword)
        print("✅ 测试账号创建成功！")
        print("用户ID: \(response.user?.id.uuidString ?? "未知")")
        print("邮箱: \(response.user?.email ?? "未知")")
        
        // 验证登录
        print("\n正在验证登录...")
        let loginResponse = try await supabaseClient.auth.signIn(email: testEmail, password: testPassword)
        print("✅ 登录验证成功！")
        print("已成功创建并验证App Store审核测试账号")
        
    } catch {
        print("❌ 创建测试账号失败: \(error.localizedDescription)")
        print("错误详情: \(error)")
    }
}

// 等待任务完成
RunLoop.main.run()
