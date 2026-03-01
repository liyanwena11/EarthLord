# EarthLord App Store Connect 产品配置清单

## 📋 检查清单

### ✅ 订阅产品（4个）- 需要验证价格

| 产品 ID | 显示名称 | 正确价格 | 当前显示价格 | 状态 |
|---------|---------|---------|--------------|------|
| `com.earthlord.sub.explorer.monthly` | 探索者通行证月付 | **¥12** | ¥38 | ⚠️ 需修正 |
| `com.earthlord.sub.explorer.yearly` | 探索者通行证年付 | **¥88** | ¥88 | ✅ 正确 |
| `com.earthlord.sub.lord.monthly` | 领主通行证月付 | **¥28** | ¥28 | ✅ 正确 |
| `com.earthlord.sub.lord.yearly` | 领主通行证年付 | **¥188** | ¥168 | ⚠️ 需修正 |

### ❌ 消耗品（4个）- 需要创建

| 产品 ID | 显示名称 | 价格 | 优先级 |
|---------|---------|------|--------|
| `com.earthlord.supply.survivor` | 生存者补给 | ¥6 | 高 |
| `com.earthlord.supply.explorer` | 探险家补给 | ¥18 | 高 |
| `com.earthlord.supply.lord` | 领主补给 | ¥30 | 高 |
| `com.earthlord.supply.overlord` | 霸主补给 | ¥68 | 高 |

---

## 🔧 App Store Connect 配置步骤

### 步骤 1：修正订阅价格

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择 **App** → **订阅**
3. 找到订阅群组
4. 修正价格：
   - 探索者月付：¥12（当前错误配置为¥38）
   - 领主年付：¥188（当前错误配置为¥168）
5. **保存**

### 步骤 2：创建消耗品

1. App → **App 内购买项目**
2. 点击 **+** → **创建 App 内购买项目**
3. 为每个消耗品填写：

#### 生存者补给
- **产品 ID**: `com.earthlord.survivor`
- **价格**: ¥6
- **名称**: 生存者补给

#### 探险家补给
- **产品 ID**: `com.earthlord.explorer`
- **价格**: ¥18
- **名称**: 探险家补给

#### 领主补给
- **产品 ID**: `com.earthlord.lord`
- **价格**: ¥30
- **名称**: 领主补给

#### 霸主补给
- **产品 ID**: `com.earthlord.overlord`
- **价格**: ¥68
- **名称**: 霸主补给

---

## 📱 真机测试验证

配置完成后：

1. **删除真机上的应用**
2. **重启真机**（清除缓存）
3. **重新安装应用**
4. **查看控制台日志**，验证：

```
✅ [IAP] 从 App Store 加载产品: 8 个
  - com.earthlord.sub.explorer.monthly: 探索者通行证-月付 - ¥12.00  ← 应该是¥12
  - com.earthlord.sub.explorer.yearly: 探索者通行证-年付 - ¥88.00
  - com.earthlord.sub.lord.monthly: 领主通行证-月付 - ¥28.00
  - com.earthlord.sub.lord.yearly: 领主通行证-年付 - ¥188.00  ← 应该是¥188
  - com.earthlord.supply.survivor: 生存者补给 - ¥6.00
  - com.earthlord.supply.explorer: 探险家补给 - ¥18.00
  - com.earthlord.supply.lord: 领主补给 - ¥30.00
  - com.earthlord.supply.overlord: 霸主补给 - ¥68.00
```

---

## ⏱️ 重要提醒

- App Store Connect 价格修改后，**可能需要 15-30 分钟**才能在沙盒环境生效
- 真机必须**重启**才能清除旧的缓存
- 消耗品创建后，**必须提交审核**才能在沙盒环境测试

---

**创建时间**: 2026-02-28
**配置状态**: 待修正
