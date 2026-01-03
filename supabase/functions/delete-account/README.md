# Delete Account Edge Function

## 功能说明

这个边缘函数用于删除用户账户。它会：
1. 从 Authorization Header 获取用户 JWT
2. 验证用户身份
3. 使用 service_role key 删除该用户的账户

## 部署方法

### 方法 1: 使用 Supabase CLI（推荐）

```bash
# 如果还没安装 Supabase CLI，先安装
brew install supabase/tap/supabase

# 登录 Supabase
supabase login

# 链接到你的项目
supabase link --project-ref lkekxzssfrspkyxtqysx

# 部署函数
supabase functions deploy delete-account
```

### 方法 2: 使用 Supabase Dashboard

1. 访问 https://supabase.com/dashboard/project/lkekxzssfrspkyxtqysx/functions
2. 点击 "Create a new function"
3. 函数名称：`delete-account`
4. 将 `index.ts` 的内容复制粘贴到编辑器
5. 点击 "Deploy"

## 使用方法

在 Swift 代码中调用此函数：

```swift
let supabase = SupabaseClient(...)

// 获取当前用户的 session token
guard let session = try? await supabase.auth.session else {
    return
}

// 调用边缘函数
let response = try await supabase.functions.invoke(
    "delete-account",
    options: FunctionInvokeOptions(
        headers: ["Authorization": "Bearer \(session.accessToken)"]
    )
)

print("Account deleted:", response)
```

## 环境变量

此函数会自动获取以下 Supabase 环境变量：
- `SUPABASE_URL`: 你的 Supabase 项目 URL
- `SUPABASE_ANON_KEY`: 匿名密钥
- `SUPABASE_SERVICE_ROLE_KEY`: 服务角色密钥（用于管理员操作）

这些变量在 Supabase 平台上自动提供，无需手动配置。

## 安全说明

- 此函数不需要启用 JWT 验证（verify_jwt: false），因为它内部会验证用户身份
- 只有提供有效 JWT 的用户才能删除自己的账户
- 使用 service_role key 确保能够删除用户，即使有 RLS 策略限制

## 返回值

成功时：
```json
{
  "success": true,
  "message": "User account deleted successfully",
  "userId": "user-uuid"
}
```

失败时：
```json
{
  "error": "错误信息"
}
```
