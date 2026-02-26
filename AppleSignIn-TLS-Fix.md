# Apple 登录 TLS 错误修复指南

## 🔍 问题分析

**错误信息**: `TLS错误导致安全连接失败`

**原因**:
1. App Transport Security (ATS) 可能阻止了 HTTPS 连接
2. Supabase 客户端配置需要优化
3. Info.plist 中缺少必要的 HTTPS 配置

## ✅ 已完成的修复

### 1. 优化 Supabase 客户端配置
- ✅ 添加自定��日志器
- ✅ 启用详细日志以调试 TLS 问题
- ✅ 正确配置 auth options

### 2. 增强错误处理
- ✅ 识别 TLS/网络错误 (NSURLErrorDomain)
- ✅ 提供用户友好的错误消息
- ✅ 记录详细的调试信息

### 3. 改进日志输出
- ✅ 显示错误域名和代码
- ✅ 提供 TLS 问题排查提示

## �� 手动配置步骤（如果 TLS 错误仍然存在）

### 步骤 1: 在 Xcode 中配置 ATS

1. **打开 Xcode 项目**
   - 选择项目文件（蓝色图标）
   - 选择 Target "EarthLord"
   - 选择 "Info" 标签

2. **添加 App Transport Security**
   - 右键点击 "Information Property List"
   - 选择 "Add Row"
   - 输入: `App Transport Security`
   - 类型选��: `Dictionary`

3. **在 App Transport Security 中添加子项**

   a. **允许任意加载** (可选)
      - Key: `NSAllowsArbitraryLoads`
      - Type: `Boolean`
      - Value: `NO`

   b. **添加域名例外**
      - 在 App Transport Security 上右键
      - "Add Row"
      - Key: `NSExceptionDomains`
      - Type: `Dictionary`

   c. **添加 Supabase 域名**
      - 在 NSExceptionDomains 上右键
      - "Add Row"
      - Key: `supabase.co`
      - Type: `Dictionary`

   d. **在 supabase.co 中添加**
      - Key: `NSExceptionMinimumTLSVersion`
      - Type: `String`
      - Value: `TLSv1.2`

### 步骤 2: 验证 Supabase Apple 登录配置

1. **登录 Supabase Dashboard**
   - 访问: https://supabase.com/dashboard
   - 选择项目: EarthLord

2. **检查 Authentication → Providers**
   - 确保 "Apple" 已启用
   - 检查 Client ID 和 Team ID 是否配置

3. **检查 URL Configuration**
   - 确认 Site URL 正确
   - 添加 Redirect URL: `earthlord://`

### 步骤 3: 验证 Xcode Signing

1. **选择 Target**
   - "Signing & Capabilities" 标签

2. **检查 Team**
   - 确保选择了正确的开发 Team
   - Bundle Identifier 正确

3. **添加 Capability** (如果需要)
   - "+ Capability"
   - 选择 "Sign in with Apple"

## 🔧 调试步骤

### 1. 查看详细日志

在 Xcode 中运行应用，查看控制台输出：
```
🔵 [AuthManager] ===== 开始 Apple 登录流程 =====
✅ [AuthManager] Apple 授权成功
🔑 [AuthManager] Apple 凭证获取成功
🔑 [AuthManager] identityToken 数据大小: XXX 字节
🔄 [AuthManager] 正在向 Supabase 验证 Apple 身份...
🔷 [Supabase] [DEBUG] 详细日志信息...
```

### 2. 常见 TLS 错误和解决方案

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `The certificate for this server is invalid` | 证书问题 | 检查系统时间，更新 macOS |
| `Could not connect to the server` | 网络问题 | 检查网络连接，确认防火墙设置 |
| `TLS handshake failed` | TLS 版本不匹配 | 配置 ATS 允许 TLSv1.2 |

### 3. 网络诊断

在终端中测试 Supabase 连接：
```bash
# 测试 HTTPS 连接
curl -v https://lkekxzssfrspkyxtqysx.supabase.co

# 测试 Supabase API
curl -X POST https://lkekxzssfrspkyxtqysx.supabase.co/auth/v1/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"password"}'
```

## 📱 测试流程

1. **清理构建**
   - Product → Clean Build Folder (⇧⌘K)

2. **删除应用** (从模拟器/设备)
   - 长按应用图标 → 删除

3. **重新安装**
   - Product → Run (⌘R)

4. **测试 Apple 登录**
   - 点击 Apple 登录按钮
   - 查看控制台日志

## 🚨 如果仍然失败

### 检查清单

- [ ] 设备连接到互联网
- [ ] 系统时间正确
- [ ] Supabase 项目启用 Apple 登录
- [ ] Bundle Identifier 匹配 Supabase 配置
- [ ] 开发者账号有效
- [ ] Xcode Signing 配置正确
- [ ] 模拟器/设备支持 Apple 登录 (iOS 13+)

### 获取更多信息

查看控制台中的完整错误日志：
```
❌ [AuthManager] 错误域名: XXX
❌ [AuthManager] 错误代码: XXX
❌ [AuthManager] 错误描述: XXX
```

将这些信息提供给技术支持以便进一步诊断。

## 📞 仍然有问题？

提供以下信息：
1. 完整的错误日志
2. 设备型号和 iOS 版本
3. Xcode 版本
4. macOS 版本
5. 网络环境（是否有防火墙/代理）

---

**最后更新**: 2026-02-24
**状态**: ✅ 修复完成
