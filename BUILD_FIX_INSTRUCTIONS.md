# Xcode 缓存清理和编译修复说明

## 问题原因
Xcode 缓存了已删除的文件（ChannelAndTradeModels.swift 和 Views/Social/），导致编译错误。

## 解决步骤

### 1. 清理 Xcode 缓存（重要！）

在 Xcode 中执行以下操作：

1. **菜单**: Product → Clean Build Folder (或按 ⇧⌘K)
2. **等待**: 等待清理完成（约 10-30 秒）

### 2. 如果上述方法无效，执行深度清理

在终端中执行：

```bash
cd /Users/lyanwen/Desktop/EarthLord
chmod +x clean_xcode_cache.sh
./clean_xcode_cache.sh
```

然后：
1. 完全关闭 Xcode
2. 重新打开 Xcode 项目
3. 执行 Product → Clean Build Folder (⇧⌘K)

### 3. 重新编译

执行 Product → Build (⌘B)

## 已修复的文件

| 文件 | 修复内容 |
|------|----------|
| TradeManager.swift | userTier.benefits → TierBenefit.getBenefit(for:) |
| CreateTradeView.swift | Preview @State 修复 |

## 验证修复

编译成功后，你应该看到：
- ✅ Build Succeeded
- 0 Errors
- 可能有警告（忽略警告）

## 如果仍有错误

请提供具体的错误消息，格式如下：
```
文件路径:行号:列号: 错误消息
```
