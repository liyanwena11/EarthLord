# 🚀 EarthLord 订阅系统完整开发指南

**版本**: 1.0  
**基于**: AI Vibe Coding 第八周课程  
**项目**: 末世领主 iOS 游戏  
**目标**: 实现 iOS 自动续期订阅系统（Auto-Renewable Subscription）

---

## 📋 课程内容概览

本文档基于飞书课程《使用 Claude Code 实现 iOS 自动续期订阅》进行 EarthLord 项目特化。
课程核心内容包括：
- ✅ 订阅制理论与设计
- ✅ AI 辅助开发流程
- ✅ StoreKit 2 实现方案
- ✅ App Store Connect 配置
- ✅ 沙盒测试与调试

---

## 第一部分：EarthLord 订阅方案设计

### 1.1 产品定义

#### 订阅等级体系

| 等级 | 命名 | 月价 | 年价 | 年度折扣 | 目标用户 |
|------|------|------|------|---------|---------|
| **基础** | 免费 | ¥0 | - | - | 新手玩家 |
| **L1** | 探索者通行证 | ¥12/月 | ¥88/年 | 省 ¥56 (39%) | 日活玩家 |
| **L2** | 领主通行证 | ¥25/月 | ¥168/年 | 省 ¥132 (44%) | 核心玩家 |

#### 产品配置表

| 产品名 | 产品 ID | 周期 | 价格 | 试用期 | 自动续费 |
|--------|--------|------|------|--------|---------|
| 探索者-月付 | `com.earthlord.sub.explorer.monthly` | 1 月 | ¥12 | 7天 | ✅ |
| 探索者-年付 | `com.earthlord.sub.explorer.yearly` | 1 年 | ¥88 | 7天 | ✅ |
| 领主-月付 | `com.earthlord.sub.lord.monthly` | 1 月 | ¥25 | 7天 | ✅ |
| 领主-年付 | `com.earthlord.sub.lord.yearly` | 1 年 | ¥168 | 7天 | ✅ |

### 1.2 权益设计矩阵

| 权益项 | 免费用户 | 探索者通行证 | 领主通行证 |
|--------|---------|-----------|---------|
| **探索次数** | 10 次/天 | ✨ 无限 | ✨ 无限 |
| **废墟搜索范围** | 1 km | ⭐ 2 km | ⭐ 2 km |
| **背包容量** | 100 格 | 📦 200 格 | 📦 300 格 |
| **建造速度** | 1x | ⚡ 2x | ⚡ 2x |
| **交易次数** | 10 次/天 | 💰 无限 | 💰 无限 |
| **专属徽章** | - | 🎖️ 探索者 | 🎖️ 领主 |
| **月度物资** | - | ¥12 物资 | ✨ ¥12 物资 + 额外 |
| **优先客服** | - | ⏱️ 优先 | ⏱️ VIP |

### 1.3 订阅等级枚举

```swift
enum SubscriptionTier: String, Codable {
    case free = "free"
    case explorer = "explorer"
    case lord = "lord"
    
    var displayName: String {
        switch self {
        case .free: return "免费用户"
        case .explorer: return "探索者通行证"
        case .lord: return "领主通行证"
        }
    }
}

enum SubscriptionPeriod: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "月度"
        case .yearly: return "年度"
        }
    }
}
```

### 1.4 商业逻辑

#### 为什么要订阅？

**对开发者**：
- ✅ 收入可预测，现金流稳定
- ✅ LTV（用户生命周期价值）显著提升
- ✅ 次年苹果分成从 30% 降至 15%
- ✅ 形成持续改进的动力

**对玩家**：
- ✅ 一次支付享受持续的游戏改善
- ✅ 灵活选择：月度尝试 → 年度省钱
- ✅ 随时取消，无风险
- ✅ 实际单月成本：¥8.7/月（年付）

#### 试用期策略

```
新用户下载 → 7 天免费试用
  ├─ Day 1-5: 享受完整权益
  ├─ Day 6: 推送"即将到期"通知
  ├─ Day 7: 自动扣费或取消
  └─ 用户可随时在设置取消
```

#### 升级/降级规则

| 场景 | 规则 | 例情 |
|------|------|------|
| 升级 | 差价按日比例扣费 | 月→年：多付部分立即扣费 |
| 降级 | 差价按日比例返还 | 年→月：多付部分返还到账户 |
| 购买周期内取消 | 继续享受至周期结束 | 月中取消→月底到期 |

---

## 第二部分：技术架构设计

### 2.1 系统架构图

```
┌─────────────────────────────────────────────┐
│         用户 UI 层                           │
├─────────────────────────────────────────────┤
│  SubscriptionView (订阅主页)                 │
│  ├─ SubscriptionCard (卡片组件)             │
│  └─ SubscriptionBenefitsView (权益对比表)   │
├─────────────────────────────────────────────┤
│    业务逻辑层 (Manager)                      │
├─────────────────────────────────────────────┤
│  IAPManager (订阅管理 + 交易处理)            │
│  ├─ 加载订阅产品                            │
│  ├─ 处理购买交易                            │
│  ├─ 检查订阅状态                            │
│  └─ 处理续费/过期                           │
├─────────────────────────────────────────────┤
│    权益系统集成层                           │
├─────────────────────────────────────────────┤
│  InventoryManager → 背包容量                │
│  BuildingManager → 建造速度                 │
│  ExplorationManager → 探索上限              │
│  TradeManager → 交易上限                    │
├─────────────────────────────────────────────┤
│    数据持久层                               │
├─────────────────────────────────────────────┤
│  本地缓存 (UserDefaults)                    │
│  ├─ 当前订阅信息                            │
│  └─ 到期时间                               │
│ Supabase (权威数据源)                       │
│  ├─ user_subscriptions 表                   │
│  └─ 订阅历史日志                            │
├─────────────────────────────────────────────┤
│    App Store StoreKit 2                     │
├─────────────────────────────────────────────┤
│  Transaction 监听器 (自动订阅处理)           │
│  Product 加载器 (产品元数据)                │
│  AppStore Server 验证 (收据验证)            │
└─────────────────────────────────────────────┘
```

### 2.2 数据模型设计

#### Swift 数据模型 (IAPModels.swift)

```swift
// ============ 权益配置 ============
struct SubscriptionBenefits: Codable {
    let dailyExplorationLimit: Int       // -1 = 无限
    let searchRangeKm: Double            // 废墟搜索范围
    let backpackCapacity: Int            // 背包格数
    let buildSpeedMultiplier: Double     // 建造倍数
    let dailyTradeLimit: Int             // -1 = 无限
    let monthlyMaterialRewards: Int       // 月度物资（¥）
    let hasExclusiveBadge: Bool         // 专属徽章
    let prioritySupport: Bool            // VIP 客服
    
    // 预定义权益包
    static let free = SubscriptionBenefits(
        dailyExplorationLimit: 10,
        searchRangeKm: 1.0,
        backpackCapacity: 100,
        buildSpeedMultiplier: 1.0,
        dailyTradeLimit: 10,
        monthlyMaterialRewards: 0,
        hasExclusiveBadge: false,
        prioritySupport: false
    )
    
    static let explorer = SubscriptionBenefits(
        dailyExplorationLimit: -1,        // 无限
        searchRangeKm: 2.0,
        backpackCapacity: 200,
        buildSpeedMultiplier: 2.0,
        dailyTradeLimit: -1,
        monthlyMaterialRewards: 12,
        hasExclusiveBadge: true,
        prioritySupport: true
    )
    
    static let lord = SubscriptionBenefits(
        dailyExplorationLimit: -1,
        searchRangeKm: 2.0,
        backpackCapacity: 300,
        buildSpeedMultiplier: 2.0,
        dailyTradeLimit: -1,
        monthlyMaterialRewards: 18,       // 额外物资
        hasExclusiveBadge: true,
        prioritySupport: true
    )
}

// ============ 产品配置 ============
struct SubscriptionProduct: Identifiable {
    let id: String                       // 产品 ID
    let tier: SubscriptionTier          // 等级
    let period: SubscriptionPeriod      // 周期
    let price: Decimal                  // 价格
    let displayName: String              // 显示名称
    let description: String              // 描述
    
    var trialDays: Int { 7 }            // 试用期
    var benefits: SubscriptionBenefits { tier.benefits }
}

// ============ 订阅状态 ============
struct DBUserSubscription: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let productId: String               // App Store 产品 ID
    let tier: SubscriptionTier
    let status: SubscriptionStatus      // active/expired/cancelled
    let originalPurchaseDate: Date
    let expiresAt: Date
    let isTrial: Bool
    let autoRenew: Bool
    let transactionId: String?
    let environment: String             // production/sandbox
    let createdAt: Date
    let updatedAt: Date
    
    var isExpired: Bool { Date() > expiresAt }
    var isTrialPeriod: Bool { isTrial && Date() < expiresAt }
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case pending = "pending"
}

// ============ 错误处理 ============
enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case verificationFailed
    case networkError
    case databaseError(String)
}
```

#### Supabase 数据库表

```sql
-- ===== 用户订阅表 =====
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,                    -- App Store 产品 ID
    tier TEXT NOT NULL,                          -- free/explorer/lord
    status TEXT NOT NULL DEFAULT 'active',       -- active/expired/cancelled
    original_purchase_date TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_trial BOOLEAN DEFAULT false,
    auto_renew BOOLEAN DEFAULT true,
    transaction_id TEXT,
    environment TEXT DEFAULT 'production',       -- production/sandbox
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===== 索引优化 =====
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_expires ON user_subscriptions(expires_at);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);

-- ===== 行级安全策略 (RLS) =====
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的订阅
CREATE POLICY "users_view_own_subscription" ON user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- 用户只能插入自己的订阅
CREATE POLICY "users_insert_own_subscription" ON user_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 只有服务器才能更新（防止篡改）
CREATE POLICY "service_update_subscription" ON user_subscriptions
    FOR UPDATE USING (false);  -- 通过 Service Role 更新

-- ===== 订阅变化日志表 =====
CREATE TABLE subscription_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    event_type TEXT NOT NULL,           -- purchased/renewed/cancelled/expired
    old_tier TEXT,
    new_tier TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 2.3 关键枚举和类型

```swift
// 订阅组名称（在 App Store Connect 中创建）
let subscriptionGroupId = "earthlord_apocalypse_pass"

// 所有订阅产品 ID
let subscriptionProductIds = Set([
    "com.earthlord.sub.explorer.monthly",  // ¥12/月
    "com.earthlord.sub.explorer.yearly",   // ¥88/年
    "com.earthlord.sub.lord.monthly",      // ¥25/月
    "com.earthlord.sub.lord.yearly"        // ¥168/年
])

// 订阅等级 ↔ 权益映射
extension SubscriptionTier {
    var benefits: SubscriptionBenefits {
        switch self {
        case .free: return .free
        case .explorer: return .explorer
        case .lord: return .lord
        }
    }
}
```

---

## 第三部分：IAPManager 订阅系统实现

### 3.1 完整的 IAPManager 架构

```swift
import StoreKit
import Supabase

@MainActor
class IAPManager: NSObject, ObservableObject {
    static let shared = IAPManager()
    
    // ========== 发布属性 ==========
    @Published var subscriptionProducts: [SubscriptionProduct] = []
    @Published var activeSubscription: DBUserSubscription?
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    // ========== 私有属性 ==========
    private var updateTask: Task<Void, Never>?
    private let supabaseClient = SupabaseClient()
    
    // MARK: - 初始化与监听
    
    override init() {
        super.init()
        setupTransactionListener()
    }
    
    private func setupTransactionListener() {
        updateTask = Task(priority: .background) {
            for await result in Transaction.updates {
                await self.handleTransaction(result)
            }
        }
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    // MARK: - 产品加载
    
    /// 加载所有订阅产品
    func loadSubscriptionProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: subscriptionProductIds)
            
            var subscriptionProducts: [SubscriptionProduct] = []
            for product in products.sorted(by: { $0.price > $1.price }) {
                let tier = extractTier(from: product.id)
                let period = extractPeriod(from: product.id)
                
                let subProduct = SubscriptionProduct(
                    id: product.id,
                    tier: tier,
                    period: period,
                    price: product.price,
                    displayName: product.displayName,
                    description: product.description
                )
                subscriptionProducts.append(subProduct)
            }
            
            self.subscriptionProducts = subscriptionProducts
        } catch {
            self.error = .networkError
            print("❌ 加载订阅产品失败: \(error)")
        }
    }
    
    // MARK: - 订阅状态检查
    
    /// 加载当前的活跃订阅
    func loadActiveSubscription() async {
        do {
            // 1️⃣ 从数据库加载
            guard let userId = supabaseClient.auth.currentSession?.user.id else {
                self.subscriptionTier = .free
                return
            }
            
            let subscription = try await supabaseClient
                .from("user_subscriptions")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "active")
                .single()
                .execute()
                .value as? [String: Any]
            
            if let subscription = subscription {
                let tier = SubscriptionTier(
                    rawValue: subscription["tier"] as? String ?? "free"
                ) ?? .free
                self.subscriptionTier = tier
                
                // 2️⃣ 检查 App Store 实际状态
                await checkSubscriptionStatusFromAppStore(tier)
            } else {
                self.subscriptionTier = .free
            }
        } catch {
            self.subscriptionTier = .free
            print("❌ 加载订阅失败: \(error)")
        }
    }
    
    /// 检查订阅在 App Store 的真实状态
    private func checkSubscriptionStatusFromAppStore(_ tier: SubscriptionTier) async {
        do {
            for productId in subscriptionProductIds {
                guard let verificationResult = try await Product(
                    id: productId
                ).latestTransaction else { continue }
                
                switch verificationResult {
                case .verified(let transaction):
                    if !transaction.isUpgraded && transaction.expirationDate! > Date() {
                        // ✅ 订阅仍有效
                        print("✅ 订阅有效: \(productId), 到期时间: \(transaction.expirationDate!)")
                    } else {
                        // ❌ 订阅已过期或升级
                        await handleExpiredSubscription(tier)
                    }
                case .unverified:
                    print("⚠️ 交易验证失败")
                }
            }
        } catch {
            print("⚠️ 从 App Store 检查状态失败: \(error)")
        }
    }
    
    // MARK: - 购买与交易处理
    
    /// 购买订阅
    func purchaseSubscription(_ product: SubscriptionProduct) async -> Bool {
        do {
            guard let storeProduct = try await Product(id: product.id) else {
                self.error = .productNotFound
                return false
            }
            
            let result = try await storeProduct.purchase()
            
            switch result {
            case .success(let verificationResult):
                await handleTransaction(verificationResult)
                return true
                
            case .userCancelled:
                print("⚠️ 用户取消购买")
                return false
                
            case .pending:
                print("⏳ 购买待审核")
                return false
                
            @unknown default:
                return false
            }
        } catch {
            self.error = .purchaseFailed(error.localizedDescription)
            return false
        }
    }
    
    /// 处理交易（订阅必须与消耗品分开处理）
    private func handleTransaction(
        _ result: VerificationResult<Transaction>
    ) async {
        switch result {
        case .verified(let transaction):
            // 🔑 关键：区分订阅和消耗品
            if subscriptionProductIds.contains(transaction.productID) {
                // 📌 订阅处理
                await handleSubscriptionTransaction(transaction)
            }
            // 🔑 关键：必须 finish，否则重复处理
            await transaction.finish()
            
        case .unverified(let transaction, let error):
            print("❌ 交易验证失败: \(error)")
            await transaction.finish()
        }
    }
    
    /// 处理订阅交易（关键逻辑）
    private func handleSubscriptionTransaction(_ transaction: Transaction) async {
        do {
            guard let userId = supabaseClient.auth.currentSession?.user.id else {
                return
            }
            
            let tier = extractTier(from: transaction.productID)
            let expirationDate = transaction.expirationDate ?? Date()
            
            // 保存到数据库
            let subscription = [
                "user_id": userId.uuidString,
                "product_id": transaction.productID,
                "tier": tier.rawValue,
                "status": "active",
                "original_purchase_date": Date().ISO8601Format(),
                "expires_at": expirationDate.ISO8601Format(),
                "is_trial": transaction.isTrialConversion ?? false,
                "auto_renew": true,
                "transaction_id": String(transaction.id),
                "environment": "production"
            ] as [String: Any]
            
            try await supabaseClient
                .from("user_subscriptions")
                .upsert(subscription, onConflict: "user_id")
                .execute()
            
            // 更新本地状态
            self.subscriptionTier = tier
            
            // 发送日志
            await logSubscriptionEvent(
                userId: userId,
                eventType: "purchased",
                newTier: tier
            )
            
            print("✅ 订阅购买成功: \(tier.displayName)")
        } catch {
            print("❌ 保存订阅失败: \(error)")
        }
    }
    
    // MARK: - 恢复与续费处理
    
    /// 恢复之前的购买
    func restoreSubscriptions() async {
        do {
            try await AppStore.sync()
            await loadActiveSubscription()
            print("✅ 恢复购买成功")
        } catch {
            print("❌ 恢复购买失败: \(error)")
        }
    }
    
    /// 处理订阅过期
    private func handleExpiredSubscription(_ tier: SubscriptionTier) async {
        do {
            guard let userId = supabaseClient.auth.currentSession?.user.id else {
                return
            }
            
            // 更新数据库状态
            try await supabaseClient
                .from("user_subscriptions")
                .update(["status": "expired"])
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // 降级回免费
            self.subscriptionTier = .free
            
            print("✅ 订阅已过期，降级为免费用户")
        } catch {
            print("❌ 处理过期失败: \(error)")
        }
    }
    
    // MARK: - 工具方法
    
    /// 打开系统订阅管理
    func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func extractTier(from productId: String) -> SubscriptionTier {
        if productId.contains("lord") { return .lord }
        if productId.contains("explorer") { return .explorer }
        return .free
    }
    
    private func extractPeriod(from productId: String) -> SubscriptionPeriod {
        if productId.contains("yearly") { return .yearly }
        return .monthly
    }
    
    private func logSubscriptionEvent(
        userId: UUID,
        eventType: String,
        newTier: SubscriptionTier
    ) async {
        do {
            try await supabaseClient
                .from("subscription_audit_log")
                .insert([
                    "user_id": userId.uuidString,
                    "event_type": eventType,
                    "new_tier": newTier.rawValue
                ])
                .execute()
        } catch {
            print("⚠️ 日志记录失败: \(error)")
        }
    }
}
```

---

## 第四部分：权益系统集成

### 4.1 管理器集成方案

权益不应该在 IAPManager 中实现，而是分散到各个业务 Manager。

#### InventoryManager 扩展

```swift
extension InventoryManager {
    /// 获取背包最大容量（根据订阅等级）
    var maxCapacity: Int {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 100
        case .explorer: return 200
        case .lord: return 300
        }
    }
    
    /// 异步加载玩家背包（确保权益同步）
    func loadPlayerInventory() async {
        // 1️⃣ 先确保订阅状态最新
        await IAPManager.shared.loadActiveSubscription()
        
        // 2️⃣ 再按最新权益加载
        let capacity = maxCapacity
        // ... 加载背包逻辑
    }
}
```

#### BuildingManager 扩展

```swift
extension BuildingManager {
    /// 获取建造速度倍数
    var buildSpeedMultiplier: Double {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 1.0
        case .explorer: return 2.0
        case .lord: return 2.0
        }
    }
    
    /// 计算实际建造时间
    func getActualBuildTime(_ baseTimes: TimeInterval) -> TimeInterval {
        return baseTimes / buildSpeedMultiplier
    }
}
```

#### ExplorationManager 扩展

```swift
extension ExplorationManager {
    /// 每日探索上限
    var dailyExplorationLimit: Int {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 10
        case .explorer: return .max  // 无限
        case .lord: return .max
        }
    }
    
    /// 废墟搜索范围（km）
    var searchRangeKm: Double {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 1.0
        case .explorer: return 2.0
        case .lord: return 2.0
        }
    }
    
    /// 检查今日探索次数是否超限
    func canExplore() -> Bool {
        let used = getUsedExplorationCount()
        return used < dailyExplorationLimit
    }
}
```

#### TradeManager 扩展

```swift
extension TradeManager {
    /// 每日交易上限
    var dailyTradeLimit: Int {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 10
        case .explorer: return .max
        case .lord: return .max
        }
    }
    
    /// 检查能否发起交易
    func canCreateOffer() -> Bool {
        let used = getUsedTradeCount()
        return used < dailyTradeLimit
    }
}
```

### 4.2 权益监听与实时同步

```swift
extension IAPManager {
    /// 当订阅等级变化时，通知所有 Manager 更新权益
    func notifySubscriptionChanged() {
        NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"))
    }
}

// 在各个 Manager 中监听
extension InventoryManager {
    func setupSubscriptionListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSubscriptionChanged),
            name: NSNotification.Name("SubscriptionChanged"),
            object: nil
        )
    }
    
    @objc func onSubscriptionChanged() {
        // 重新加载背包（应用新容量限额）
        Task {
            await loadPlayerInventory()
        }
    }
}
```

---

## 第五部分：UI 层实现

### 5.1 SubscriptionView (主页面)

```swift
import SwiftUI

struct SubscriptionView: View {
    @StateObject private var iapManager = IAPManager.shared
    @State private var selectedTier: SubscriptionTier = .explorer
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // ========== 顶部：当前订阅状态 ==========
                CurrentSubscriptionCard(
                    tier: iapManager.subscriptionTier,
                    subscription: iapManager.activeSubscription
                )
                
                // ========== 中间：产品列表 ==========
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(iapManager.subscriptionProducts) { product in
                            SubscriptionCard(
                                product: product,
                                isCurrentPlan: iapManager.subscriptionTier == product.tier,
                                onPurchase: {
                                    Task {
                                        _ = await iapManager.purchaseSubscription(product)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // ========== 底部：权益对比表 ==========
                SubscriptionBenefitsView()
                
                // ========== 底部按钮 ==========
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await iapManager.restoreSubscriptions()
                        }
                    }) {
                        Label("恢复购买", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        iapManager.openSubscriptionManagement()
                    }) {
                        Label("管理订阅", systemImage: "gearshape.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("末日通行证")
        }
        .task {
            await iapManager.loadSubscriptionProducts()
            await iapManager.loadActiveSubscription()
        }
    }
}
```

### 5.2 SubscriptionCard (卡片组件)

```swift
struct SubscriptionCard: View {
    let product: SubscriptionProduct
    let isCurrentPlan: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题与标签
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    Text(product.period.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCurrentPlan {
                    Text("当前计划")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            // 价格
            HStack {
                Text("¥\(product.price.description)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("/\(product.period == .monthly ? "月" : "年")")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // 描述
            Text(product.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 购买按钮
            Button(action: onPurchase) {
                Text(isCurrentPlan ? "已订阅" : "立即订阅")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isCurrentPlan ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isCurrentPlan)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### 5.3 SubscriptionBenefitsView (权益对比)

```swift
struct SubscriptionBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("权益对比")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 1) {
                // 表头
                BenefitRow(
                    label: "权益项",
                    free: "免费",
                    explorer: "探索者",
                    lord: "领主"
                )
                .background(Color(.systemGray5))
                
                // 数据行
                BenefitRow(
                    label: "探索次数",
                    free: "10 次/天",
                    explorer: "无限",
                    lord: "无限"
                )
                
                BenefitRow(
                    label: "搜索范围",
                    free: "1 km",
                    explorer: "2 km",
                    lord: "2 km"
                )
                
                BenefitRow(
                    label: "背包容量",
                    free: "100 格",
                    explorer: "200 格",
                    lord: "300 格"
                )
                
                BenefitRow(
                    label: "建造速度",
                    free: "1x",
                    explorer: "2x",
                    lord: "2x"
                )
                
                BenefitRow(
                    label: "交易次数",
                    free: "10 次/天",
                    explorer: "无限",
                    lord: "无限"
                )
                
                BenefitRow(
                    label: "月度礼包",
                    free: "无",
                    explorer: "¥12",
                    lord: "¥18"
                )
            }
            .cornerRadius(8)
        }
        .padding()
    }
}

struct BenefitRow: View {
    let label: String
    let free: String
    let explorer: String
    let lord: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            VStack {
                Text(free)
                    .font(.caption)
            }
            .frame(width: 60)
            
            VStack {
                Text(explorer)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(width: 60)
            
            VStack {
                Text(lord)
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            .frame(width: 60)
        }
        .padding(8)
        .background(Color(.systemBackground))
    }
}
```

### 5.4 ProfileTabView 集成入口

在 Profile 标签页中添加订阅入口：

```swift
struct ProfileTabView: View {
    var body: some View {
        NavigationStack {
            List {
                // ========== 订阅卡片 ==========
                NavigationLink(destination: SubscriptionView()) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("末日通行证")
                                .font(.headline)
                            
                            Text("升级享受特权")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                // ... 其他项目
            }
        }
    }
}
```

---

## 第六部分：App Store Connect 配置

### 6.1 创建订阅组

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择应用 → App 内购买项目 → 订阅
3. 点击 `+` → 创建新订阅组

**配置**:
- 组名称: `末日通行证` (Apocalypse Pass)
- 参考名称: `earthlord_apocalypse_pass`

### 6.2 创建订阅产品（重要：按等级高到低排序）

| # | 产品名 | 产品 ID | 周期 | 价格 | 优先级 |
|---|--------|--------|------|------|-------|
| 1 | 领主-年付 | `com.earthlord.sub.lord.yearly` | 1 年 | ¥168 | 高 |
| 2 | 领主-月付 | `com.earthlord.sub.lord.monthly` | 1 月 | ¥25 | 中高 |
| 3 | 探索者-年付 | `com.earthlord.sub.explorer.yearly` | 1 年 | ¥88 | 中 |
| 4 | 探索者-月付 | `com.earthlord.sub.explorer.monthly` | 1 月 | ¥12 | 低 |

**重要**: 产品必须按价值高到低排序，这决定了升级/降级规则。

#### 6.2.1 创建每个产品的步骤

**对于每个产品**:

1. 输入产品 ID (e.g., `com.earthlord.sub.explorer.monthly`)
2. 选择周期 (1 个月 / 1 年)
3. 设置价格（¥12/25/88/168）
4. 启用试用期 (7 天免费)
5. 启用自动续费

### 6.3 本地化信息配置

**对每个产品**，在"显示名称和描述"中添加:

#### 探索者-月付

**显示名称** (35 字以内):
```
探索者通行证-月度订阅
首月仅需 7 天免费试用
```

**描述** (400 字):
```
解锁探索者权益，享受一个月的特权体验：

✨ 每日探索次数无限（免费仅 10 次）
🗺️ 废墟搜索范围扩大至 2 km（免费 1 km）
📦 背包容量提升至 200 格（免费 100 格）
⚡ 建造速度提升至 2 倍（免费 1 倍）
💰 每日交易次数无限（免费 10 次）
🎖️ 获得专属"探索者"徽章
🎁 每月获得 ¥12 价值物资

首月仅需 7 天免费试用，之后每月 ¥12。
随时可在 App Store 设置中取消。
```

#### 领主-年付

**显示名称**:
```
领主通行证-年度订阅
省省 44%，年仅需 ¥168
```

**描述**:
```
成为末世之主，享受一整年的VIP待遇：

✨ 所有探索者权益
🎖️ 升级为"领主"徽章
🎁 每月 ¥18 价值物资（额外 ¥6）
⏱️ VIP 客服优先响应
💎 专属玩家社群访问

年付 ¥168 = 月均 ¥14，相比月付 ¥12 更划算！
首年享受 7 天免费试用期。
每年自动续费，可随时取消。
```

### 6.4 沙盒测试账号配置

1. 用户和访问 → 沙盒 → 测试员
2. 点击 `+` 创建沙盒测试账号

**创建 3 个测试账号**:

| 账号 | 用途 | 邮箱例 |
|------|------|--------|
| 测试账号 1 | 新订阅 | `explorer-test@example.com` |
| 测试账号 2 | 升级测试 | `lord-test@example.com` |
| 测试账号 3 | 恢复测试 | `restore-test@example.com` |

**沙盒时间加速规则**:
```
实际周期 → 沙盒周期
1 周    → 3 分钟
1 个月  → 5 分钟
2 个月  → 10 分钟
1 年    → 1 小时
```

### 6.5 设置试用期

每个产品都应启用 7 天免费试用：

1. 编辑产品
2. 试用期 → 7 天
3. 保存

---

## 第七部分：沙盒测试完整指南

### 7.1 本地测试设置

#### 第一步: 签出 Xcode 中的沙盒账号

```
Settings > App Store > Sign Out
Settings > App Store > Sign In with Sandbox Account
输入测试邮箱: explorer-test@example.com
输入密码: 12345678
```

#### 第二步: 在线检查产品配置

确保以下条件都通过：
- [ ] 4 个产品都已在 App Store Connect 创建
- [ ] 产品 ID 与代码完全匹配
- [ ] 每个产品都有本地化信息
- [ ] 试用期设置为 7 天
- [ ] 订阅组已创建

### 7.2 测试场景与预期结果

#### 场景1️⃣: 新用户购买月度订阅

**操作步骤**:
1. 打开应用 → 末日通行证
2. 选择"探索者-月付" (¥12/月)
3. 点击"立即订阅"
4. 系统弹出支付窗口 → 确认购买

**预期结果** ✅ :
- ✅ 支付成功
- ✅ 显示当前：探索者通行证
- ✅ 显示到期日期（5 分钟后）
- ✅ 权益立即生效（背包 200 格，探索无限）

**常见问题**:
如果显示"剩余 0 天"：
```swift
// 这是沙盒特性，需要修改显示逻辑
// 见下一章节 7.3
```

#### 场景2️⃣: 升级到高等级订阅

**操作步骤**:
1. 已购买"探索者-月付"
2. 进入订阅界面
3. 选择"领主-月付" (¥25/月)
4. 点击"立即订阅"

**预期结果** ✅ :
- ✅ 计算差价，立即扣费
- ✅ 订阅等级升级为"领主"
- ✅ 新权益立即生效（背包 300 格）

#### 场景3️⃣: 自动续费测试

**操作步骤**:
1. 购买订阅后
2. 等待 5 分钟（沙盒时间加速）
3. 观察到期后的处理

**预期结果** ✅ :
- ✅ 到期后自动续费
- ✅ 显示新的到期日期
- ✅ 权益不中断

#### 场景4️⃣: 取消订阅

**操作步骤**:
1. 设置 > Apple ID > 订阅 > 末日通行证
2. 选择要取消的订阅
3. 点击"取消订阅"

**预期结果** ✅ :
- ✅ 显示"已取消"
- ✅ 继续享受至周期结束
- ✅ 过期后降级为免费

#### 场景5️⃣: 恢复购买

**操作步骤**:
1. 已购买订阅的设备
2. 删除应用 + 重新安装
3. 打开应用 → 末日通行证
4. 点击"恢复购买"

**预期结果** ✅ :
- ✅ 检查并恢复之前的订阅
- ✅ 显示"当前：探索者通行证"
- ✅ 权益恢复

---

### 7.3 常见问题排查

#### 问题1️⃣: 显示"剩余 0 天"

**现象**:
```
探索者通行证
到期时间: 2025-02-24
剩余: 0 天
```

**原因**:
- 沙盒环境月订阅只有 5 分钟有效期
- `remainingDays` 计算的是完整天数
- 同一天内到期 = 0 天

**解决方案**:
修改 `DBUserSubscription` 的 `remainingDays` 计算：

```swift
struct DBUserSubscription {
    // ❌ 旧方法：只计算完整天数
    /*
    var remainingDays: Int? {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expires_at).day
        return max(0, days ?? 0)
    }
    */
    
    // ✅ 新方法：向上取整 + 智能显示
    var remainingDays: Int? {
        guard expires_at > Date() else { return 0 }
        let remainingSeconds = expires_at.timeIntervalSince(Date())
        return max(1, Int(ceil(remainingSeconds / 86400)))  // 向上取整
    }
    
    // ✅ 新增：精确剩余时间（便于沙盒调试）
    var formattedRemainingTime: String {
        let remaining = expires_at.timeIntervalSince(Date())
        if remaining < 60 { return "剩余 \(Int(remaining)) 秒" }
        if remaining < 3600 { return "剩余 \(Int(remaining / 60)) 分钟" }
        if remaining < 86400 { return "剩余 \(Int(remaining / 3600)) 小时" }
        return "剩余 \(Int(ceil(remaining / 86400))) 天"
    }
}

// 在 SubscriptionCard 中使用精确时间显示
Text(iapManager.activeSubscription?.formattedRemainingTime ?? "已过期")
    .font(.caption)
    .foregroundColor(.red)
```

#### 问题2️⃣: 产品显示但无法购买

**检查清单**:
- [ ] Info.plist 中 SKAdNetworkItems 配置正确
- [ ] 产品 ID 与代码完全匹配
- [ ] 沙盒测试账号已登录
- [ ] 网络连接正常

**解决方案**:
```swift
// 在 loadSubscriptionProducts() 中添加日志
print("🔍 尝试加载产品: \(subscriptionProductIds)")
let products = try await Product.products(for: subscriptionProductIds)
print("✅ 成功加载 \(products.count) 个产品")

products.forEach { product in
    print("  - \(product.id): \(product.displayName) (\(product.price))")
}
```

#### 问题3️⃣: 清空 Xcode 缓存

```bash
# 清空 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 重置沙盒（可选）
xcrun simctl erase all

# 重新编译并测试
```

#### 问题4️⃣: 三元运算符类型不匹配

**错误**:
```swift
.background(isCurrentPlan ? Color.gray : LinearGradient(...))
// Error: 类型不兼容
```

**解决方案**:
```swift
// ❌ 错误方式
.background(isCurrentPlan ? Color.gray : LinearGradient(...))

// ✅ 正确方式 1: 使用 Group
.background(
    Group {
        if isCurrentPlan { Color.gray }
        else { LinearGradient(...) }
    }
)

// ✅ 正确方式 2: 统一为 Shape
.background(
    isCurrentPlan ? 
    AnyShapeStyle(Color.gray) :
    AnyShapeStyle(LinearGradient(...))
)
```

---

## 第八部分：完整开发检查清单

### 8.1 项目设置阶段

- [ ] 已配置 Apple ID 和开发团队
- [ ] Info.plist 中配置了 App Group ID
- [ ] 启用了 In-App Purchase capability

```xml
<!-- Info.plist 中的必要配置 -->
<key>SKAdNetworkItems</key>
<array/>  <!-- Apple 会自动填充 -->

<key>NSRequiresItunesStoreActions</key>
<false/>

<key>AppGroupIdentifier</key>
<string>group.com.earthlord.store</string>
```

### 8.2 代码实现阶段

- [ ] 创建 IAPModels.swift
  - [ ] SubscriptionTier 枚举
  - [ ] SubscriptionPeriod 枚举
  - [ ] SubscriptionProduct 结构体
  - [ ] DBUserSubscription 结构体
  - [ ] SubscriptionBenefits 权益配置
  - [ ] SubscriptionError 错误类型

- [ ] 创建/扩展 IAPManager.swift
  - [ ] 初始化与 Transaction 监听
  - [ ] loadSubscriptionProducts()
  - [ ] loadActiveSubscription()
  - [ ] purchaseSubscription()
  - [ ] handleSubscriptionTransaction()
  - [ ] restoreSubscriptions()
  - [ ] handleExpiredSubscription()

- [ ] 创建 UI 层
  - [ ] SubscriptionView.swift
  - [ ] SubscriptionCard.swift
  - [ ] SubscriptionBenefitsView.swift
  - [ ] ProfileTabView 中添加入口

- [ ] 权益系统集成
  - [ ] InventoryManager.maxCapacity
  - [ ] BuildingManager.buildSpeedMultiplier
  - [ ] ExplorationManager 集成
  - [ ] TradeManager 集成

### 8.3 数据库阶段

- [ ] 执行 Supabase 迁移
  - [ ] 创建 user_subscriptions 表
  - [ ] 创建 subscription_audit_log 表
  - [ ] 创建索引
  - [ ] 配置 RLS 策略

### 8.4 App Store Connect 配置

- [ ] 创建订阅组
  - [ ] 组名: "末日通行证"
  - [ ] 参考名: "earthlord_apocalypse_pass"

- [ ] 创建 4 个订阅产品
  - [ ] 领主-年付 (¥168，优先级最高)
  - [ ] 领主- 月付 (¥25)
  - [ ] 探索者-年付 (¥88)
  - [ ] 探索者-月付 (¥12，优先级最低)

- [ ] 配置每个产品
  - [ ] 设置周期（1 月 / 1 年）
  - [ ] 设置价格
  - [ ] 启用 7 天试用期
  - [ ] 添加本地化信息
  - [ ] 设置产品图标（可选）

- [ ] 创建沙盒测试账号
  - [ ] 至少 3 个测试账号

### 8.5 沙盒测试阶段

**使用 SubscriptionTestChecklist 进行检查**:

```swift
enum SubscriptionTestCase {
    case newPurchase        // 新用户购买
    case upgrade           // 升级订阅
    case autRenew          // 自动续费
    case cancelAndExpire   // 取消和过期
    case restore           // 恢复购买
    case networkError      // 网络错误处理
}
```

- [ ] 新用户购买月度订阅
  - [ ] 支付成功
  - [ ] 权益立即生效
  - [ ] 显示到期时间

- [ ] 升级到年度订阅
  - [ ] 差价计算正确
  - [ ] 权益升级

- [ ] 自动续费
  - [ ] 等待到期时间
  - [ ] 自动续费成功
  - [ ] 权益不中断

- [ ] 取消订阅
  - [ ] 在设置中可取消
  - [ ] 继续享受至周期结束
  - [ ] 过期后权益降级

- [ ] 恢复购买
  - [ ] 删除应用后恢复
  - [ ] 换设备后恢复

- [ ] 错误处理
  - [ ] 网络错误有提示
  - [ ] 支付失败有重试选项
  - [ ] 验证失败有降级方案

### 8.6 发布前准备

- [ ] 编译通过，无错误无警告
- [ ] 所有测试场景通过
- [ ] 隐私政策涵盖订阅条款
- [ ] 用户可随时取消订阅
- [ ] 数据库备份完整
- [ ] 版本号已更新

---

## 第九部分：数据库迁移执行

### 9.1 Supabase 迁移 SQL

```sql
-- ===== 创建用户订阅表 =====
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,                    -- App Store 产品 ID
    tier TEXT NOT NULL CHECK (tier IN ('free', 'explorer', 'lord')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'pending')),
    original_purchase_date TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_trial BOOLEAN DEFAULT false,
    auto_renew BOOLEAN DEFAULT true,
    transaction_id TEXT,
    environment TEXT DEFAULT 'production',       -- production/sandbox
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===== 创建索引优化查询 =====
CREATE INDEX idx_user_subscriptions_user_id 
    ON user_subscriptions(user_id);

CREATE INDEX idx_user_subscriptions_status_expires 
    ON user_subscriptions(status, expires_at);

CREATE INDEX idx_user_subscriptions_user_status 
    ON user_subscriptions(user_id, status);

-- ===== 行级安全策略 =====
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的订阅
CREATE POLICY "users_view_own_subscription" ON user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- 用户只能插入自己的订阅
CREATE POLICY "users_insert_own_subscription" ON user_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 只有 Service Role 才能更新（防止客户端篡改）
CREATE POLICY "service_role_update_subscription" ON user_subscriptions
    FOR UPDATE USING (false) WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ===== 创建审计日志表 =====
CREATE TABLE IF NOT EXISTS subscription_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('purchased', 'renewed', 'cancelled', 'expired', 'upgraded', 'downgraded')),
    old_tier TEXT,
    new_tier TEXT,
    transaction_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscription_audit_user_id 
    ON subscription_audit_log(user_id);

CREATE INDEX idx_subscription_audit_created 
    ON subscription_audit_log(created_at DESC);

-- ===== 自动时间戳更新触发器 =====
CREATE OR REPLACE FUNCTION update_user_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER update_subscription_timestamp
    BEFORE UPDATE on user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_subscription_timestamp();
```

### 9.2 执行迁移

#### 方式1: Supabase 仪表盘

1. 登录 [Supabase](https://supabase.com)
2. 选择项目 → SQL Editor
3. 创建新 Query → 粘贴上述 SQL
4. 点击运行

#### 方式2: Supabase CLI

```bash
# 创建迁移文件
supabase migration new create_subscription_tables

# 编辑 migrations/[timestamp]_create_subscription_tables.sql
# 粘贴上述 SQL

# 应用迁移
supabase migration up
```

---

## 第十部分：完整代码示例

### 10.1 最小可行产品 (MVP) 代码框架

```swift
// ============ 第一步：创建 IAPModels.swift ============

import Foundation

enum SubscriptionTier: String, Codable {
    case free, explorer, lord
}

struct SubscriptionBenefits {
    let backpackCapacity: Int
    let buildSpeedMultiplier: Double
    
    static let explorer = SubscriptionBenefits(
        backpackCapacity: 200,
        buildSpeedMultiplier: 2.0
    )
    
    static let lord = SubscriptionBenefits(
        backpackCapacity: 300,
        buildSpeedMultiplier: 2.0
    )
}

// ============ 第二步：扩展 InventoryManager ============

extension InventoryManager {
    var maxCapacity: Int {
        switch IAPManager.shared.subscriptionTier {
        case .free: return 100
        case .explorer: return 200
        case .lord: return 300
        }
    }
}

// ============ 第三步：创建订阅视图 ============

struct SubscriptionView: View {
    @StateObject private var iapManager = IAPManager.shared
    
    var body: some View {
        VStack {
            Text("当前: \(iapManager.subscriptionTier.rawValue)")
            
            Button("购买探索者") {
                // 购买逻辑
            }
        }
        .task {
            await iapManager.loadActiveSubscription()
        }
    }
}

// ============ 第四步：在 ProfileTab 中集成 ============

NavigationLink(destination: SubscriptionView()) {
    Text("末日通行证")
}
```

---

## 第十一部分：常见问题解答

### Q1: 试用期后为什么自动扣费?

**答**: 这是 Apple 的设计。如果用户在试用期内未取消，自动续费是默认行为。

**提示**:
```
// 在 UI 中明确提醒用户
Text("首个 7 天免费试用后，每月自动扣费")
    .foregroundColor(.red)
```

### Q2: 用户取消后还能享受权益吗?

**答**: 可以。用户取消后，权益继续有效到周期结束，然后自动降级为免费。

```
取消订阅时间: 2025-02-15
周期结束时间: 2025-03-15
└─ 2025-02-15 - 2025-03-15 仍享受权益
└─ 2025-03-15 自动降级为免费
```

### Q3: 如何处理试用期内取消的用户?

**答**: 在 handleExpiredSubscription 中添加逻辑：

```swift
if subscription.isTrial && subscription.status == "cancelled" {
    // 发送"挽留"文案通知
    NotificationCenter.default.post(name: NSNotification.Name("TrialCancelled"))
}
```

### Q4: 支付失败后如何重试?

**答**: 通过 Task 重试机制：

```swift
func purchaseWithRetry(_ product: SubscriptionProduct, maxRetries: Int = 3) async -> Bool {
    for attempt in 1...maxRetries {
        if await purchaseSubscription(product) {
            return true
        }
        print("⚠️ 第 \(attempt) 次购买失败，3 秒后重试...")
        try await Task.sleep(nanoseconds: 3_000_000_000)
    }
    return false
}
```

### Q5: 升级/降级如何计算差价?

**答**: 这由 App Store 自动处理。用户升级时，系统会计算比例差价。

---

## 第十二部分：发布与优化

### 12.1 提交 App Store 审核

1. 编译版本 → Product > Archive
2. V Organizer > Distribute App
3. App Store Connect 上传
4. 填写发布说明，提交审核

**发布说明示例**:
```
v2.0 新增

新功能：
- 推出"末日通行证"订阅系统
- 3 个等级权益（探索者/领主/VIP）
- 灵活的月度/年度计划

改进：
- 订阅用户享受 2 倍建造速度
- 背包容量提升至 300 格
- 专属社群访问权限
```

### 12.2 上线后的监控指标

| 指标 | 计算方式 | 目标 |
|------|--------|------|
| **转化率** | (新订阅用户 / DAU) × 100% | > 5% |
| **留存率** | 续费用户 / 新订阅用户 | > 80% |
| **ARPPU** | 月度收入 / 月活用户 | > ¥5 |
| **LTV** | 平均用户生命周期价值 | > ¥50 |

### 12.3 优化建议

**第 1 个月**: 监控基线数据  
**第 2 个月**: A/B 测试价格  
**第 3 个月**: 优化推荐位置  
**第 4+ 个月**: 增加高端产品或组合套餐  

---

## 总结与下一步

### ✅ 完成的里程碑

- ✅ 订阅方案设计（2 个等级 × 2 个周期）
- ✅ 技术架构设计（IAPManager + 权益系统）
- ✅ 数据库迁移（user_subscriptions 表）
- ✅ UI 层实现（SubscriptionView + 卡片组件）
- ✅ App Store Connect 配置指南
- ✅ 沙盒测试完整清单
- ✅ 常见问题排查

### 📋 立即可执行的步骤

1. **第 1 天**: 在 App Store Connect 创建 4 个订阅产品
2. **第 2 天**: 执行 Supabase 数据库迁移
3. **第 3 天**: 实现 IAPManager 代码
4. **第 4 天**: 创建订阅 UI 视图
5. **第 5 天**: 进行沙盒测试（8 个测试场景）
6. **第 6 天**: 修复问题并重新测试
7. **第 7 天**: 提交 App Store 审核

### 🎯 预期成果

- 🎮 完整的订阅系统
- 💰 稳定的月度收入
- 👥 提升 LTV 和用户留存
- 📊 可量化的商业指标

---

**课程来源**: AI Vibe Coding 第八周  
**最后更新**: 2025 年 2 月  
**版本**: 1.0 完整版

祝开发顺利！🚀
