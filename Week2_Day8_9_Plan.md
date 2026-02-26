# 🚀 Week 2 - Day 8-9 Social & Trade 系统计划

**日期**: 2026年2月26-27日（Day 12-13）  
**状态**: 🔄 准备启动  
**编译**: ✅ 0 错误 + 0 警告  

---

## 📋 系统概览

### Day 8-9 任务分解

```
Day 8 (4 小时) - 社交频道系统
├─ 1️⃣ 数据模型 (1 小时)
│  ├─ Channel 模型
│  ├─ Message 模型
│  └─ ChannelMember 模型
├─ 2️⃣ ChannelManager (1.5 小时)
│  ├─ 创建/获取频道
│  ├─ 发送消息
│  ├─ 加载消息历史
│  └─ 管理成员
├─ 3️⃣ UI 组件 (1.5 小时)
│  ├─ ChannelListView
│  ├─ ChatView
│  └─ CreateChannelView
└─ 4️⃣ 页签集成 (0.5 小时)
   └─ 在主导航中添加社交标签

Day 9 (5 小时) - 交易系统 + 权益集成
├─ 1️⃣ 数据模型 (1 小时)
│  ├─ Trade 模型
│  ├─ TradeOffer 模型
│  └─ TradeHistory 模型
├─ 2️⃣ TradeManager (1.5 小时)
│  ├─ 创建交易
│  ├─ 验证资源
│  ├─ 手续费计算 (含Tier折扣)
│  └─ 交易完成处理
├─ 3️⃣ UI 组件 (1.5 小时)
│  ├─ TradeListView
│  ├─ CreateTradeView
│  └─ TradeDetailView
├─ 4️⃣ Tier 权益集成 (0.5 小时)
│  ├─ TieManager 调用 Trade 折扣
│  ├─ 权益应用验证
│  └─ UI 显示折扣优惠
└─ 5️⃣ 最终验证 (0.5 小时)
   ├─ 编译检查
   ├─ 功能测试
   └─ 文档生成
```

---

## 🎯 Day 8: 社交频道系统

### 功能需求

```
需求 1: 频道列表
├─ 显示用户的所有频道
├─ 支持私聊和群聊
├─ 显示最后消息预览
└─ 显示未读计数

需求 2: 聊天界面
├─ 实时消息显示
├─ 消息分页加载
├─ 输入框和发送
├─ 消息时间戳

需求 3: 创建频道
├─ 新建私聊 (选择用户)
├─ 新建群聊 (命名 + 选择成员)
├─ 设置频道权限
└─ 邀请成员

需求 4: 成员管理
├─ 显示频道成员
├─ 移除成员 (权限检查)
├─ 成员在线状态
└─ @mention 功能
```

### 数据模型设计

#### Channel (频道)

```swift
struct Channel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let type: ChannelType  // .private or .group
    let createdBy: String  // 创建者 user_id
    let createdAt: Date
    let updatedAt: Date
    var members: [String]  // 成员 user_id 列表
    var isArchived: Bool
}

enum ChannelType: String, Codable {
    case `private`  // 1对1私聊
    case group      // 群聊
}
```

#### Message (消息)

```swift
struct Message: Codable, Identifiable {
    let id: String
    let channelId: String
    let senderId: String
    let senderName: String
    let content: String
    let createdAt: Date
    var isEdited: Bool
    let editedAt: Date?
}
```

#### ChannelMember (成员)

```swift
struct ChannelMember: Codable, Identifiable {
    let id: String
    let channelId: String
    let userId: String
    let joinedAt: Date
    var role: MemberRole  // owner, admin, member

    enum MemberRole: String, Codable {
        case owner
        case admin
        case member
    }
}
```

### ChannelManager 设计

```swift
@MainActor
class ChannelManager: ObservableObject {
    static let shared = ChannelManager()
    
    @Published var channels: [Channel] = []
    @Published var currentChannel: Channel?
    @Published var messages: [Message] = []
    
    // 频道操作
    func createChannel(name: String, type: ChannelType, members: [String])
    func getChannel(id: String) -> Channel?
    func deleteChannel(id: String)
    
    // 消息操作
    func sendMessage(channelId: String, content: String)
    func loadMessages(channelId: String, limit: Int = 50)
    func deleteMessage(messageId: String)
    
    // 成员操作
    func addMember(channelId: String, userId: String)
    func removeMember(channelId: String, userId: String)
    
    // 实时订阅
    func subscribeToChannel(id: String)
    func unsubscribeFromChannel(id: String)
}
```

### UI 组件设计

#### ChannelListView
```
┌─────────────────────────┐
│ 社交 (标题栏)           │
├─────────────────────────┤
│ [+ 新建频道]            │
├─────────────────────────┤
│ 频道1    消息预览   ⏰   │
│ 频道2    消息预览   🔴2  │
│ 频道3    消息预览      │
│ ...                  │
└─────────────────────────┘
```

#### ChatView
```
┌─────────────────────────┐
│ #频道名              X   │ ← 标题栏
├─────────────────────────┤
│                         │
│ [系统消息] 10:00     │
│ Alice: 你好 👋       │
│ Bob: 大家好         │
│ Alice: 最近怎样？    │
│                         │
├─────────────────────────┤
│ [消息输入框  ]   [发送] │
└─────────────────────────┘
```

---

## 🤝 Day 9: 交易系统

### 功能需求

```
需求 1: 交易列表
├─ 显示待处理交易
├─ 过滤：出价/求价/已成交
├─ 排序：时间/价值
└─ 搜索功能

需求 2: 创建交易
├─ 输入：提供资源 + 求取资源
├─ 数量验证
├─ 手续费计算 (含Tier折扣)
├─ 预览交易内容
└─ 发布交易

需求 3: 交易详情
├─ 显示交易双方信息
├─ 显示交易内容
├─ 接受/拒绝/取消操作
├─ 交易历史记录
└─ 评价功能

需求 4: Tier 权益
├─ VIP/Empire 用户：交易费折扣
├─ 显示优惠信息
├─ 自动应用折扣
└─ 权益说明
```

### 数据模型设计

#### Trade (交易)

```swift
struct Trade: Codable, Identifiable {
    let id: String
    let creatorId: String
    let creatorName: String
    let createdAt: Date
    var expiresAt: Date
    
    // 交易内容
    let offering: [ResourceAmount]    // 提供的资源
    let requesting: [ResourceAmount]  // 求取的资源
    
    // 交易状态
    var status: TradeStatus  // pending, accepted, rejected, completed
    var acceptedBy: String?  // 接受者 user_id
    
    // 手续费相关
    let tradeFee: Int        // 基础手续费 (%)
    var finalFee: Int        // 实际手续费 (% - 考虑Tier折扣)
}

enum TradeStatus: String, Codable {
    case pending    // 等待中
    case accepted   // 已接受
    case rejected   // 已拒绝
    case completed  // 已完成
    case expired    // 已过期
}

struct ResourceAmount: Codable {
    let resourceId: String
    let resourceName: String
    let quantity: Int
}
```

#### TradeOffer (交易报价)

```swift
struct TradeOffer: Codable, Identifiable {
    let id: String
    let tradeId: String
    let offererId: String
    let offerContent: [ResourceAmount]
    let createdAt: Date
}
```

### TradeManager 设计

```swift
@MainActor
class TradeManager: ObservableObject {
    static let shared = TradeManager()
    
    @Published var trades: [Trade] = []
    @Published var myTrades: [Trade] = []
    @Published var tradeHistory: [Trade] = []
    
    // 交易操作
    func createTrade(offering: [ResourceAmount], requesting: [ResourceAmount]) -> Trade?
    func acceptTrade(tradeId: String)
    func rejectTrade(tradeId: String)
    func completeTrade(tradeId: String)
    func cancelTrade(tradeId: String)
    
    // 查询操作
    func getTrade(id: String) -> Trade?
    func searchTrades(query: String) -> [Trade]
    func getTradesByStatus(_ status: TradeStatus) -> [Trade]
    
    // Tier 权益集成
    func calculateTradeFee(baseFee: Int, userTier: UserTier) -> Int {
        let discount = UserTier.getBenefit(for: userTier)?.tradeFeeDiscount ?? 0.0
        return Int(Double(baseFee) * (1.0 - discount))
    }
    
    // 验证
    func validateResources(items: [ResourceAmount]) -> Bool
    func validateTrade(trade: Trade) -> (isValid: Bool, errorMessage: String?)
}
```

### 手续费计算

```
交易手续费计算公式：

基础手续费 = 10% (总交易价值的)

Tier 折扣:
├─ Free:     0% 折扣  → 最终费用: 10%
├─ Support:  0% 折扣  → 最终费用: 10%
├─ Lordship: 0% 折扣  → 最终费用: 10%
├─ Empire:   0% 折扣  → 最终费用: 10%
└─ VIP:      20% 折扣 → 最终费用: 8%  ✨

示例:
交易价值: 100 资源
├─ 免费用户: 100 + 10% = 110 (付费10)
└─ VIP用户: 100 + 10% × (1-20%) = 100 + 8% = 108 (付费8)
                                   节省 2 资源 ✨
```

### UI 组件设计

#### TradeListView
```
┌─────────────────────────┐
│ 交易市场                │
├─────────────────────────┤
│ [全部] [求价] [出价]  [✓已成交] │
│ [🔍 搜索...]            │
├─────────────────────────┤
│ Alice 求: 粮食×100      │
│ 出: 木材×50   💰 8%手续 │
│                         │
│ Bob 求: 铁×20          │
│ 出: 粮食×30  💰 10%手续 │
│                         │
│ Carol 求: 金×5         │
│ 出: 粮食×200 💚 VIP 8% │
└─────────────────────────┘
```

---

## 📊 系统集成架构

### 完整集成链 (Day 8-9 后)

```
用户 
  ├─ 社交功能
  │  ├─ ChannelManager
  │  │  ├─ createChannel()
  │  │  ├─ sendMessage()
  │  │  └─ subscribeToChannel()
  │  └─ ChannelListView + ChatView
  │
  └─ 交易功能
     ├─ TradeManager
     │  ├─ createTrade()
     │  ├─ calculateTradeFee(userTier) ← Tier权益
     │  └─ completeTrade()
     └─ TradeListView + TradeDetailView
```

### Tier 权益集成

```
用户升级到 VIP
    ↓
IAPManager 完成交易
    ↓
TierManager.updateTier(.vip)
    ↓
TierManager.applyBenefitsToGameSystems()
    ├─ BuildingManager.applyBuildingBenefit()
    ├─ ProductionManager.applyProductionBenefit()
    ├─ InventoryManager.applyInventoryBenefit()
    ├─ TerritoryManager.applyTerritoryBenefit()
    └─ TradeManager.applyTradeBenefit() [新增]
        └─ 交易手续费自动从10% → 8% ✨
```

---

## ⏱️ 时间分配

### Day 8: 社交频道系统 (4 小时)

```
❌ 00:00 - 01:00  数据模型 + ChannelManager
❌ 01:00 - 02:30  UI 组件 (ChannelListView, ChatView)
❌ 02:30 - 03:00  CreateChannelView 和集成
❌ 03:00 - 04:00  编译验证 + 文档
```

### Day 9: 交易系统 + 权益集成 (5 小时)

```
❌ 00:00 - 01:00  数据模型 + TradeManager + 手续费计算
❌ 01:00 - 02:30  UI 组件 (TradeListView, TradeDetailView)
❌ 02:30 - 03:30  CreateTradeView + Tier权益集成
❌ 03:30 - 04:00  最终测试 + 修复
❌ 04:00 - 05:00  文档生成
```

---

## ✅ 验证清单

### 编译验证
- [ ] 0 编译错误
- [ ] 0 编译警告
- [ ] 所有导入正确

### 功能验证
- [ ] ChannelManager 创建/发送/加载消息
- [ ] TradeManager 创建/接受交易
- [ ] 手续费计算正确
- [ ] Tier 权益自动应用
- [ ] UI 实时更新

### 集成验证
- [ ] 与 TierManager 无缝集成
- [ ] 与数据库同步
- [ ] 与现有系统兼容

### 文档验证
- [ ] Day 8 社交系统文档
- [ ] Day 9 交易系统文档
- [ ] API 文档

---

## 📝 关键代码示例

### 创建频道

```swift
let channel = Channel(
    id: UUID().uuidString,
    name: "开发讨论",
    description: "关于游戏开发的讨论",
    type: .group,
    createdBy: currentUser.id,
    createdAt: Date(),
    updatedAt: Date(),
    members: [user1.id, user2.id, user3.id],
    isArchived: false
)

await ChannelManager.shared.createChannel(
    name: channel.name,
    type: channel.type,
    members: channel.members
)
```

### 发送消息

```swift
await ChannelManager.shared.sendMessage(
    channelId: currentChannel.id,
    content: "大家好！"
)
```

### 创建交易

```swift
let offering = [ResourceAmount(resourceId: "wood", resourceName: "木材", quantity: 50)]
let requesting = [ResourceAmount(resourceId: "food", resourceName: "粮食", quantity: 100)]

if let trade = await TradeManager.shared.createTrade(
    offering: offering,
    requesting: requesting
) {
    // 交易创建成功
    print("交易手续费: \(trade.finalFee)%")
}
```

### Tier 权益应用

```swift
// 当用户升级到 VIP 时
let vipBenefit = TierBenefit(tradeFeeDiscount: 0.2, ...)
let finalFee = TradeManager.shared.calculateTradeFee(
    baseFee: 10,
    userTier: .vip
)
// 结果: 8% (10% - 20% 折扣)
```

---

## 🎯 Success Criteria

```
✅ Day 8 完成指标:
├─ ChannelManager 实现完整
├─ 4 个 UI 组件完成
├─ 聊天功能可用
└─ 0 编译错误

✅ Day 9 完成指标:
├─ TradeManager 实现完整
├─ 3 个 UI 组件完成
├─ 手续费计算正确
├─ Tier 权益生效
└─ 0 编译错误

✅ 整体完成指标:
├─ Week 2 两日完成
├─ ~500-600 行代码
├─ 完全集成
└─ 文档完整
```

---

**准备状态**: 🟢 准备启动 Day 8
**代码行数预期**: 500-600 行
**文档行数预期**: 1000+ 行
**预计完成**: 2026年2月27日晚间
