# 🧪 Day 4-5 系统集成测试指南

## 📌 测试目标

验证 Tier 权益系统与 4 个核心游戏系统的集成，确保：
1. 权益正确应用到各个管理器
2. 游戏机制正确响应权益倍数
3. 权益重置能够正常工作
4. 无编译错误或内存泄漏

---

## 🔍 单元测试

### Test 1: BuildingManager 权益应用

**测试场景**:
```swift
// 创建 Tier 权益实例
let proBenefit = TierBenefit(
    tierId: "pro",
    buildSpeedMultiplier: 1.3,
    productionSpeedMultiplier: 1.3,
    inventoryCapacityBonus: 25,
    name: "Pro"
)

// 应用权益
BuildingManager.shared.applyBuildingBenefit(proBenefit)

// 验证
assert(BuildingManager.shared.buildSpeedMultiplier == 1.3)
```

**预期结果**: ✅ buildSpeedMultiplier 更新为 1.3

---

### Test 2: 建筑加速计算

**测试场景**:
```swift
// 设定 Pro Tier (1.3x 加速)
BuildingManager.shared.applyBuildingBenefit(proBenefit)

// 建造一个需时 130 秒的建筑
let template = BuildingTemplate(
    templateId: "house",
    buildTimeSeconds: 130,  // 130 秒
    ...
)

// 启动建造
try await BuildingManager.shared.startConstruction(...)

// 验证完成时间
// 预期: completedAt = now + (130 / 1.3) = now + 100 秒
// 而不是 now + 130 秒
```

**预期结果**: ✅ 建筑完成时间 = 原始时间 / 1.3 = 100 秒

**验证方法**:
1. 启动应用，登录账户
2. 购买 Pro 订阅
3. 开始建造
4. 在数据库中检查 `build_completed_at` 时间
5. 确认时间 = now + (buildTimeSeconds / 1.3)

---

### Test 3: ProductionManager 权益应用

**测试场景**:
```swift
// 应用权益
ProductionManager.shared.applyProductionBenefit(vipBenefit)

// 验证
assert(ProductionManager.shared.productionSpeedMultiplier == 1.8)
```

**预期结果**: ✅ productionSpeedMultiplier 更新为 1.8

---

### Test 4: 生产加速计算

**测试场景**:
```swift
// 设定 VIP Tier (1.8x 加速)
ProductionManager.shared.applyProductionBenefit(vipBenefit)

// 启动 60 分钟的农场生产
let template = ProductionTemplate(
    buildingTemplateId: "farm",
    productionTimeMinutes: 60,  // 60 分钟
    ...
)

try await ProductionManager.shared.startProduction(...)

// 验证完成时间
// 预期: completionTime = now + (60 * 60 / 1.8) = now + 2000 秒 (33.3 分钟)
// 而不是 now + 3600 秒 (60 分钟)
```

**预期结果**: ✅ 生产完成时间 = 原始时间 / 1.8 ≈ 33.3 分钟

**验证方法**:
1. 应用 VIP Tier
2. 启动生产任务
3. 检查数据库中的 `completion_time`
4. 确认时间 = now + (productionTimeMinutes * 60 / 1.8)

---

### Test 5: InventoryManager 容量扩展

**测试场景**:
```swift
// 初始状态
assert(InventoryManager.shared.maxCapacity == 100)

// 应用 Pro Tier
InventoryManager.shared.applyInventoryBenefit(proBenefit)
assert(InventoryManager.shared.capacityBonus == 25)
assert(InventoryManager.shared.maxCapacity == 125)

// 应用 VIP Tier
InventoryManager.shared.applyInventoryBenefit(vipBenefit)
assert(InventoryManager.shared.capacityBonus == 50)
assert(InventoryManager.shared.maxCapacity == 150)
```

**预期结果**:
- Free: maxCapacity = 100
- Pro: maxCapacity = 125
- VIP: maxCapacity = 150

**验证方法**:
1. 在 InventoryView 中查看容量显示
2. 添加物品超过 100kg 但少于 125kg，应该只在 Pro Tier 下允许
3. 确认容量计算正确

---

### Test 6: 权益重置

**测试场景**:
```swift
// 应用权益后重置
BuildingManager.shared.applyBuildingBenefit(proBenefit)
assert(BuildingManager.shared.buildSpeedMultiplier == 1.3)

BuildingManager.shared.resetBuildingBenefit()
assert(BuildingManager.shared.buildSpeedMultiplier == 1.0)

// 同样测试其他管理器
ProductionManager.shared.applyProductionBenefit(vipBenefit)
ProductionManager.shared.resetProductionBenefit()
assert(ProductionManager.shared.productionSpeedMultiplier == 1.0)

InventoryManager.shared.applyInventoryBenefit(proBenefit)
InventoryManager.shared.resetInventoryBenefit()
assert(InventoryManager.shared.maxCapacity == 100)
```

**预期结果**: ✅ 所有管理器权益正确重置为默认值

---

## 🎮 集成测试

### Integration Test 1: 完整购买流程

**步骤**:
```
1. 启动应用，进入主界面
   ↓
2. 打开 SubscriptionStoreView
   ↓
3. 点击 "Pro" 广告位
   ↓
4. 完成 IAP 购买流程
   ↓
5. 验证 TierManager.updateUserTier() 被调用
   ↓
6. 验证 applyBenefitsToGameSystems() 被调用
   ↓
7. 进入主游戏界面
```

**验证点**:
- [ ] 购买成功，无错误弹窗
- [ ] 用户 Tier 已更新
- [ ] SubscriptionStoreView 显示当前 Tier
- [ ] 可以开始建造/生产
- [ ] 日志显示权益应用信息

---

### Integration Test 2: 权益实时体验

**步骤**:
```
1. 购买 Pro 订阅后进入游戏
   ↓
2. 开始建造（例如建房子，需时 100 秒）
   ↓
3. 观察建造完成时间
```

**验证点**:
- [ ] 建造进度条移动速度快 23% (相对于 Pro Tier 1.3x)
- [ ] 数据库中记录的完成时间 = now + 77 秒（100 / 1.3）
- [ ] 建造最终完成
- [ ] 建筑升级后可用

**时间验证**:
```
原始建造时间: 100 秒
Pro Tier (1.3x): 100 / 1.3 ≈ 77 秒 (快 23%)
VIP Tier (1.8x): 100 / 1.8 ≈ 56 秒 (快 44%)
```

---

### Integration Test 3: 权益过期处理

**步骤**:
```
1. 购买 Pro 订阅（假设有效期 1 天）
   ↓
2. 进入游戏，权益已应用
   ↓
3. 时间向前推进超过 1 天 (模拟器或数据库修改)
   ↓
4. TierManager.checkTierExpiration() 被触发
   ↓
5. applyDefaultBenefits() 被调用
   ↓
6. 权益重置，回到 Free Tier
```

**验证点**:
- [ ] 权益正确过期
- [ ] 建造/生产速度恢复到 1.0x (无加速)
- [ ] 背包容量恢复到 100kg
- [ ] SubscriptionStoreView 显示 "无活跃订阅"

---

## 🐛 调试技巧

### Enable Verbose Logging

在 AppDelegate 或应用启动时启用详细日志:

```swift
// 在 EarthLordApp.swift 中
@main
struct EarthLordApp: App {
    init() {
        // 启用详细日志
        Logger.enable(level: .debug)
    }
}
```

查看日志输出:
```
🏗️ [建筑] 应用Tier权益: 建筑速度倍数 = 1.3
🏭 [生产] 应用Tier权益: 生产速度倍数 = 1.3
🎒 [背包] 应用Tier权益: 容量加成 = 25 kg, 总容量 = 125 kg
✅ [权益] 已应用 Tier pro 权益到所有系统
```

---

### Database Verification

使用 Supabase Console 验证数据库中的权益记录:

1. 打开 Supabase Dashboard
2. 查看 `user_tiers` 表格，确认用户的 Tier 已更新
3. 查看 `entitlements` 表格，确认订阅有效期正确
4. 查看 `player_buildings` 表格，验证 `build_completed_at` 时间计算正确

```sql
-- 验证用户 Tier
SELECT id, user_id, tier_id, created_at, expires_at 
FROM user_tiers 
WHERE user_id = 'USER_ID_HERE';

-- 验证建筑完成时间
SELECT id, building_name, build_started_at, build_completed_at,
       EXTRACT(EPOCH FROM (build_completed_at - build_started_at)) as duration_seconds
FROM player_buildings
WHERE user_id = 'USER_ID_HERE'
ORDER BY build_started_at DESC
LIMIT 5;
```

---

## ✅ 测试检查清单

### 编译阶段
- [x] 无编译错误
- [x] 无编译警告
- [x] 所有 import 正确

### BuildingManager
- [ ] buildSpeedMultiplier 初始值为 1.0
- [ ] applyBuildingBenefit() 正确设置倍数
- [ ] startConstruction() 应用倍数到计算中
- [ ] resetBuildingBenefit() 重置为 1.0
- [ ] 日志正确输出

### ProductionManager
- [ ] productionSpeedMultiplier 初始值为 1.0
- [ ] applyProductionBenefit() 正确设置倍数
- [ ] startProduction() 应用倍数到计算中
- [ ] resetProductionBenefit() 重置为 1.0
- [ ] 日志正确输出

### InventoryManager
- [ ] maxCapacity 初始值为 100
- [ ] capacityBonus 初始值为 0
- [ ] applyInventoryBenefit() 正确增加容量
- [ ] resetInventoryBenefit() 重置为 0
- [ ] 容量验证逻辑正确

### TierManager
- [ ] applyBenefitsToGameSystems() 调用所有管理器方法
- [ ] applyDefaultBenefits() 重置所有管理器
- [ ] 正确获取 TierBenefit 配置
- [ ] 错误处理正确
- [ ] 日志正确输出

### 用户体验
- [ ] 购买订阅后权益立即生效
- [ ] 有效期内权益持续生效
- [ ] 权益过期后自动重置
- [ ] 无明显卡顿或延迟
- [ ] 内存使用正常

---

## 🚀 测试执行命令

### 运行单元测试 (如有 XCTest)
```bash
xcodebuild test -scheme EarthLord -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 清理构建
```bash
xcodebuild clean -scheme EarthLord
```

### 构建并运行
```bash
xcodebuild build -scheme EarthLord -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 📊 性能指标

监测以下指标，确保权益应用不影响性能:

| 指标 | 目标 | 实际 |
|------|------|------|
| 应用权益延迟 | < 100ms | _ |
| 重置权益延迟 | < 100ms | _ |
| 建造计算耗时 | < 10ms | _ |
| 生产计算耗时 | < 10ms | _ |
| 内存占用增加 | < 5MB | _ |

---

## 📝 测试报告模板

```
Day 4-5 集成测试报告
===================

测试日期: [DATE]
测试者: [NAME]

单元测试: [PASS/FAIL]
  - BuildingManager: [PASS/FAIL]
  - ProductionManager: [PASS/FAIL]
  - InventoryManager: [PASS/FAIL]
  - TierManager: [PASS/FAIL]

集成测试: [PASS/FAIL]
  - 完整购买流程: [PASS/FAIL]
  - 权益实时体验: [PASS/FAIL]
  - 权益过期处理: [PASS/FAIL]

问题列表:
- [如有问题，逐一列出]

性能指标:
[填写上述表格]

签核:
测试者: ________________  日期: __________
PM: ________________  日期: __________
```

---

**测试标记**: 🧪 Phase 1 Week 1 Integration Testing
**完成目标**: 验证 4 个核心系统的 Tier 权益应用与重置
