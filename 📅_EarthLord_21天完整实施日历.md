# 📅 EarthLord 16 产品完整实施日历 (21天)

**更新日期**: 2026-02-24  
**项目**: 末世领主（EarthLord）完整订阅系统  
**目标**: 将基础 4 产品系统扩展到完整 16 产品三层付费模型  

---

## 📊 21 天实施概览

```
┌─────────────────────────────────────────────────────────────┐
│                    项目时间线 (21 天)                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Phase 1: 消耗性产品 & 基础架构      (Day 1-7)   ✅ Week 1  │
│ ├─ App Store 配置 (1天)                                      │
│ ├─ 代码实现 (3天)                                            │
│ ├─ 权益集成 (2天)                                            │
│ └─ 测试优化 (1天)                                            │
│                                                               │
│ Phase 2: 非续期订阅系统            (Day 8-14)   ✅ Week 2  │
│ ├─ 产品配置 (1天)                                            │
│ ├─ 代码扩展 (3天)                                            │
│ ├─ 权益机制 (2天)                                            │
│ └─ 集成测试 (1天)                                            │
│                                                               │
│ Phase 3: 自动续期订阅 & 上线       (Day 15-21)  ✅ Week 3  │
│ ├─ 续期产品 (1天)                                            │
│ ├─ 核心逻辑 (3天)                                            │
│ ├─ 系统优化 (2天)                                            │
│ └─ 最终验收 (1天)                                            │
│                                                               │
│ 总工作量: 168 小时 (21 天 × 8 小时/天)               │
│ 团队规模: 1-2 名工程师                                      │
│ 风险等级: 中等 (涉及支付系统)                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗓️ PHASE 1: 消耗性产品 & 基础架构 (Day 1-7)

### Day 1: 环境准备与产品配置

**主题**: 🌐 基础设施搭建  
**工作量**: 4 小时  
**团队**: 1 人  

#### 上午 (两小时)

| 时间 | 任务 | 输出 | 状态 |
|------|------|------|------|
| 09:00-10:00 | 登录 App Store Connect | 账户验证完成 | - |
| 10:00-11:00 | 创建 4 个消耗性产品 ID | 产品已在控制台激活 | - |

**操作步骤**:
```
App Store Connect (https://appstoreconnect.apple.com)
├─ 应用程序 > App 内购买项目
├─ 创建 4 个产品:
│  1. com.earthlord.supply.survivor    ($0.99 = ¥6)
│  2. com.earthlord.supply.explorer    ($2.99 = ¥18)
│  3. com.earthlord.supply.lord        ($4.99 = ¥30)
│  4. com.earthlord.supply.overlord    ($9.99 = ¥68)
└─ 记录所有 4 个产品 ID
```

#### 下午 (两小时)

| 时间 | 任务 | 输出 | 状态 |
|------|------|------|------|
| 14:00-15:00 | 本地化配置 | 中文版本已上传 | - |
| 15:00-16:00 | 创建沙盒账户 | 2 个测试账户已创建 | - |

**操作步骤**:
```
本地化配置:
├─ 产品管理 > 本地化
├─ 添加语言: 中文 (简体)
├─ 添加显示名称和描述
└─ 提交审核

沙盒账户创建:
├─ 用户和角色 > 沙盒 > 测试账户
├─ 账户 1: test.survivor@example.com
├─ 账户 2: test.vip@example.com
└─ 记录密码 (妥善保管)
```

#### 学习输出物

```
✅ Day 1 完成清单:
- [x] 4 个消耗性产品 ID 已激活
- [x] 中文本地化完成
- [x] 2 个沙盒测试账户可用
- [x] 产品配置文档已记录

📝 需要记录的关键数据:
┌─────────────────────────────────────────┐
│ 产品 ID                | 状态   | 审核  │
├─────────────────────────────────────────┤
│ com.earthlord.supply.* | ✅ 活跃 | ✅   │
└─────────────────────────────────────────┘
```

---

### Day 2: 代码框架搭建 (上)

**主题**: 💻 Swift 代码实现  
**工作量**: 6 小时  
**目标**: 完成 IAPModels.swift 和基础 IAPManager  

#### 上午

```swift
// 任务 1: 创建 IAPModels.swift
// 预计: 3 小时

✅ 完成内容:
- [x] 产品 ID 常量定义 (IAPProductID)
- [x] ProductCategory 枚举
- [x] Entitlement 权益模型
- [x] SubscriptionRecord 订阅记录
- [x] PurchaseItem 购买项目模型

📊 代码行数: ~600 行
🔗 需要集成:
   └─ StoreKit 2 框架
   └─ Codable 协议
```

#### 下午

```swift
// 任务 2: 创建 IAPManager.swift (基础版)
// 预计: 3 小时

✅ 完成内容:
- [x] IAPManager 单例初始化
- [x] setupProductCache()
- [x] loadProducts()
- [x] purchase() 基础方法
- [x] setupTransactionListener()
- [x] checkVerified() 收据验证

📊 代码行数: ~400 行
🔗 需要集成:
   └─ StoreKit 2 Product API
   └─ Transaction 监听器
   └─ @MainActor 注解
```

#### 提交清单

```
✅ Day 2 完成清单:
- [x] IAPModels.swift 创建完成
- [x] IAPManager.swift 基础框架完成
- [x] 编译测试 (0 errors, 0 warnings)
- [x] 单元测试框架搭建

🧪 测试覆盖:
- [ ] Entitlement 权益初始化 (16 个产品)
- [ ] 产品 ID 分类正确性
- [ ] 权益数值范围验证
```

---

### Day 3: IAPManager 扩展与UI基础

**主题**: 🎨 UI 框架 + 权益管理  
**工作量**: 6 小时  

#### 上午

```swift
// 任务 1: IAPManager 扩展
// 功能: 权益授予、存储、恢复

✅ 实现方法:
- [x] grantConsumableRewards()     【消耗性商品资源奖励】
- [x] activateTemporaryPerks()     【临时权益激活】
- [x] activateAutoRenewPerks()     【持续权益激活】
- [x] checkSubscriptionStatus()    【订阅状态检查】
- [x] getActiveSubscriptions()     【获取活跃订阅】
- [x] saveSubscriptionRecord()     【本地保存】
- [x] loadSubscriptionRecords()    【加载记录】

时间分配:
├─ 消耗性奖励 (1h)
├─ 权益应用 (1.5h)
│  ├─ 建筑加速
│  ├─ 生产加速
│  ├─ 资源加成
│  └─ 背包容量
├─ 本地存储 (1h)
└─ 权益管理 (1h)
```

#### 下午

```swift
// 任务 2: SubscriptionView UI 框架
// 预计: 3 小时

✅ UI 组件:
- [x] SubscriptionView 主视图
- [x] 分类标签 (战术/领主/帝国/VIP)
- [x] SubscriptionProductCard 产品卡片
- [x] 权益预览面板
- [x] 购买按钮 with 价格显示

UI 布局:
┌─────────────────────────────┐
│  末世权益                    │ ← 标题
├─────────────────────────────┤
│ [战术] [领主] [帝国] [VIP]  │ ← 分类标签
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 产品名称        ¥6      │ │ ← 产品卡片
│ │ 权益1 权益2 权益3      │ │   (可滚动)
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [立即购买 ¥6]  [恢复购买]   │ ← 操作按钮
└─────────────────────────────┘

预计代码行数: ~400 行
```

#### 完成条件

```
✅ Day 3 完成清单:
- [x] IAPManager 所有扩展方法实现
- [x] SubscriptionView UI 完成
- [x] 本地存储集成
- [x] 编译测试通过

🧪 功能验证:
- [ ] 模拟购买流程 (不实际扣费)
- [ ] 权益数据结构验证
- [ ] UI 响应式布局测试
```

---

### Day 4: 权益系统集成 (上)

**主题**: ⚙️ 权益应用到游戏系统  
**工作量**: 6 小时  

#### 上午: RightsManager 创建

```swift
// 任务: 创建 RightsManager.swift
// 目的: 统一管理权益检查和应用

✅ 主要方法:
- [x] checkAndApplyRights()       【检查并应用所有权益】
- [x] applyEntitlementToSystems() 【应用到各游戏系统】
- [x] checkExpiredRights()        【检查过期权益】
- [x] removeEntitlement()         【移除权益】
- [x] hasRight()                  【权益检查】
- [x] getHighestTierRight()       【获取最高等级权益】

实现步骤:
1. 从 IAPManager 获取活跃订阅
2. 为每个订阅创建 Entitlement 对象
3. 应用权益到对应系统
4. 缓存权益数据
5. 监听权益更新

代码行数: ~300 行
```

#### 下午: 建筑系统集成

```swift
// 任务: 在 BuildingManager 中应用权益
// 预计: 3 小时

✅ 集成点:
1. calculateBuildingTime() 
   └─ 应用建造加速权益 (建造时间 -20/40/60%)

2. calculateProductionTime()
   └─ 应用生产加速权益 (生产周期 -15/30/50%)

3. getQueueLimit()
   └─ 应用无限队列权益 (帝国等级)

示例代码:
```
class BuildingManager {
    func calculateBuildingTime(_ baseTime: Int) -> Int {
        // 获取权益
        let entitlement = RightsManager.shared.getHighestTierRight()
        // 应用加速
        let speedup = entitlement?.buildSpeedBonus ?? 0
        return Int(Double(baseTime) * (1 - speedup))
    }
}
```

预计代码改动: ~200 行 (BuildingManager)
```

#### 完成条件

```
✅ Day 4 完成清单:
- [x] RightsManager 完整实现
- [x] BuildingManager 集成权益
- [x] 功能测试 (权益正确应用)
- [x] 编译 0 errors/warnings

🔗 集成验证:
- [ ] 权益数据流: IAPManager → RightsManager → BuildingManager
- [ ] 权益值在合理范围 (0-100%)
- [ ] 过期权益正确移除
```

---

### Day 5: 权益系统集成 (下)

**主题**: ⚙️ 完成系统集成  
**工作量**: 6 小时  

#### 全天任务

```
多系统集成 (1小时 × 6 个系统):

1️⃣ InventoryManager (库存系统)
   ├─ applyBackpackCapacity()        【背包容量】
   └─ 应用权益到物品存储

2️⃣ ProductionManager (生产系统)
   ├─ applyProductionBonus()         【资源产出】
   └─ 应用权益到资源生成速率

3️⃣ ShopManager (商店系统)
   ├─ applyShopDiscount()            【VIP折扣】
   └─ 应用权益到商品价格

4️⃣ TeleportManager (传送系统)
   ├─ applyDailyTeleportLimit()      【传送次数】
   └─ 应用权益到快速旅行

5️⃣ DefenseManager (防御系统)
   ├─ applyDefenseBonus()            【防御加成】
   └─ 应用权益到防御计算

6️⃣ QuestManager (任务系统)
   ├─ applyVIPQuestsAccess()         【VIP任务】
   └─ 应用权益到任务解锁
```

#### 权益检查位置

```
// 关键检查点 (需要在这些位置检查权益):

1. 建造开始
   if RightsManager.shared.hasRight("buildSpeedup") {
       adjustBuildingTime()
   }

2. 资源计算
   let production = baseProduction * (1 + RightsManager.shared.getResourceBonus())

3. 商店购买
   let finalPrice = originalPrice * (1 - RightsManager.shared.getShopDiscount() / 100)

4. 每日任务
   if RightsManager.shared.hasVIPAccess() {
       unlockPremiumTasks()
   }
```

#### 完成条件

```
✅ Day 5 完成清单:
- [x] 6 个系统完成权益集成
- [x] 权益检查点全覆盖
- [x] 功能测试通过
- [x] 性能基准测试 (无性能回退)

📊 集成规模:
├─ 修改文件数: 6 个 Manager
├─ 新增代码行: ~600 行
├─ 修改面积: Medium
└─ 风险等级: Low (功能性集成)
```

---

### Day 6-7: 测试与优化

**主题**: 🧪 沙盒测试 + 代码优化  
**工作量**: 6 小时  

#### Day 6: 完整沙盒测试

```
测试场景执行:

✅ T01 - 消耗性购买 (Survivor)
├─ 前置: 登录沙盒账户 (test.survivor@example.com)
├─ 操作: 点击购买 survivor 补给包 (¥6)
├─ 验证: 
│  ├─ 购买成功 (应显示确认对话)
│  ├─ 资源增加 (验证 InventoryManager)
│  ├─ 交易记录保存 (检查 UserDefaults)
│  └─ 控制台无错误日志
└─ 预期: ✅ 通过

✅ T02 - 消耗性购买 (Overlord)
├─ 操作: 点击购买 overlord 补给包 (¥68)
├─ 验证: 
│  ├─ 购买确认
│  ├─ 稀有资源增加
│  ├─ 资源数量正确 (5000 木材 + 传奇碎片)
│  └─ 控制台验证
└─ 预期: ✅ 通过

⏳ 恢复购买测试
├─ 操作: 点击 "恢复购买" 按钮
├─ 验证: 之前购买的产品重新获得
└─ 预期: ✅ 通过
```

#### Day 7: 代码优化与文档

```
优化清单:

1️⃣ 代码质量 (1.5 小时)
   ├─ [ ] Swift Lint 检查 (0 violations)
   ├─ [ ] 代码格式化 (使用 swiftformat)
   ├─ [ ] 注释完整性检查
   └─ [ ] 移除调试代码

2️⃣ 内存优化 (1.5 小时)
   ├─ [ ] Entitlement 对象缓存
   ├─ [ ] 图片资源懒加载
   ├─ [ ] 检查循环引用
   └─ [ ] 内存泄漏检测

3️⃣ 性能优化 (1.5 小时)
   ├─ [ ] 权益检查缓存 (避免重复计算)
   ├─ [ ] 异步操作优化 (减少主线程阻塞)
   ├─ [ ] 数据库查询优化
   └─ [ ] UI 响应性测试

4️⃣ 文档完成 (1.5 小时)
   ├─ [ ] 代码注释
   ├─ [ ] 集成文档
   ├─ [ ] FAQ 文档
   └─ [ ] 已知问题记录
```

#### Phase 1 完成验收

```
✅ Phase 1 完成标准:
- [x] 4 个消耗性产品可正常购买
- [x] 资源正确分配
- [x] 无编译错误
- [x] 沙盒测试通过 (T01, T02)
- [x] 基础架构完成
- [x] 代码质量达标 (0 violations)
- [x] 性能基准建立

📦 交付物:
├─ IAPModels.swift (完整)
├─ IAPManager.swift (Phase 1 完成)
├─ SubscriptionView.swift
├─ RightsManager.swift
├─ 6 个 Manager 的权益集成
├─ 测试报告
└─ 集成文档

💾 提交到 Git:
git commit -m "Feat: Complete Phase 1 - Consumable Products & Basic IAP"
git push origin main
```

---

## 🗓️ PHASE 2: 非续期订阅系统 (Day 8-14)

### Day 8: 非续期产品配置

**主题**: 🌐 App Store Connect 配置  
**工作量**: 3 小时  

```
创建 9 个非续期订阅产品:

分组 1: 战术支援包 (3个)
├─ com.earthlord.tactical.1m   (¥8, 30天)
├─ com.earthlord.tactical.3m   (¥18, 90天)
└─ com.earthlord.tactical.1y   (¥58, 365天)

分组 2: 领主特权包 (3个)
├─ com.earthlord.lordship.1m   (¥18, 30天)
├─ com.earthlord.lordship.3m   (¥38, 90天)
└─ com.earthlord.lordship.1y   (¥128, 365天)

分组 3: 帝国统治者包 (3个)
├─ com.earthlord.empire.1m     (¥38, 30天)
├─ com.earthlord.empire.3m     (¥88, 90天)
└─ com.earthlord.empire.1y     (¥298, 365天)

操作步骤:
1. App Store Connect > App 内购买项目
2. 点击 + 添加项目
3. 选择 "非续期订阅"
4. 依次填入 9 个产品
   ├─ 产品 ID
   ├─ 名称 (中文)
   ├─ 描述
   ├─ 价格 (选择对应金额)
   └─ 保存
5. 批量本地化 (中文版本)
6. 提交审核

预计时间: 30-45 分钟/产品 × 9 = 4.5 小时
实际优化后: 1-2 分钟/产品 = 15-20 分钟
```

### Day 9-11: 代码扩展 (非续期订阅)

**主题**: 💻 核心逻辑实现  
**工作量**: 12 小时  

#### Day 9: 产品定义扩展

```swift
// 任务 1: 扩展 IAPModels.swift
// 添加 9 个非续期订阅的权益定义

✅ 需要扩展:
- [x] 战术支援权益 (3 个产品, 权益相同)
- [x] 领主特权权益 (3 个产品, 权益相同)
- [x] 帝国统治者权益 (3 个产品, 权益相同)
- [x] Entitlement 构造器扩展 (case 语句)

权益对应关系:
战术支援 (1m/3m/1y):
├─ 建造时间 -20%
├─ 生产周期 -15%
├─ 背包容量 +25kg
├─ 每日奖励 ¥500
├─ 商店折扣 10%
└─ 传送次数 3/天

领主特权 (1m/3m/1y):
├─ 建造时间 -40%
├─ 生产周期 -30%
├─ 资源产出 +20%
├─ 背包容量 +50kg
├─ [所有战术权益]
└─ 每周限定挑战

帝国统治者 (1m/3m/1y):
├─ 建造时间 -60%
├─ 生产周期 -50%
├─ 资源产出 +40%
├─ 背包容量 +100kg
├─ [所有领主权益]
├─ 每月限定挑战
├─ 领地防御 +15%
└─ 专属客服

代码行数: ~600 行
```

#### Day 10: IAPManager 扩展

```swift
// 任务 2: 扩展 IAPManager
// 处理非续期订阅的生命周期

✅ 需要实现:
- [x] checkSubscriptionExpiration()   【定期检查过期】
- [x] activateTemporaryPerks()        【激活临时权益】
- [x] scheduleExpirationNotification()【过期提醒】
- [x] handleSubscriptionExpired()      【处理过期】
- [x] upgradeSubscription()           【升级订阅】
- [x] downgradeSubscription()         【降级订阅】

关键逻辑:
1. 用户购买 tactical.1m (¥8, 30天)
   ├─ 创建 SubscriptionRecord
   ├─ 设置过期时间 = NOW() + 30天
   ├─ 存储到本地
   ├─ 同步到 Supabase
   ├─ 激活权益 (20% 加速)
   └─ 显示确认

2. 每日检查过期
   ├─ 遍历所有订阅
   ├─ 如果过期时间 < NOW():
   │  ├─ 移除权益
   │  ├─ 更新本地记录
   │  ├─ 显示过期通知
   │  └─ 推送续期建议
   └─ 继续检查

代码行数: ~500 行
```

#### Day 11: 数据库与 UI

```swift
// 任务 3: 数据库设计 + 新 UI

✅ 数据库操作:
- [x] user_subscriptions 表创建
- [x] subscription_audit_log 表创建
- [x] RLS 策略配置
- [x] 数据库迁移脚本

✅ UI 扩展:
- [x] 分类选项卡扩展 (添加战术/领主/帝国)
- [x] 产品卡片信息扩展
  ├─ 显示时长 (30/90/365 天)
  ├─ 显示 "最划算" 标签 (季度/年度)
  └─ 权益对比
- [x] 购买后过期倒计时显示
- [x] 续期建议弹窗

示例 UI:
┌───────────────────────────────┐
│ 战术支援-90天  最划算 ¥18     │
│ 建造 -20% 生产 -15%          │
│ 每月仅需 ¥6 (vs ¥8 月卡)    │
│ [立即购买]                    │
├───────────────────────────────┤
│ 剩余 28 天  [续期]            │  ← 已购买时显示
└───────────────────────────────┘

代码行数: UI 扩展 ~300 行
```

#### 完成标准

```
✅ Day 9-11 完成标准:
- [x] 9 个非续期产品权益完整定义
- [x] IAPManager 升级/降级逻辑完成
- [x] 数据库表创建和 RLS 配置
- [x] 新 UI 组件创建完成
- [x] 编译 0 错误
- [x] 单元测试覆盖新功能

📊 代码统计:
├─ IAPModels.swift: +600 行
├─ IAPManager.swift: +500 行
├─ SubscriptionView.swift: +300 行
├─ 数据库脚本: 新增
└─ 总计: +1400 行
```

---

### Day 12-13: 权益和服务器同步

**主题**: 🔄 高级功能  
**工作量**: 8 小时  

#### Day 12: 权益升级/降级

```swift
// 用户订阅场景分析

场景 1: 购买高级订阅
用户已有 tactical.1m (¥8)
  → 想升级到 empire.1m (¥38)
  额外支付: ¥30
  权益: 切换到帝国权益
  操作: 
  ├─ 取消旧订阅
  ├─ 创建新订阅
  ├─ 同步旧权益到新权益过渡
  └─ 显示升级确认

场景 2: 购买低级订阅
用户已有 empire.1m (¥38, 还有 20 天)
  → 购买 tactical.1y (¥58)
  选择:
  ├─ A. 延长订阅 (推荐)
  │  └─ 帝国权益继续至原过期日期
  │     然后切换到战术权益 365 天
  └─ B. 替换订阅 (用户选择)
      └─ 立即切换 (可能亏损)

权益过渡策略:
// 伪代码
if newTier > currentTier:
    // 升级: 立即应用新权益
    applyNewEntitlement(new)
    scheduleExpiration(newSubscriptionID)
else:
    // 降级: 提示用户选择
    showDowngradeOptions()
```

#### Day 13: Supabase 同步

```swift
// 任务: 实现服务器端权益备份与恢复

✅ 同步流程:
1. 本地购买完成
   ├─ 创建 SubscriptionRecord
   ├─ 记录交易 ID、收据等
   └─ 存储到 UserDefaults

2. 后台同步到 Supabase
   ├─ 调用 API 上传记录
   ├─ Supabase 验证收据
   ├─ 创建 subscription_audit_log 记录
   └─ 返回确认 (synced_to_server = true)

3. 跨设备恢复
   ├─ 用户登录其他设备
   ├─ 调用 restorePurchases()
   ├─ 从 Supabase 查询历史购买
   ├─ 重新应用权益
   └─ 同步本地存储

关键 API:

// 上传订阅
POST /rest/v1/user_subscriptions
{
  "user_id": "...",
  "product_id": "com.earthlord.tactical.1m",
  "transaction_id": "...",
  "purchase_date": "2026-02-24T...",
  "expiration_date": "2026-03-26T...",
  "is_auto_renewable": false
}

// 查询订阅历史
GET /rest/v1/user_subscriptions
?user_id=eq.UUID&order=created_at.desc

// 记录审计日志
POST /rest/v1/subscription_audit_log
{
  "user_id": "...",
  "action": "purchase|renew|cancelation|upgrade",
  "product_id": "...",
  "old_state": {...},
  "new_state": {...}
}
```

#### 完成标准

```
✅ 同步完成标准:
- [x] 升级/降级逻辑完整测试
- [x] Supabase API 集成完成
- [x] 权益恢复机制工作
- [x] 审计日志记录正确
- [x] 错误处理完善 (网络错误等)

🔒 安全检查:
- [x] 收据验证在服务端完成
- [x] RLS 策略防止用户间数据泄露
- [x] 交易 ID 防重复
- [x] 审计日志不可篡改
```

---

### Day 14: 集成测试 & 压力测试

**主题**: 🧪 质量保证  
**工作量**: 4 小时  

```
集成测试清单:

✅ T03 - 非续期购买: tactical.1m
├─ 操作: 购买战术支援 30 天
├─ 验证:
│  ├─ [x] 权益立即生效 (建造 -20%)
│  ├─ [x] 本地记录保存
│  ├─ [x] 同步到 Supabase
│  ├─ [x] 权益生效确认通知
│  └─ [x] 无错误日志
└─ 预期: ✅ 通过

✅ T04 - 非续期购买: empire.1y
├─ 操作: 购买帝国统治 365 天
├─ 验证:
│  ├─ [x] 权益应用 (建造 -60%, 产出 +40%)
│  ├─ [x] 每月稀有物资箱生成机制
│  ├─ [x] 无限队列激活
│  └─ [x] 防御 +15% 应用
└─ 预期: ✅ 通过

✅ T08 - 权益过期
├─ 操作: 模拟 30 天后权益过期
├─ 验证:
│  ├─ [x] 权益自动移除
│  ├─ [x] 本地记录更新
│  ├─ [x] 过期通知发送
│  └─ [x] 数字化指标恢复到基础值
└─ 预期: ✅ 通过

✅ T10 - 升级订阅
├─ 操作: tactical.1m → empire.1m
├─ 验证:
│  ├─ [x] 权益即时升级
│  ├─ [x] 定价差异计算 (¥8 → ¥38, 扣款 ¥30)
│  ├─ [x] 审计日志记录 "upgrade"
│  └─ [x] 新的过期日期正确
└─ 预期: ✅ 通过

压力测试:
├─ 同时 5 个权益激活
├─ 权益检查 1000 次
├─ 内存使用监控
└─ CPU 使用监控

✅ Phase 2 完成标准:
- [x] 所有 9 个产品可购买
- [x] 权益过期机制完成
- [x] 升级/降级完成
- [x] Supabase 同步完成
- [x] 集成测试通过 (T03/T04/T08/T10)
- [x] 压力测试通过 (无内存泄漏)
```

---

## 🗓️ PHASE 3: 自动续期订阅 & 上线 (Day 15-21)

### Day 15: VIP 产品配置

**主题**: 🌐 续期订阅产品  
**工作量**: 3 小时  

```
创建 4 个续期订阅:

com.earthlord.vip.monthly
├─ 基础价格: ¥12/月
├─ 试用期: 3 天 (免费)
├─ 推介价格: ¥6/月 (首月)
├─ 自动续费: 是
└─ 订阅组: earthlord_vip_subscriptions

com.earthlord.vip.monthly.trial
├─ 基础价格: ¥6/月 (首月优惠)
├─ 续费: ¥12/月 (第二月)
├─ 试用期: 0 (直接支付)
└─ 针对: 对标试用用户

com.earthlord.vip.quarterly
├─ 基础价格: ¥28/3个月
├─ 月均成本: ¥9.3/月 (vs ¥12 月卡)
├─ 节省: 22% 优惠
└─ 自动续费: 是 (每 3 个月)

com.earthlord.vip.annual
├─ 基础价格: ¥88/年
├─ 月均成本: ¥7.3/月 (vs ¥12 月卡)
├─ 节省: 39% 优惠
└─ 自动续费: 是 (每年)

操作步骤 (同 Day 8):
1. App Store Connect > App 内购买项目
2. 选择 "自动续期订阅"
3. 创建订阅组 "earthlord_vip_subscriptions"
4. 新建 4 个产品 (设置续期周期)
5. 本地化后提交审核
6. 设置沙盒测试账户 (测试自动续费)

预计时间: 1-2 小时
```

### Day 16-18: 续期逻辑实现

**主题**: 💻 自动续费核心  
**工作量**: 12 小时  

#### Day 16: 续期产品权益定义

```swift
// 任务: 扩展 Entitlement 处理续期产品

VIP 权益对标:
- VIP 月卡 = 战术支援权益
- VIP 季卡 = 战术支援权益 (但月数为 3)
- VIP 年卡 = 战术支援权益 (但月数为 12)
+ 额外:
  ├─ 每月补给券 (¥20-50)
  ├─ 月度排行榜参赛
  ├─ 专属徽章系统
  └─ 抢先测试新功能

权益生效规则:
if isVIPSubscribed && !subscription.expired:
    applyVIPEntitlements()
    scheduleMonthlyBonusDelivery()  // 月度补给
    enableVIPBadge()                 // VIP 标志
else if subscription.expirationDate < 7days:
    showRenewalReminder()            // 续期提醒
```

#### Day 17: 自动续费事件处理

```swift
// 任务: 实现续费监听和处理

StoreKit 2 续费事件:
1. 订阅即将续费 (前 7 天)
   ├─ 推送通知: "您的 VIP 订阅将在 X 天后续费"
   └─ 用户可选: 取消或确认

2. 续费成功
   ├─ 交易类型: autoRenewal
   ├─ 创建新 SubscriptionRecord
   ├─ 生效期延长
   ├─ 重新应用权益
   └─ 发送确认通知

3. 续费失败
   ├─ 原因: 支付方法过期/余额不足
   ├─ 显示错误提示
   ├─ 提供重新支付选项
   └─ 记录审计日志

4. 用户取消订阅
   ├─ 取消时间立即生效或月底生效 (用户选择)
   ├─ 管理后台同步取消
   ├─ 权益移除
   └─ 记录 "cancelation" 审计

关键代码:

for await result in Transaction.updates {
    do {
        let transaction = try checkVerified(result)
        
        if transaction.isUpgraded {
            // 自动续费事件
            await handleAutoRenewal(transaction)
        }
        
        if let revocationDate = transaction.revocationDate {
            // 用户已取消订阅
            // revocationDate = 订阅何时停止有效
            await handleCancelation(transaction)
        }
    }
}
```

#### Day 18: 续费管理 UI

```swift
// 任务: 创建订阅管理界面

UI 界面:
┌─────────────────────────────┐
│ VIP 订阅管理                 │
├─────────────────────────────┤
│ VIP 月会员                   │
│ ¥12/月 (自动续费)            │
│ 下次续费: 2026-03-24         │
│ 剩余天数: 28 天              │
│                             │
│ [取消续费]                   │
│ [升级到 VIP 年会员]          │
├─────────────────────────────┤
│ 历史订阅:                    │
│ • VIP 月会员 x3 (已过期)    │
│ • 战术支援-90天 (已过期)    │
└─────────────────────────────┘

功能:
- 显示当前活跃订阅
- 显示续费日期
- 提供升级选项 (月 → 季/年)
- 显示取消确认选项
- 显示历史订阅记录
```

#### 完成标准

```
✅ Day 16-18 完成标准:
- [x] VIP 产品权益完整定义
- [x] 自动续费事件处理完成
- [x] 续费失败处理完成
- [x] 用户取消订阅逻辑完成
- [x] 订阅管理 UI 完成
- [x] 编译 0 错误

📊 代码统计:
├─ IAPModels 扩展: +200 行
├─ IAPManager 扩展: +400 行
├─ 新 UI 组件: +300 行
└─ 总计: +900 行
```

---

### Day 19-20: 系统优化与集成

**主题**: ⚡️ 性能优化 + 完整集成  
**工作量**: 8 小时  

#### Day 19: 完整系统集成

```
集成检查清单:

1️⃣ 权益叠加处理
   ├─ 用户同时有多个订阅时的权益计算
   ├─ 选择最高等级权益
   └─ 权益加成不叠加 (取最大值)

2️⃣ 跨产品组兼容性
   ├─ 消耗性产品 + 订阅同时使用
   ├─ 两部分权益合并应用
   └─ 过期处理独立

3️⃣ UI 统一性
   ├─ 所有购买流程统一
   ├─ 确认对话格式统一
   ├─ 错误提示格式统一
   └─ 权益显示统一

4️⃣ 数据一致性
   ├─ 本地数据 = Supabase 数据
   ├─ 权益状态 = 订阅状态
   ├─ 交易记录 = 审计日志
   └─ 恢复购买 = 数据同步

测试:
✅ T12 - 多产品叠加
├─ 操作:
│  ├─ 购买 survivor 补给包 (消耗性)
│  ├─ 购买 tactical.1m (非续期)
│  └─ 购买 vip.monthly (续期)
├─ 验证:
│  ├─ [x] 3 个权益都应用
│  ├─ [x] 权益正确合并
│  ├─ [x] 过期处理独立
│  └─ [x] 无冲突
└─ 预期: ✅ 通过
```

#### Day 20: 性能与安全优化

```
性能优化 (预期 30-40% 性能提升):

1️⃣ 权益检查缓存
   ├─ 缓存 Entitlement 对象 (需要时重新计算)
   ├─ 避免频繁初始化权益
   └─ 减少权益检查调用

2️⃣ 订阅日期计算优化
   ├─ 使用 Calendar.dateComponents() 而非 DateFormatter
   ├─ 缓存天数计算结果
   └─ 避免频繁日期格式化

3️⃣ 数据库查询优化
   ├─ 创建索引在关键字段
   ├─ 避免 N+1 查询问题
   ├─ 使用分页加载历史订阅
   └─ 优化 RLS 策略查询

4️⃣ 内存管理
   ├─ 避免循环引用 (使用 [weak self])
   ├─ 及时释放大对象
   ├─ 监控内存泄漏
   └─ 图片资源优化 (WebP 格式)

安全优化:
✅ 收据验证
   ├─ 在服务端验证 (不在客户端)
   ├─ 检查收据签名
   ├─ 检查收据时间戳
   └─ 防止重放攻击

✅ 数据加密
   ├─ 本地存储使用 Keychain (敏感信息)
   ├─ Supabase 使用 HTTPS
   ├─ 用户数据 RLS 保护
   └─ API 使用 JWT 认证

✅ 输入验证
   ├─ 验证产品 ID 有效性
   ├─ 验证价格范围 (不为负数)
   ├─ 验证日期有效性
   └─ 验证交易 ID 格式
```

#### 完成标准

```
✅ Day 19-20 完成标准:
- [x] 完整系统集成验收
- [x] 所有 12 个测试场景通过
- [x] 性能优化完成 (性能提升 30%+)
- [x] 安全审计完成
- [x] 无编译错误
- [x] 代码审查通过

📊 集成规模:
├─ 代码行数: 16 个产品完整提及
├─ 文件修改数: 15+ 个文件
├─ 功能点数: 30+ 个功能
└─ 测试覆盖: 12 个场景 100% 通过
```

---

### Day 21: 最终验收与上线准备

**主题**: ✅ 质量检查 + 上线准备  
**工作量**: 2 小时用于最终验收 + 2 小时用于文档  

#### 最终验收清单

```
核心功能验收:

✅ 消耗性产品 (4 个)
├─ [ ] 全部可购买
├─ [ ] 资源正确分配
└─ [ ] 无错误

✅ 非续期订阅 (9 个)
├─ [ ] 全部可购买
├─ [ ] 权益生效
├─ [ ] 倒计时显示
├─ [ ] 过期处理
└─ [ ] 升级/降级

✅ 自动续费订阅 (4 个)
├─ [ ] 全部可购买
├─ [ ] 自动续费
├─ [ ] 取消订阅
└─ [ ] 续费失败处理

✅ 数据同步
├─ [ ] Supabase 同步正常
├─ [ ] 恢复购买完整
└─ [ ] 审计日志记录

✅ UI/UX
├─ [ ] 界面美观
├─ [ ] 响应快速
├─ [ ] 提示清晰
└─ [ ] 流程顺畅

✅ 安全性
├─ [ ] 收据验证安全
├─ [ ] RLS 策略生效
├─ [ ] 交易 ID 防重
└─ [ ] 敏感信息加密

全部检查项目:
   ☑️ 16/16 功能项目
   ☑️ 12/12 测试场景
   ☑️ 0 编译错误
   ☑️ 0 运行崩溃
   ☑️ 100% 测试通过率

✅ 最终验收: 通过 ✓
```

#### 上线前检查

```
1️⃣ App Store Connect 设置
   ├─ [ ] 16 个产品已批准
   ├─ [ ] 本地化完成 (中文)
   ├─ [ ] 隐私政策已更新
   └─ [ ] 家长控制已配置

2️⃣ App 版本
   ├─ [ ] 版本号更新 (e.g., 2.1.0 → 2.2.0)
   ├─ [ ] BuildNumber 递增
   ├─ [ ] 发行说明已编写
   └─ [ ] 截图/预览已更新

3️⃣ 代码审查
   ├─ [ ] 全代码审查完成
   ├─ [ ] 无安全漏洞
   ├─ [ ] 无性能问题
   └─ [ ] 注释完整

4️⃣ 文档完整
   ├─ [ ] API 文档
   ├─ [ ] 故障排查指南
   ├─ [ ] 已知问题列表
   └─ [ ] FAQ 文档

5️⃣ 备份与恢复
   ├─ [ ] 代码 Git 分支
   ├─ [ ] 数据库备份
   ├─ [ ] 配置备份
   └─ [ ] 恢复流程测试
```

#### 提交与监控

```
提交流程:

1. 构建 Archive
   └─ xcodebuild -scheme EarthLord -configuration Release archive

2. 上传到 App Store Connect
   └─ xcodebuild -exportArchive -archivePath ... -exportPath ...

3. 提交审核
   ├─ App Store Connect > 构建版本 > 提交以供审核
   ├─ 选择发布方式 (手动批准)
   └─ 等待审核 (36-72 小时)

4. 发布
   ├─ 审批通过 → 手动发布
   ├─ 设置发布时间 (可推迟)
   └─ 发布后监控

5. 上线后监控 (第 1-7 天)
   ├─ [ ] 崩溃率监控 (目标 < 0.1%)
   ├─ [ ] 性能监控 (内存/CPU)
   ├─ [ ] 用户评分 (目标 4.5+)
   ├─ [ ] 购买成功率 (目标 95%+)
   └─ [ ] 关键日志监控 (无异常)

紧急预案:
├─ 版本热备 (如出现严重 bug)
└─ 回滚方案 (恢复旧版本)
```

#### 最终交付物

```
📦 Project Close-Out Deliverables:

代码:
├─ ✅ IAPModels.swift (完整)
├─ ✅ IAPManager.swift (完整)
├─ ✅ SubscriptionView.swift (完整)
├─ ✅ RightsManager.swift (完整)
├─ ✅ 6 个系统集成代码
├─ ✅ 数据库迁移脚本
└─ ✅ 所有测试代码

文档:
├─ ✅ 16 产品完整开发指南 (~15,000 行)
├─ ✅ 21 天实施日历 (本文档)
├─ ✅ API 文档
├─ ✅ 故障排查指南
├─ ✅ 已知问题列表
└─ ✅ FAQ 文档

测试:
├─ ✅ 12 个完整测试场景
├─ ✅ 测试报告 (100% 通过)
├─ ✅ 性能基准测试
├─ ✅ 安全审计报告
└─ ✅ 压力测试结果

统计:
├─ 📊 总代码行数: ~5,000 行 (Swift)
├─ 📊 文档行数: ~20,000 行
├─ 📊 测试覆盖率: 95%+
├─ 📊 工作时间: 168 小时 (3 周 × 8 小时/天)
└─ 📊 项目完成度: 100%

✅ PROJECT STATUS: ✅ COMPLETE & READY FOR PRODUCTION
```

---

## 📊 关键指标与目标

### 项目进度跟踪

| Phase | 目标 | 完成度 | 状态 |
|-------|------|--------|------|
| Phase 1 | 4 消耗性产品 | 0% | 📅 Day 1-7 |
| Phase 2 | 9 非续期订阅 | 0% | 📅 Day 8-14 |
| Phase 3 | 4 续期订阅 | 0% | 📅 Day 15-21 |
| 总体 | 16 产品完整系统 | 0% | 📅 Day 1-21 |

### 质量指标

```
通过标准:

编译质量:
├─ 编译错误: 0 (必须)
├─ 编译警告: 0 (目标)
└─ Lint 违规: 0 (目标)

功能完整:
├─ 功能实现率: 100% (12/12 场景通过)
├─ 测试通过率: 100% (所有自动化测试通过)
└─ 权益应用正确率: 100%

性能指标:
├─ 应用启动时间: < 2s
├─ 购买流程耗时: < 5s
├─ 权益检查耗时: < 100ms
└─ 内存占用: < 200MB

用户体验:
├─ UI 响应时间: < 300ms
├─ 屏幕帧率: ≥ 60fps
├─ 崩溃率: < 0.1%
└─ 用户满意度: 4.5+ 星
```

### 风险管理

```
关键风险:

🔴 高风险:
1. App Store 审核延迟
   └─ 应对: 提前 2 周提交
2. 支付验证失败
   └─ 应对: 加强测试覆盖
3. 数据同步异常
   └─ 应对: 实施本地-云端双备

🟡 中风险:
1. 权益叠加复杂
   └─ 应对: 详细文档和测试
2. 性能回退
   └─ 应对: 性能基准测试

🟢 低风险:
1. UI 美化需求变更
   └─ 应对: 预留 1-2 天调整
```

---

## ✅ 21 天快速参考

```
Week 1 (Day 1-7) - 基础架构 + 消耗性
├─ 📅 Day 1: 产品配置
├─ 📅 Day 2-3: 代码实现
├─ 📅 Day 4-5: 权益集成
└─ 📅 Day 6-7: 测试优化

Week 2 (Day 8-14) - 非续期订阅
├─ 📅 Day 8: 产品配置
├─ 📅 Day 9-11: 代码扩展
├─ 📅 Day 12-13: 权益同步
└─ 📅 Day 14: 集成测试

Week 3 (Day 15-21) - 续期订阅 + 上线
├─ 📅 Day 15: 续期产品配置
├─ 📅 Day 16-18: 续期实现
├─ 📅 Day 19-20: 优化集成
└─ 📅 Day 21: 最终验收

总结:
✅ 16 个产品完整系统
✅ 三层付费模型
✅ 完整权益系统
✅ 服务器同步
✅ 100% 测试通过
✅ 生产就绪
```

---

## 📞 支持 & 联系

**遇到问题?**
- 查阅 [16 产品完整开发指南](🚀_EarthLord_16产品完整开发指南.md) 第 9 章
- 参考故障排查指南
- 联系开发团队

**文档更新:**
- 最后更新: 2026-02-24
- 下次审查: 2026-03-24

---

**🎉 准备好了吗? Let's Build!**

按照本计划执行，你将在 21 天内完成一个完整的三层付费系统。
