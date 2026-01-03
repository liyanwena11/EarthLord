# Google 登录配置指南

## ✅ 已完成的工作

### 1️⃣ 代码实现
- ✅ **AuthManager.swift** - 实现完整的 Google 登录逻辑
- ✅ **EarthLordApp.swift** - 添加 URL 回调处理
- ✅ **AuthView.swift** - 连接 Google 登录按钮
- ✅ **Info.plist** - 创建 URL Schemes 配置文件

### 2️⃣ 详细日志
所有关键步骤都添加了中文日志，方便调试：
- 🔵 蓝色 - 流程步骤
- ✅ 绿色 - 成功完成
- ❌ 红色 - 错误失败
- ⚠️ 黄色 - 警告信息

## 🔧 配置步骤

### 步骤 1：获取 Google Client ID

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建或选择一个项目
3. 启用 **Google Sign-In API**
4. 转到 **凭据 (Credentials)** → **创建凭据 (Create Credentials)** → **OAuth 2.0 客户端 ID**
5. 选择应用类型：**iOS**
6. 填写信息：
   - **名称**：EarthLord iOS
   - **Bundle ID**：从 Xcode 项目中获取（通常是 `com.yourname.EarthLord`）
7. 创建后会得到一个 Client ID，格式如：
   ```
   123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
   ```

### 步骤 2：配置 Supabase

1. 前往 [Supabase Dashboard](https://app.supabase.com/)
2. 选择您的项目 **EarthLord**
3. 转到 **Authentication** → **Providers** → **Google**
4. 启用 Google Provider
5. 填入配置：
   - **Authorized Client IDs**：粘贴上一步获取的 iOS Client ID
   - **Skip nonce check**：✅ 开启（已完成）
6. 保存配置

### 步骤 3：修改 Info.plist

打开 `/EarthLord/Info.plist` 文件，将 `YOUR_GOOGLE_CLIENT_ID` 替换为您的实际 Client ID：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- 替换这里 👇 -->
            <string>com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz123456</string>
        </array>
    </dict>
</array>
```

**⚠️ 注意**：
- 保留 `com.googleusercontent.apps.` 前缀
- 只替换后面的数字和字符部分

### 步骤 4：修改 AuthManager.swift

打开 `/EarthLord/Managers/AuthManager.swift`，找到第 380 行：

```swift
// ⚠️ 重要：将此 Client ID 替换为您在 Google Cloud Console 创建的 iOS Client ID
let googleClientID = "YOUR_GOOGLE_IOS_CLIENT_ID.apps.googleusercontent.com"
```

替换为您的实际 Client ID：

```swift
let googleClientID = "123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com"
```

### 步骤 5：验证 Bundle ID

1. 在 Xcode 中打开项目
2. 选择项目 → **TARGETS** → **EarthLord**
3. 转到 **General** 标签
4. 确认 **Bundle Identifier** 与 Google Cloud Console 中配置的一致

## 🔄 登录流程

### 用户操作流程
```
1. 打开 App → 认证页面
   ↓
2. 点击 "使用 Google 登录" 按钮
   ↓
3. 弹出 Google 登录页面（浏览器或原生）
   ↓
4. 选择 Google 账号并授权
   ↓
5. 自动返回 App
   ↓
6. 登录成功，跳转主页面 ✅
```

### 技术流程（带日志）
```
🔵 [Google登录] 开始 Google 登录流程
🔵 [Google登录] 成功获取根视图控制器
🔵 [Google登录] 配置完成，Client ID: xxx
🔵 [Google登录] 开始调用 Google Sign In
  ↓（用户在浏览器/原生页面登录）
✅ [Google登录] Google Sign In 成功
🔵 [Google登录] 用户邮箱: user@example.com
✅ [Google登录] 成功获取 ID Token
🔵 [Google登录] Token 前20位: eyJhbGciOiJSUzI1NiI...
🔵 [Google登录] 开始调用 Supabase signInWithIdToken
✅ [Google登录] Supabase 登录成功
🔵 [Google登录] Supabase 用户 ID: xxxxx-xxxx-xxxx
✅ [Google登录] 登录流程完成，用户已认证
🔵 [Google登录] 登录流程结束
```

## 📝 代码详解

### AuthManager.signInWithGoogle()

```swift
func signInWithGoogle() async {
    isLoading = true
    errorMessage = nil
    print("🔵 [Google登录] 开始 Google 登录流程")

    do {
        // 1. 获取根视图控制器（必需，Google SDK 要求）
        guard let rootViewController = ... else { return }
        print("🔵 [Google登录] 成功获取根视图控制器")

        // 2. 配置 Google Client ID
        let googleClientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
        print("🔵 [Google登录] 配置完成，Client ID: \(googleClientID)")

        // 3. 调用 Google Sign In SDK
        print("🔵 [Google登录] 开始调用 Google Sign In")
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: []
        )
        print("✅ [Google登录] Google Sign In 成功")

        // 4. 获取 ID Token
        guard let idToken = result.user.idToken?.tokenString else { return }
        print("✅ [Google登录] 成功获取 ID Token")

        // 5. 使用 ID Token 登录 Supabase
        print("🔵 [Google登录] 开始调用 Supabase signInWithIdToken")
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken
            )
        )
        print("✅ [Google登录] Supabase 登录成功")

        // 6. 更新认证状态
        currentUser = session.user
        isAuthenticated = true
        print("✅ [Google登录] 登录流程完成，用户已认证")

    } catch let error as NSError {
        print("❌ [Google登录] 登录失败")
        print("❌ [Google登录] 错误信息: \(error.localizedDescription)")

        // 用户取消登录
        if error.code == GIDSignInError.canceled.rawValue {
            errorMessage = "用户取消了登录"
            print("⚠️ [Google登录] 用户主动取消登录")
        } else {
            errorMessage = "Google 登录失败：\(error.localizedDescription)"
        }
    }

    isLoading = false
    print("🔵 [Google登录] 登录流程结束\n")
}
```

### EarthLordApp URL 处理

```swift
WindowGroup {
    RootView()
        .onOpenURL { url in
            // 处理 Google 登录回调 URL
            print("🔵 [App] 收到 URL 回调: \(url)")
            GIDSignIn.sharedInstance.handle(url)
            print("✅ [App] Google Sign In 处理 URL 完成")
        }
}
```

## 🐛 常见问题

### 1. 错误：Invalid Client ID
**原因**：Info.plist 或 AuthManager 中的 Client ID 不正确

**解决方案**：
- 检查 Google Cloud Console 中的 Client ID
- 确认复制时没有多余的空格或换行
- 确保包含完整的 `.apps.googleusercontent.com` 后缀

### 2. 错误：Redirect URI mismatch
**原因**：Bundle ID 与 Google Cloud Console 配置不匹配

**解决方案**：
- 在 Xcode 中检查 Bundle Identifier
- 在 Google Cloud Console 中更新或重新创建 OAuth Client
- 确保两者完全一致

### 3. 登录后闪退或无响应
**原因**：Info.plist 中的 URL Scheme 配置错误

**解决方案**：
- 检查 `CFBundleURLSchemes` 是否正确
- 格式必须是：`com.googleusercontent.apps.YOUR_CLIENT_ID`
- 确保在数组 `<array>` 中

### 4. 错误：无法获取视图控制器
**原因**：App 启动时窗口未就绪

**解决方案**：
- 确保在主界面完全加载后才点击登录
- 检查 SceneDelegate 或 WindowScene 配置

## 🧪 测试步骤

### 1. 基本测试
```
1. 运行 App
2. 进入认证页面
3. 点击 "使用 Google 登录"
4. 查看 Xcode 控制台日志
5. 应该看到：
   🔵 [Google登录] 开始 Google 登录流程
   🔵 [Google登录] 成功获取根视图控制器
   ...
```

### 2. 完整登录测试
```
1. 点击 Google 登录
2. 选择 Google 账号
3. 授权后返回 App
4. 查看控制台日志：
   ✅ [Google登录] Google Sign In 成功
   ✅ [Google登录] Supabase 登录成功
   ✅ [Google登录] 登录流程完成，用户已认证
5. App 自动跳转到主页面
6. 进入个人中心，查看用户信息
```

### 3. 取消登录测试
```
1. 点击 Google 登录
2. 在登录页面点击"取消"
3. 查看控制台日志：
   ⚠️ [Google登录] 用户主动取消登录
4. 显示提示："用户取消了登录"
5. 留在认证页面
```

### 4. 退出重新登录测试
```
1. Google 登录成功 → 主页面
2. 进入个人中心 → 退出登录
3. 返回认证页面
4. 再次点击 Google 登录
5. 应该直接登录（或要求重新授权）
```

## 📊 日志输出示例

### 成功登录
```
🔵 [Google登录] 开始 Google 登录流程
🔵 [Google登录] 成功获取根视图控制器
🔵 [Google登录] 配置完成，Client ID: 123456789-xxx.apps.googleusercontent.com
🔵 [Google登录] 开始调用 Google Sign In
✅ [Google登录] Google Sign In 成功
🔵 [Google登录] 用户邮箱: user@gmail.com
✅ [Google登录] 成功获取 ID Token
🔵 [Google登录] Token 前20位: eyJhbGciOiJSUzI1NiI...
🔵 [Google登录] 开始调用 Supabase signInWithIdToken
✅ [Google登录] Supabase 登录成功
🔵 [Google登录] Supabase 用户 ID: 12345678-1234-1234-1234-123456789012
✅ [Google登录] 登录流程完成，用户已认证
🔵 [Google登录] 登录流程结束

🔵 [App] 收到 URL 回调: com.googleusercontent.apps.123456789-xxx:/oauth2redirect/...
✅ [App] Google Sign In 处理 URL 完成
```

### 用户取消
```
🔵 [Google登录] 开始 Google 登录流程
🔵 [Google登录] 成功获取根视图控制器
🔵 [Google登录] 配置完成，Client ID: 123456789-xxx.apps.googleusercontent.com
🔵 [Google登录] 开始调用 Google Sign In
❌ [Google登录] 登录失败
❌ [Google登录] 错误代码: -5
❌ [Google登录] 错误信息: The user canceled the sign-in flow.
⚠️ [Google登录] 用户主动取消登录
🔵 [Google登录] 登录流程结束
```

### 错误示例
```
🔵 [Google登录] 开始 Google 登录流程
🔵 [Google登录] 成功获取根视图控制器
🔵 [Google登录] 配置完成，Client ID: INVALID_CLIENT_ID
🔵 [Google登录] 开始调用 Google Sign In
❌ [Google登录] 登录失败
❌ [Google登录] 错误代码: -2
❌ [Google登录] 错误信息: Invalid Client ID
🔵 [Google登录] 登录流程结束
```

## 📚 参考资料

- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)
- [Supabase Auth - Google Provider](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [GoogleSignIn SDK Documentation](https://github.com/google/GoogleSignIn-iOS)

## ✅ 检查清单

在测试前，请确认：

- [ ] 已在 Google Cloud Console 创建 iOS OAuth Client
- [ ] 已获取 iOS Client ID（格式：xxx.apps.googleusercontent.com）
- [ ] 已在 Supabase 启用 Google Provider
- [ ] 已将 Client ID 添加到 Supabase Authorized Client IDs
- [ ] 已开启 Supabase Skip nonce check
- [ ] 已修改 Info.plist 中的 URL Scheme
- [ ] 已修改 AuthManager.swift 中的 googleClientID
- [ ] Bundle ID 与 Google Cloud Console 配置一致
- [ ] GoogleSignIn SDK 已正确添加到项目

---

✅ **Google 登录功能已完整实现！**

请按照上述步骤配置 Client ID，然后即可开始测试。
