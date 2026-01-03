# Xcode 配置 URL Schemes 指南

## ❌ 问题解决

### 错误信息
```
Multiple commands produce '/Users/lyanwen/Library/Developer/Xcode/DerivedData/EarthLord-xxx/Build/Products/Debug-iphonesimulator/EarthLord.app/Info.plist'
```

### 原因
项目使用了新的 Xcode 14+ 项目结构，不需要独立的 Info.plist 文件。

### 解决方案
✅ 已删除 `EarthLord/Info.plist` 文件

## 🔧 在 Xcode 中配置 URL Schemes

### 方法 1：使用 Info Tab（推荐）

1. **打开项目设置**
   - 在 Xcode 中打开项目
   - 点击左侧项目导航器中的项目名称（蓝色图标）
   - 选择 **TARGETS** → **EarthLord**

2. **进入 Info 标签**
   - 点击顶部的 **Info** 标签
   - 找到 **URL Types** 部分

3. **添加 URL Type**
   - 点击 **URL Types** 左侧的展开箭头
   - 点击 **+** 按钮添加新的 URL Type

4. **配置 URL Scheme**
   - **Identifier**: `com.googleusercontent.apps`
   - **URL Schemes**: `com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID`
   - **Role**: `Editor`

   **示例：**
   ```
   Identifier: com.googleusercontent.apps
   URL Schemes: com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz123456
   Role: Editor
   ```

5. **保存**
   - 配置会自动保存

### 方法 2：使用 Info.plist 源码编辑

1. **打开 Info Tab**
   - 同上，进入 **Info** 标签

2. **右键点击任意条目**
   - 选择 **Show Raw Keys/Values**

3. **添加 URL Types**
   - 右键点击空白处
   - 选择 **Add Row**
   - 添加以下配置：

   ```
   Key: CFBundleURLTypes
   Type: Array
   ```

   展开 `CFBundleURLTypes`，添加：
   ```
   Item 0: Dictionary
     ├─ CFBundleTypeRole: String = Editor
     └─ CFBundleURLSchemes: Array
          └─ Item 0: String = com.googleusercontent.apps.YOUR_CLIENT_ID
   ```

### 方法 3：直接编辑 Info.plist（高级）

如果项目中没有 Info.plist 文件，Xcode 会自动生成。您也可以：

1. **创建 Info.plist**
   - 右键点击 EarthLord 文件夹
   - 选择 **New File...**
   - 选择 **Property List**
   - 命名为 `Info.plist`

2. **添加 URL Types**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleURLTypes</key>
       <array>
           <dict>
               <key>CFBundleTypeRole</key>
               <string>Editor</string>
               <key>CFBundleURLSchemes</key>
               <array>
                   <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
               </array>
           </dict>
       </array>
   </dict>
   </plist>
   ```

3. **设置项目配置**
   - 选择 **TARGETS** → **EarthLord**
   - 选择 **Build Settings** 标签
   - 搜索 `Info.plist File`
   - 设置为 `EarthLord/Info.plist`

## ✅ 验证配置

### 1. 检查 Info Tab
1. 打开 **TARGETS** → **EarthLord** → **Info**
2. 展开 **URL Types**
3. 确认看到您添加的 URL Scheme

### 2. 构建项目
```bash
# 清理构建文件夹
Product → Clean Build Folder (⇧⌘K)

# 重新构建
Product → Build (⌘B)
```

### 3. 查看生成的 Info.plist
```bash
# 项目构建后，查看生成的 Info.plist
# 路径：DerivedData/EarthLord-xxx/Build/Products/Debug-iphonesimulator/EarthLord.app/Info.plist

# 使用命令行查看
plutil -p ~/Library/Developer/Xcode/DerivedData/EarthLord-*/Build/Products/Debug-iphonesimulator/EarthLord.app/Info.plist | grep -A 5 CFBundleURLTypes
```

## 🎯 完整配置步骤（Google 登录）

### 步骤 1：获取 Google Client ID

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建 iOS OAuth Client
3. 获取 Client ID，格式：
   ```
   123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
   ```

### 步骤 2：配置 URL Scheme

在 Xcode 中添加 URL Type：
```
URL Schemes: com.googleusercontent.apps.123456789-abcdefghijklmnopqrstuvwxyz123456
```

**⚠️ 重要：**
- 保留 `com.googleusercontent.apps.` 前缀
- 只替换后面的 Client ID 部分

### 步骤 3：更新 AuthManager.swift

打开 `AuthManager.swift`，找到第 380 行：
```swift
let googleClientID = "123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com"
```

### 步骤 4：测试

1. 运行项目
2. 点击 Google 登录
3. 查看控制台日志
4. 验证 URL 回调

## 📸 截图示例

### Info Tab 配置

```
┌─────────────────────────────────────┐
│ Info                                │
├─────────────────────────────────────┤
│ Custom iOS Target Properties        │
│                                     │
│ ▼ URL Types                         │
│   ▶ Item 0                          │
│     Document Role: Editor           │
│     Identifier: com.googleuser...   │
│     URL Schemes:                    │
│       ▶ Item 0                      │
│         com.googleusercontent.a...  │
└─────────────────────────────────────┘
```

## 🐛 常见问题

### 1. 找不到 Info Tab
**解决方案：**
- 确保选择了 **TARGETS**（不是 PROJECT）
- 点击顶部的 **Info** 标签

### 2. 无法添加 URL Type
**解决方案：**
- 确保 Xcode 版本 >= 14
- 尝试重启 Xcode

### 3. 配置后仍然报错
**解决方案：**
```bash
# 清理项目
Product → Clean Build Folder (⇧⌘K)

# 删除 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/EarthLord-*

# 重新构建
Product → Build (⌘B)
```

### 4. Google 登录回调失败
**检查：**
1. URL Scheme 是否正确
2. Client ID 是否匹配
3. Bundle ID 是否一致

## 📚 参考资料

- [Apple Developer - Custom URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios/start-integrating)

---

✅ **配置完成后，重新构建项目即可！**
