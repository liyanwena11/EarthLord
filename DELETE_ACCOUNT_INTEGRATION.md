# 删除账户功能集成指南

## ✅ 已完成的工作

### 1. 边缘函数
- **文件**: `supabase/functions/delete-account/index.ts`
- **功能**: 验证用户身份并使用 service_role key 删除账户
- **状态**: 已创建，等待部署

### 2. AccountService 更新
- **文件**: `EarthLord/Managers/AccountService.swift`
- **改进**:
  - 使用 Supabase Functions 客户端（更简洁）
  - 添加 `@MainActor` 支持
  - 删除成功后自动登出
  - 更好的错误处理和恢复建议

### 3. UI 视图
- **文件**: `EarthLord/Views/DeleteAccountView.swift`
- **功能**:
  - 警告界面显示删除后果
  - 二次确认对话框
  - 加载状态和错误处理
  - 自动关闭和登出

## 🚀 如何集成到现有视图

### 选项 1: 从设置页面导航

在你的设置视图中添加导航链接：

```swift
NavigationLink {
    DeleteAccountView()
} label: {
    HStack {
        Image(systemName: "trash")
            .foregroundColor(.red)
        Text("删除账户")
            .foregroundColor(.red)
    }
}
```

### 选项 2: 使用 Sheet 弹出

```swift
struct SettingsView: View {
    @State private var showDeleteAccount = false

    var body: some View {
        Button("删除账户") {
            showDeleteAccount = true
        }
        .foregroundColor(.red)
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
    }
}
```

### 选项 3: 直接调用 AccountService

如果你想在其他地方直接调用删除功能：

```swift
Task {
    do {
        let success = try await AccountService.shared.deleteAccountSimple()
        if success {
            print("账户删除成功")
        }
    } catch {
        print("删除失败: \(error.localizedDescription)")
    }
}
```

## 📋 部署清单

### 第一步: 部署边缘函数

使用以下任一方法：

**方法 A: Supabase Dashboard**
1. 访问: https://supabase.com/dashboard/project/lkekxzssfrspkyxtqysx/functions
2. 创建新函数: `delete-account`
3. 复制 `supabase/functions/delete-account/index.ts` 内容
4. 取消勾选 "Verify JWT"
5. 部署

**方法 B: Supabase CLI**
```bash
cd /Users/lyanwen/Desktop/EarthLord
supabase login
supabase link --project-ref lkekxzssfrspkyxtqysx
supabase functions deploy delete-account --no-verify-jwt
```

### 第二步: 添加到 Xcode 项目

1. 打开 Xcode
2. 确保以下文件已添加到项目:
   - `AccountService.swift` (已更新)
   - `DeleteAccountView.swift` (新文件)

### 第三步: 集成到你的应用

根据上面的集成选项，将删除账户功能添加到合适的位置。

### 第四步: 测试

1. 构建并运行应用
2. 登录一个测试账户
3. 导航到删除账户页面
4. 确认删除
5. 验证:
   - 账户已从 Supabase Auth 中删除
   - 应用自动登出
   - 无法再用该账户登录

## 🔒 安全注意事项

- ✅ 函数验证用户 JWT，确保只能删除自己的账户
- ✅ 使用 service_role key 确保删除权限
- ✅ 二次确认防止误操作
- ✅ 删除后自动登出清理本地状态

## 🐛 故障排除

### 错误: "Missing authorization header"
- 确保用户已登录
- 检查 session token 是否有效

### 错误: "Invalid or expired token"
- Token 可能已过期，请重新登录
- 检查 Supabase 项目配置

### 错误: "Failed to delete user account"
- 检查边缘函数日志
- 确认 service_role key 环境变量已设置
- 验证 Supabase Auth 设置

## 📞 获取帮助

如果遇到问题：
1. 检查 Supabase Dashboard 的 Edge Functions 日志
2. 查看应用的控制台输出
3. 验证所有环境变量已正确设置

## 🎯 下一步

考虑添加以下功能：
- [ ] 删除前导出用户数据
- [ ] 软删除（标记为已删除但保留数据）
- [ ] 删除账户前的最后确认邮件
- [ ] 账户删除冷静期（30天后真正删除）
