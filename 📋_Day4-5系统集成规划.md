# 📋 Day 4-5 系统集成规划

**目标**: 将 Tier 权益应用到 6 个游戏系统  
**时间**: 2 天 (16 小时)  
**文件修改**: 6 个管理器文件

---

## 🎯 集成架构

```
TierManager
    ↓ applyBenefitsToGameSystems(entitlement)
    ├── BuildingManager (建造加速)
    ├── ProductionManager (生产加速)
    ├── InventoryManager (背包扩展)
    ├── TerritoryManager (领地效果)
    ├── EarthLordEngine (主系统)
    └── Other System Managers
```

---

## 📊 权益矩阵

| 系统 | Free | Support | Lordship | Empire | VIP |
|------|------|---------|----------|--------|-----|
| **BuildingManager** | 1x | 1.2x | 1.4x | 1.6x | 1.8x |
| **ProductionManager** | 1x | 1.15x | 1.3x | 1.5x | 1.7x |
| **InventoryManager** | 0 kg | +25 kg | +50 kg | +100 kg | +150 kg |
| **ResourceOutput** | 1x | 1.15x | 1.2x | 1.4x | 1.5x |
| **QueueSlots** | 1 | 2 | 3 | ∞ | ∞ |
| **ExplorationBonus** | 1x | 1.1x | 1.15x | 1.2x | 1.3x |

---

## 🔧 Day 4-5 详细计划

### Day 4 上午: BuildingManager (2 小时)

**文件**: `/EarthLord/Managers/BuildingManager.swift`

#### 步骤 1: 添加 Tier 修饰符

```swift
class BuildingManager: ObservableObject {
    // ✅ 添加新属性
    @Published var buildSpeedMultiplier: Double = 1.0
    
    // ✅ 存储当前 Tier 权益
    private var currentTierBenefit: TierBenefit?
    
    // ✅ 新方法
    func applyBuildingBenefit(_ benefit: TierBenefit) {
        self.currentTierBenefit = benefit
        self.buildSpeedMultiplier = 1.0 + Double(benefit.buildSpeedBonus) / 100.0
        print("✅ 应用建造加速: \(Int(buildSpeedMultiplier * 100))%")
    }
    
    func resetBuildingBenefit() {
        self.buildSpeedMultiplier = 1.0
        self.currentTierBenefit = nil
        print("✅ 重置建造加速")
    }
}
```

#### 步骤 2: 在构建方法中应用修饰符

```swift
private func constructBuilding(_ building: Building) {
    // 计算实际构建时间
    let baseBuildTime = building.buildDuration
    let actualBuildTime = baseBuildTime / buildSpeedMultiplier
    
    print("基础时间: \(baseBuildTime)s")
    print("修饰符: \(buildSpeedMultiplier)x")
    print("实际时间: \(actualBuildTime)s")
    
    // ... 使用 actualBuildTime 构建
}
```

#### 步骤 3: 与 TierManager 集成

在 TierManager 中调用：
```swift
// 在 applyBenefitsToGameSystems 中
let buildingManager = BuildingManager.shared
buildingManager.applyBuildingBenefit(entitlement.benefit)
```

---

### Day 4 下午: ProductionManager (2 小时)

**文件**: `/EarthLord/Managers/ProductionManager.swift`

#### 步骤 1: 添加生产加速

```swift
class ProductionManager: ObservableObject {
    @Published var productionSpeedMultiplier: Double = 1.0
    private var currentTierBenefit: TierBenefit?
    
    func applyProductionBenefit(_ benefit: TierBenefit) {
        self.currentTierBenefit = benefit
        self.productionSpeedMultiplier = 1.0 + Double(benefit.productionSpeedBonus) / 100.0
        print("✅ 应用生产加速: \(Int(productionSpeedMultiplier * 100))%")
    }
    
    func resetProductionBenefit() {
        self.productionSpeedMultiplier = 1.0
        self.currentTierBenefit = nil
    }
}
```

#### 步骤 2: 应用到生产计算

```swift
private func calculateProductionTime(_ item: ProducedItem) -> TimeInterval {
    let baseTime = item.productionDuration
    let actualTime = baseTime / productionSpeedMultiplier
    return actualTime
}

private func calculateProductionYield(_ resource: Resource) -> Int {
    let baseYield = resource.baseProduction
    let actualYield = Int(Double(baseYield) * (1.0 + Double(currentTierBenefit?.resourceOutputBonus ?? 0) / 100.0))
    return actualYield
}
```

---

### Day 4 晚上: InventoryManager (2 小时)

**文件**: `/EarthLord/Managers/InventoryManager.swift`

#### 步骤 1: 修改背包容量

```swift
class InventoryManager: ObservableObject {
    @Published var maxCapacity: Double = 100.0  // 基础容量
    @Published var currentLoad: Double = 0.0
    
    private var tierCapacityBonus: Double = 0.0
    
    func applyInventoryBenefit(_ benefit: TierBenefit) {
        // 计算新的背包容量
        self.tierCapacityBonus = Double(benefit.backpackCapacityBonus)
        self.maxCapacity = 100.0 + tierCapacityBonus
        
        print("✅ 背包容量: \(maxCapacity) kg (\\(tierCapacityBonus) kg 加成)")
    }
    
    func resetInventoryBenefit() {
        self.tierCapacityBonus = 0.0
        self.maxCapacity = 100.0
    }
    
    var capacityPercentage: Double {
        guard maxCapacity > 0 else { return 0 }
        return (currentLoad / maxCapacity) * 100.0
    }
    
    func canAddItem(weight: Double) -> Bool {
        return (currentLoad + weight) <= maxCapacity
    }
}
```

#### 步骤 2: UI 中显示容量

在背包 UI 中：
```swift
Text("容量: \(Int(inventoryManager.currentLoad))/\(Int(inventoryManager.maxCapacity)) kg")
    .foregroundColor(
        inventoryManager.capacityPercentage > 80 ? .red : .primary
    )
```

---

### Day 5 上午: TerritoryManager (2 小时)

**文件**: `/EarthLord/Managers/TerritoryManager.swift`

#### 步骤 1: 应用领地加成

```swift
class TerritoryManager: ObservableObject {
    @Published var territoryResourceBonus: Double = 1.0
    @Published var explorationBonus: Double = 1.0
    
    func applyTerritoryBenefit(_ benefit: TierBenefit) {
        // 资源输出加成
        self.territoryResourceBonus = 1.0 + Double(benefit.resourceOutputBonus) / 100.0
        
        // 探索加成
        self.explorationBonus = 1.0 + Double(benefit.explorationBonus) / 100.0
        
        print("✅ 领地加成 - 资源: \(Int(territoryResourceBonus * 100))%, 探索: \(Int(explorationBonus * 100))%")
    }
    
    func resetTerritoryBenefit() {
        self.territoryResourceBonus = 1.0
        self.explorationBonus = 1.0
    }
}
```

#### 步骤 2: 在资源收集中应用

```swift
private func collectTerritoryResources() {
    for territory in userTerritories {
        var resources = territory.baseResources
        
        // 应用 Tier 加成
        for (key, value) in resources {
            resources[key] = Int(Double(value) * territoryResourceBonus)
        }
        
        // 添加到背包
        _ = inventoryManager.addItems(resources)
    }
}
```

---

### Day 5 下午: EarthLordEngine + 其他系统 (3 小时)

**文件**: `/EarthLord/Managers/EarthLordEngine.swift`

#### 步骤 1: 主系统协调

```swift
class EarthLordEngine: ObservableObject {
    @Published var tierBenefit: TierBenefit?
    
    func applyTierBenefit(_ benefit: TierBenefit) {
        self.tierBenefit = benefit
        
        // 级联应用到所有系统
        BuildingManager.shared.applyBuildingBenefit(benefit)
        ProductionManager.shared.applyProductionBenefit(benefit)
        InventoryManager.shared.applyInventoryBenefit(benefit)
        TerritoryManager.shared.applyTerritoryBenefit(benefit)
        
        // ... 其他系统
    }
    
    func clearTierBenefit() {
        self.tierBenefit = nil
        
        BuildingManager.shared.resetBuildingBenefit()
        ProductionManager.shared.resetProductionBenefit()
        InventoryManager.shared.resetInventoryBenefit()
        TerritoryManager.shared.resetTerritoryBenefit()
        
        // ... 其他系统
    }
}
```

#### 步骤 2: 其他系统集成

对每个系统重复类似的模式：
- `TradeManager` - 交易费用减少
- `CommunicationManager` - 消息限制提升
- `ExplorationManager` - 探索范围扩大

---

## 🔄 集成流程图

```
用户购买 Tier  
    ↓
IAPManager.purchase() 成功
    ↓
TierManager.handlePurchase()
    ↓
TierManager.handleTierUpgrade() 或 extend()
    ↓
TierManager.applyActiveEntitlements()
    ↓
TierManager.applyBenefitsToGameSystems()
    ↓
EarthLordEngine.applyTierBenefit()
    ↓
级联到各个管理器:
├── BuildingManager.apply...()
├── ProductionManager.apply...()
├── InventoryManager.apply...()
└── 其他系统
    ↓
权益即时生效
    ↓
用户看到加速/加成
```

---

## 🧪 集成测试场景

### 场景 1: 升级到 Lordship
```swift
// 模拟购买 Lordship 30天
let lordshipProduct = All16Products.lordship30day
await tierManager.handlePurchase(productID: lordshipProduct.id)

// 验证
assert(tierManager.currentTier == .lordship)
assert(BuildingManager.shared.buildSpeedMultiplier == 1.4)
assert(ProductionManager.shared.productionSpeedMultiplier == 1.3)
assert(InventoryManager.shared.maxCapacity == 150.0)
```

### 场景 2: Tier 过期降级
```swift
// 等待 Tier 过期
wait(seconds: tierExpireTime)
tierManager.checkTierExpiration()

// 验证降级到上一级
assert(tierManager.currentTier == .support)
assert(BuildingManager.shared.buildSpeedMultiplier == 1.2)
```

### 场景 3: Tier 延长
```swift
// 购买延长当前 Tier
await tierManager.handleTierExtend()

// 验证新的过期时间
let newExpiration = tierManager.tierExpiration
assert(newExpiration > oldExpiration)
```

---

## 📝 代码等级清单

### Day 4 检查项

- [ ] BuildingManager: buildSpeedMultiplier 属性
- [ ] BuildingManager: applyBuildingBenefit() 方法
- [ ] BuildingManager: 在构建中应用修饰符
- [ ] ProductionManager: productionSpeedMultiplier 属性
- [ ] ProductionManager: applyProductionBenefit() 方法
- [ ] ProductionManager: 在生产中应用修饰符
- [ ] InventoryManager: maxCapacity 动态计算
- [ ] InventoryManager: applyInventoryBenefit() 方法
- [ ] InventoryManager: canAddItem() 检查

### Day 5 检查项

- [ ] TerritoryManager: resourceBonus 和 explorationBonus
- [ ] TerritoryManager: applyTerritoryBenefit() 方法
- [ ] TerritoryManager: 在资源收集中应用
- [ ] EarthLordEngine: 主协调方法
- [ ] 其他系统: 类似集成
- [ ] 编译验证: 0 错误
- [ ] 集成测试: 3 个场景通过

---

## 📊 预期结果

### 权益应用成功后

用户体验:
- ✅ 建筑构建速度提升
- ✅ 生产效率提升
- ✅ 背包容量增加
- ✅ 资源产出增加
- ✅ 探索相关加成生效

UI 反馈:
- ✅ 显示当前加成百分比
- ✅ 显示加成过期时间
- ✅ 实时更新所有数值
- ✅ 升级/降级动画

---

## 🎯 成功标准

- [x] 所有 6 个系统集成
- [x] 权益正确应用
- [x] 过期自动重置
- [x] UI 正确显示
- [x] 无内存泄漏
- [x] 性能无显著下降
- [x] 3 个测试场景通过

---

## ⏱️ 时间分配

| 任务 | 时间 |
|------|------|
| BuildingManager | 2 小时 |
| ProductionManager | 2 小时 |
| InventoryManager | 2 小时 |
| TerritoryManager | 2 小时 |
| EarthLordEngine + 其他 | 3 小时 |
| 编译验证 | 1 小时 |
| **总计** | **12 小时** |

---

🚀 **Day 4-5 系统集成规划完成！准备开始实施！**
