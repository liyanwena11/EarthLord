# EarthLord - App Store IAP 快速实施指南

**目标**: 在 App Store Connect 上配置所有订阅产品  
**预计时间**: 1-2小时  
**难度**: ⭐⭐ (中等)

---

## 🚀 快速启动清单

### Step 1: 准备产品信息 (5分钟)

在 App Store Connect 中需要创建的产品：

#### 现有产品 ✅ (已在StoreManager中定义)
```
1. 幸存者补给包   com.earthlord.supply.survivor    ¥6
2. 探险家补给包   com.earthlord.supply.explorer    ¥18
3. 领主补给包     com.earthlord.supply.lord        ¥30
4. 霸主补给包     com.earthlord.supply.overlord    ¥68
```

#### 新增产品 🆕 (待配置)

**非续期订阅 - 战术支援包**
```
5. 战术支援-月度    com.earthlord.tactical.1m       ¥8    [30天]
6. 战术支援-季度    com.earthlord.tactical.3m       ¥18   [90天]
7. 战术支援-年度    com.earthlord.tactical.1y       ¥58   [365天]
```

**非续期订阅 - 领主特权包**
```
8. 领主特权-月度    com.earthlord.lordship.1m       ¥18   [30天]
9. 领主特权-季度    com.earthlord.lordship.3m       ¥38   [90天]
10. 领主特权-年度   com.earthlord.lordship.1y       ¥128  [365天]
```

**自动续期订阅 - VIP会员**
```
11. VIP月会员      com.earthlord.vip.monthly       ¥12/月
12. VIP月试用      com.earthlord.vip.trial         ¥6/月 (首月)
13. VIP季会员      com.earthlord.vip.quarterly     ¥28/季
14. VIP年会员      com.earthlord.vip.annual        ¥88/年
```

---

### Step 2: 登录 App Store Connect (5分钟)

1. 访问 https://appstoreconnect.apple.com
2. 用Apple ID登录
3. 选择 "我的App" → "EarthLord" (末世领主)
4. 侧边栏选择 "App 内购买项目"

---

### Step 3: 上传补给包产品 (20分钟)

#### 3.1 查看已创建的产品

应该已经有4个补给包存在。如果没有，需要逐个创建：

**步骤**:
```
1. 点击 "创建新的 App 内购买项目"
2. 选择类型 → "消耗性"
3. 填写产品信息
```

**示例配置 - 幸存者补给包**:

| 字段 | 值 |
|------|-----|
| **产品 ID** | com.earthlord.supply.survivor |
| **类型** | 消耗性 |
| **参考名称** | 幸存者补给包 |
| **价格等级** | ¥6 RMB Tier |
| **多语言名称 (中文)** | 幸存者补给包 |
| **多语言描述 (中文)** | 包含基础生存物资：矿泉水10瓶、罐头5罐、木材30单位、石头20单位。在紧急时刻解决燃眉之急！ |
| **屏幕截图** | [准备配图] |

---

### Step 4: 创建非续期订阅产品 (30分钟)

#### 4.1 创建战术支援-月度

```
1. 点击"创建新的 App 内购买项目"
2. 选择类型 → "非续期订阅"
3. 填写信息
```

**配置示例**:

| 字段 | 值 |
|------|-----|
| **产品 ID** | com.earthlord.tactical.1m |
| **类型** | 非续期订阅 |
| **参考名称** | 战术支援包-30天 |
| **价格等级** | ¥8 RMB Tier |
| **订阅期限** | 其他 → 30 天 |
| **名称 (中文)** | 战术支援包 |
| **描述 (中文)** | **30天会员特权** - 建造时间减少20%，生产周期减少15%，背包容量+25kg，每日登录奖励500资源币，VIP商店额外10%折扣，每天3次免费传送到收藏地点。 |

#### 4.2 复制创建其他战术支援商品

重复上述步骤，创建：
- `com.earthlord.tactical.3m` (¥18, 90天)
- `com.earthlord.tactical.1y` (¥58, 365天)

#### 4.3 创建领主特权包系列

同样流程，创建：
- `com.earthlord.lordship.1m` (¥18, 30天)
- `com.earthlord.lordship.3m` (¥38, 90天)
- `com.earthlord.lordship.1y` (¥128, 365天)

**描述示例**:
```
**30天领主特权** - 包含战术支援所有权益，
另外还有：建造时间减少40%，生产周期减少30%，
所有资源产出+20%，背包容量+50kg，每周限定挑战，
VIP名牌效果，VIP专属商店额外20%折扣，建造优先权。
```

---

### Step 5: 创建自动续期订阅 - VIP会员 (40分钟)

#### 5.1 创建VIP月会员

```
1. 点击"创建新的 App 内购买项目"
2. 选择类型 → "自动续期订阅"
3. 创建订阅组 (如果还没有)
```

**第一步：创建订阅组**

| 字段 | 值 |
|------|-----|
| **参考名称** | VIP会员 |
| **订阅组 ID** | com.earthlord.vip |
| **显示名称** | VIP会员 |

**第二步：在组内创建月会员**

| 字段 | 值 |
|------|-----|
| **产品 ID** | com.earthlord.vip.monthly |
| **参考名称** | VIP月会员 |
| **显示名称** | VIP月会员 |
| **价格等级** | ¥12 RMB Tier |
| **订阅时长** | 1 个月 |
| **名称 (中文)** | VIP月会员 |
| **描述 (中文)** | 自动续期订阅 ¥12/月。包含战术支援所有权益 + 每月¥20补给券 + 月度排行榜参赛 + 会员社区访问权限。 |

#### 5.2 创建首月试用版本

在同一订阅组中创建试用产品：

| 字段 | 值 |
|------|-----|
| **产品 ID** | com.earthlord.vip.trial |
| **参考名称** | VIP月会员-试用 |
| **显示名称** | VIP月会员(首月试用) |
| **价格等级** | ¥6 RMB Tier |
| **试用期** | 7 天 + 1 个月 (或直接配置为首月半价) |
| **名称 (中文)** | VIP月会员 |
| **描述 (中文)** | **首月优惠 ¥6** - 首月后自动降价至 ¥12/月。 |

#### 5.3 创建季度和年度会员

在同一 `com.earthlord.vip` 组内创建：

**季度会员**:
- 产品 ID: `com.earthlord.vip.quarterly`
- 价格: ¥28 (3个月)
- 描述: 自动续期订阅 ¥28/季。每月折合¥9.3，比月会员便宜22%...

**年度会员**:
- 产品 ID: `com.earthlord.vip.annual`
- 价格: ¥88 (12个月)
- 描述: 自动续期订阅 ¥88/年。每月折合¥7.3，比月会员便宜39%...

---

### Step 6: 配置营销图片 (15分钟)

为每个产品添加屏幕截图：

#### 推荐设计清单

| 产品 | 屏幕截图建议 |
|------|------------|
| **补给包** | 物资内容展示、叠加对比、推荐角标 |
| **战术支援** | 加速效果演示、权益清单、对比表格 |
| **VIP会员** | 会员等级展示、权益详解、社区功能、续费价格 |

**推荐工具**: Figma / 简图 / 在线设计工具

**规格**:
- 分辨率: 1242 x 2208 px (iPhone)
- 格式: PNG / JPG
- 数量: 1-5 张

---

### Step 7: 配置游戏内推荐页面 (30分钟 编码)

#### 7.1 更新 StoreManager.swift

在Xcode中更新现有的商店管理器：

```swift
// 添加新的订阅产品ID定义
enum SubscriptionType: String, CaseIterable {
    // 战术支援包
    case tactical1m = "com.earthlord.tactical.1m"
    case tactical3m = "com.earthlord.tactical.3m"
    case tactical1y = "com.earthlord.tactical.1y"
    
    // VIP会员
    case vipMonthly = "com.earthlord.vip.monthly"
    case vipQuarterly = "com.earthlord.vip.quarterly"
    case vipAnnual = "com.earthlord.vip.annual"
}

// 创建订阅产品展示模型
let subscriptionProducts = [
    SubscriptionProduct(
        id: .tactical1m,
        name: "战术支援包",
        duration: "30天",
        price: "¥8",
        benefits: ["建造-20%", "生产-15%", "背包+25kg", "每日奖励"],
        highlight: "入门必选"
    ),
    // ... 其他产品
]
```

#### 7.2 创建订阅展示 UI

```swift
// 在 ShopView 中添加订阅栏目
struct SubscriptionShowcase: View {
    let products: [SubscriptionProduct]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("会员特权").font(.headline)
            
            ForEach(products) { product in
                SubscriptionCard(product: product)
                    .onTapGesture {
                        // 触发购买流程
                        Task {
                            await purchaseSubscription(product.id)
                        }
                    }
            }
        }
    }
}
```

---

### Step 8: 本地测试 (20分钟)

#### 8.1 配置测试用户

1. App Store Connect → 用户和角色 → 沙盒技术人员
2. 创建测试账户：
   - 邮箱: `tester+001@example.com`
   - 密码: 设置安全密码
   - 年龄设置: 18+

#### 8.2 在真机上测试

```
1. iPhone/iPad 登出真实 Apple ID
2. 进入设置 → [顶部ID] → Media & Purchases
3. 登出，选择"使用现有 Apple ID" → 输入测试账户
4. 运行App，进入商店
5. 尝试购买，验证流程是否正常
6. 检查沙盒状态下的交易记录
```

#### 8.3 验证项

- [ ] 产品显示正确
- [ ] 价格显示正确 (¥标记)
- [ ] 购买按钮响应
- [ ] 购买完成后显示成功
- [ ] 验证收据 (Receipt validation)

---

### Step 9: 准备审核资料 (10分钟)

App Store 审核需要：

#### 9.1 隐私政策

更新 `Localizable.xcstrings` 或在 Info.plist 中配置：

```
隐私政策 URL: https://你的域名/privacy.html
```

**需要说明**:
```
1. 我们收集哪些数据 (用户ID、购买历史等)
2. 如何使用这些数据 (游戏内验证、统计分析)
3. 数据保护措施 (加密、安全存储)
4. 用户权利 (访问、删除、导出)
```

#### 9.2 服务条款

```
服务条款 URL: https://你的域名/terms.html
```

**需要说明**:
```
1. 订阅自动续期政策
2. 取消订阅方式
3. 退款政策
4. 用户责任
```

#### 9.3 应用内界面

在应用内需要有以下说明：

```swift
// 在商店页面底部添加常见问题解答
let faqList = [
    FAQ("如何取消订阅?", "https://support.apple.com/zh-cn/HT202039"),
    FAQ("为什么自动扣费?", "订阅会在账户自动续费..."),
    FAQ("如何申请退款?", "https://reportaproblem.apple.com"),
]
```

---

### Step 10: 提交审核 (5分钟)

#### 10.1 App Store Connect 中的提交

1. 版本号增加 (e.g., 1.0 → 1.1)
2. 发布说明添加字样：

```
- 新增 VIP 会员系统，提供游戏加速和独占权益
- 新增非续期订阅选项
- 优化商店界面
```

3. 检查所有价格等级
4. 上传新的屏幕截图
5. 点击 "提交以供审核"

#### 10.2 审核预期

- **第一次审核**: 通常 24-48 小时
- **如有问题**: Apple 会发送反馈邮件
- **常见问题**: 缺少取消方式、价格不清楚

---

## 📋 产品配置对照表

为快速查阅，完整产品信息：

```
┌─────────────────────────────────────────────────────┐
│          现有产品 (消耗性)  ✅                       │
├─────────────────────────────────────────────────────┤
│ 1. com.earthlord.supply.survivor      ¥6    [新手]  │
│ 2. com.earthlord.supply.explorer      ¥18   [中坚]  │
│ 3. com.earthlord.supply.lord          ¥30   [核心]  │
│ 4. com.earthlord.supply.overlord      ¥68   [重度]  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│     新增产品 (非续期订阅) 🆕 待配置                 │
├─────────────────────────────────────────────────────┤
│ 5. com.earthlord.tactical.1m         ¥8    [30天]   │
│ 6. com.earthlord.tactical.3m         ¥18   [90天]   │
│ 7. com.earthlord.tactical.1y         ¥58   [365天]  │
│                                                       │
│ 8. com.earthlord.lordship.1m         ¥18   [30天]   │
│ 9. com.earthlord.lordship.3m         ¥38   [90天]   │
│ 10. com.earthlord.lordship.1y        ¥128  [365天]  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│   新增产品 (自动续期订阅) 🆕 待配置                 │
├─────────────────────────────────────────────────────┤
│ 11. com.earthlord.vip.trial          ¥6    [首月]   │
│ 12. com.earthlord.vip.monthly        ¥12   [每月]   │
│ 13. com.earthlord.vip.quarterly      ¥28   [每季]   │
│ 14. com.earthlord.vip.annual         ¥88   [每年]   │
└─────────────────────────────────────────────────────┘
```

---

## ✅ 验收清单

### 配置完成标志

- [ ] 所有14个产品在 App Store Connect 中创建完毕
- [ ] 每个产品都有中文名称和描述
- [ ] 所有产品都有价格等级设置
- [ ] 上传了宣传图片和屏幕截图
- [ ] 配置了隐私政策和服务条款链接
- [ ] 更新了 StoreManager.swift (新增订阅类型)
- [ ] 创建了订阅展示 UI 界面
- [ ] 使用沙盒账户进行了端到端测试
- [ ] 验证了收据验证流程
- [ ] 准备好了审核资料

### 预计完成时间

| 环节 | 时间 |
|------|------|
| Step 1-7 (App Store Connect配置) | 2 小时 |
| Step 8 (代码集成) | 1 小时 |
| Step 9 (本地测试) | 1 小时 |
| Step 10 (准备审核) | 0.5 小时 |
| **总计** | **4.5 小时** |

---

## 🎯 后续优化方向

### 短期 (第1-2周)
- 监测各产品的转化率
- 收集用户反馈
- 优化推荐文案

### 中期 (第3-4周)
- A/B 测试定价
- 尝试首月 50% 折扣
- 分析用户购买偏好

### 长期 (持续)
- 引入生命周期管理
- 分群推荐不同产品
- 打造会员社区特权
- 定期推出限时促销

---

**准备好了吗？立即开始配置！🚀**

后续如有任何问题，欢迎反馈。
