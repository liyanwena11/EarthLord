# 🧠 SubscriptionStoreView 快速参考

## 📍 文件位置
`/EarthLord/Views/Shop/SubscriptionStoreView.swift` (515 行)

---

## 🔧 如何使用

### 1. 打开订阅商店
```swift
@State private var showSubscriptionStore = false

// 在适当的地方
Button("打开商店") {
    showSubscriptionStore = true
}
.sheet(isPresented: $showSubscriptionStore) {
    SubscriptionStoreView()
}
```

### 2. 在导航中使用
```swift
NavigationLink("订阅商店", destination: SubscriptionStoreView())
```

---

## 🎨 5 个标签页

| 标签 | 产品类型 | 产品数 | 用途 |
|------|---------|--------|------|
| 消耗品 | 一次性购买 | 4 | 物资包 |
| 支持者 | Support Tier | 3 | 20% 加速 |
| 领主 | Lordship Tier | 3 | 40% 加速 |
| 帝国 | Empire Tier | 3 | 60% 加速 |
| VIP | 自动续费 | 3 | 最高权益 |

---

## 🔌 集成的管理器

### IAPManager
- `shared` - 单例访问
- `initialize()` - 加载产品
- `purchase(product)` - 购买
- `restorePurchases()` - 恢复

### TierManager
- `shared` - 单例访问
- `currentTier` - 当前等级
- `tierExpiration` - 过期时间

---

## ⚙️ 状态流

### 加载流程
```
onAppear
  ↓
iapManager.initialize()
  ↓
加载产品列表
  ↓
更新 availableProducts
```

### 购买流程
```
点击购买
  ↓
handlePurchase(product)
  ↓
iapManager.purchase()
  ↓
显示结果警告
```

### 恢复流程
```
点击恢复购买
  ↓
restorePurchases()
  ↓
iapManager.restorePurchases()
  ↓
显示结果警告
```

---

## 🎯 自定义

### 改变标签页顺序
编辑 SubscriptionStoreView 中的 TabView：
```swift
TabView(selection: $viewModel.selectedTab) {
    // 改变这里的顺序
    ProductTabView(...).tag(0)  // 第一个
    ProductTabView(...).tag(1)  // 第二个
    // ...
}
```

### 添加新的过滤器
```swift
private func getCustomProducts() -> [Product] {
    let products = iapManager.getProductsByType()
    return /* 自定义过滤 */
}
```

### 修改购买后的消息
```swift
private func handlePurchase(_ product: Product) async {
    // ... 在这里修改 alertMessage
}
```

---

## 🐛 调试

### 打印调试信息
```swift
// 在 handlePurchase 中
iapManager.printDebugInfo()

// 在任何 Task 中
print("选中标签: \(viewModel.selectedTab)")
```

### 检查 Tier 信息
```swift
print("当前 Tier: \(tierManager.currentTier.displayName)")
print("权力等级: \(tierManager.currentTier.powerLevel)")
print("过期时间: \(String(describing: tierManager.tierExpiration))")
```

### 重置管理器
```swift
Button("重置") {
    iapManager.resetManager()
}
```

---

## ⚠️ 常见问题

### Q: 为什么看不到产品？
A: 检查：
1. IAPManager.shared.availableProducts 是否为空
2. App Store 配置是否正确
3. 网络连接是否正常

### Q: 购买按钮不工作？
A: 检查：
1. 是否使用 Sandbox 账户
2. 产品 ID 是否匹配 All16Products
3. 查看控制台日志

### Q: Tier 没有更新？
A: 检查：
1. TierManager.shared 是否存在
2. 购买是否成功
3. tierManager.handlePurchase() 是否被调用

---

## 📱 响应式设计

- ✅ 适配所有屏幕大小
- ✅ TabView 自动适应
- ✅ 产品卡片自动调整
- ✅ 文字大小自适应

---

## 🔐 安全性

- ✅ @MainActor 确保线程安全
- ✅ 错误完整处理
- ✅ 异步操作正确管理
- ✅ 无敏感信息泄露

---

## 📊 性能

- 轻量级视图组件
- 高效的列表渲染
- 最小化重新计算
- 适当的内存管理

---

## 🎓 关键代码片段

### 获取消耗品列表
```swift
private func getConsumableProducts() -> [Product] {
    let typeProducts = iapManager.getProductsByType()
    return (typeProducts[.consumable] ?? [])
}
```

### 获取 Tier 产品
```swift
private func getTierProducts(_ tier: UserTier) -> [Product] {
    let tierProducts = iapManager.getProductsByTier()
    return (tierProducts[tier] ?? [])
}
```

### 处理购买结果
```swift
if success {
    alertTitle = "购买成功"
    alertMessage = "感谢您的购买！"
} else {
    alertTitle = "购买失败"
    alertMessage = iapManager.errorMessage ?? "未知错误"
}
```

---

## 🚀 后续修改

### 添加购买历史显示
在 TierHeaderView 下方添加最近购买列表

### 添加促销信息
在 ProductRowView 上方添加折扣标签

### 添加 FAQ 弹出窗口
点击帮助按钮显示 FAQ

### 添加评价和评论
在产品卡片中添加星级和评价数

---

✅ **SubscriptionStoreView 已完全准备好使用！**
