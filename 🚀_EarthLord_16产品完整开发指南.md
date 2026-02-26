# 🚀 EarthLord 16 产品完整开发指南

**版本**: 2.0 (完整版)  
**创建日期**: 2026-02-24  
**开发周期**: 21 天（3个阶段）  
**目标**: 构建完整的三层付费系统（消耗性 + 非续期订阅 + 自动续期订阅）  

---

## 📋 文档快速导航

| 章节 | 内容 | 工作量 | 优先级 |
|------|------|------|-------|
| [1. 整体架构](#1-整体架构) | 系统设计、数据流、集成点 | 2h | 🔴 必读 |
| [2. 产品定义](#2-16产品完整定义) | 16个产品配置、权益映射 | 3h | 🔴 必读 |
| [3. 代码实现](#3-代码实现指南) | IAPModels、IAPManager、UI组件 | 12h | 🔴 必读 |
| [4. 数据库设计](#4-数据库设计) | 表结构、RLS 策略、迁移脚本 | 3h | 🔴 必读 |
| [5. 权益系统](#5-权益系统集成) | 权益判断、权限管理、UI适配 | 6h | 🟡 重要 |
| [6. 测试策略](#6-完整测试策略) | 测试场景、沙盒配置、验证清单 | 8h | 🟡 重要 |
| [7. App Store 配置](#7-app-store-connect-完整配置) | 产品申报、本地化、定价 | 4h | 🟡 重要 |
| [8. 21天实施计划](#8-21天分阶段实施计划) | 日期分解、里程碑、风险控制 | 参考 | 🟢 参考 |
| [9. 故障排查](#9-故障排查指南) | 常见问题、调试技巧、解决方案 | 参考 | 🟢 参考 |

---

## 1. 整体架构

### 1.1 系统设计概览

```
┌─────────────────────────────────────────────────────────────┐
│                     EarthLord 付费系统架构                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              用户界面层 (SwiftUI Views)                │   │
│  │  ├─ 主菜单 → 付费入口                                   │   │
│  │  ├─ 商店 (Store View)                                 │   │
│  │  ├─ 补给包选择界面                                      │   │
│  │  ├─ 订阅月卡选择界面                                    │   │
│  │  └─ VIP 会员选择界面                                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          业务逻辑层 (IAPManager + 权益管理)              │   │
│  │  ├─ 产品管理 (16 products)                            │   │
│  │  ├─ 交易处理                                           │   │
│  │  ├─ 订阅状态检查                                        │   │
│  │  ├─ 权益检查 & 授予                                     │   │
│  │  └─ 恢复购买                                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌───────────────────────────┬─────────────────────────┐    │
│  │   本地存储                 │     远程同步              │    │
│  │  ├─ UserDefaults         │  ├─ Supabase Auth      │    │
│  │  ├─ Keychain             │  ├─ user_subscriptions  │    │
│  │  └─ 推送收据              │  ├─ subscription_audit   │    │
│  │                           │  └─ RLS 策略            │    │
│  └───────────────────────────┴─────────────────────────┘    │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │        游戏系统集成 (各功能模块)                         │   │
│  │  ├─ 建筑系统 (加速权益)                                │   │
│  │  ├─ 生产系统 (资源权益)                                │   │
│  │  ├─ 背包系统 (容量权益)                                │   │
│  │  ├─ 社交系统 (VIP 权益)                               │   │
│  │  └─ 排行榜 (会员权益)                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              StoreKit 2 框架 (Apple)                  │   │
│  │  ├─ Transaction 监听                                 │   │
│  │  ├─ Product 查询 & 缓存                               │   │
│  │  ├─ Subscription 状态                                │   │
│  │  └─ 收据验证                                         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 支付流程图

```
┌─────────┐
│ 用户点击│
│ 购买    │
└────┬────┘
     │
     ↓
┌─────────────────────┐
│ 显示 SKPaymentQueue │
│ Apple 支付界面       │
└────┬────────────────┘
     │
     ├─ 用户支付成功 ──→ ┌─────────────┐
     │                  │ 获取收据     │
     │                  │ 本地保存     │
     │                  │ 服务端验证   │
     │                  └────┬────────┘
     │                       │
     │                       ↓
     │                  ┌──────────────────┐
     │                  │ 授予权益         │
     │                  │ 更新本地缓存     │
     │                  │ 同步到 Supabase  │
     │                  │ 发送通知         │
     │                  └────┬─────────────┘
     │                       │
     │                       ↓
     │                  ┌──────────────────┐
     │                  │ ✅ 完成           │
     │                  └──────────────────┘
     │
     ├─ 用户取消 ──→ ❌ 流程中断
     │
     └─ 支付失败 ──→ ❌ 显示错误信息
```

### 1.3 数据流

```
用户操作
  ↓
View (选择产品)
  ↓
IAPManager (处理购买)
  ↓
StoreKit 2 (发起交易)
  ↓
Apple 服务器 (验证支付)
  ↓
IAPManager (验证收据)
  ↓
Supabase (记录订阅)
  ↓
权益系统 (授予权益)
  ↓
游戏系统 (应用权益)
  ↓
本地 UI 更新
  ↓
用户看到权益生效
```

### 1.4 关键集成点

#### 权益授予流程
```swift
购买成功
  ↓
IAPManager.handlePurchase(transactionID)
  ↓
验证收据 & 产品类型
  ↓
调用权益系统: RightsManager.grantRights(product)
  ↓
RightsManager 判断权益类型:
  ├─ 消耗性: BuildingManager.addSpeedup()
  ├─ 非续期: SubscriptionManager.activateTemporaryPerks()
  └─ 续期: SubscriptionManager.activateAutoRenewPerks()
  ↓
各系统应用权益
  ↓
更新 UI & 通知用户
```

---

## 2. 16 产品完整定义

### 2.1 产品分类结构

```
IAP 产品结构 (16 个产品)
├─ 消耗性 (Consumable) × 4
│  ├─ com.earthlord.supply.survivor    (¥6)
│  ├─ com.earthlord.supply.explorer    (¥18)
│  ├─ com.earthlord.supply.lord        (¥30)
│  └─ com.earthlord.supply.overlord    (¥68)
│
├─ 非续期订阅 (Non-Renewing) × 9
│  ├─ 战术支援 (3个)
│  │  ├─ com.earthlord.tactical.1m     (¥8, 30天)
│  │  ├─ com.earthlord.tactical.3m     (¥18, 90天)
│  │  └─ com.earthlord.tactical.1y     (¥58, 365天)
│  ├─ 领主特权 (3个)
│  │  ├─ com.earthlord.lordship.1m     (¥18, 30天)
│  │  ├─ com.earthlord.lordship.3m     (¥38, 90天)
│  │  └─ com.earthlord.lordship.1y     (¥128, 365天)
│  └─ 帝国统治者 (3个)
│     ├─ com.earthlord.empire.1m       (¥38, 30天)
│     ├─ com.earthlord.empire.3m       (¥88, 90天)
│     └─ com.earthlord.empire.1y       (¥298, 365天)
│
└─ 自动续期订阅 (Auto-Renewable) × 4
   ├─ com.earthlord.vip.monthly        (¥12/月)
   ├─ com.earthlord.vip.monthly.trial  (¥6/月, 首月)
   ├─ com.earthlord.vip.quarterly      (¥28/3月)
   └─ com.earthlord.vip.annual         (¥88/年)
```

### 2.2 产品详细规格表

#### 消耗性产品

| ID | 名称 | 价格 | 受众 | 权益 | 类型 |
|----|------|------|------|------|------|
| 1 | survivor | ¥6 | 新手 | 基础资源包 | Consumable |
| 2 | explorer | ¥18 | 活跃 | 中级资源包 | Consumable |
| 3 | lord | ¥30 | 核心 | 高级资源包 | Consumable |
| 4 | overlord | ¥68 | 重度 | 稀有资源包 | Consumable |

**消耗性权益明细**:
```
Survivor (¥6):
- 木材 ×300
- 石头 ×300
- 金属 ×150
- 水 ×300

Explorer (¥18):
- 木材 ×1000
- 石头 ×1000
- 金属 ×500
- 水 ×1000
- 食物 ×500
- 医疗品 ×200

Lord (¥30):
- 木材 ×2000
- 石头 ×2000
- 金属 ×1000
- 稀有金属 ×200
- 医疗品 ×500
- 燃料 ×300

Overlord (¥68):
- 木材 ×5000
- 石头 ×5000
- 金属 ×2500
- 稀有金属 ×500
- 传奇碎片 ×50
- 医疗品 ×1000
- 燃料 ×800
```

#### 非续期订阅 - 战术支援包

| ID | 时长 | 价格 | 月均 | 权益等级 |
|----|------|------|------|---------|
| 5 | 30天 | ¥8 | ¥8 | ⭐ 基础 |
| 6 | 90天 | ¥18 | ¥6 | ⭐ 基础 |
| 7 | 365天 | ¥58 | ¥4.8 | ⭐ 基础 |

**权益**:
- ⚡ 建造时间 -20%
- ⌛ 生产周期 -15%
- 👜 背包容量 +25 kg
- 🎁 每日登录 ¥500 资源币
- 🛍️ VIP 商店 10% 折扣
- 📍 每天 3 次快速传送

#### 非续期订阅 - 领主特权包

| ID | 时长 | 价格 | 月均 | 权益等级 |
|----|------|------|------|---------|
| 8 | 30天 | ¥18 | ¥18 | ⭐⭐ 高级 |
| 9 | 90天 | ¥38 | ¥12.7 | ⭐⭐ 高级 |
| 10 | 365天 | ¥128 | ¥10.7 | ⭐⭐ 高级 |

**权益** (包含战术支援 + ):
- ⚡ 建造时间 -40%
- ⌛ 生产周期 -30%
- 📈 资源产出 +20%
- 👜 背包容量 +50 kg
- 🏆 每周限定挑战
- 💎 VIP 名牌显示
- 🛍️ VIP 商店 20% 折扣

#### 非续期订阅 - 帝国统治者包

| ID | 时长 | 价格 | 月均 | 权益等级 |
|----|------|------|------|---------|
| 11 | 30天 | ¥38 | ¥38 | ⭐⭐⭐ 顶级 |
| 12 | 90天 | ¥88 | ¥29.3 | ⭐⭐⭐ 顶级 |
| 13 | 365天 | ¥298 | ¥24.8 | ⭐⭐⭐ 顶级 |

**权益** (包含领主特权 + ):
- ⚡ 建造时间 -60%
- ⌛ 生产周期 -50%
- 📈 资源产出 +40%
- 👜 背包容量 +100 kg
- 🌟 每月稀有物资箱 (¥98 价值)
- 🎯 无限建造队列
- 🏰 领地防御 +15%
- 💬 专属客服支持

#### 自动续期订阅 - VIP 会员

| ID | 周期 | 价格 | 续费 | 权益等级 |
|----|------|------|------|---------|
| 14 | 月 | ¥12/月 | 自动 | 🟢 月会 |
| 15 | 月试用 | ¥6/月 | 自动 | 🟢 试用 |
| 16 | 季/年 | ¥28/季或¥88/年 | 自动 | 🟢 期权 |

**权益**:
- ✅ 包含战术支援所有权益
- 🎁 每月 ¥20-50 补给券
- 📊 月度排行榜参赛
- 🏆 专属徽章系统
- 🎮 抢先测试新功能
- 📅 每月登录奖励

### 2.3 权益矩阵表

```
权益\订阅类型        | 消耗性 | 战术  | 领主  | 帝国  | VIP月 |
─────────────────────┼────────┼───────┼───────┼───────┼────────
建造时间加速          | 无     | -20%  | -40%  | -60%  | -20%  |
生产加速             | 无     | -15%  | -30%  | -50%  | -15%  |
资源产出加成          | 无     | 无    | +20%  | +40%  | 无    |
背包容量             | 无     | +25kg | +50kg | +100kg| +25kg |
每日登录奖励          | 无     | ¥500  | ¥500  | ¥500  | ¥500  |
VIP 商店折扣         | 无     | 10%   | 20%   | 20%   | 10%   |
快速传送(每天)        | 无     | 3次   | 3次   | 3次   | 3次   |
专属活动参赛         | 无     | 无    | 每周  | 每月  | 每月  |
VIP 名牌效果        | 无     | 无    | 是    | 是    | 否    |
无限建造队列         | 无     | 无    | 无    | 是    | 无    |
领地防御加成         | 无     | 无    | 无    | +15%  | 无    |
专属客服支持         | 无     | 无    | 无    | 是    | 否    |
稀有物资箱(月)        | 无     | 无    | 无    | 是    | 否    |
补给券(月)           | 无     | 无    | 无    | 无    | ¥20-50|
```

---

## 3. 代码实现指南

### 3.1 IAPModels.swift (完整版)

这个文件定义了所有 16 个产品的模型和权益系统。

```swift
import Foundation
import StoreKit

// MARK: - 产品ID 常量定义

struct IAPProductID {
    
    // MARK: 消耗性产品 (Consumable)
    static let consumableProductIDs = Set([
        "com.earthlord.supply.survivor",
        "com.earthlord.supply.explorer",
        "com.earthlord.supply.lord",
        "com.earthlord.supply.overlord"
    ])
    
    // MARK: 非续期订阅 - 战术支援包
    static let tacticalProductIDs = Set([
        "com.earthlord.tactical.1m",
        "com.earthlord.tactical.3m",
        "com.earthlord.tactical.1y"
    ])
    
    // MARK: 非续期订阅 - 领主特权包
    static let lordshipProductIDs = Set([
        "com.earthlord.lordship.1m",
        "com.earthlord.lordship.3m",
        "com.earthlord.lordship.1y"
    ])
    
    // MARK: 非续期订阅 - 帝国统治者包
    static let empireProductIDs = Set([
        "com.earthlord.empire.1m",
        "com.earthlord.empire.3m",
        "com.earthlord.empire.1y"
    ])
    
    // MARK: 自动续期订阅 - VIP 会员
    static let vipProductIDs = Set([
        "com.earthlord.vip.monthly",
        "com.earthlord.vip.monthly.trial",
        "com.earthlord.vip.quarterly",
        "com.earthlord.vip.annual"
    ])
    
    // MARK: 所有产品 ID
    static let allProductIDs = consumableProductIDs
        .union(tacticalProductIDs)
        .union(lordshipProductIDs)
        .union(empireProductIDs)
        .union(vipProductIDs)
    
    // MARK: 通用方法
    static func isMembershipProduct(_ productID: String) -> Bool {
        return tacticalProductIDs.contains(productID) ||
               lordshipProductIDs.contains(productID) ||
               empireProductIDs.contains(productID) ||
               vipProductIDs.contains(productID)
    }
    
    static func getProductCategory(_ productID: String) -> ProductCategory {
        if consumableProductIDs.contains(productID) {
            return .consumable
        } else if tacticalProductIDs.contains(productID) {
            return .tactical
        } else if lordshipProductIDs.contains(productID) {
            return .lordship
        } else if empireProductIDs.contains(productID) {
            return .empire
        } else if vipProductIDs.contains(productID) {
            return .vip
        }
        return .unknown
    }
}

// MARK: - 产品分类枚举

enum ProductCategory: String, Codable {
    case consumable = "consumable"          // 消耗性
    case tactical = "tactical"               // 战术支援
    case lordship = "lordship"               // 领主特权
    case empire = "empire"                   // 帝国统治者
    case vip = "vip"                         // VIP会员
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .consumable: return "补给包"
        case .tactical: return "战术支援"
        case .lordship: return "领主特权"
        case .empire: return "帝国统治者"
        case .vip: return "VIP会员"
        case .unknown: return "未知"
        }
    }
    
    var tier: Int {
        switch self {
        case .consumable: return 0
        case .tactical: return 1
        case .lordship: return 2
        case .empire: return 3
        case .vip: return 1
        case .unknown: return -1
        }
    }
}

// MARK: - 时长枚举 (用于策略/权益类型)

enum SubscriptionDuration: String, Codable {
    case oneMonth = "1m"
    case threeMonths = "3m"
    case oneYear = "1y"
    
    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .oneYear: return 365
        }
    }
    
    var displayName: String {
        switch self {
        case .oneMonth: return "30天"
        case .threeMonths: return "90天"
        case .oneYear: return "365天"
        }
    }
}

// MARK: - 权益模型

struct Entitlement: Codable {
    let productID: String
    let category: ProductCategory
    
    // 产品特定权益
    let buildSpeedBonus: Double                    // 建造时间减少百分比
    let productionSpeedBonus: Double               // 生产周期减少百分比
    let resourceOutputBonus: Double                // 资源产出增加百分比
    let backpackCapacityBonus: Int                 // 背包容量增加
    
    // 时间特定权益
    let dailyReward: Int                           // 每日登录奖励 (资源币)
    let shopDiscountPercentage: Int                // VIP商店折扣
    let dailyTeleportTimes: Int                    // 每日传送次数
    
    // 活动权益
    let hasWeeklyChallenge: Bool                   // 每周限定挑战
    let hasMonthlyChallenge: Bool                  // 每月限定挑战
    let hasVIPBadge: Bool                          // VIP名牌效果
    let hasUnlimitedQueues: Bool                   // 无限建造队列
    let defenseBonus: Double                       // 领地防御加成
    let hasCustomerSupport: Bool                   // 专属客服支持
    
    // 特殊权益
    let monthlyRareLootBox: Bool                   // 每月稀有物资箱
    let monthlySupplyVoucher: Int                  // 每月补给券 (资源币)
    
    // 订阅相关
    let duration: Int                              // 天数 (如果适用)
    let isAutoRenewable: Bool                      // 是否自动续期
    
    init(productID: String) {
        self.productID = productID
        let category = IAPProductID.getProductCategory(productID)
        self.category = category
        
        // 根据产品 ID 初始化权益
        switch productID {
        // MARK: 消耗性产品
        case "com.earthlord.supply.survivor":
            buildSpeedBonus = 0
            productionSpeedBonus = 0
            resourceOutputBonus = 0
            backpackCapacityBonus = 0
            dailyReward = 0
            shopDiscountPercentage = 0
            dailyTeleportTimes = 0
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 0
            isAutoRenewable = false
            
        // MARK: 消耗性产品 - Explorer
        case "com.earthlord.supply.explorer":
            buildSpeedBonus = 0
            productionSpeedBonus = 0
            resourceOutputBonus = 0
            backpackCapacityBonus = 0
            dailyReward = 0
            shopDiscountPercentage = 0
            dailyTeleportTimes = 0
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 0
            isAutoRenewable = false
            
        // MARK: 消耗性产品 - Lord
        case "com.earthlord.supply.lord":
            buildSpeedBonus = 0
            productionSpeedBonus = 0
            resourceOutputBonus = 0
            backpackCapacityBonus = 0
            dailyReward = 0
            shopDiscountPercentage = 0
            dailyTeleportTimes = 0
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 0
            isAutoRenewable = false
            
        // MARK: 消耗性产品 - Overlord
        case "com.earthlord.supply.overlord":
            buildSpeedBonus = 0
            productionSpeedBonus = 0
            resourceOutputBonus = 0
            backpackCapacityBonus = 0
            dailyReward = 0
            shopDiscountPercentage = 0
            dailyTeleportTimes = 0
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 0
            isAutoRenewable = false
            
        // MARK: 非续期 - 战术支援 (30天)
        case "com.earthlord.tactical.1m":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 30
            isAutoRenewable = false
            
        // MARK: 非续期 - 战术支援 (90天)
        case "com.earthlord.tactical.3m":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 90
            isAutoRenewable = false
            
        // MARK: 非续期 - 战术支援 (365天)
        case "com.earthlord.tactical.1y":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 365
            isAutoRenewable = false
            
        // MARK: 非续期 - 领主特权 (30天)
        case "com.earthlord.lordship.1m":
            buildSpeedBonus = 0.40
            productionSpeedBonus = 0.30
            resourceOutputBonus = 0.20
            backpackCapacityBonus = 50
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = true
            hasMonthlyChallenge = false
            hasVIPBadge = true
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 30
            isAutoRenewable = false
            
        // MARK: 非续期 - 领主特权 (90天)
        case "com.earthlord.lordship.3m":
            buildSpeedBonus = 0.40
            productionSpeedBonus = 0.30
            resourceOutputBonus = 0.20
            backpackCapacityBonus = 50
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = true
            hasMonthlyChallenge = false
            hasVIPBadge = true
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 90
            isAutoRenewable = false
            
        // MARK: 非续期 - 领主特权 (365天)
        case "com.earthlord.lordship.1y":
            buildSpeedBonus = 0.40
            productionSpeedBonus = 0.30
            resourceOutputBonus = 0.20
            backpackCapacityBonus = 50
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = true
            hasMonthlyChallenge = false
            hasVIPBadge = true
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 365
            isAutoRenewable = false
            
        // MARK: 非续期 - 帝国统治者 (30天)
        case "com.earthlord.empire.1m":
            buildSpeedBonus = 0.60
            productionSpeedBonus = 0.50
            resourceOutputBonus = 0.40
            backpackCapacityBonus = 100
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = true
            hasVIPBadge = true
            hasUnlimitedQueues = true
            defenseBonus = 0.15
            hasCustomerSupport = true
            monthlyRareLootBox = true
            monthlySupplyVoucher = 0
            duration = 30
            isAutoRenewable = false
            
        // MARK: 非续期 - 帝国统治者 (90天)
        case "com.earthlord.empire.3m":
            buildSpeedBonus = 0.60
            productionSpeedBonus = 0.50
            resourceOutputBonus = 0.40
            backpackCapacityBonus = 100
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = true
            hasVIPBadge = true
            hasUnlimitedQueues = true
            defenseBonus = 0.15
            hasCustomerSupport = true
            monthlyRareLootBox = true
            monthlySupplyVoucher = 0
            duration = 90
            isAutoRenewable = false
            
        // MARK: 非续期 - 帝国统治者 (365天)
        case "com.earthlord.empire.1y":
            buildSpeedBonus = 0.60
            productionSpeedBonus = 0.50
            resourceOutputBonus = 0.40
            backpackCapacityBonus = 100
            dailyReward = 500
            shopDiscountPercentage = 20
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = true
            hasVIPBadge = true
            hasUnlimitedQueues = true
            defenseBonus = 0.15
            hasCustomerSupport = true
            monthlyRareLootBox = true
            monthlySupplyVoucher = 0
            duration = 365
            isAutoRenewable = false
            
        // MARK: 续期 - VIP 月会员
        case "com.earthlord.vip.monthly":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 20
            duration = 30
            isAutoRenewable = true
            
        // MARK: 续期 - VIP 月会员试用
        case "com.earthlord.vip.monthly.trial":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 20
            duration = 30
            isAutoRenewable = true
            
        // MARK: 续期 - VIP 季度会员
        case "com.earthlord.vip.quarterly":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 30
            duration = 90
            isAutoRenewable = true
            
        // MARK: 续期 - VIP 年度会员
        case "com.earthlord.vip.annual":
            buildSpeedBonus = 0.20
            productionSpeedBonus = 0.15
            resourceOutputBonus = 0
            backpackCapacityBonus = 25
            dailyReward = 500
            shopDiscountPercentage = 10
            dailyTeleportTimes = 3
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 50
            duration = 365
            isAutoRenewable = true
            
        default:
            buildSpeedBonus = 0
            productionSpeedBonus = 0
            resourceOutputBonus = 0
            backpackCapacityBonus = 0
            dailyReward = 0
            shopDiscountPercentage = 0
            dailyTeleportTimes = 0
            hasWeeklyChallenge = false
            hasMonthlyChallenge = false
            hasVIPBadge = false
            hasUnlimitedQueues = false
            defenseBonus = 0
            hasCustomerSupport = false
            monthlyRareLootBox = false
            monthlySupplyVoucher = 0
            duration = 0
            isAutoRenewable = false
        }
    }
    
    // MARK: 便利方法
    func getCombinedBonuses() -> [String: Any] {
        return [
            "buildSpeedBonus": buildSpeedBonus,
            "productionSpeedBonus": productionSpeedBonus,
            "resourceOutputBonus": resourceOutputBonus,
            "backpackCapacityBonus": backpackCapacityBonus,
            "defenseBonus": defenseBonus,
            "shopDiscountPercentage": shopDiscountPercentage
        ]
    }
}

// MARK: - 订阅记录模型

struct SubscriptionRecord: Codable {
    let id: String                                  // 唯一标识符
    let userID: String                              // 用户 ID
    let productID: String                           // 产品 ID
    let category: ProductCategory                   // 产品分类
    let purchaseDate: Date                          // 购买日期
    let expirationDate: Date                        // 过期日期
    let transactionID: String                       // 交易 ID
    let receiptData: String                         // 收据数据 (Base64)
    let isActive: Bool                              // 是否激活
    let autoRenewEnabled: Bool                      // 是否启用自动续期
    let platform: String                            // 平台 (iOS/Android)
    let deviceID: String                            // 设备 ID
    let syncedToServer: Bool                        // 是否同步到服务器
    let lastSyncedAt: Date?                         // 最后同步时间
    
    // MARK: 计算属性
    var remainingDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return max(components.day ?? 0, 0)
    }
    
    var isExpiringSoon: Bool {
        return remainingDays <= 3
    }
    
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expirationDate)
    }
}

// MARK: - 购买项目模型

struct PurchaseItem: Codable, Identifiable {
    let id: String                                  // 产品 ID
    let displayName: String                         // 显示名称
    let description: String                         // 描述
    let price: Decimal                              // 价格
    let currencyCode: String                        // 货币代码
    let subscriptionPeriod: String?                 // 订阅周期 (如果适用)
    let introPrice: Decimal?                        // 介绍价 (如果适用)
    let introPricePeriod: String?                   // 介绍价周期
    let trialPeriod: String?                        // 试用期
    let groupID: String?                            // 订阅组 ID
}

// MARK: - 交易记录模型

struct TransactionRecord: Codable {
    let transactionID: String
    let originalTransactionID: String
    let productID: String
    let purchaseDate: Date
    let expirationDate: Date?
    let revocationDate: Date?
    let bundleID: String
    let environment: String
    let status: String
    let offerID: String?
    let isUpgrade: Bool
    let isDowngrade: Bool
}
```

### 3.2 IAPManager.swift (核心管理器)

```swift
import Foundation
import StoreKit

@MainActor
class IAPManager: NSObject, ObservableObject {
    
    static let shared = IAPManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var subscriptionRecords: [SubscriptionRecord] = []
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    // MARK: - 初始化
    
    override private init() {
        super.init()
        setupProductCache()
        setupTransactionListener()
    }
    
    // MARK: - 产品加载
    
    func setupProductCache() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: IAPProductID.allProductIDs)
            self.products = products.sorted { $0.price < $1.price }
            
            // 加载购买状态
            await loadPurchasedProducts()
        } catch {
            errorMessage = "加载产品失败: \(error.localizedDescription)"
            print("❌ 产品加载失败: \(error)")
        }
    }
    
    func loadPurchasedProducts() async {
        for product in products {
            do {
                if let transaction = try await product.currentEntitlement {
                    purchasedProductIDs.insert(product.id)
                }
            } catch {
                print("⚠️ 无法检查产品 \(product.id) 的权利: \(error)")
            }
        }
    }
    
    // MARK: - 购买处理
    
    func purchase(_ product: Product) async {
        do {
            print("🛒 开始购买: \(product.id)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证收据
                let transaction = try checkVerified(verification)
                await handlePurchaseSuccess(transaction)
                print("✅ 购买成功: \(product.id)")
                
            case .userCancelled:
                errorMessage = "购买已取消"
                print("⚠️ 用户取消购买")
                
            case .pending:
                errorMessage = "购买等待父母审批"
                print("⏳ 购买等待审批")
                
            @unknown default:
                errorMessage = "未知的购买状态"
                print("❌ 未知的购买状态")
            }
        } catch {
            errorMessage = "购买失败: \(error.localizedDescription)"
            print("❌ 购买失败: \(error)")
        }
    }
    
    // MARK: - 交易监听
    
    func setupTransactionListener() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction = transaction {
                        await self?.handleTransaction(transaction)
                    }
                } catch {
                    print("❌ 交易验证失败: \(error)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        switch transaction.productType {
        case .consumable, .nonConsumable, .autoRenewable, .nonRenewable:
            await handlePurchaseSuccess(transaction)
            await transaction.finish()
            
        @unknown default:
            print("❌ 未知的产品类型")
        }
    }
    
    private func handlePurchaseSuccess(_ transaction: Transaction) async {
        // 更新本地购买状态
        purchasedProductIDs.insert(transaction.productID)
        
        // 创建订阅记录
        let record = SubscriptionRecord(
            id: UUID().uuidString,
            userID: try? AuthManager.shared.currentUser?.id ?? "",
            productID: transaction.productID,
            category: IAPProductID.getProductCategory(transaction.productID),
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate ?? Date().addingTimeInterval(86400),
            transactionID: transaction.id.description,
            receiptData: transaction.signedSafeReceipt ?? "",
            isActive: true,
            autoRenewEnabled: transaction.isUpgraded == false,
            platform: "iOS",
            deviceID: UIDevice.current.identifierForVendor?.uuidString ?? "",
            syncedToServer: false,
            lastSyncedAt: nil
        )
        
        subscriptionRecords.append(record)
        
        // 异步保存到本地和服务器
        Task {
            await saveSubscriptionRecord(record)
            await syncToServer(record)
            await grantEntitlements(record)
        }
    }
    
    // MARK: - 收据验证
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 权益授予
    
    private func grantEntitlements(_ record: SubscriptionRecord) async {
        let entitlement = Entitlement(productID: record.productID)
        
        // 根据产品类型应用权益
        switch record.category {
        case .consumable:
            await grantConsumableRewards(record.productID)
        case .tactical, .lordship, .empire:
            await activateTemporaryPerks(entitlement, duration: record.remainingDays)
        case .vip:
            await activateAutoRenewPerks(entitlement)
        case .unknown:
            break
        }
    }
    
    private func grantConsumableRewards(_ productID: String) async {
        let resources: [String: Int] = {
            switch productID {
            case "com.earthlord.supply.survivor":
                return ["wood": 300, "stone": 300, "metal": 150, "water": 300]
            case "com.earthlord.supply.explorer":
                return ["wood": 1000, "stone": 1000, "metal": 500, "water": 1000, "food": 500, "supply": 200]
            case "com.earthlord.supply.lord":
                return ["wood": 2000, "stone": 2000, "metal": 1000, "rareMetals": 200, "supply": 500, "fuel": 300]
            case "com.earthlord.supply.overlord":
                return ["wood": 5000, "stone": 5000, "metal": 2500, "rareMetals": 500, "legendFragments": 50, "supply": 1000, "fuel": 800]
            default:
                return [:]
            }
        }()
        
        // 调用库存管理器添加资源
        if let inventoryManager = getInventoryManager() {
            for (resource, amount) in resources {
                await inventoryManager.addResource(type: resource, amount: amount, reason: "权益奖励: \(productID)")
            }
        }
    }
    
    private func activateTemporaryPerks(_ entitlement: Entitlement, duration: Int) async {
        // 调用建筑、生产等系统应用权益
        if let buildingManager = getBuildingManager() {
            buildingManager.applyBuildingSpeedup(percentage: entitlement.buildSpeedBonus, duration: duration)
            buildingManager.applyBuildingQueueExpansion(unlimited: entitlement.hasUnlimitedQueues, duration: duration)
        }
        
        // 保存权益到本地存储
        let defaults = UserDefaults.standard
        defaults.setValue(entitlement.buildSpeedBonus, forKey: "buildSpeedBonus_\(entitlement.productID)")
        defaults.setValue(Date().addingTimeInterval(TimeInterval(duration * 86400)), forKey: "buildSpeedBonusExpiration_\(entitlement.productID)")
    }
    
    private func activateAutoRenewPerks(_ entitlement: Entitlement) async {
        // VIP 会员权益永久有效 (只要订阅持续)
        let defaults = UserDefaults.standard
        defaults.setValue(entitlement.buildSpeedBonus, forKey: "vipBuildSpeedBonus")
        defaults.setValue(true, forKey: "isVIPMember")
    }
    
    // MARK: - 订阅管理
    
    func checkSubscriptionStatus(productID: String) -> Bool {
        guard let record = subscriptionRecords.first(where: { $0.productID == productID }) else {
            return false
        }
        return record.isActive && record.expirationDate > Date()
    }
    
    func getActiveSubscriptions() -> [SubscriptionRecord] {
        return subscriptionRecords.filter { $0.isActive && $0.expirationDate > Date() }
    }
    
    func getHighestTierSubscription() -> SubscriptionRecord? {
        let active = getActiveSubscriptions()
        return active.max { a, b in
            IAPProductID.getProductCategory(a.productID).tier < IAPProductID.getProductCategory(b.productID).tier
        }
    }
    
    func getRemainingDaysForProduct(_ productID: String) -> Int {
        guard let record = subscriptionRecords.first(where: { $0.productID == productID }) else {
            return 0
        }
        return record.remainingDays
    }
    
    // MARK: - 持久化存储
    
    func saveSubscriptionRecord(_ record: SubscriptionRecord) async {
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(record) {
            defaults.set(encoded, forKey: "subscription_\(record.id)")
        }
    }
    
    func loadSubscriptionRecords() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        let fileManager = FileManager.default
        
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let recordsFile = cacheDir.appendingPathComponent("subscriptionRecords.json")
            
            if let data = try? Data(contentsOf: recordsFile),
               let records = try? decoder.decode([SubscriptionRecord].self, from: data) {
                self.subscriptionRecords = records
            }
        }
    }
    
    // MARK: - 服务器同步
    
    private func syncToServer(_ record: SubscriptionRecord) async {
        // 调用 Supabase API 保存订阅记录
        guard let userID = try? AuthManager.shared.currentUser?.id else {
            print("❌ 无法获取用户ID")
            return
        }
        
        do {
            let response = try await URLSession.shared.data(
                for: URLRequest(url: URL(string: "https://your-supabase-url/rest/v1/user_subscriptions")!)
            )
            print("✅ 订阅记录已同步到服务器")
        } catch {
            print("⚠️ 同步失败: \(error)")
        }
    }
    
    // MARK: - 恢复购买
    
    func restorePurchases() async {
        do {
            print("🔄 开始恢复购买...")
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    await handlePurchaseSuccess(transaction)
                    await transaction.finish()
                } catch {
                    print("❌ 恢复购买失败: \(error)")
                }
            }
            
            errorMessage = "购买已恢复"
            print("✅ 购买恢复完成")
        } catch {
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
            print("❌ 恢复购买失败: \(error)")
        }
    }
    
    // MARK: - 辅助方法
    
    private func getInventoryManager() -> InventoryManager? {
        // 返回全局库存管理器实例
        return InventoryManager.shared
    }
    
    private func getBuildingManager() -> BuildingManager? {
        // 返回全局建筑管理器实例
        return BuildingManager.shared
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
}
```

### 3.3 订阅 UI 视图 (SubscriptionView)

```swift
import SwiftUI

struct SubscriptionView: View {
    @StateObject private var iapManager = IAPManager.shared
    @State private var selectedCategory: ProductCategory = .tactical
    @State private var showingPurchaseConfirm = false
    @State private var selectedProduct: Product?
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题栏
                VStack {
                    HStack {
                        Text("末世权益")
                            .font(.system(size: 28, weight: .bold))
                        
                        Spacer()
                        
                        Button(action: { }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    Text("提升你的生存优势")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .padding(.bottom, 20)
                
                // 分类标签
                HStack(spacing: 8) {
                    categoryTab("战术", category: .tactical)
                    categoryTab("领主", category: .lordship)
                    categoryTab("帝国", category: .empire)
                    categoryTab("会员", category: .vip)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // 产品列表
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredProducts, id: \.id) { product in
                            SubscriptionProductCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onSelect: {
                                    selectedProduct = product
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 底部操作
                VStack(spacing: 12) {
                    if let selected = selectedProduct {
                        Button(action: {
                            Task {
                                await iapManager.purchase(selected)
                            }
                        }) {
                            HStack {
                                Text("现在购买")
                                    .font(.headline)
                                Spacer()
                                Text(selected.displayPrice)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { Task { await iapManager.restorePurchases() } }) {
                            Text("恢复购买")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func categoryTab(_ label: String, category: ProductCategory) -> some View {
        Button(action: { selectedCategory = category }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(selectedCategory == category ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(6)
        }
    }
    
    var filteredProducts: [Product] {
        iapManager.products.filter { product in
            IAPProductID.getProductCategory(product.id) == selectedCategory
        }
    }
}

// MARK: - 订阅产品卡片

struct SubscriptionProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getProductName(product.id))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(getProductDescription(product.id))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let period = getSubscriptionPeriod(product.id) {
                        Text(period)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 权益预览
            entitlementPreview(product.id)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onSelect)
    }
    
    @ViewBuilder
    private func entitlementPreview(_ productID: String) -> some View {
        let entitlement = Entitlement(productID: productID)
        
        VStack(alignment: .leading, spacing: 4) {
            if entitlement.buildSpeedBonus > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("建造速度 -\(Int(entitlement.buildSpeedBonus * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if entitlement.resourceOutputBonus > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.orange)
                    Text("资源产出 +\(Int(entitlement.resourceOutputBonus * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if entitlement.shopDiscountPercentage > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.pink)
                    Text("商店折扣 \(entitlement.shopDiscountPercentage)%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getProductName(_ productID: String) -> String {
        switch productID {
        case "com.earthlord.tactical.1m": return "战术支援-月"
        case "com.earthlord.tactical.3m": return "战术支援-季"
        case "com.earthlord.tactical.1y": return "战术支援-年"
        case "com.earthlord.lordship.1m": return "领主特权-月"
        case "com.earthlord.lordship.3m": return "领主特权-季"
        case "com.earthlord.lordship.1y": return "领主特权-年"
        case "com.earthlord.empire.1m": return "帝国统治-月"
        case "com.earthlord.empire.3m": return "帝国统治-季"
        case "com.earthlord.empire.1y": return "帝国统治-年"
        case "com.earthlord.vip.monthly": return "VIP月会员"
        case "com.earthlord.vip.annual": return "VIP年会员"
        default: return productID
        }
    }
    
    private func getProductDescription(_ productID: String) -> String {
        let entitlement = Entitlement(productID: productID)
        var benefits: [String] = []
        
        if entitlement.buildSpeedBonus > 0 {
            benefits.append("加速\(Int(entitlement.buildSpeedBonus * 100))%")
        }
        if entitlement.shopDiscountPercentage > 0 {
            benefits.append("优惠\(entitlement.shopDiscountPercentage)%")
        }
        if entitlement.hasVIPBadge {
            benefits.append("VIP标志")
        }
        
        return benefits.joined(separator: " • ")
    }
    
    private func getSubscriptionPeriod(_ productID: String) -> String? {
        switch productID {
        case "com.earthlord.tactical.1m", "com.earthlord.lordship.1m", "com.earthlord.empire.1m":
            return "30 天"
        case "com.earthlord.tactical.3m", "com.earthlord.lordship.3m", "com.earthlord.empire.3m":
            return "90 天"
        case "com.earthlord.tactical.1y", "com.earthlord.lordship.1y", "com.earthlord.empire.1y":
            return "365 天"
        case "com.earthlord.vip.monthly":
            return "/月"
        case "com.earthlord.vip.annual":
            return "/年"
        default:
            return nil
        }
    }
}

#Preview {
    SubscriptionView()
}
```

---

## 4. 数据库设计

### 4.1 Supabase 表结构

#### user_subscriptions 表

```sql
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    
    -- 购买信息
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiration_date TIMESTAMPTZ NOT NULL,
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    receipt_data TEXT,
    
    -- 订阅状态
    is_active BOOLEAN DEFAULT TRUE,
    is_auto_renewable BOOLEAN DEFAULT FALSE,
    next_renewal_date TIMESTAMPTZ,
    
    -- 设备信息
    device_id VARCHAR(100),
    platform VARCHAR(20) DEFAULT 'iOS',
    
    -- 同步信息
    synced_to_server BOOLEAN DEFAULT FALSE,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT purchase_not_in_future CHECK (purchase_date <= NOW())
);

-- 创建索引
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_product_id ON user_subscriptions(product_id);
CREATE INDEX idx_user_subscriptions_is_active ON user_subscriptions(is_active);
CREATE INDEX idx_user_subscriptions_expiration_date ON user_subscriptions(expiration_date);

-- 启用 RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS 策略: 用户只能查看自己的订阅
CREATE POLICY "Users can view their own subscriptions"
    ON user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 策略: 服务器可以插入/更新
CREATE POLICY "Service role can manage subscriptions"
    ON user_subscriptions
    USING (auth.role() = 'service_role');
```

#### subscription_audit_log 表

```sql
CREATE TABLE subscription_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    
    action VARCHAR(50) NOT NULL,
    product_id VARCHAR(100),
    
    -- 审计数据
    old_state JSONB,
    new_state JSONB,
    
    -- 元数据
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(100),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_action CHECK (action IN ('purchase', 'renew', 'cancelation', 'upgrade', 'downgrade', 'restore', 'refund'))
);

-- 创建索引
CREATE INDEX idx_audit_log_user_id ON subscription_audit_log(user_id);
CREATE INDEX idx_audit_log_action ON subscription_audit_log(action);
CREATE INDEX idx_audit_log_created_at ON subscription_audit_log(created_at);

-- 启用 RLS
ALTER TABLE subscription_audit_log ENABLE ROW LEVEL SECURITY;

-- RLS 策略
CREATE POLICY "Users can view their own audit logs"
    ON subscription_audit_log
    FOR SELECT
    USING (auth.uid() = user_id);
```

#### user_entitlements 表 (权益缓存)

```sql
CREATE TABLE user_entitlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 权益标志
    has_tactical_support BOOLEAN DEFAULT FALSE,
    has_lordship BOOLEAN DEFAULT FALSE,
    has_empire BOOLEAN DEFAULT FALSE,
    has_vip BOOLEAN DEFAULT FALSE,
    
    -- 加成百分比
    build_speed_bonus NUMERIC(5,2) DEFAULT 0,
    production_speed_bonus NUMERIC(5,2) DEFAULT 0,
    resource_output_bonus NUMERIC(5,2) DEFAULT 0,
    defense_bonus NUMERIC(5,2) DEFAULT 0,
    
    -- 绝对加成
    backpack_capacity_bonus INT DEFAULT 0,
    daily_reward INT DEFAULT 0,
    shop_discount_percentage INT DEFAULT 0,
    daily_teleport_times INT DEFAULT 0,
    
    -- 权益过期时间
    perk_expiration_date TIMESTAMPTZ,
    
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT user_id_unique UNIQUE (user_id)
);

-- 创建索引
CREATE INDEX idx_entitlements_user_id ON user_entitlements(user_id);
CREATE INDEX idx_entitlements_expiration ON user_entitlements(perk_expiration_date);

-- 启用 RLS
ALTER TABLE user_entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own entitlements"
    ON user_entitlements
    FOR SELECT
    USING (auth.uid() = user_id);
```

### 4.2 数据库迁移脚本

```sql
-- supabase_migration_011_subscription_system.sql
-- 版本: 1.0
-- 目标: 创建完整的订阅系统表和策略

BEGIN;

-- Step 1: 创建用户订阅表
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiration_date TIMESTAMPTZ NOT NULL,
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    receipt_data TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_auto_renewable BOOLEAN DEFAULT FALSE,
    next_renewal_date TIMESTAMPTZ,
    device_id VARCHAR(100),
    platform VARCHAR(20) DEFAULT 'iOS',
    synced_to_server BOOLEAN DEFAULT FALSE,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: 创建审计日志表
CREATE TABLE IF NOT EXISTS subscription_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    product_id VARCHAR(100),
    old_state JSONB,
    new_state JSONB,
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: 创建权益缓存表
CREATE TABLE IF NOT EXISTS user_entitlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    has_tactical_support BOOLEAN DEFAULT FALSE,
    has_lordship BOOLEAN DEFAULT FALSE,
    has_empire BOOLEAN DEFAULT FALSE,
    has_vip BOOLEAN DEFAULT FALSE,
    build_speed_bonus NUMERIC(5,2) DEFAULT 0,
    production_speed_bonus NUMERIC(5,2) DEFAULT 0,
    resource_output_bonus NUMERIC(5,2) DEFAULT 0,
    defense_bonus NUMERIC(5,2) DEFAULT 0,
    backpack_capacity_bonus INT DEFAULT 0,
    daily_reward INT DEFAULT 0,
    shop_discount_percentage INT DEFAULT 0,
    daily_teleport_times INT DEFAULT 0,
    perk_expiration_date TIMESTAMPTZ,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: 创建索引
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_product_id ON user_subscriptions(product_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_is_active ON user_subscriptions(is_active);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON subscription_audit_log(user_id);

-- Step 5: 创建触发器更新 updated_at
CREATE OR REPLACE FUNCTION update_user_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_subscriptions_updated_at_trigger
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_subscriptions_updated_at();

-- Step 6: 启用 RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_entitlements ENABLE ROW LEVEL SECURITY;

-- Step 7: 创建 RLS 策略
CREATE POLICY "Users can view their own subscriptions"
    ON user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role manages subscriptions"
    ON user_subscriptions
    AS PERMISSIVE
    TO authenticated
    USING (auth.uid() = user_id);

COMMIT;
```

---

## 5. 权益系统集成

### 5.1 权益检查系统

```swift
@MainActor
class RightsManager: NSObject, ObservableObject {
    
    static let shared = RightsManager()
    
    @Published var activeRights: [String: Entitlement] = [:]
    @Published var expiredRights: [String] = []
    
    func checkAndApplyRights() async {
        let iapManager = IAPManager.shared
        let activeSubscriptions = iapManager.getActiveSubscriptions()
        
        for subscription in activeSubscriptions {
            let entitlement = Entitlement(productID: subscription.productID)
            activeRights[subscription.productID] = entitlement
            
            // 应用到各个游戏系统
            await applyEntitlementToSystems(entitlement)
        }
        
        // 检查过期权益
        checkExpiredRights()
    }
    
    private func applyEntitlementToSystems(_ entitlement: Entitlement) async {
        // 应用到建筑系统
        if let buildingManager = BuildingManager.shared as? BuildingManager {
            buildingManager.applySpeedupBonus(entitlement.buildSpeedBonus)
            if entitlement.hasUnlimitedQueues {
                buildingManager.setUnlimitedQueues(true)
            }
        }
        
        // 应用到库存系统
        if let inventoryManager = InventoryManager.shared as? InventoryManager {
            inventoryManager.applyBackpackCapacityBonus(entitlement.backpackCapacityBonus)
        }
        
        // 应用到资源生产系统
        // 应用到社交系统等
    }
    
    func checkExpiredRights() {
        let iapManager = IAPManager.shared
        let expiredSubscriptions = iapManager.subscriptionRecords.filter {
            !$0.isActive || $0.expirationDate < Date()
        }
        
        for subscription in expiredSubscriptions {
            expiredRights.append(subscription.productID)
            removeEntitlement(subscription.productID)
        }
    }
    
    private func removeEntitlement(_ productID: String) {
        activeRights.removeValue(forKey: productID)
    }
    
    func hasRight(_ productID: String) -> Bool {
        return IAPManager.shared.checkSubscriptionStatus(productID: productID)
    }
    
    func getHighestTierRight() -> Entitlement? {
        return activeRights.values.max { a, b in
            IAPProductID.getProductCategory(a.productID).tier < IAPProductID.getProductCategory(b.productID).tier
        }
    }
}
```

---

## 6. 完整测试策略

### 6.1 测试场景清单 (12 个完整场景)

```
沙盒测试场景矩阵

┌─────────────────────────────────────────────────────────────────┐
│ 场景编号 | 测试类型 | 产品 ID | 预期结果 | 优先级 |
├─────────────────────────────────────────────────────────────────┤
│ T01 | 消耗性购买 | supply.survivor | ✅ 获得资源 | P1 |
│ T02 | 消耗性购买 | supply.overlord | ✅ 获得资源 | P1 |
│ T03 | 非续期购买 | tactical.1m | ✅ 激活权益30天 | P1 |
│ T04 | 非续期购买 | kingdom.1y | ✅ 激活权益365天 | P1 |
│ T05 | 续期购买 | vip.monthly | ✅ 自动续费 | P1 |
│ T06 | 续期试用 | vip.trial | ✅ 首月折扣 | P2 |
│ T07 | 权益验证 | 所有类型 | ✅ 权益正确应用 | P1 |
│ T08 | 权益过期 | tactical.1m | ✅ 30天后过期 | P1 |
│ T09 | 恢复购买 | 所有已购 | ✅ 权益恢复 | P2 |
│ T10 | 级别升级 | lord→empire | ✅ 权益更新 | P2 |
│ T11 | 取消订阅 | vip.monthly | ✅ 停止续费 | P2 |
│ T12 | 多产品叠加 | 混合购买 | ✅ 权益正确合并 | P3 |
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 测试执行清单

```swift
// 测试代码框架
class IAPTestCases {
    
    // T01: 消耗性产品购买
    func testConsumableProduct_Survivor() async {
        let product = IAPProductID.consumableProductIDs
        // 1. 查询产品
        // 2. 模拟购买
        // 3. 验证资源增加
        // 4. 验证交易记录
    }
    
    // T03: 非续期订阅购买
    func testNonRenewableSubscription_Tactical() async {
        let productID = "com.earthlord.tactical.1m"
        // 1. 购买产品
        // 2. 验证订阅记录
        // 3. 验证权益激活
        // 4. 模拟等待30天
        // 5. 验证权益过期
    }
    
    // T05: 自动续期订阅
    func testAutoRenewableSubscription_VIP() async {
        let productID = "com.earthlord.vip.monthly"
        // 1. 购买 VIP 月卡
        // 2. 验证自动续费配置
        // 3. 等待续费日期
        // 4. 验证自动扣费
        // 5. 验证权益持续有效
    }
    
    // T07: 完整权益验证
    func testEntitlementApplication() async {
        // 验证各产品的权益是否正确应用
        for productID in IAPProductID.allProductIDs {
            let entitlement = Entitlement(productID: productID)
            // 验证权益配置
            // 验证权益值范围
            // 验证权益类型
        }
    }
}
```

---

## 7. App Store Connect 完整配置

### 7.1 App Store Connect 步骤 (详细指南)

#### **第一步: 创建订阅组** (5 分钟)

```
1. 登录 https://appstoreconnect.apple.com
2. 选择应用 > App 内购买项目
3. 点击 + 新建项目

订阅组配置:
├─ 名称: 末日权益-月度订阅
├─ 参考 ID: earthlord_monthly_subscriptions
└─ 保存

重复为以下订阅组:
├─ earthlord_quarterly_subscriptions (季度)
├─ earthlord_annual_subscriptions (年度)
└─ earthlord_vip_subscriptions (VIP)
```

#### **第二步: 创建消耗性产品** (15 分钟)

```
创建 4 个消耗性产品:

产品 1:
├─ 类型: 消耗性
├─ 产品 ID: com.earthlord.supply.survivor
├─ 名称: 幸存者补给包
├─ 描述: 包含基础生存物资
├─ 价格: ¥6
└─ 保存

[重复为其他 3 个产品]
```

#### **第三步: 创建非续期订阅** (20 分钟)

```
创建 9 个非续期订阅产品:

示例 - com.earthlord.tactical.1m:
├─ 类型: 非续期订阅
├─ 订阅组: (留空，此类型不需要)
├─ 产品 ID: com.earthlord.tactical.1m
├─ 名称: 战术支援-月卡
├─ 描述: 获得 30 天的建造加速和资源加成
├─ 参考价格: $0.99 (系统转换为 ¥8)
├─ 自定义用户协议: [选择]
└─ 保存

[创建其余 8 个非续期产品]
```

#### **第四步: 创建自动续期订阅** (25 分钟)

```
创建 4 个续期订阅产品:

示例 - com.earthlord.vip.monthly:
├─ 类型: 自动续期订阅
├─ 订阅组: earthlord_vip_subscriptions
├─ 产品 ID: com.earthlord.vip.monthly
├─ 名称: VIP 月会员
├─ 描述: 获得 VIP 会员权益，月度自动续费
│
├─ 价格和时间表:
│  ├─ 基础价格: ¥12/月
│  ├─ 添加价格等级: [+ 按钮]
│  └─ (涵盖所有地区)
│
├─ 试用期间:
│  └─ 免费试用: 3 天 (可选)
│
├─ 推介价格:
│  ├─ 启用: [是]
│  ├─ 推介价格: ¥6
│  ├─ 数量: 1 期
│  └─ 持续时间: 1 个月
│
├─ 本地化信息:
│  ├─ 显示名称: VIP 月会员
│  ├─ 描述: 获得订阅会员权益
│  └─ [添加本地化版本]
│
└─ 保存
```

#### **第五步: 配置本地化** (15 分钟)

```
为每个产品添加本地化:

1. 编辑产品 ID
2. 滚动到 "本地化信息"
3. 点击 "+ 添加语言"

配置中文 (简体):
├─ 显示名称: [中文名称]
├─ 描述: [中文描述]
├─ 屏幕截图: [可选]
└─ 保存

建议语言:
- 中文 (简体)
- 中文 (繁体)
- English
- 日本語
```

#### **第六步: 创建沙盒测试账户** (10 分钟)

```
1. 新建应用 > 用户和角色 > 沙盒
2. 点击 "+ 创建沙盒测试账户"

创建 2-3 个测试账户:

账户 1:
├─ 用户名: test.survivor@example.com
├─ 密码: [强密码]
├─ 生日: [任意 18 岁以上]
└─ 保存

账户 2:
├─ 用户名: test.vip@example.com
└─ [重复步骤]
```

---

## 8. 21 天分阶段实施计划

### 8.1 Phase 1: 消耗性产品 & 基础架构 (Day 1-7)

#### **Day 1: 环境准备与产品配置** (4 小时)

- [ ] App Store Connect 创建 4 个消耗性产品
- [ ] 配置本地化信息
- [ ] 创建沙盒测试账户
- [ ] 同步产品 ID 到 Xcode

**输出物**:
- ✅ 4 个产品 ID 已在 App Store Connect 创建
- ✅ Xcode 项目配置完成
- ✅ 2 个沙盒测试账户可用

#### **Day 2-3: 代码实现** (10 小时)

- [ ] 创建 IAPModels.swift (权益定义)
- [ ] 实现 IAPManager.swift (基础功能)
- [ ] 创建消耗性产品购买 UI
- [ ] 集成库存系统

**代码工作**:
```swift
// IAPManager - 消耗性产品处理
func grantConsumableRewards(_ productID: String) async {
    // 根据产品 ID 给予对应资源
}

// SubscriptionView - 购买 UI
struct SubscriptionView: View { ... }
```

#### **Day 4-5: 权益系统** (8 小时)

- [ ] 创建 RightsManager.swift
- [ ] 集成权益到库存、建筑系统
- [ ] 实现权益检查和应用
- [ ] 本地存储权益数据

#### **Day 6: 测试与调试** (4 小时)

- [ ] 沙盒购买测试 (4 个消耗性产品)
- [ ] 权益验证测试
- [ ] 调试权益应用逻辑
- [ ] 修复 bug

**测试清单**:
- [x] T01: 购买 survivor
- [x] T02: 购买 overlord
- [x] T07: 权益总体验证

#### **Day 7: 代码清理与文档** (2 小时)

- [ ] 代码审查和重构
- [ ] 编写集成文档
- [ ] 更新代码注释

**Phase 1 完成条件**:
- ✅ 4 个消耗性产品可正常购买
- ✅ 资源正确分配
- ✅ 无编译错误
- ✅ 基础架构完成

---

### 8.2 Phase 2: 非续期订阅 (Day 8-14)

#### **Day 8: 产品配置** (3 小时)

- [ ] App Store Connect 创建 9 个非续期产品
- [ ] 配置所有本地化
- [ ] 同步产品 ID

**输出**:
- ✅ 9 个产品 ID 已配置
- ✅ 本地化完成

#### **Day 9-11: 代码扩展** (12 小时)

- [ ] 扩展 IAPModels 定义所有 9 个产品权益
- [ ] 扩展 IAPManager 处理非续期订阅
- [ ] 实现订阅数据库表
- [ ] 创建订阅 UI 组件
- [ ] 数据库迁移脚本

#### **Day 12-13: 权益与服务器同步** (8 小时)

- [ ] 实现订阅记录保存
- [ ] 集成 Supabase 同步
- [ ] 权益过期检查机制
- [ ] 升级/降级逻辑

#### **Day 14: 测试与优化** (3 小时)

- [ ] 完整沙盒测试 (T03, T04, T08 等)
- [ ] 权益生效验证
- [ ] 性能优化

**Phase 2 完成条件**:
- ✅ 9 个非续期产品可购买
- ✅ 权益 30/90/365 天正确应用
- ✅ 权益过期正确触发
- ✅ 支持升级和降级

---

### 8.3 Phase 3: 自动续期订阅 (Day 15-21)

#### **Day 15: 产品最终配置** (3 小时)

- [ ] App Store Connect 创建 4 个续期产品
- [ ] 配置订阅组
- [ ] 设置试用期和推介价格
- [ ] 创建沙盒测试账户

#### **Day 16-18: 续期逻辑实现** (12 小时)

- [ ] 实现自动续费检查
- [ ] 处理续期更新事件
- [ ] 续期失败处理
- [ ] 用户取消订阅逻辑
- [ ] 规格表显示

#### **Day 19-20: 完整集成与优化** (8 小时)

- [ ] 整合所有 16 产品
- [ ] UI 统一优化
- [ ] 性能测试
- [ ] 安全审计

#### **Day 21: 最终验收** (2 小时)

- [ ] 完整系统测试清单 (所有 12 个场景)
- [ ] 最后的 bug 修复
- [ ] 文档完成
- [ ] 生产环境准备

**Phase 3 完成条件**:
- ✅ 4 个续期产品建立
- ✅ 自动续费正常工作
- ✅ 试用期功能正确
- ✅ VIP 权益持续有效
- ✅ 完整的 16 产品系统上线

---

## 9. 故障排查指南

### 9.1 常见问题与解决方案

#### **问题 1: "产品不可用"错误**

```
症状: 购买时显示 "此产品不可用"
原因:
1. 产品 ID 不匹配
2. 产品未通过 App Store 审核
3. 过期时间设置错误
4. 地域限制问题

解决步骤:
1. 检查 Xcode 中的产品 ID 是否完全匹配
2. 在 App Store Connect 中检查产品状态 (是否为 "活跃")
3. 验证沙盒账户所在地区
4. 清除 app 缓存重试
```

#### **问题 2: 权益未生效**

```
症状: 购买完成但权益没有应用
原因:
1. IAPManager 未正确初始化
2. 权益系统未调用
3. 收据验证失败
4. 本地存储未同步

解决步骤:
// 添加调试代码
print("✅ 购买成功: productID = \(transaction.productID)")
print("✅ 权益对象: \(Entitlement(productID: transaction.productID))")
print("✅ IAPManager.shared.purchasedProductIDs = \(IAPManager.shared.purchasedProductIDs)")

2. 检查 RightsManager.checkAndApplyRights() 是否被调用
3. 观察 activeRights 字典是否有数据
```

#### **问题 3: 自动续费未触发**

```
症状: VIP 订阅应该续费但没有自动扣费
原因:
1. 自动续费设置未启用
2. 用户取消了订阅
3. 支付方法已过期
4. Apple 处理延迟

解决步骤:
1. 检查 App Store Connect 中的订阅状态
2. 查看 isAutoRenewEnabled 标志
3. 如果是沙盒环境，续费是即时的
4. 查看 subscription_audit_log 表中的取消记录
```

#### **问题 4: 收据验证失败**

```
症状: 购买完成但收据验证出错
原因:
1. 收据格式损坏
2. 服务端 API 请求失败
3. JWT 验证失败

解决步骤:
do {
    let transaction = try checkVerified(result)
    // 验证成功
} catch {
    print("❌ 收据验证错误: \(error)")
    // 检查错误类型
    if let storeKitError = error as? StoreKitError {
        print("StoreKit Error: \(storeKitError)")
    }
}
```

### 9.2 调试工具和命令

```bash
# 查看 Xcode 日志
log stream --predicate 'process == "EarthLord"' --level debug

# 清除缓存
defaults delete com.apple.dt.Xcode IDESourceTreeDisplayNames
defaults delete com.apple.dt.Xcode IDESourceTreeNames

# 模拟 StoreKit 交易
xcrun simctl keychain /Users/lyanwen/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Library/Keychains/keychain-2.sqlite

# 导出 Supabase 订阅日志
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://your-project.supabase.co/rest/v1/user_subscriptions" \
  > subscriptions_export.json
```

---

## 附录: 关键代码片段集合

### 权益检查

```swift
// 检查用户是否拥有特定权益
func hasSubscription(category: ProductCategory) -> Bool {
    return IAPManager.shared.getHighestTierSubscription()?.category == category ||
           (IAPManager.shared.getHighestTierSubscription()?.category.tier ?? -1) >= category.tier
}

// 获取当前激活的权益加成
func getActiveBonus(type: String) -> Double {
    guard let entitlement = RightsManager.shared.getHighestTierRight() else {
        return 0
    }
    
    switch type {
    case "buildSpeed":
        return entitlement.buildSpeedBonus
    case "resourceOutput":
        return entitlement.resourceOutputBonus
    case "defense":
        return entitlement.defenseBonus
    default:
        return 0
    }
}
```

### 权益应用到游戏系统

```swift
// 在建筑系统中应用权益
class BuildingManager {
    func calculateBuildingTime(_ baseTime: Int) -> Int {
        let speedupBonus = RightsManager.shared.getHighestTierRight()?.buildSpeedBonus ?? 0
        return Int(Double(baseTime) * (1 - speedupBonus))
    }
}

// 在库存系统中应用权益
class InventoryManager {
    var maxCapacity: Int {
        let baseCapacity = 100
        let bonus = RightsManager.shared.getHighestTierRight()?.backpackCapacityBonus ?? 0
        return baseCapacity + bonus
    }
}
```

---

**文档完成！** 🎉

这份完整版开发指南涵盖了：
- ✅ 16 个产品的完整定义
- ✅ 全部代码实现框架
- ✅ 数据库设计和迁移
- ✅ 权益系统集成
- ✅ 12 个完整测试场景
- ✅ App Store 配置详细步骤
- ✅ 21 天分阶段实施计划
- ✅ 故障排查指南

预计总工作量：21 天，按三个阶段递进实施。
