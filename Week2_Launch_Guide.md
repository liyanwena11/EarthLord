# 🚀 Week 2 启动指南

**开始日期**: 2026年2月25日  
**Phase**: Phase 1 - Week 2  
**目标完成度**: 100%  
**前置条件**: Phase 1 Week 1 已完成 (95%)

---

## 📊 建筑项目总体进度

```
Phase 1: 订阅系统 + 核心权益
├─ Week 1: ✅ 95% 完成
│  ├─ Day 1-2: Models + IAP (完成)
│  ├─ Day 3: SubscriptionStoreView (完成)
│  ├─ Day 4-5: System Integration (完成)
│  └─ 待冲配: 最后 5% 优化
│
├─ Week 2: 🚀 即将启动
│  ├─ Day 6-7: Territory & Defense (新)
│  ├─ Day 8-9: Social & Trade (新)
│  └─ Day 10: App Store 准备
│
└─ Phase 2: 高级功能 (后续)
   ├─ 任务系统
   ├─ 成就系统
   └─ 商城系统
```

---

## 🎯 Week 2 核心目标

### 1️⃣ Territory & Defense 系统集成 (Day 6-7)

**功能范围**:
- 圈地权益应用 (Tier 增加圈地数量/大小)
- 防御加成 (Tier 提升防御力/恢复速度)
- TerritoryManager 与 Tier 系统关联

**关键文件**:
- `TerritoryManager.swift` - 添加防御倍数和权益应用
- `TierManager.swift` - 扩展 applyBenefitsToGameSystems()
- 新增: `DefenseSystemManager.swift` (如需)

**权益配置参考** (来自 TierBenefitConfig):
```swift
// 来自 UserTier.swift
let defenseBonus: Double          // 防御加成 (%)
// Tier 0 (Free): 0% 
// Tier 1 (Support): 0%
// Tier 2 (Lordship): 0%
// Tier 3 (Empire): 15%
// Tier 4 (VIP): 0%
```

**验证清单**:
- [ ] TerritoryManager 有 defenseBonusMultiplier 属性
- [ ] applyTerritoryBenefit() 方法实现
- [ ] resetTerritoryBenefit() 方法实现
- [ ] TierManager 调用 applyTerritoryBenefit()
- [ ] 编译无错误

---

### 2️⃣ Social & Trade 系统 (Day 8-9)

**功能范围**:
- 频道创建/管理功能
- 玩家交易系统
- 社交功能集成

**关键文件**:
- `ChannelManager.swift` - 已存在，需要功能完善
- `TradeManager.swift` - 新建或完善
- 相关 Views 和 Models

**Tier 相关权益**:
```swift
let hasWeeklyChallenge: Bool      // 每周挑战
let hasMonthlyChallenge: Bool     // 每月挑战
let hasUnlimitedQueues: Bool      // 无限队列
```

**验证清单**:
- [ ] 频道创建功能正常
- [ ] 消息发送接收功能正常
- [ ] 交易系统集成正常
- [ ] Tier 权益正确应用
- [ ] 编译无错误

---

### 3️⃣ App Store 上架准备 (Day 10)

**检查清单**:
- [ ] 所有功能已实现和测试
- [ ] 编译零错误零警告
- [ ] 性能指标符合要求
- [ ] 隐私政策已配置
- [ ] App icons/截图已准备
- [ ] Version 号已更新

---

## ⚙️ 技术准备

### Week 2 开发前的检查

**1. 代码库整理**
```bash
# 检查所有文件编译状态
xcodebuild clean -scheme EarthLord
xcodebuild build -scheme EarthLord

# 验证无错误
```

**2. 数据库检查**
- [ ] 所有必要的表已创建
- [ ] RLS 政策已配置
- [ ] 索引已优化

**3. 依赖检查**
- [ ] Supabase SDK 版本确认
- [ ] IAP 框架可用
- [ ] 所有 CocoaPods 依赖已安装

---

## 🔗 Week 1 完成标志

### 代码质量检查

**编译状态** ✅:
- 错误数: 0
- 警告数: 0
- Build Success: ✅

**文档完整** ✅:
- Day 1-2 文档: ✅
- Day 3 文档: ✅
- Day 4-5 文档: ✅
- 集成验证报告: ✅

**功能验证** ✅:
- Models 完整: ✅
- IAP 集成: ✅
- Tier 系统: ✅
- BuildingManager: ✅
- ProductionManager: ✅
- InventoryManager: ✅
- TierManager: ✅

---

## 🎓 Week 2 关键学习点

### 从 Week 1 学到的模式

**权益应用模式** (适用于所有系统):
```swift
// 1. 添加权益属性
@Published var benefitMultiplier: Double = 1.0
private var currentTierBenefit: TierBenefit?

// 2. 添加应用方法
func applyBenefit(_ benefit: TierBenefit) {
    benefitMultiplier = calculateMultiplier(from: benefit)
}

// 3. 添加重置方法
func resetBenefit() {
    benefitMultiplier = 1.0
}

// 4. 在业务逻辑中应用
let adjustedValue = originalValue / benefitMultiplier
```

**权益计算模式** (来自 UserTier):
```swift
// 当 bonus 是百分比时 (0-1):
var multiplier: Double {
    guard bonus > 0 else { return 1.0 }
    return 1.0 / (1.0 - bonus)
}

// 示例:
// bonus = 0.20 → multiplier = 1.25 (快 20%)
// bonus = 0.40 → multiplier = 1.67 (快 40%)
```

---

## 📋 Day 6 启动步骤

### 准备阶段 (Day 6 上午)

1. **代码审查**
   - [ ] Review Week 1 所有修改
   - [ ] 确认编译无问题
   - [ ] 运行基础测试

2. **规划 Territory 系统**
   - [ ] 确认 TerritoryManager 的当前状态
   - [ ] 识别需要修改的方法
   - [ ] 准备 defenseBonusMultiplier 属性

3. **准备 Defense 系统**
   - [ ] 查看 TierBenefitConfig 中的 defenseBonus 配置
   - [ ] 确定如何应用防御加成
   - [ ] 准备测试用例

### 实施阶段 (Day 6 下午 + Day 7)

1. **TerritoryManager 修改**
   ```swift
   // 模式 (参考 BuildingManager):
   @Published var defenseBonusMultiplier: Double = 1.0
   func applyTerritoryBenefit(_ benefit: TierBenefit) { ... }
   func resetTerritoryBenefit() { ... }
   ```

2. **TierManager 扩展**
   ```swift
   // 在 applyBenefitsToGameSystems() 中添加:
   TerritoryManager.shared.applyTerritoryBenefit(tierBenefit)
   
   // 在 applyDefaultBenefits() 中添加:
   TerritoryManager.shared.resetTerritoryBenefit()
   ```

3. **验证和测试**
   - [ ] 编译无错误
   - [ ] Territory 权益正确应用
   - [ ] Territory 权益正确重置
   - [ ] 日志输出正确

---

## 🎯 关键成功指标 (KPI)

### Week 2 完成标准

| 模块 | 完成标准 | 验证方式 |
|------|---------|--------|
| Territory & Defense | 所有权益应用正确 | 编译验证 + 功能测试 |
| Social & Trade | 频道和交易可用 | 功能测试 |
| App Store 就绪 | 零错误零警告 | 编译验证 |
| 总体完成度 | 100% → Phase 2 | Build Success ✅ |

---

## 📞 常见问题

**Q1: Week 1 没有完完全全完成怎么办?**
- A: 现在的 95% 完成度足以开始 Week 2
- 最后 5% 的 UI 优化和性能调优可以在 Week 2 中并行进行

**Q2: TerritoryManager 应该如何修改?**
- A: 参考 BuildingManager 的模式完全相同，只是改变属性名和数值类型

**Q3: 是否需要重写 TierManager 的其他部分?**
- A: 否，主要是扩展 applyBenefitsToGameSystems() 和 applyDefaultBenefits()

---

## 🚀 准备好了吗?

### Week 2 启动前的最终检查

```
✅ Week 1 编译: 0 错误, 0 警告
✅ Week 1 功能: 5 个系统已集成
✅ 文档准备: 完整的参考指南
✅ 代码模式: Territory 应用者可参考
✅ 测试标准: 已定义

🚀 准备就绪，启动 Week 2!
```

---

**准备就绪**: 2026-02-24 ✅  
**预计 Week 2 启动**: 2026-02-25 🚀  
**Phase 1 目标完成**: 2026-03-07 (30 天内冲到 100%)
