# 🔧 领地建造问题诊断和修复

## 问题描述
用户在领地界面点击"建造"按钮后，��法看到可建造的建筑列表。

## 可能的原因

### 1. ❌ 背包已满（最可能）
**控制台日志显示**:
```
[2026-02-23T07:00:29Z] [🔍 DEBUG] [ExplorationManager.swift:149] 📝 系统：背包重量已更新为 192.55 kg
[2026-02-23T07:01:38Z] [⚠️ WARNING] [EarthLordEngine.swift:386] ⚠️ [搜刮] 背包已满，无法搜刮
```

**影响**: 背包已满可能导致：
- InventoryManager 无法正确加载物品
- 资源检查失败
- 建造按钮被禁用

### 2. ❌ 数据库表缺失
**控制台日志显示**:
```
[2026-02-23T07:00:43Z] [❌ ERROR] [InventoryManager.swift:162] ❌ [背包] 加载失败: Could not find the table 'public.item_definitions' in the schema cache
```

**影响**: `inventoryManager.items` 可能为空，导致建筑卡片无法显示资源状态。

### 3. ❌ UI 刷新问题
**控制台日志显示**:
```
[2026-02-23T07:00:41Z] [ℹ️ INFO] [BuildingManager.swift:43] 🏗️ [建筑] ✅ 加载 5 个建筑模板
[2026-02-23T07:00:41Z] [ℹ️ INFO] [BuildingManager.swift:275] 🏗️ [建筑] ✅ 加载 0 个建筑
```

**说明**: 建筑模板已加载，但 UI 可能没有正确显示。

---

## ✅ 已添加的调试日志

我在 `BuildingBrowserView.swift` 中添加了详细的调试日志：

```swift
.onAppear {
    LogDebug("🏗️ [BuildingBrowserView] onAppear 开始")
    LogDebug("  - territoryId: \(territoryId)")
    LogDebug("  - 建筑模板数量: \(buildingManager.buildingTemplates.count)")
    LogDebug("  - 筛选后的模板数量: \(filteredTemplates.count)")
    LogDebug("  - 当前分类: \(selectedCategory.rawValue)")

    Task {
        await buildingManager.fetchPlayerBuildings(territoryId: territoryId)
        await MainActor.run {
            LogDebug("🏗️ [BuildingBrowserView] fetchPlayerBuildings 完成")
            LogDebug("  - 建筑模板数量: \(buildingManager.buildingTemplates.count)")
            LogDebug("  - 玩家建筑数量: \(buildingManager.playerBuildings.count)")
        }
    }
    if inventoryManager.items.isEmpty {
        Task {
            await inventoryManager.loadInventory()
            await MainActor.run {
                LogDebug("🏗️ [BuildingBrowserView] loadInventory 完成")
                LogDebug("  - 物品数量: \(inventoryManager.items.count)")
            }
        }
    }
}
```

---

## 🔍 诊断步骤

### 第一步：清理背包

背包已满（192.55/200 kg），这可能导致各种问题。

**方法 1：使用物品**
1. 进入「资源管理」→「背包」
2. 使用一些物品（如水、食物）
3. 释放背包空间

**方法 2：临时提高背包容量**
我可以添加一个临时功能来提高背包上限。

### 第二步：查看调试日志

重新打开建筑浏览器，查看控制台输出：

```
🏗️ [BuildingBrowserView] onAppear 开始
  - territoryId: xxx
  - 建筑模板数量: X
  - 筛选后的模板数量: X
  - 当前分类: xxx
```

**预期输出**:
- 建筑模板数量: 5
- 筛选后的模板数量: 5（如果选"全部"）
- 当前分类: "全部" 或其他分类

### 第三步：检查分类筛选

如果您选择了某个分类（如"防御"），而该分类下没有建筑，会显示"暂无建筑模板"。

**解决方法**:
- 点击第一个分类标签"全部"
- 查看是否显示建筑

### 第四步：检查 InventoryManager

如果 `inventoryManager.items` 为空，建筑卡片仍会显示，但资源指示器会显示为红色（缺少资源）。

---

## 🛠️ 临时解决方案

### 方案 1：使用物品释放背包空间

添加快速使用物品的功能：<tool_call>Write<arg_key>content</arg_key><arg_value>// TODO: 添加到 BackpackView 或 InventoryView
// 快速使用物品功能
func quickUseItem(_ item: BackpackItem) {
    // 减少物品数量
    // 更新背包重量
    // 保存到数据库
}
