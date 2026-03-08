乖乖# App Store审核回复文档

## 📱 应用描述（中文版）

### 应用名称
**地球新主 (EarthLord)**

### 应用简介
《地球新主》是一款基于GPS定位的LBS（Location-Based Service）生存游戏。在2051年的末日世界中，玩家作为一名开拓者，通过真实世界行走来圈占领地、探索资源、建造家园，并与其他玩家进行交易和社交。

### 核心价值
1. **Walk to Earn** - 通过真实世界行走获得游戏奖励，鼓励健康运动
2. **真实地理位置** - 基于真实地图和POI的沉浸式游戏体验
3. **社交互动** - 基于地理位置的玩家交易和通讯系统
4. **生存建造** - 资源管理和建筑建造��硬核玩法

### 目标用户
- 18-35岁喜欢运动和探索的玩家
- 对LBS和生存建造游戏感兴趣的玩家
- 希望通过游戏化方式促进运动的人群

### 解决的问题
- 传统游戏缺乏运动 - 通过GPS圈地机制鼓励用户外出行走
- 缺乏创新玩法 - 结合真实地理位置的游戏体验
- 社交互动单一 - 基于位置的距离限制社交

---

## 📱 Application Description (English Version)

### App Name
**EarthLord**

### App Summary
EarthLord is a location-based survival game where players explore a post-apocalyptic world in 2051. As a pioneer, you claim territories by walking in the real world, explore resources, build structures, and interact with other players through trading and communication systems.

### Core Value Proposition
1. **Walk to Earn** - Get rewards for real-world walking, promoting healthy exercise
2. **Real Geographic Location** - Immersive gameplay based on real maps and POIs
3. **Social Interaction** - Location-based player trading and communication
4. **Survival & Building** - Hardcore gameplay with resource management and construction

### Target Audience
- Players aged 18-35 who enjoy exercise and exploration
- Gamers interested in LBS and survival building games
- Users seeking gamified motivation for physical activity

### Problems Solved
- Lack of exercise in traditional games - GPS territory claiming encourages outdoor walking
- Lack of innovative gameplay - Real-world location-based gaming experience
- Limited social interaction - Distance-based social features

---

## 🎮 核心功能演示

### 1. GPS圈地系统
**功能说明：** 玩家通过真实世界行走来圈占领地

**演示步骤：**
1. 点击地图页面的"开始圈地"按钮
2. 在真实世界中行走（或使用GPS模拟）
3. 点击"停止圈地"按钮
4. 系统自动检测路径是否闭合
5. 显示圈占的领地面积和位置

**技术特点：**
- 实时GPS追踪
- 路径闭合检测
- 碰撞检测（避免与他人领地重叠）
- 面积计算
- 云端同步

### 2. 探索系统
**功能说明：** 基于真实POI（兴趣点）的资源探索

**演示步骤：**
1. 查看地图上的POI标记（商店、餐厅、公园等）
2. 点击附近的POI查看详情
3. 点击"探索"按钮
4. 获得随机生成的资源物品

**技术特点：**
- 真实POI数据集成
- 距离检测（500米内可探索）
- AI物品生成系统
- 冷却时间机制

### 3. 建造系统
**功能说明：** 在领地上建造各种功能建筑

**演示步骤：**
1. 进入"领地"标签页
2. 选择一个领地
3. 点击"建造"按钮
4. 选择建筑类型（小屋、农场、工场等）
5. 确认建造位置
6. 消耗资源完成建造

**建筑类型：**
- 小屋 - 增加存储空间
- 农场 - 生产食物
- 工场 - 生产材料
- 防御塔 - 保护领地

### 4. 交易系统
**功能说明：** 玩家间物品交易平台

**演示步骤：**
1. 进入"资源"标签页
2. 点击"交易"按钮
3. 浏览市场中的交易挂单
4. 或点击"创建交易"发布自己的挂单
5. 选择要交易的物品和数量
6. 确认交易

### 5. 通讯系统
**功能说明：** 基于距离限制的社交通讯

**演示步骤：**
1. 进入"通讯"标签页
2. 浏览附近玩家创建的频道（5公里内）
3. 点击"加入"加入频道
4. 发送文字消息
5. 使用PTT（Push-To-Talk）语音功能

### 6. 行走奖励
**功能说明：** Walk to Earn机制

**演示步骤：**
1. 打开App并携带手机
2. 正常行走
3. 系统自动记录步数和距离
4. 达到里程碑时获得奖励

---

## 🧪 测试指南

### 测试账号信息
```
邮箱：test@earthlord.game
密码：Test123456@

备用测试账号：
邮箱：earthlord.test@gmail.com
密码：EarthTest123456
```

### 详细测试步骤

#### 步骤1：登录（2分钟）
1. 打开应用
2. 等待启动动画完成
3. 点击"登录"按钮
4. 输入测试账号：test@earthlord.game
5. 输入密码：Test123456@
6. 点击"登录"
7. 等待进入主界面

**预期结果：** 成功登录，显示5个标签页（地图、领地、资源、通讯、个人）

#### 步骤2：GPS圈地（5分钟）
**方法A：真实GPS（推荐）**
1. 允许应用访问GPS位置
2. 进入"地图"标签页
3. 点击"开始圈地"按钮
4. 在真实世界中走一小圈（约50-100米）
5. 点击"停止圈地"按钮
6. 等待系统检测路径闭合

**方法B：模拟GPS（使用Xcode）**
1. 在Xcode中选择Scheme
2. 编辑Scheme → Run → Options
3. 添加GPX文件（项目中的SimulatedRun.gpx）
4. 运行应用并模拟GPS移动

**预期结果：**
- 成功创建领地
- 显示领地面积
- 领地显示在地图上

#### 步骤3：探索POI（3分钟）
1. 在地图上查看附近的POI标记
2. 点击一个POI标记
3. 查看POI详情（名称、类型、距离）
4. 点击"探索"按钮
5. 等待探索完成动画
6. 查看获得的物品

**预期结果：**
- 成功探索POI
- 获得随机物品
- 物品进入背包

#### 步骤4：查看背包和建造（3分钟）
1. 进入"资源"标签页
2. 查看背包中的物品
3. 查看背包容量和负重
4. 进入"领地"标签页
5. 选择一个领地
6. 点击"建造"按钮
7. 浏览可建造的建筑

**预期结果：**
- 显示背包物品列表
- 显示背包容量进度条
- 显示可建造建筑列表

#### 步骤5：交易系统（3分钟）
1. 进入"资源"标签页
2. 点击"交易"按钮
3. 浏览市场中的交易
4. 查看交易详情（物品、数量、价格）
5. 点击"创建交易"
6. 选择要交易的物品
7. 设置交易价格

**预期结果：**
- 显示交易市场列表
- 可以创建交易挂单
- 可以查看交易详情

#### 步骤6：通讯系统（3分钟）
1. 进入"通讯"标签页
2. 浏览附近的频道
3. 点击"创建频道"
4. 输入频道名称
5. 创建成功
6. 在频道中发送消息

**预期结果：**
- 显示附近玩家频道
- 可以创建新频道
- 可以发送文字消息

#### 步骤7：查看个人中心（2分钟）
1. 进入"个人"标签页
2. 查看用户信息
3. 查看数据统计（领地数、背包负重、附近玩家）
4. 查看"末日通行证"入口
5. 滚动到底部
6. 点击"设置"
7. 查看设置页面
8. 点击"帮助中心"
9. 查看FAQ

**预期结果：**
- 显示完整个人资料
- 显示数据统计
- 可以访问设置和帮助

#### 步骤8：商店和订阅（4分钟）
1. 在个人中心点击"物资商城"
2. 浏览可购买的补给包
3. 点击一个补给包查看详情
4. **不要购买**（这是演示，不是真实购买）
5. 返回个人中心
6. 点击"末日通行证"
7. 浏览订阅计划
8. 查看订阅权益对比

**预期结果：**
- 显示补给包列表
- 显示订阅计划
- **使用沙盒环境，不会真实扣费**

---

## ⚠️ 已知限制和说明

### 1. GPS权限要求
**说明：** 应用需要GPS权限才能使用圈地功能
**解决方案：** 测试时请允许"始终"访问位置权限

### 2. 网络连接
**说明：** 应用需要网络连接（使用Supabase后端）
**解决方案：** 确保设备连接到互联网

### 3. IAP沙盒环境
**说明：** 应用内购使用沙盒环境测试
**解决方案：**
- 使用沙盒测试账号
- 不会真实扣费
- 购买后可以删除购买记录

### 4. 部分功能需要等级
**说明：** 某些高级功能需要达到一定等级才能使用
**解决方案：** 测试账号已预设等级，可以访问大部分功能

### 5. 地图数据
**说明：** POI数据来源于真实地图数据
**解决方案：** 如果测试区域POI较少，建议在市中心区域测试

---

## 🐛 已修复的问题

### 审核期间修复的问题
1. ✅ 添加了完整的设置页面
2. ✅ 添加了帮助中心和FAQ
3. ✅ 添加了用户协议页面
4. ✅ 添加了关于页面
5. ✅ 添加了账号管理功能
6. ✅ 改进了退出登录流程
7. ✅ 完善了账号删除功能
8. ✅ 添加了隐私政策链接
9. ✅ 添加了技术支持链接

---

## 📞 联系方式

如有任何问题，请通过以下方式联系我们：
- **官网：** https://liyanwena11.github.io/earthlord-support/
- **隐私政策：** https://liyanwena11.github.io/earthlord-support/privacy.html
- **邮箱：** support@earthlord.game

---

## 📝 App Store Connect 回复模板

```
Dear App Store Review Team,

Thank you for your review. Here is the requested information about EarthLord:

【App Description】
EarthLord is a location-based survival game set in a post-apocalyptic world of 2051. Players claim territories by walking in the real world, explore resources at real POIs, build structures, and interact with other players through trading and communication systems.

The app provides an innovative "Walk to Earn" experience that encourages outdoor exercise while delivering immersive gameplay.

【Core Features Demo Video】
[Attached 30-90 second screen recording demonstrating:
1. Login flow
2. GPS territory claiming
3. POI exploration
4. Building system
5. Trading system
6. Communication system]

【Test Account】
Email: test@earthlord.game
Password: Test123456@

【Testing Instructions】
Step 1 - Login: Use test credentials to sign in

Step 2 - Territory Claiming:
- Go to "Map" tab
- Tap "Start Claiming"
- Walk in real world (or use GPS simulation)
- Tap "Stop Claiming"
- View claimed territory

Step 3 - Exploration:
- Tap on nearby POI markers
- Tap "Explore" button
- View obtained resources

Step 4 - Building:
- Go to "Territory" tab
- Select a territory
- Tap "Build"
- Browse available buildings

Step 5 - Trading:
- Go to "Resources" tab
- Tap "Trading"
- Browse market or create listing

Step 6 - Communication:
- Go to "Communication" tab
- Browse nearby channels
- Join channel and send message

【Known Limitations】
- GPS permission required for territory claiming
- Internet connection required (uses Supabase backend)
- IAP uses sandbox environment (no real charges)
- Some advanced features require player level progression

【Recent Improvements】
We have added:
- Complete Settings page with account management
- Help Center with comprehensive FAQ
- Terms of Service page
- About page with app information
- Improved logout and account deletion flow

The app is fully functional and ready for review. Looking forward to your approval.

Best regards,
EarthLord Development Team
```

---

## 📹 演示视频录制脚本

### 视频时长：60-90秒
### 分辨率：1080p或更高
### 格式：MP4

#### 场景1：应用启动和登录（0-10秒）
- [ ] 打开应用
- [ ] 显示启动动画（末世主题视频）
- [ ] 进入登录界面
- [ ] 输入测试账号密码
- [ ] 点击登录

#### 场景2：GPS圈地演示（10-30秒）
- [ ] 进入"地图"标签页
- [ ] 显示地图和当前位置
- [ ] 点击"开始圈地"
- [ ] 模拟GPS移动（或真实行走）
- [ ] 显示路径追踪动画
- [ ] 点击"停止圈地"
- [ ] 显示领地创建成功

#### 场景3：探索系统演示（30-45秒）
- [ ] 显示地图上的POI标记
- [ ] 点击一个POI
- [ ] 显示POI详情弹窗
- [ ] 点击"探索"按钮
- [ ] 显示探索动画
- [ ] 显示获得的物品

#### 场景4：建造系统演示（45-55秒）
- [ ] 进入"领地"标签页
- [ ] 显示领地列表
- [ ] 选择一个领地
- [ ] 点击"建造"
- [ ] 显示建筑列表

#### 场景5：交易和通讯演示（55-70秒）
- [ ] 进入"资源"标签页
- [ ] 点击"交易"
- [ ] 显示交易市场
- [ ] 进入"通讯"标签页
- [ ] 显示频道列表
- [ ] 发送一条消息

#### 场景6：个人中心和设置（70-85秒）
- [ ] 进入"个人"标签页
- [ ] 显示用户信息
- [ ] 显示数据统计
- [ ] 滚动到底部
- [ ] 点击"设置"
- [ ] 显示设置页面

#### 场景7：帮助中心（85-90秒）
- [ ] 点击"帮助中心"
- [ ] 显示FAQ列表
- [ ] 展开一个问题查看答案

### 录制注意事项
1. 使用真机录制（不要使用模拟器）
2. 确保屏幕录制清晰可见
3. 操作流畅，不要有卡顿
4. 突出核心功能
5. 适当添加文字标注说明功能
6. 控制在90秒以内

---

**文档版本：** v1.0
**最后更新：** 2025年3月8日
**用途：** App Store审核回复
