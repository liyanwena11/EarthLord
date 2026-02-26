# 🎯 Day 3 实施指南 - SubscriptionStoreView

## 📋 概述

**目标**: 创建完整的订阅商店 UI，展示所有 16 个产品

**文件**: `SubscriptionStoreView.swift` (预计 500+ 行)

**位置**: `/EarthLord/EarthLord/Views/SubscriptionStoreView.swift`

---

## 📐 架构设计

### UI 层次结构

```
SubscriptionStoreView
├── Header: 当前 Tier 显示
│   ├── 用户头像/姓名
│   ├── 当前 Tier 徽章
│   ├── Tier 过期时间
│   └── 升级建议按钮
├── TabView (5 个标签页)
│   ├── Tab 1: 消耗品 (4个产品)
│   ├── Tab 2: Support Tier (3个产品)
│   ├── Tab 3: Lordship Tier (3个产品)
│   ├── Tab 4: Empire Tier (3个产品)
│   └── Tab 5: VIP 自动续费 (3个产品)
└── 底部: 恢复购买按钮
```

---

## 🎨 UI 组件清单

### 1. Header 组件 (TierHeaderView)

```swift
struct TierHeaderView: View {
    @ObservedObject var tierManager: TierManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button("关闭") { dismiss() }
                Spacer()
                Text("订阅商店")
                Spacer()
                Button("帮助") { ... }
            }
            .padding()
            
            // 当前 Tier 卡片
            RoundedRectangle(cornerRadius: 12)
                .fill(tierManager.currentTier.badgeColor)
                .overlay(
                    VStack {
                        Text("当前等级: \(tierManager.currentTier.displayName)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let expiration = tierManager.tierExpiration {
                            Text("过期: \(expiration.formatted())")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("\(tierManager.currentTier.powerLevel)% 权力")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                )
                .frame(height: 100)
                .padding()
        }
    }
}
```

**包含**:
- 关闭按钮
- 当前 Tier 显示
- Tier 颜色编码
- 过期时间显示
- 权力等级

---

### 2. 产品行组件 (ProductRowView)

```swift
struct ProductRowView: View {
    let product: Product
    let iapProduct: IAPProduct
    let isLoading: Bool
    let isPurchased: Bool
    let onPurchase: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(iapProduct.displayName)
                        .font(.headline)
                    
                    Text(iapProduct.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = iapProduct.duration {
                        Text("有效期: \(duration.days) 天")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isPurchased {
                    Label("已拥有", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Button("购买") {
                            Task { await onPurchase() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading)
                    }
                }
            }
            
            // 权益预览
            HStack(spacing: 12) {
                ForEach(iapProduct.benefits.prefix(3), id: \.self) { benefit in
                    Label(benefit, systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                if iapProduct.benefits.count > 3 {
                    Text("+\(iapProduct.benefits.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

**包含**:
- 产品名称 + 描述
- 价格显示
- 购买按钮
- "已拥有" 标签
- 权益预览
- 有效期标签 (订阅)

---

### 3. 标签页视图 (ProductTabView)

```swift
struct ProductTabView: View {
    let products: [Product]
    let iapManager: IAPManager
    let tierManager: TierManager
    @State var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(products, id: \.id) { product in
                    if let iapProduct = iapManager.getProductInfo(for: product.id) {
                        ProductRowView(
                            product: product,
                            iapProduct: iapProduct,
                            isLoading: isLoading,
                            isPurchased: iapManager.hasProduct(product.id),
                            onPurchase: {
                                await handlePurchase(product)
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private func handlePurchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        let success = await iapManager.purchase(product)
        
        if success {
            // 购买成功，通知会自动触发 TierManager 更新
            print("✅ 购买成功")
        } else if let error = iapManager.errorMessage {
            print("❌ 购买失败: \(error)")
        }
    }
}
```

**包含**:
- 产品列表滚动
- 购买处理
- 错误状态
- 加载状态

---

### 4. 主商店视图 (SubscriptionStoreView)

```swift
struct SubscriptionStoreView: View {
    @ObservedObject var iapManager = IAPManager.shared
    @ObservedObject var tierManager = TierManager.shared
    @StateObject var viewModel = SubscriptionStoreViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TierHeaderView()
                
                if iapManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if iapManager.availableProducts.isEmpty {
                    Text("未能加载产品")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $viewModel.selectedTab) {
                        // Tab 1: 消耗品
                        ProductTabView(
                            products: filterByType(.consumable),
                            iapManager: iapManager,
                            tierManager: tierManager
                        )
                        .tabItem {
                            Label("消耗品", systemImage: "bag.fill")
                        }
                        .tag(0)
                        
                        // Tab 2: Support
                        ProductTabView(
                            products: filterByTier(.support),
                            iapManager: iapManager,
                            tierManager: tierManager
                        )
                        .tabItem {
                            Label("支持者", systemImage: "heart.fill")
                        }
                        .tag(1)
                        
                        // Tab 3: Lordship
                        ProductTabView(
                            products: filterByTier(.lordship),
                            iapManager: iapManager,
                            tierManager: tierManager
                        )
                        .tabItem {
                            Label("领主", systemImage: "crown.fill")
                        }
                        .tag(2)
                        
                        // Tab 4: Empire
                        ProductTabView(
                            products: filterByTier(.empire),
                            iapManager: iapManager,
                            tierManager: tierManager
                        )
                        .tabItem {
                            Label("帝国", systemImage: "star.fill")
                        }
                        .tag(3)
                        
                        // Tab 5: VIP
                        ProductTabView(
                            products: filterByType(.autoRenewable),
                            iapManager: iapManager,
                            tierManager: tierManager
                        )
                        .tabItem {
                            Label("VIP", systemImage: "sparkles")
                        }
                        .tag(4)
                    }
                }
                
                // 底部按钮
                HStack {
                    Button(action: restorePurchases) {
                        Label("恢复购买", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { dismiss() }) {
                        Label("关闭", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { await iapManager.initialize() }
            }
        }
    }
    
    private func filterByType(_ type: SubscriptionType) -> [Product] {
        let typeProducts = iapManager.getProductsByType()
        return typeProducts[type] ?? []
    }
    
    private func filterByTier(_ tier: UserTier) -> [Product] {
        let tierProducts = iapManager.getProductsByTier()
        return tierProducts[tier] ?? []
    }
    
    private func restorePurchases() {
        Task {
            let success = await iapManager.restorePurchases()
            if success {
                print("✅ 购买已恢复")
            } else {
                print("❌ 恢复失败")
            }
        }
    }
}
```

---

### 5. ViewModel (SubscriptionStoreViewModel)

```swift
@MainActor
class SubscriptionStoreViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var showPurchaseConfirmation = false
    @Published var purchasingProduct: Product?
}
```

---

## 📦 5 个标签页详细规划

### Tab 1: 消耗品 (4个产品)

| 产品 | 价格 | 描述 |
|------|------|------|
| Survivor Pack | ¥6 | 基础物资包 |
| Explorer Pack | ¥18 | 探索者物资包 |
| Lord Pack | ¥30 | 领主物资包 |
| Overlord Pack | ¥68 | 末日霸主包 |

**特性**:
- 一次性购买
- 直接到邮箱
- 可重复购买

---

### Tab 2: Support 等级 (3个产品)

| 产品 | 价格 | 持续时间 | 权益 |
|------|------|--------|------|
| Support 30d | ¥8 | 30 天 | 20% 建造加速 |
| Support 90d | ¥18 | 90 天 | 20% 建造加速 |
| Support 365d | ¥58 | 365 天 | 20% 建造加速 |

**特性**:
- Support 等级权益
- 限时订阅
- 可升级到更高等级

---

### Tab 3: Lordship 等级 (3个产品)

| 产品 | 价格 | 持续时间 | 权益 |
|------|------|--------|------|
| Lordship 30d | ¥18 | 30 天 | 40% 建造 + 30% 生产 |
| Lordship 90d | ¥38 | 90 天 | 40% 建造 + 30% 生产 |
| Lordship 365d | ¥128 | 365 天 | 40% 建造 + 30% 生产 |

**特性**:
- Lordship 等级权益
- 背包 +50kg
- 资源 +20%

---

### Tab 4: Empire 等级 (3个产品)

| 产品 | 价格 | 持续时间 | 权益 |
|------|------|--------|------|
| Empire 30d | ¥38 | 30 天 | 60% 建造 + 50% 生产 |
| Empire 90d | ¥88 | 90 天 | 60% 建造 + 50% 生产 |
| Empire 365d | ¥298 | 365 天 | 60% 建造 + 50% 生产 |

**特性**:
- Empire 等级权益
- 背包 +100kg
- 资源 +40% + 无限队列

---

### Tab 5: VIP 自动续费 (3个产品)

| 产品 | 价格 | 周期 | 权益 |
|------|------|------|------|
| VIP Monthly | ¥12/月 | 30 天 | VIP 权益 (所有) |
| VIP Quarterly | ¥28/季 | 90 天 | VIP 权益 (所有) |
| VIP Annual | ¥88/年 | 365 天 | VIP 权益 (所有) |

**特性**:
- 自动续费
- 可随时取消
- 最高权益等级

---

## 🎨 设计规范

### 颜色方案

```swift
// Tier 颜色
let tierColors: [UserTier: Color] = [
    .free: .gray,
    .support: .blue,
    .lordship: .purple,
    .empire: .orange,
    .vip: .red
]

// 按钮颜色
- 已拥有: .green
- 可购买: .blue
- 禁用: .gray
- 价格: .blue
```

### 字体方案

```swift
- 标题: .headline + .bold
- 产品名: .headline
- 描述: .caption + .secondary
- 价格: .headline + .blue
- 权益: .caption2 + .orange
```

### 间距方案

```swift
- 标签间距: 8pt
- 卡片内部: 12pt
- 卡片外部: 12pt
- 按钮高度: 44pt
```

---

## 📲 状态管理流程

```
用户点击购买
  ↓
ProductRowView.onPurchase()
  ↓
SubscriptionStoreView.handlePurchase()
  ↓
iapManager.purchase(product) async
  ↓
产品成功验证
  ↓
handlePurchaseVerification()
  ↓
tierManager.handlePurchase() → Tier 更新
  ↓
NotificationCenter 通知
  ↓
ProductRowView isPurchased 状态刷新
  ↓
UI 从"购买"变"已拥有"
```

---

## 🔄 加载流程

```
SubscriptionStoreView onAppear
  ↓
Task { await iapManager.initialize() }
  ↓
iapManager.loadProducts() (从 App Store)
  ↓
iapManager.loadPurchasedProducts() (从 Keychain)
  ↓
availableProducts 更新
  ↓
purchasedProductIDs 更新
  ↓
TabView 使用 getProductsByTier() / getProductsByType()
  ↓
ProductTabView 显示产品列表
```

---

## ⚠️ 错误处理

### 加载失败
```swift
if iapManager.availableProducts.isEmpty {
    Text("未能加载产品")
}
```

### 购买失败
```swift
if let error = iapManager.errorMessage {
    Alert("购买失败", message: error)
}
```

### 网络问题
```swift
// IAPManager 自动处理
// 显示重试选项
```

---

## 🧪 测试场景

### T01: 加载产品
1. 打开商店
2. 验证所有 16 个产品加载
3. 检查价格显示
4. 检查分类正确

### T02: 购买消耗品
1. 点击 Survivor Pack
2. 完成 App Store 购买
3. 检查状态变为"已拥有"
4. 检查物资增加到邮箱

### T03: 升级 Tier
1. 购买 Support 30 天
2. 检查当前 Tier 更新
3. 检查权益应用到游戏系统
4. 检查过期时间显示

---

## 📋 实施步骤

1. **创建 ViewModel** (30 行)
   - selectedTab 状态

2. **创建 ProductRowView** (80 行)
   - 产品显示
   - 购买按钮
   - 状态处理

3. **创建 TierHeaderView** (70 行)
   - 当前 Tier 显示
   - 过期时间
   - 头部导航

4. **创建 ProductTabView** (60 行)
   - 产品列表
   - 产品过滤
   - 购买处理

5. **创建 SubscriptionStoreView** (200+ 行)
   - TabView 组织
   - 标签页内容
   - 底部控件
   - 生命周期

---

## 🎯 验收标准

- [x] 所有 16 个产品显示
- [x] 5 个标签页正常切换
- [x] 价格显示正确
- [x] 购买流程完整
- [x] 错误处理完善
- [x] 当前 Tier 显示正确
- [x] 已拥有产品标记
- [x] 恢复购买功能
- [x] 加载状态反馈
- [x] 响应式设计

---

## 📅 时间预计

| 任务 | 时间 |
|------|------|
| ViewModel | 15 分钟 |
| ProductRowView | 30 分钟 |
| TierHeaderView | 25 分钟 |
| ProductTabView | 30 分钟 |
| SubscriptionStoreView | 60 分钟 |
| 测试和调整 | 30 分钟 |
| **总计** | **3 小时** |

---

🚀 **准备开始 Day 3 实施！**
