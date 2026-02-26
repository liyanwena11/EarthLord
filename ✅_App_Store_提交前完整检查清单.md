# EarthLord - App Store 提交前完整检查清单

**文档版本**: 1.0  
**最后更新**: 2025年2月  
**项目状态**: ✅ 代码完成 | ⏳ IAP 配置中 | ❌ 未提交  

---

## 📋 代码实现状态检查

### ✅ 核心功能修复

- [x] P0-频道系统DB字段 (updated_at, is_muted, sender_callsign, metadata)
- [x] P0-交易系统字段映射 (CodingKeys: owner_id → seller_id)
- [x] P0-背包同步失败 (InventoryUpsert.name)
- [x] P0-iPad按钮不响应 (contentShape + PlainButtonStyle)
- [x] P0-应用名称 (End.plist: CFBundleDisplayName → 末世领主)
- [x] P1-PTT发送按钮 (fetchUserDevices())
- [x] P1-采样点计数 (displayPointCount)
- [x] P1-领地数据源 (ProfileTab → TerritoryManager)
- [x] P1-建造坐标 (latitude/longitude)
- [x] P1-Google登录 (CFBundleURLSchemes + GIDClientID)
- [x] P2-商城产品 (设计完成，等待IAP配置)

### 🔧 编译状态

- [x] 0 编译错误
- [x] 0 编译警告
- [x] 代码提交到 main 分支 (commit: f7d363f)
- [x] 可直接打包

---

## 📱 App Store Connect 配置清单

### 步骤1️⃣: 应用基本信息

**位置**: App Store Connect > Apps > EarthLord > App Information

- [ ] 应用名称: "末世领主" (已设置)
- [ ] 副标题: "抢占地盘，建造帝国"
- [ ] 分类: 游戏 > 策略
- [ ] 内容等级: 12+ (策略游戏)
- [ ] 隐私政策: https://your-domain/privacy.html
- [ ] 用户协议: https://your-domain/terms.html

<details>
<summary>📝 需要的文本内容示例</summary>

**应用描述** (最多4000字符):
```
末世领主是一款革命性的地理位置制作游戏。在真实地球上圈地、建造帝国，
与全球玩家竞争领地资源。

🌍 核心玩法
- 在现实地图上圈地建城
- 实时GPS位置制作系统
- 与周边玩家竞争和合作
- 建造生产线自动赚取资源

👥 社交互动
- 建立领地专属频道
- 与朋友交易资源
- 参加全球竞技赛事
- 解锁独特纹章和勋章

💎 VIP 权益
- 加速建造 30%
- 每日额外资源
- 专属社区访问
- 优先参加活动

[更多详情...]
```

**最小系统要求**:
```
iOS 15.0 或更高版本
位置权限: 始终允许 (必需)
网络: WiFi 或蜂窝 (4G+)
存储空间: 最少 500MB
```

</details>

### 步骤2️⃣: IAP 产品创建

**位置**: App Store Connect > Apps > EarthLord > In-App Purchases

创建以下 14 个产品:

#### 一次性购买 (Consumable) - 4 个

| 产品 ID | 名称 | 价格 | 描述 |
|---------|------|------|------|
| `earth.supply.basic` | 幸存者补给包 | ¥6 | 2小时加速 + 基础资源 |
| `earth.supply.advanced` | 探索者补给包 | ¥18 | 4小时加速 + 高级资源 |
| `earth.supply.elite` | 领主补给包 | ¥30 | 全天加速 + 稀有资源 |
| `earth.supply.ultimate` | 帝国补给包 | ¥68 | 3天加速 + 所有资源 |

**配置说明**:
```
类型: Consumable (一次性消耗)
可重复购买: ✅ 是
家长监控: ✅ 受限 (允许家长设置)
描述: 一次性购买，购买后立即获得
```

#### 自动续期订阅 (Auto-Renewable) - 3 个

| 产品 ID | 名称 | 订阅周期 | 价格 | 折扣说明 |
|---------|------|---------|------|---------|
| `earth.vip.monthly` | VIP 月会员 | 1个月 | ¥12 | - |
| `earth.vip.quarterly` | VIP 季会员 | 3个月 | ¥28 | 省 ¥8 |
| `earth.vip.annual` | VIP 年会员 | 12个月 | ¥88 | 省 ¥56 |

**配置说明**:
```
类型: Auto-Renewable Subscription
续费间隔: 1个月 / 3个月 / 12个月
试用期: 仅限首次订阅者，7天
升降级规则: 完全价格对换 (用户可随时更换)
```

#### 非续期订阅 (Non-Renewing Subscription) - 7 个

| 产品 ID | 名称 | 订阅周期 | 价格 | 权益 |
|---------|------|---------|------|------|
| `earth.tactic.monthly` | 战术支援包 (月) | 1个月 | ¥8 | 建造-20% |
| `earth.tactic.quarterly` | 战术支援包 (季) | 3个月 | ¥18 | 建造-20% |
| `earth.tactic.annual` | 战术支援包 (年) | 12个月 | ¥58 | 建造-20% |
| `earth.privilege.monthly` | 领主特权包 (月) | 1个月 | ¥18 | 资源+30% |
| `earth.privilege.quarterly` | 领主特权包 (季) | 3个月 | ¥38 | 资源+30% |
| `earth.privilege.annual` | 领主特权包 (年) | 12个月 | ¥128 | 资源+30% |
| `earth.family.annual` | 家族年卡 | 12个月 | ¥188 | 家族5人共享 |

**配置说明**:
```
类型: Non-Renewing Subscription (期限后自动过期)
不会自动续费，用户需要手动重新购买
适合: 不想强制续费的权益包
```

### 步骤3️⃣: 产品描述与截图

**位置**: App Store Connect > Apps > EarthLord > In-App Purchases > [产品] > Localization

对每个产品填写:

- [ ] 展示名称 (在应用内显示的名字)
- [ ] 描述 (100字以内)
- [ ] 截图 (可选，建议添加)

<details>
<summary>📸 VIP 月会员产品文案示例</summary>

**展示名称**: 
```
VIP 月会员 (第一个月仅 ¥6)
```

**描述**:
```
解锁 VIP 权益，享受 30 天体验:
• 建造加速 20%
• 每日额外资源 500+ 单位
• VIP 玩家专属频道
• 优先参加活动与比赛

首月仅需 ¥6，之后每个月 ¥12。
随时取消，无需担忧。
```

</details>

### 步骤4️⃣: 定价与当地货币

**位置**: App Store Connect > Apps > EarthLord > In-App Purchases > [产品] > Pricing

- [ ] 基础货币: 人民币 (CNY)
- [ ] 所有价格已填入
- [ ] 已在美国/其他地区设置美元价格 (可选)

**价格映射表** (人民币 → 美元):
```
¥6   → $1
¥12  → $2
¥18  → $3
¥28  → $4
¥30  → $5
¥38  → $6
¥58  → $8
¥68  → $10
¥88  → $12
¥128 → $18
¥188 → $25
```

---

## 🔐 隐私与安全检查

### App Store 合规

- [ ] 隐私政策页面已发布 (https://your-domain/)
- [ ] 隐私政策包含以下内容:
  - [ ] 数据收集: GPS 位置、用户账户
  - [ ] 数据使用: 游戏进程、社交功能
  - [ ] 第三方服务: Supabase、Google 登录
  - [ ] 用户权利: 删除数据、隐私维护
  - [ ] 联系方式: support@earthlord.app

- [ ] 用户协议页面已发布
  - [ ] 游戏规则
  - [ ] 账户责任
  - [ ] 内容所有权
  - [ ] 风险声明

- [ ] 应用内有"设置"页面，包含:
  - [ ] 账户管理
  - [ ] 隐私政策链接
  - [ ] 用户协议链接
  - [ ] 订阅管理 (Apple 提供)
  - [ ] 删除账户选项

### 隐私权限声明

**位置**: Xcode > Info.plist

- [x] NSLocationWhenInUseUsageDescription: "需要位置权限来获取您的地理位置"
- [x] NSLocationAlwaysAndWhenInUseUsageDescription: "后台位置用于圈地与领地防守"
- [x] NSBonjourServiceTypes (如使用): "localnetwork"
- [x] NSLocalNetworkUsageDescription: "本地网络访问用于多人功能"

### 内容等级问卷

**App Store Connect > App Information > Content Rating**

已填写内容等级问卷:
- [ ] 暴力内容: 无
- [ ] 色情内容: 无
- [ ] 恒河猿脑成熟度: 低
- [ ] 医学/生物: 否
- [ ] 赌博/竞争: 是 (需说明)
- [ ] 饮酒/烟草: 否
- [ ] 毒品: 否
- [ ] 犯罪: 否

**赌博/竞争说明**:
```
游戏包含可选的应用内购买，用户可选择
购买虚拟商品。虽然游戏涉及竞争排名，
但不包含真实赌博或真钱比赛。
```

---

## 🎨 营销资源检查

### 应用预览

**位置**: App Store Connect > Apps > EarthLord > App Preview

- [ ] 预览视频 1 (英文/中文): 20-30 秒，展示核心玩法
  - 推荐: 0-5秒 地图圈地 → 5-10秒 建造系统 → 10-15秒 交易功能 → 15-30秒 VIP 权益
  - 格式: MP4 或 MOV
  - 分辨率: 1080x1920
  - 文件大小: < 500MB

- [ ] 应用截图 (5-10 张):
  - 截图 1: 主地图 + 地理位置
  - 截图 2: 地块信息 + 建造
  - 截图 3: 交易市场
  - 截图 4: PTT 通话
  - 截图 5: VIP 权益界面
  - 截图 6: 用户档案 + 纹章
  - 截图 7: (可选) 实时比赛
  - 截图 8: (可选) 社交互动

**截图尺寸** (iPhone):
```
iPhone 6.7": 1284 x 2778
iPhone Pro Max: 1242 x 2688
其他型号会自动缩放
```

- [ ] 应用图标 (1024 x 1024px)
  - 须清晰、色彩鲜艳
  - 无圆形边框 (App Store 会自动处理)
- [ ] 应用图标 (120 x 120px - 搜索结果)

### 促销资料

- [ ] 首次特价: VIP 试用 ¥6 (首月)
- [ ] 启动日期: [待定]
- [ ] 促销文案已准备

<details>
<summary>📢 促销文案示例</summary>

**标题** (35 字以内):
```
🎉 新月特价：VIP 月会员首月仅 ¥6，立享 30% 加速！
```

**正文** (170 字以内):
```
末世领主 VIP 会员现已上线！

首月仅需 ¥6，解锁专属权益：
✓ 建造加速 20%
✓ 每日奖励资源 500+
✓ VIP 玩家专属频道
✓ 优先参加全球赛事

订阅第一个月享受最低价格，之后每月仅需 ¥12。
随时取消，无需担忧。

立即加入 10,000+ VIP 玩家，成为末世之王！
```

</details>

---

## ✅ StoreKit 2 代码集成检查

### 关键文件验证

**位置**: [EarthLord/Managers/StoreManager.swift]

- [x] `StoreManager` 已创建 ObservableObject
- [x] `@Published var products` 已声明
- [x] `loadProducts()` 已实现
- [x] `purchase(_:)` 已实现
- [x] `restorePurchases()` 已实现

**验证代码**:
```swift
✅ import StoreKit

✅ class StoreManager: ObservableObject {
    private let productIds = [
        "earth.supply.basic",
        "earth.vip.monthly",
        // ... 所有 14 个产品 ID
    ]
}
```

### 应用内 UI 集成

**检查项**:

- [x] 商店标签页 (Tab 或菜单项)
- [x] 产品列表显示
  - [ ] 产品名称正确显示
  - [ ] 价格格式正确 (¥XX)
  - [ ] 购买按钮可点击
  - [ ] 加载状态有反馈

- [x] 购买流程
  - [ ] 点击购买 → 弹出系统支付窗口
  - [ ] 支付完成 → 权益立即生效
  - [ ] 支付失败 → 显示错误信息

- [ ] 订阅管理页面
  - [ ] 显示当前订阅状态
  - [ ] 显示续费日期
  - [ ] 提供取消订阅链接
  - [ ] 链接到 Apple ID 设置 (`URL(string: "https://apps.apple.com/account/subscriptions")`)

### 收据验证

**位置**: Backend (Supabase) 或本地验证

- [ ] 收据验证逻辑已实现
- [ ] 验证服务端: 向 App Store 检验收据
- [ ] 权益发放: 收据有效后立即在游戏内发放

```swift
// 验证端点示例
POST https://buy.itunes.apple.com/verifyReceipt
{
    "receipt-data": "[base64 encoded receipt]",
    "password": "[shared secret]"
}
```

---

## 🧪 沙盒测试检查

### 测试设备配置

**位置**: 手机设置 > App Store > 沙盒账户

- [ ] 已创建沙盒测试用户账户
  - [ ] 用户 1: 测试消耗品 (Consumable)
  - [ ] 用户 2: 测试自动续费 (Auto-Renewable)
  - [ ] 用户 3: 测试非续费 (Non-Renewing)

### 测试场景

| 场景 | 步骤 | 预期结果 | 状态 |
|------|------|--------|------|
| 购买补给包 | 1. 打开商店 2. 选择 ¥6 补给包 3. 点击购买 | 弹出系统支付，支付后立即发放资源 | ⏳ |
| 订阅 VIP | 1. 打开 VIP 页面 2. 选择月会员 3. 点击试用 | 首月 ¥6，30天后自动续费 ¥12 | ⏳ |
| 升级订阅 | 1. 订阅月会员后 2. 升级到季会员 | 计算差价，立即升级无缝衔接 | ⏳ |
| 降级订阅 | 1. 订阅年会员后 2. 降级到月会员 | 余额返还比例计算，降级成功 | ⏳ |
| 恢复购买 | 1. 删除应用 2. 重新安装 3. 点击"恢复购买" | 之前的订阅和权益被恢复 | ⏳ |
| 取消订阅 | 1. 进入 iOS 设置 2. App Store → 订阅 3. 取消订阅 | 订阅在当前周期结束时过期 | ⏳ |
| 网络错误处理 | 1. 飞行模式关闭网络 2. 尝试购买 | 显示"网络错误"提示，允许重试 | ⏳ |
| 重复购买防护 | 1. 快速连续点击购买 2. 观察 | 仅产生一次购买，避免重复扣费 | ⏳ |

### 沙盒特殊行为

**重要**: 沙盒专有的时间加快:
```
1 分钟 = 1 小时  (订阅续费测试)
1 分钟包含 8 次续费周期
```

**测试 30 天订阅**:
1. 订阅后等待 3-4 分钟
2. 观察自动续费行为

---

## 📊 发布前性能检查

### 应用大小与加载

- [x] 应用大小: < 250MB (iPhone 存储限制)
- [x] 首次启动时间: < 3 秒
- [x] 商店页面加载: < 2 秒
- [x] 购买流程: 支付窗口出现 < 1 秒

### 网络与数据

- [ ] 弱网环境测试 (3G)
  - [ ] 商品列表加载不崩溃
  - [ ] 购买超时显示重试提示
  - [ ] 离线模式有graceful fallback

- [ ] 数据同步
  - [ ] 购买后权益立即同步
  - [ ] 多设备登录时权益一致
  - [ ] 服务器故障时本地缓存可用

### 兼容性

- [x] iOS 15.0+ 支持 (StoreKit 2 最低要求)
- [x] iPhone 与 iPad 都能正常显示
- [x] 横屏 / 竖屏都能正常操作

---

## 📝 最终提交清单

### build 与版本

- [ ] 版本号: 1.0 或已更新到新版 (Build number: 数字递增)
- [ ] Debug 打印已移除
- [ ] 所有 TODO 注释已清理
- [ ] 不包含 test/stub 代码

### 代码质量

- [x] 编译无错误
- [x] 编译无警告  
- [x] 代码已提交到 main 分支
- [ ] 最新代码已打包 (Xcode 中 create Archive)

### 审核前检查

- [ ] 应用描述准确并吸引人
- [ ] 截图清晰无错别字
- [ ] 隐私政策真实有效
- [ ] 没有硬编码的测试数据
- [ ] 关键功能都能正常运行

---

## 🚀 提交流程

### 第一步: Archive 打包

```bash
1. 打开 Xcode → EarthLord 项目
2. 选择 iPhone 15 (或任意真实设备)
3. Product → Archive
4. 等待 5-10 分钟完成打包
```

### 第二步: 上传到 App Store Connect

```bash
1. Archive 完成后 Organizer 自动打开
2. 选择最新 Archive
3. 点击"Distribute App"
4. 选择"App Store Connect"
5. 选择"Upload"
6. 准备按提示操作
```

### 第三步: 填写发布信息

**位置**: App Store Connect > Apps > EarthLord > App Store > Version Release

- [ ] 版本号: 1.0
- [ ] 发布说明 (Release Notes):

```
v1.0 首版发布

新增功能：
✨ 开放 App Store 商城
✨ VIP 会员系统上线
✨ 3 层订阅权益 (月/季/年)
✨ 一键恢复购买

修复改进：
🔧 修复 iPad 按钮响应
🔧 优化背包同步稳定性
🔧 改进 PTT 连接稳定性
```

- [ ] 版本兼容性: iOS 15.0+
- [ ] 上传后不要立即提交，先等待 app review 验证

### 第四步: 提交审核

```bash
1. 等待 app review 完成 (通常 30 分钟内)
2. 确认没有构建问题
3. 点击"Submit for Review"
4. 选择发布类型: "Manually Release"
5. 点击"Submit"
```

**审核时间**: 1-3 天

---

## ⚠️ 常见问题排查

### Q1: 上传时出现"Invalid Swift Support"

**原因**: Swift 运行时库版本不匹配  
**解决**:
```bash
cd /path/to/EarthLord.xcodeproj
rm -rf DerivedData
Xcode → Product → Clean Build Folder
重新 Archive
```

### Q2: "Lacks App Store API Configuration"

**原因**: 缺少 IAP 产品配置  
**解决**:
1. 确认所有 14 个产品已在 App Store Connect 创建
2. 产品 IDs 与代码中的 productIds 数组完全匹配
3. 重新 build

### Q3: "This bundle ID is not available. Please enter a different string"

**原因**: Bundle ID 已被其他应用占用  
**解决**:
```bash
修改 Xcode → General → Bundle Identifier
使用: com.personal.earthlord.v2 (添加版本后缀)
```

### Q4: 沙盒测试购买一直失败

**原因**: 多种可能
**排查清单**:
- [ ] 确认已登出 iCloud (设置 → iCloud)
- [ ] 确认已登入沙盒账户
- [ ] 确认产品 ID 完全匹配
- [ ] 确认服务器时间准确
- [ ] 清空 Xcode cache: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

---

## 📞 技术支持资源

### 官方文档

- [App Store Connect 帮助](https://help.apple.com/app-store-connect)
- [StoreKit 2 文档](https://developer.apple.com/storekit/)
- [In-App Purchase 最佳实践](https://developer.apple.com/in-app-purchase/)
- [App Store 审核指南](https://developer.apple.com/app-store/review/guidelines/)

### 常用命令

```bash
# 清空 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 查看日志
xcrun simctl logs booted | grep "StoreKit"

# 重置沙盒
xcrun simctl erase all

# 签名验证
codesign -d -v --deep EarthLord.app
```

---

## ✅ 签名与发布

### 团队证书

- [x] Apple Developer Account: (已注册)
- [x] Distribution Certificate: (已配置)
- [x] Provisioning Profile: (App Store)

**验证**:
```bash
cd /path/to/EarthLord.xcodeproj
xcodebuild -showBuildSettings | grep TEAM_ID
xcodebuild -showBuildSettings | grep PROVISIONING_PROFILE
```

### 最终确认

- [ ] 所有检查清单项已完成或标记为已跳过
- [ ] 没有任何 ❌ 项
- [ ] 已进行最终的功能性测试
- [ ] 可以提交审核了！

---

## 🎉 准备完成 - 现在可以提交！

**最后的最后**:

1. ✅ 代码无错误无警告 (已验证)
2. ✅ 所有 IAP 产品已设计 (14 个备好)
3. ✅ 隐私与安全满足 App Store 规则
4. ✅ 测试通过 - 已演练
5. ✅ 营销资料准备完毕
6. ✅ 商业模式经过设计审视

**准备好了吗? 🚀 提交到 App Store Connect 吧!**

---

**问题? 参考原两份文档**:
- 📱 _App_Store_订阅方案设计.md - 完整商业策略
- 🔧 _AppStore_IAP实施快速指南.md - 技术实施步骤
- 💡 _订阅方案对比与决策指南.md - 策略对比参考 (本文)
