# 🏆 EarthLord 成就系统 - 完整实施指南

## ✅ 已完成的工作

### 1. 数据库层
- ✅ `supabase_migration_009_tasks_achievements.sql` - 基础成就表
- ✅ `supabase_migration_010_achievement_leaderboard.sql` - 排行榜系统
- ✅ `supabase_migration_011_achievement_data.sql` - 31个成就数据

### 2. 管理器层
- ✅ `AchievementManager.swift` - 成就管理器
  - 获取成就定义
  - 更新成就进度
  - 批量检查和解锁
  - 统计数据计算

- ✅ `LeaderboardManager.swift` - 排行榜管理器
  - 排行榜数据获取
  - 用户统计查询
  - 赛季和奖励管理

### 3. UI 组件
- ✅ `AchievementsView.swift` - 成就主界面
  - 分类筛选
  - 成就卡片列表
  - 成就详情弹窗
  - 统计概览
  - 排行榜入口

- ✅ `AchievementStatsView.swift` - 个人界面成就统计
  - 总��分、解锁数量、完成度、排名
  - 与 AchievementManager 数据同步
  - 点击查看详细统计

- ✅ `CategoryAchievementStatsView.swift` - 分类成就详细统计
  - 按分类显示统计数据
  - 积分、解锁数、排名

### 4. 集成文档
- ✅ `AchievementIntegrationExamples.swift` - 集成示例和指南

---

## 📋 实施步骤

### 步骤 1：执行数据库迁移 ⚠️ 必须执行

```bash
# 按顺序执行以下迁移脚本

# 1. ���础成就表（如果还没执行）
supabase db push supabase_migration_009_tasks_achievements.sql

# 2. 排行榜系统（如果还没执行）
supabase db push supabase_migration_010_achievement_leaderboard.sql

# 3. 成就数据初始化（新增）
supabase db push supabase_migration_011_achievement_data.sql
```

或者在 Supabase Dashboard 的 SQL Editor 中手动执行这些 SQL 文件的内容。

### 步骤 2：验证数据库

执行以下 SQL 验证数据是否正确插入：

```sql
-- 检查成就数量
SELECT COUNT(*) FROM achievements;
-- 应该返回 31

-- 检查各分类成就数量
SELECT category, COUNT(*) as count
FROM achievements
GROUP BY category
ORDER BY category;
```

预期结果：
```
category       | count
---------------+-------
building       | 5
exploration    | 5
resource       | 6
social         | 4
territory      | 6
trade          | 5
```

### 步骤 3：游戏事件集成

在相应位置调用成就系统：

```swift
// 示例 1: 在建造建筑时（EarthLordEngine）
func onBuildingBuilt(buildingType: String) async {
    // 更新"任意建筑"成就
    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "build_any",
        currentValue: getTotalBuildingCount()
    )

    // 更新特定建筑成就
    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "build_\(buildingType)",
        currentValue: getBuildingCount(type: buildingType)
    )
}

// 示例 2: 在收集资源时（ExplorationManager）
func onResourceCollected(resourceType: String, amount: Int) async {
    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "resource_\(resourceType)",
        currentValue: getTotalResourceCollected(resourceType: resourceType)
    )

    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "resource_any",
        currentValue: getTotalAllResources()
    )
}

// 示例 3: 在占领领地时（TerritoryManager）
func onTerritoryClaimed() async {
    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "territory_count",
        currentValue: territories.count
    )
}

// 示例 4: 在探索POI时（ExplorationManager）
func onPOIScavenged() async {
    await AchievementManager.shared.checkAndUnlockAchievements(
        requirementType: "poi_scavenged",
        currentValue: getScavengedPOICount()
    )
}
```

### 步骤 4：应用启动初始化

在 `EarthLordApp.swift` 中添加：

```swift
@main
struct EarthLordApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var achievementManager = AchievementManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // 初始化成就数据
                    if authManager.currentUser != nil {
                        await achievementManager.refreshData()
                    }
                }
        }
    }
}
```

---

## 🧪 测试方法

### 1. 手动测试解锁成就

在测试菜单或调试视图中添加：

```swift
// 测试建筑成就
Button("测试: 解锁第一个建筑成就") {
    Task {
        try? await AchievementManager.shared.updateProgress(
            achievementId: "build_first",
            progress: 1.0
        )
        print("✅ 已解锁 build_first")
    }
}

// 测试资源成就
Button("测试: 解锁资源成就") {
    Task {
        try? await AchievementManager.shared.updateProgress(
            achievementId: "resource_1000",
            progress: 1.0
        )
        print("✅ 已解锁 resource_1000")
    }
}

// 测试批量解锁
Button("测试: 解锁5个建筑成就") {
    Task {
        for i in 1...5 {
            try? await AchievementManager.shared.updateProgress(
                achievementId: "build_\(i)",
                progress: 1.0
            )
        }
        print("✅ 已解锁5个建筑成就")
    }
}

// 测试排行榜更新
Button("测试: 刷新排行榜") {
    Task {
        try? await LeaderboardManager.shared.recalculateAllRankings()
        print("✅ 排行榜已重新计算")
    }
}
```

### 2. 真机测试检查清单

- [ ] 个人界面显示成就统计卡片
- [ ] 成就统计显示正确的数字（积分、解锁数、完成度）
- [ ] 点击"查看完整排行榜"可以打开排行榜详情
- [ ] 任务标签页可以看到成就列表
- [ ] 成就列表顶部显示统计概览
- [ ] 分类筛选可以正常工作
- [ ] 点击成就卡片可以打开详情弹窗
- [ ] 详情弹窗显示正确的成就信息
- [ ] 未解锁成就显示进度条
- [ ] 已解锁成就显示"已获得奖励"
- [ ] 下拉刷新可以更新数据

---

## 🎨 UI 设计规范

### 颜色方案
```swift
// 背景
背景色: Color(red: 0x12/255, green: 0x18/255, blue: 0x26/255)

// 卡片背景
卡片背景: Color(red: 0x1E/255, green: 0x24/255, blue: 0x30/255)

// 分隔线
分隔线: Color(red: 0x2A/255, green: 0x30/255, blue: 0x3D/255)

// 图标蓝色
图标蓝: Color(red: 0x34/255, green: 0x98/255, blue: 0xDB/255)

// 文字颜色
主文字: .white
副文字: Color(red: 0xB0/255, green: 0xB8/255, blue: 0xC4/255)
弱文字: Color(red: 0x6B/255, green: 0x77/255, blue: 0x85/255)

// 特殊颜色
金色: Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255)
绿色: Color(red: 0x00/255, green: 0xFF/255, blue: 0x88/255)
```

### 圆角规范
```swift
卡片圆角: 12
按钮圆角: 20
小圆角: 8
```

### 字体大小
```swift
标题: 18-24 (bold)
副标题: 16 (semibold)
正文: 13-14
小字: 11-12
```

---

## 🐛 常见问题排查

### 问题 1：成就不显示
**可能原因：**
- 数据库迁移未执行
- 成就表为空

**解决方法：**
```sql
-- 检查成就表
SELECT COUNT(*) FROM achievements;

-- 如果为 0，重新执行迁移
-- 或者手动插入测试数据
INSERT INTO achievements (id, category, title, description, icon, requirement, reward_experience, is_active)
VALUES ('test_achievement', 'building', '测试成就', '这是一个测试成就', 'star.fill', 'build_count:test:1', 100, true);
```

### 问题 2：排行榜不更新
**可能原因：**
- 数据库触发器未创建
- 触发器被禁用

**解决方法：**
```sql
-- 检查触发器
SELECT trigger_name
FROM information_schema.triggers
WHERE event_object_table = 'user_achievements';

-- 手动更新排行榜
SELECT update_user_achievement_leaderboard('your-user-id');

-- 重新计算排名
SELECT recalculate_leaderboard_rankings();
```

### 问题 3：点击没反应
**可能原因：**
- 视图层级问题
- 手势冲突

**解决方法：**
- 检查是否有其他视图遮挡
- 使用 `.buttonStyle(PlainButtonStyle())` 避免默认样式冲突
- 确保 `@State` 变量正确绑定

### 问题 4：数据不刷新
**可能原因：**
- 没有调用 `refreshData()`
- 缓存未更新

**解决方法：**
```swift
// 在视图出现时刷新
.onAppear {
    Task {
        await AchievementManager.shared.refreshData()
    }
}

// 添加下拉刷新
.refreshable {
    await AchievementManager.shared.refreshData()
}
```

---

## 📊 成就列表

### 建筑成就 (5个)
1. **第一块砖** - 建造你的第一个建筑
2. **建造者** - 建造10个建筑
3. **建筑大师** - 建造50个建筑
4. **建筑宗师** - 建造100个建筑
5. **全能建造者** - 建造所有类型的建筑

### 资源成就 (6个)
1. **初探资源** - 收集1000单位资源
2. **资源大亨** - 收集10000单位资源
3. **资源霸主** - 收集100000单位资源
4. **资源王者** - 收集1000000单位资源
5. **食物专家** - 收集50000单位食物
6. **水源守护者** - 收集50000单位水

### 领地成就 (6个)
1. **领主** - 拥有你的第一个领地
2. **城主** - 拥有5个领地
3. **封疆大吏** - 拥有10个领地
4. **帝国缔造者** - 拥有50个领地
5. **繁荣领地** - 将领地升级到10级
6. **超级领地** - 将领地升级到50级

### 探索成就 (5个)
1. **探险家** - 完成首次探索
2. **荒原探索者** - 探索10个POI
3. **荒原猎人** - 探索50个POI
4. **荒原之王** - 探索100个POI
5. **地图制作者** - 探索500个POI

### 交易成就 (5个)
1. **交易新手** - 完成首次交易
2. **商人** - 完成10次交易
3. **贸易专家** - 完成50次交易
4. **贸易大师** - 完成100次交易
5. **商业巨子** - 完成1000次交易

### 社交成就 (4个)
1. **交友** - 添加第一个好友
2. **人脉** - 拥有10个好友
3. **乐于助人** - 帮助好友10次
4. **公会成员** - 加入公会

---

## 🎯 下一步计划

### 必需项（当前版本）
- [x] 数据库设计
- [x] 管理器实现
- [x] UI 组件开发
- [x] 集成指南
- [ ] 游戏事件集成
- [ ] 测试和调试

### 可选项（未来版本）
- [ ] 成就通知系统
- [ ] 成就分享功能
- [ ] 成就对比功能
- [ ] 好友成就排行榜
- [ ] 成就里程碑动画
- [ ] 成就徽章展示

---

## 📞 支持

如有问题，请查看：
1. `AchievementIntegrationExamples.swift` - 详细的集成示例
2. 数据库迁移脚本中的注释
3. Xcode 控制台的调试日志

---

**版本**: 2.0
**日期**: 2026-02-27
**状态**: ✅ 完整版，可以立即使用
**预计集成时间**: 1-2 小时