# 🔧 修复 Swift Package Manager 依赖包问题

## 问题描述
```
Missing package product 'GoogleSignInSwift'
Missing package product 'Supabase'
Missing package product 'GoogleSignIn'
```

## 解决方法

### 方法 1：在 Xcode 中重新解析包（最简单）

#### 步骤：
1. **打开 Xcode 项目**
   ```bash
   open EarthLord.xcodeproj
   ```

2. **清理缓存**
   - 按 `Cmd+Shift+K` (Clean Build Folder)

3. **重置包缓存**
   - 菜单栏：**File** → **Packages** → **Reset Package Caches**

4. **解析包版本**
   - 菜单栏：**File** → **Packages** → **Resolve Package Versions**
   - 等待 Xcode 下载并解析所有依赖包（可能需要 2-5 分钟）

5. **重新编译**
   - 按 `Cmd+B` 编译项目

---

### 方法 2：手动添加依赖包

如果方法 1 不行，尝试手动添加：

1. **打开项目设置**
   - 点击左侧项目导航器中的 **EarthLord** 项目（蓝色图标）
   - 选择 **EarthLord** target
   - 点击 **Package Dependencies** 标签

2. **检查已添加的包**
   应该看到以下包：
   - `Supabase` (https://github.com/supabase/supabase-swift)
   - `GoogleSignIn` (https://github.com/google/GoogleSignIn-iOS)

3. **如果缺少，手动添加**
   - 点击 **+** 按钮
   - 搜索并添加：
     ```
     https://github.com/supabase/supabase-swift
     ```
   - 选择版本 **2.39.0** 或 **Up to Next Major Version**
   - 点击 **Add Package**

   - 重复添加：
     ```
     https://github.com/google/GoogleSignIn-iOS
     ```
   - 选择版本 **9.0.0** 或 **Up to Next Major Version**
   - 点击 **Add Package**

---

### 方法 3：删除 DerivedData 并重新打开

```bash
# 1. 关闭 Xcode

# 2. 删除 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/EarthLord-*

# 3. 删除项目缓存
rm -rf .build

# 4. 重新打开项目
open EarthLord.xcodeproj

# 5. Xcode 会自动重新解析依赖包
```

---

### 方法 4：检查网络连接

有时候是网络问题导致无法下载包：

1. **检查网络**
   - 确保能访问 GitHub
   - 如果在国内，可能需要配置代理

2. **使用代理或 VPN**
   - 如果使用了 VPN，确保 Xcode 能访问
   - 或者配置 Git 代理：
     ```bash
     git config --global http.proxy http://127.0.0.1:7890
     ```

---

### 方法 5：最后手段 - 清理并重新克隆

```bash
# 1. 完全关闭 Xcode

# 2. 删除所有缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/EarthLord-*
rm -rf .build
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# 3. 删除 xcworkspace
rm -rf EarthLord.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/

# 4. 重新打开项目
open EarthLord.xcodeproj

# 5. Xcode 会重新创建所有依赖
```

---

## 验证修复

编译成功后，检查控制台：
```
✅ Build succeeded!
```

如果还有错误，检查：
1. Package.resolved 文件是否存在
2. 网络连接是否正常
3. Xcode 版本是否支持（建议 Xcode 15.0+）

---

## 常见问题

### Q: 下载很慢或卡住？
**A**:
- 检查网络连接
- 尝试使用 VPN
- 配置 Git 代理

### Q: 提示包版本冲突？
**A**:
- 删除 Package.resolved
- 重新解析包版本
- 选择兼容的版本

### Q: 删除 DerivedData 后还是不行？
**A**:
- 重启 Mac
- 重启 Xcode
- 检查 Xcode 版本（更新到最新版本）

---

**最后更新**: 2026-02-23
