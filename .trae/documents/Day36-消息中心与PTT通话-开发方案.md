# Day 36：消息中心与PTT通话 - 完整开发方案

> 第36天开发内容：官方频道 + 消息聚合 + PTT通话 + 呼号系统
> **最后更新：包含完整的四步实现方案**

---

## 一、功能概览

### 1.1 核心功能清单

| 模块 | 功能 | 状态 |
|------|------|------|
| **数据库** | 创建官方频道（固定UUID） | 待完成 |
| **数据库** | 创建 user_profiles 表（存储呼号） | 待完成 |
| **Models** | MessageCategory 枚举（消息分类） | 待完成 |
| **Manager** | ensureOfficialChannelSubscribed()（强制订阅） | 待完成 |
| **Manager** | getChannelSummaries()（消息聚合） | 待完成 |
| **Manager** | loadAllChannelLatestMessages() | 待完成 |
| **Views** | OfficialChannelDetailView（官方频道页） | 待完成 |
| **Views** | MessageCenterView（消息中心） | 待完成 |
| **Views** | PTTCallView（PTT通话） | 待完成 |
| **Views** | CallsignSettingsSheet（呼号设置） | 待完成 |

### 1.2 与 Day 35 的关系

| Day 35 完成的 | Day 36 要做的 |
|--------------|--------------|
| 距离过滤算法 | 复用，不修改 |
| 普通频道通讯 | 添加官方频道 |
| Realtime 推送 | 复用，不修改 |
| 聊天界面 | 添加消息中心和PTT |

---

## 二、文件清单

### 2.1 需要修改的文件

| 文件 | 路径 | 说明 |
|------|------|------|
| `CommunicationModels.swift` | `Models/` | 添加 MessageCategory 枚举 |
| `CommunicationManager.swift` | `Managers/` | 添加官方频道和消息聚合方法 |

### 2.2 需要创建的文件

| 文件 | 路径 | 说明 |
|------|------|------|
| `OfficialChannelDetailView.swift` | `Views/Communication/` | 官方频道详情页 |
| `MessageCenterView.swift` | `Views/Communication/` | 消息中心 |
| `MessageRowView.swift` | `Views/Communication/` | 消息行组件 |
| `PTTCallView.swift` | `Views/Communication/` | PTT通话界面 |
| `CallsignSettingsSheet.swift` | `Views/Communication/` | 呼号设置弹窗 |

### 2.3 数据库操作

| 操作 | 说明 |
|------|------|
| INSERT 官方频道 | 使用 MCP 创建固定 UUID 的官方频道 |
| CREATE TABLE user_profiles | 使用 MCP 创建呼号存储表 |

---

## 三、实现步骤

### 3.1 Day 36-A：官方频道数据库

#### 步骤1：创建官方频道

使用 MCP Supabase 工具执行 SQL：

```sql
-- 1. 先检查是否存在
SELECT * FROM communication_channels
WHERE id = '00000000-0000-0000-0000-000000000000';

-- 2. 如果返回空，执行以下 INSERT
INSERT INTO communication_channels (
    id,
    channel_type,
    name,
    channel_code,
    description,
    is_active,
    is_public,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'official',
    '官方频道',
    'OFF-MAIN',
    '地球领主官方公告频道，发布生存指南、游戏资讯、任务和紧急广播。',
    true,
    true,
    now()
);

-- 3. 验证创建成功
SELECT id, name, channel_type, channel_code
FROM communication_channels
WHERE channel_type = 'official';
```

**预期结果**：

```
id: 00000000-0000-0000-0000-000000000000
name: 官方频道
channel_type: official
channel_code: OFF-MAIN
```

#### 步骤2：扩展 CommunicationModels.swift

在 `Models/CommunicationModels.swift` 中添加：

```swift
// MARK: - 消息分类（官方频道专用）

enum MessageCategory: String, Codable, CaseIterable {
    case survival = "survival"   // 生存指南
    case news = "news"           // 游戏资讯
    case mission = "mission"     // 任务发布
    case alert = "alert"         // 紧急广播

    var displayName: String {
        switch self {
        case .survival: return "生存指南"
        case .news: return "游戏资讯"
        case .mission: return "任务发布"
        case .alert: return "紧急广播"
        }
    }

    var color: Color {
        switch self {
        case .survival: return .green
        case .news: return .blue
        case .mission: return .orange
        case .alert: return .red
        }
    }

    var iconName: String {
        switch self {
        case .survival: return "leaf.fill"
        case .news: return "newspaper.fill"
        case .mission: return "target"
        case .alert: return "exclamationmark.triangle.fill"
        }
    }
}

// 扩展 MessageMetadata，添加 category 字段
// 在现有的 MessageMetadata 结构体中添加：
struct MessageMetadata: Codable {
    let deviceType: String?
    let category: String?  // ✅ 新增：消息分类

    enum CodingKeys: String, CodingKey {
        case deviceType = "device_type"
        case category
    }
}

// 在 ChannelMessage 中添加计算属性
extension ChannelMessage {
    var category: MessageCategory? {
        guard let categoryString = metadata?.category else { return nil }
        return MessageCategory(rawValue: categoryString)
    }
}
```

#### 步骤3：扩展 CommunicationManager

在 `Managers/CommunicationManager.swift` 中添加：

```swift
// MARK: - 官方频道相关

/// 官方频道固定 UUID
static let officialChannelId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

/// 确保用户订阅了官方频道（强制订阅）
func ensureOfficialChannelSubscribed(userId: UUID) async {
    let officialId = CommunicationManager.officialChannelId

    // 检查是否已订阅
    if subscribedChannels.contains(where: { $0.channel.id == officialId }) {
        print("✅ [官方频道] 已订阅")
        return
    }

    // 强制订阅官方频道
    do {
        struct SubscribeParams: Encodable {
            let p_user_id: String
            let p_channel_id: String
        }

        let params = SubscribeParams(
            p_user_id: userId.uuidString,
            p_channel_id: officialId.uuidString
        )

        try await client.rpc("subscribe_to_channel", params: params).execute()

        // 刷新订阅列表
        await loadSubscribedChannels(userId: userId)
        print("✅ [官方频道] 已自动订阅")
    } catch {
        print("❌ [官方频道] 订阅失败: \(error)")
    }
}

/// 检查是否是官方频道
func isOfficialChannel(_ channelId: UUID) -> Bool {
    return channelId == CommunicationManager.officialChannelId
}
```

#### 步骤4：在登录后自动订阅官方频道

找到用户登录成功后加载通讯数据的位置（通常在 `CommunicationTabView.onAppear`），添加：

```swift
.onAppear {
    if let userId = authManager.currentUser?.id {
        Task {
            await communicationManager.loadDevices(userId: userId)
            // ✅ 新增：确保订阅官方频道
            await communicationManager.ensureOfficialChannelSubscribed(userId: userId)
        }
    }
}
```

---

### 3.2 Day 36-B：官方频道 UI

#### 步骤1：重写 OfficialChannelDetailView

创建/重写 `Views/Communication/OfficialChannelDetailView.swift`：

```swift
import SwiftUI

struct OfficialChannelDetailView: View {
    let channel: CommunicationChannel

    @StateObject private var communicationManager = CommunicationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: MessageCategory?
    @State private var isLoading = true

    private var messages: [ChannelMessage] {
        let allMessages = communicationManager.getMessages(for: channel.id)
        if let category = selectedCategory {
            return allMessages.filter { $0.category == category }
        }
        return allMessages
    }

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 导航栏
                navigationBar

                // 分类过滤器
                categoryFilter

                // 消息列表
                messageListView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadMessages()
        }
    }

    // MARK: - 导航栏
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(.red)
                    Text(channel.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.text)
                }

                Text("官方公告 · 全球覆盖")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ApocalypseTheme.cardBackground)
    }

    // MARK: - 分类过滤器
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部
                CategoryChip(
                    title: "全部",
                    icon: "list.bullet",
                    color: ApocalypseTheme.primary,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                // 各分类
                ForEach(MessageCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.iconName,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(ApocalypseTheme.cardBackground.opacity(0.5))
    }

    // MARK: - 消息列表
    private var messageListView: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                    .padding(.top, 50)
            } else if messages.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        OfficialMessageBubble(message: message)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(ApocalypseTheme.secondaryText.opacity(0.5))

            Text(selectedCategory == nil ? "暂无公告" : "暂无\(selectedCategory!.displayName)")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.text)
            Spacer()
        }
    }

    private func loadMessages() {
        isLoading = true
        Task {
            await communicationManager.loadChannelMessages(channelId: channel.id)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - 分类标签组件
struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(16)
        }
    }
}

// MARK: - 官方消息气泡
struct OfficialMessageBubble: View {
    let message: ChannelMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 分类标签
            if let category = message.category {
                HStack(spacing: 4) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 12))
                    Text(category.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.color.opacity(0.15))
                .cornerRadius(8)
            }

            // 消息内容
            Text(message.content)
                .font(.body)
                .foregroundColor(ApocalypseTheme.text)

            // 时间
            Text(message.timeAgo)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.category?.color.opacity(0.3) ?? Color.clear, lineWidth: 1)
        )
    }
}
```

#### 步骤2：在 ChannelCenterView 添加官方频道入口

打开 `Views/Communication/ChannelCenterView.swift`，修改：

1. 添加状态变量：

```swift
@State private var selectedOfficialChannel: CommunicationChannel?
@State private var showingOfficialChannel = false
```

2. 修改频道点击逻辑：

```swift
// 在频道行的点击处理中
Button(action: {
    if subscribedChannel.channel.channelType == .official {
        selectedOfficialChannel = subscribedChannel.channel
        showingOfficialChannel = true
    } else {
        // 原有的进入聊天逻辑
        selectedChannel = subscribedChannel.channel
        showingChat = true
    }
}) {
    // 频道行视图...
}
```

3. 添加 navigationDestination：

```swift
.navigationDestination(isPresented: $showingOfficialChannel) {
    if let channel = selectedOfficialChannel {
        OfficialChannelDetailView(channel: channel)
    }
}
```

---

### 3.3 Day 36-C：消息聚合页

#### 步骤1：扩展 CommunicationManager

在 `Managers/CommunicationManager.swift` 中添加：

```swift
// MARK: - 消息聚合相关

/// 频道摘要（用于消息聚合页）
struct ChannelSummary: Identifiable {
    let channel: CommunicationChannel
    let lastMessage: ChannelMessage?
    let unreadCount: Int

    var id: UUID { channel.id }
}

/// 获取所有订阅频道的摘要（最新消息 + 未读数）
func getChannelSummaries() -> [ChannelSummary] {
    return subscribedChannels.map { subscribedChannel in
        let messages = channelMessages[subscribedChannel.channel.id] ?? []
        let lastMessage = messages.last
        // 简化版：暂不计算真实未读数，后续可扩展
        let unreadCount = 0

        return ChannelSummary(
            channel: subscribedChannel.channel,
            lastMessage: lastMessage,
            unreadCount: unreadCount
        )
    }.sorted { summary1, summary2 in
        // 官方频道置顶
        if summary1.channel.channelType == .official && summary2.channel.channelType != .official {
            return true
        }
        if summary1.channel.channelType != .official && summary2.channel.channelType == .official {
            return false
        }
        // 其他按最新消息时间排序
        let time1 = summary1.lastMessage?.createdAt ?? summary1.channel.createdAt
        let time2 = summary2.lastMessage?.createdAt ?? summary2.channel.createdAt
        return time1 > time2
    }
}

/// 加载所有订阅频道的最新消息（用于消息聚合页初始化）
func loadAllChannelLatestMessages() async {
    for subscribedChannel in subscribedChannels {
        let channelId = subscribedChannel.channel.id
        // 只加载最新的 1 条消息（用于预览）
        do {
            let messages: [ChannelMessage] = try await client
                .from("channel_messages")
                .select()
                .eq("channel_id", value: channelId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let lastMessage = messages.first {
                if channelMessages[channelId] == nil {
                    channelMessages[channelId] = [lastMessage]
                } else if !channelMessages[channelId]!.contains(where: { $0.id == lastMessage.id }) {
                    channelMessages[channelId]?.append(lastMessage)
                }
            }
        } catch {
            print("❌ [消息聚合] 加载频道 \(channelId) 最新消息失败: \(error)")
        }
    }
}
```

#### 步骤2：创建 MessageRowView 组件

创建 `Views/Communication/MessageRowView.swift`：

```swift
import SwiftUI

struct MessageRowView: View {
    let summary: CommunicationManager.ChannelSummary

    private var isOfficial: Bool {
        summary.channel.channelType == .official
    }

    var body: some View {
        HStack(spacing: 12) {
            // 频道图标
            channelIcon

            // 频道信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(summary.channel.name)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.text)

                    if isOfficial {
                        Text("官方")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // 时间
                    if let lastMessage = summary.lastMessage {
                        Text(lastMessage.timeAgo)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.secondaryText)
                    }
                }

                // 最新消息预览
                HStack {
                    if let lastMessage = summary.lastMessage {
                        if let callsign = lastMessage.senderCallsign {
                            Text("\(callsign): ")
                                .font(.subheadline)
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.secondaryText)
                            .lineLimit(1)
                    } else {
                        Text("暂无消息")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.secondaryText)
                            .italic()
                    }

                    Spacer()

                    // 未读数
                    if summary.unreadCount > 0 {
                        Text("\(summary.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(ApocalypseTheme.primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        .background(isOfficial ? ApocalypseTheme.primary.opacity(0.1) : ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    private var channelIcon: some View {
        ZStack {
            Circle()
                .fill(channelIconColor.opacity(0.2))
                .frame(width: 50, height: 50)

            Image(systemName: channelIconName)
                .font(.system(size: 22))
                .foregroundColor(channelIconColor)
        }
    }

    private var channelIconName: String {
        switch summary.channel.channelType {
        case .official: return "megaphone.fill"
        case .public_channel: return "antenna.radiowaves.left.and.right"
        case .walkieTalkie: return "person.wave.2.fill"
        case .campRadio: return "radio.fill"
        case .satellite: return "antenna.radiowaves.left.and.right.circle.fill"
        }
    }

    private var channelIconColor: Color {
        switch summary.channel.channelType {
        case .official: return .red
        case .public_channel: return .blue
        case .walkieTalkie: return ApocalypseTheme.primary
        case .campRadio: return .purple
        case .satellite: return .cyan
        }
    }
}
```

#### 步骤3：重写 MessageCenterView

创建/重写 `Views/Communication/MessageCenterView.swift`：

```swift
import SwiftUI

struct MessageCenterView: View {
    @StateObject private var communicationManager = CommunicationManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var isLoading = true
    @State private var selectedChannel: CommunicationChannel?
    @State private var showingChat = false
    @State private var showingOfficialChannel = false

    private var summaries: [CommunicationManager.ChannelSummary] {
        communicationManager.getChannelSummaries()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 标题栏
                    headerView

                    // 内容区
                    if isLoading {
                        loadingView
                    } else if summaries.isEmpty {
                        emptyStateView
                    } else {
                        messageListView
                    }
                }
            }
            .onAppear {
                loadData()
            }
            .navigationDestination(isPresented: $showingChat) {
                if let channel = selectedChannel {
                    ChannelChatView(channel: channel)
                }
            }
            .navigationDestination(isPresented: $showingOfficialChannel) {
                if let channel = selectedChannel {
                    OfficialChannelDetailView(channel: channel)
                }
            }
        }
    }

    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("消息中心")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.text)

            Spacer()

            // 刷新按钮
            Button(action: { loadData() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18))
                    .foregroundColor(ApocalypseTheme.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 加载中
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.secondaryText)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.secondaryText.opacity(0.5))

            Text("暂无消息")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.text)

            Text("订阅频道后，消息会显示在这里")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.secondaryText)

            Spacer()
        }
    }

    // MARK: - 消息列表
    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(summaries) { summary in
                    Button(action: {
                        selectedChannel = summary.channel
                        // 根据频道类型选择不同的详情页
                        if summary.channel.channelType == .official {
                            showingOfficialChannel = true
                        } else {
                            showingChat = true
                        }
                    }) {
                        MessageRowView(summary: summary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 方法
    private func loadData() {
        isLoading = true

        Task {
            if let userId = authManager.currentUser?.id {
                await communicationManager.loadSubscribedChannels(userId: userId)
                await communicationManager.loadAllChannelLatestMessages()
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }
}
```

---

### 3.4 Day 36-D：PTT通话 + 呼号设置

#### 步骤1：创建 user_profiles 表

使用 MCP Supabase 工具执行 SQL：

```sql
-- 创建 user_profiles 表（存储呼号）
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    callsign TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 启用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 用户只能查看和修改自己的资料
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_user_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_user_profiles_updated_at();
```

**验证**：

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_profiles';
```

#### 步骤2：重写 PTTCallView

创建/重写 `Views/Communication/PTTCallView.swift`：

```swift
import SwiftUI

struct PTTCallView: View {
    @StateObject private var communicationManager = CommunicationManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var selectedChannelId: UUID?
    @State private var messageContent: String = ""
    @State private var isPressingPTT: Bool = false
    @State private var showingSuccess: Bool = false

    private var subscribedChannels: [SubscribedChannel] {
        communicationManager.subscribedChannels.filter {
            // 排除官方频道（官方频道只能接收）
            !communicationManager.isOfficialChannel($0.channel.id)
        }
    }

    private var selectedChannel: CommunicationChannel? {
        subscribedChannels.first { $0.channel.id == selectedChannelId }?.channel
    }

    private var canSend: Bool {
        communicationManager.canSendMessage() &&
        selectedChannel != nil &&
        !messageContent.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            ApocalypseTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 标题
                headerView

                // 当前频率卡片
                if let channel = selectedChannel {
                    frequencyCard(channel: channel)
                }

                // 频道切换标签栏
                channelTabBar

                Spacer()

                // 消息输入区
                messageInputArea

                // PTT 按钮
                pttButton

                Spacer()

                // 提示文字
                Text("长按按钮发送呼叫，松开结束")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.secondaryText)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            if selectedChannelId == nil {
                selectedChannelId = subscribedChannels.first?.channel.id
            }
        }
        .overlay(successToast)
    }

    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("PTT 呼叫")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.text)

            Spacer()

            // 当前设备
            HStack(spacing: 4) {
                Image(systemName: communicationManager.getCurrentDeviceType().iconName)
                Text(communicationManager.getCurrentDeviceType().displayName)
                    .font(.caption)
            }
            .foregroundColor(ApocalypseTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ApocalypseTheme.primary.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 频率卡片
    private func frequencyCard(channel: CommunicationChannel) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24))
                    .foregroundColor(ApocalypseTheme.primary)

                Spacer()

                // 范围指示
                HStack(spacing: 4) {
                    Text(communicationManager.getCurrentDeviceType().rangeText)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
                .foregroundColor(ApocalypseTheme.secondaryText)
            }

            Text(channel.channelCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(ApocalypseTheme.text)

            Text(channel.name)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    // MARK: - 频道切换标签栏
    private var channelTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(subscribedChannels) { subscribedChannel in
                    let channel = subscribedChannel.channel
                    let isSelected = channel.id == selectedChannelId

                    Button(action: {
                        selectedChannelId = channel.id
                    }) {
                        HStack(spacing: 4) {
                            Text(channel.channelCode)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(channel.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? .white : ApocalypseTheme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - 消息输入区
    private var messageInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("呼叫内容")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ApocalypseTheme.text)

            TextEditor(text: $messageContent)
                .frame(height: 80)
                .padding(12)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)
                .foregroundColor(ApocalypseTheme.text)
                .overlay(
                    Group {
                        if messageContent.isEmpty {
                            Text("输入您的呼叫内容，然后按住PTT按钮发送")
                                .foregroundColor(ApocalypseTheme.secondaryText)
                                .padding(16)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - PTT 按钮
    private var pttButton: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: isPressingPTT ? "waveform" : "mic.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)

                Text(isPressingPTT ? "发送中..." : "按住发送")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 120)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isPressingPTT
                                ? [Color.gray, Color.gray.opacity(0.7)]
                                : (canSend
                                    ? [ApocalypseTheme.primary, ApocalypseTheme.primary.opacity(0.7)]
                                    : [Color.gray, Color.gray.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: isPressingPTT ? Color.gray.opacity(0.5) : ApocalypseTheme.primary.opacity(0.5), radius: 10)
            .scaleEffect(isPressingPTT ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressingPTT)
        }
        .disabled(!canSend)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in
                    guard canSend else { return }
                    isPressingPTT = true
                    triggerHapticFeedback()
                }
                .onEnded { _ in
                    isPressingPTT = false
                    sendPTTMessage()
                }
        )
    }

    // MARK: - 成功提示
    private var successToast: some View {
        Group {
            if showingSuccess {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("消息已发送")
                            .font(.subheadline)
                            .foregroundColor(ApocalypseTheme.text)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(20)
                    .shadow(radius: 10)

                    Spacer().frame(height: 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - 方法
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func sendPTTMessage() {
        guard let channelId = selectedChannelId,
              !messageContent.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        let content = messageContent

        Task {
            let success = await communicationManager.sendChannelMessage(
                channelId: channelId,
                content: content,
                latitude: nil,
                longitude: nil
            )

            if success {
                await MainActor.run {
                    messageContent = ""
                    showingSuccess = true

                    // 成功震动
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)

                    // 隐藏成功提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSuccess = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - DeviceType 扩展（如果不存在）
extension DeviceType {
    var iconName: String {
        switch self {
        case .radio: return "radio"
        case .walkieTalkie: return "person.wave.2.fill"
        case .campRadio: return "antenna.radiowaves.left.and.right"
        case .satellite: return "antenna.radiowaves.left.and.right.circle"
        }
    }

    var displayName: String {
        switch self {
        case .radio: return "收音机"
        case .walkieTalkie: return "对讲机"
        case .campRadio: return "营地电台"
        case .satellite: return "卫星通讯"
        }
    }

    var rangeText: String {
        switch self {
        case .radio: return "仅接收"
        case .walkieTalkie: return "3km"
        case .campRadio: return "30km"
        case .satellite: return "100km+"
        }
    }
}
```

#### 步骤3：创建 CallsignSettingsSheet

创建 `Views/Communication/CallsignSettingsSheet.swift`：

```swift
import SwiftUI

struct CallsignSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var callsign: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    private var isValid: Bool {
        let trimmed = callsign.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 3 && trimmed.count <= 20
    }

    var body: some View {
        NavigationView {
            ZStack {
                ApocalypseTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // 说明
                    infoSection

                    // 输入框
                    inputSection

                    // 错误提示
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // 保存按钮
                    saveButton

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("呼号设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
        .onAppear {
            loadCurrentCallsign()
        }
        .alert("保存成功", isPresented: $showingSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("您的呼号已更新为：\(callsign)")
        }
    }

    // MARK: - 说明区
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(ApocalypseTheme.primary)
                Text("什么是呼号？")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.text)
            }

            Text("呼号是您在电波中的身份标识，其他幸存者会通过呼号识别您。就像真实电台中的 \"CQ CQ，这里是 BJ-Alpha-001\"。")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.secondaryText)

            // 格式示例
            VStack(alignment: .leading, spacing: 4) {
                Text("推荐格式：")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.secondaryText)

                HStack(spacing: 12) {
                    ForEach(["BJ-Alpha-001", "SH-Beta-42", "Survivor-X"], id: \.self) { example in
                        Text(example)
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ApocalypseTheme.primary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 输入区
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("您的呼号")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ApocalypseTheme.text)

            TextField("输入呼号（3-20字符）", text: $callsign)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(14)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(10)
                .foregroundColor(ApocalypseTheme.text)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isValid ? ApocalypseTheme.primary : Color.gray, lineWidth: 1)
                )
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            Text("仅支持字母、数字和连字符（-）")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.secondaryText)
        }
    }

    // MARK: - 保存按钮
    private var saveButton: some View {
        Button(action: saveCallsign) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("保存呼号")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isValid ? ApocalypseTheme.primary : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(!isValid || isLoading)
    }

    // MARK: - 方法
    private func loadCurrentCallsign() {
        // 从 authManager 加载当前呼号
        // 这里假设 authManager 有 userProfile 属性
        // 如果没有，需要添加或直接从数据库读取
        callsign = ""  // TODO: 从 authManager 读取
    }

    private func saveCallsign() {
        guard isValid else { return }

        // 验证格式：仅字母、数字、连字符
        let pattern = "^[A-Za-z0-9-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(callsign.startIndex..., in: callsign)

        if regex?.firstMatch(in: callsign, range: range) == nil {
            errorMessage = "呼号只能包含字母、数字和连字符"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let userId = authManager.currentUser?.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
                }

                // 使用 upsert 保存呼号
                try await supabase
                    .from("user_profiles")
                    .upsert([
                        "user_id": userId.uuidString,
                        "callsign": callsign
                    ], onConflict: "user_id")
                    .execute()

                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "保存失败：\(error.localizedDescription)"
                }
            }
        }
    }
}
```

#### 步骤4：在设备管理页添加呼号设置入口

打开 `Views/Communication/DeviceManagementView.swift`，添加：

```swift
// 添加状态变量
@State private var showingCallsignSettings = false

// 在设备列表下方添加呼号设置按钮
VStack(spacing: 16) {
    // ... 现有的设备卡片列表 ...

    Divider()
        .background(ApocalypseTheme.secondaryText.opacity(0.3))
        .padding(.vertical, 8)

    // 呼号设置入口
    Button(action: {
        showingCallsignSettings = true
    }) {
        HStack {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 20))
                .foregroundColor(ApocalypseTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("呼号设置")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.text)

                Text("未设置")  // TODO: 显示实际呼号
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.secondaryText)
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
    .buttonStyle(PlainButtonStyle())
}
.sheet(isPresented: $showingCallsignSettings) {
    CallsignSettingsSheet()
}
```

---

## 四、验收标准

### 4.1 Day 36-A 代码检查

- [ ] 官方频道在数据库中存在（UUID: 00000000-0000-0000-0000-000000000000）
- [ ] CommunicationModels.swift 已添加 MessageCategory 枚举
- [ ] MessageCategory 有 displayName, color, iconName 属性
- [ ] MessageMetadata 已添加 category 字段
- [ ] ChannelMessage 有 category 计算属性
- [ ] CommunicationManager.swift 已添加 officialChannelId
- [ ] CommunicationManager.swift 已添加 ensureOfficialChannelSubscribed()
- [ ] CommunicationManager.swift 已添加 isOfficialChannel()
- [ ] 登录后会自动订阅官方频道

### 4.2 Day 36-B 代码检查

- [ ] OfficialChannelDetailView.swift 已重写
- [ ] CategoryChip 组件已创建
- [ ] OfficialMessageBubble 组件已创建
- [ ] ChannelCenterView.swift 已添加官方频道入口逻辑
- [ ] 能从频道列表点击官方频道进入详情页

### 4.3 Day 36-C 代码检查

- [ ] CommunicationManager.swift 已添加 ChannelSummary 结构体
- [ ] CommunicationManager.swift 已添加 getChannelSummaries() 方法
- [ ] CommunicationManager.swift 已添加 loadAllChannelLatestMessages() 方法
- [ ] MessageRowView.swift 已创建
- [ ] MessageCenterView.swift 已重写（包含 NavigationStack）

### 4.4 Day 36-D 代码检查

- [ ] user_profiles 表已创建
- [ ] user_profiles 表有 callsign 字段
- [ ] RLS 策略已启用
- [ ] PTTCallView.swift 已重写
- [ ] CallsignSettingsSheet.swift 已创建
- [ ] DeviceManagementView.swift 已添加呼号设置入口
- [ ] DeviceType 扩展已添加（iconName, displayName, rangeText）

### 4.5 功能测试

#### 测试1：官方频道订阅
- [ ] 登录应用
- [ ] 官方频道出现在频道列表中
- [ ] 点击官方频道进入 OfficialChannelDetailView
- [ ] 显示分类过滤器

#### 测试2：消息中心显示
- [ ] 进入"消息"Tab
- [ ] 显示所有订阅频道
- [ ] 官方频道置顶显示
- [ ] 显示最新一条消息预览

#### 测试3：PTT通话
- [ ] 进入PTT通话页面
- [ ] 输入呼叫内容
- [ ] 长按PTT按钮 → 震动反馈
- [ ] 松开按钮 → 消息发送
- [ ] 显示"✅ 消息已发送"

#### 测试4：呼号设置
- [ ] 设备管理页显示"呼号设置"入口
- [ ] 点击入口 → 显示设置弹窗
- [ ] 输入新呼号 → 保存成功
- [ ] 发送消息后，消息显示新呼号

---

## 五、踩坑记录

### 5.1 数据库问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 官方频道不显示 | 数据库未创建官方频道 | 用MCP执行SQL创建 |
| 呼号保存失败 | user_profiles表不存在 | 用MCP创建user_profiles表 |
| 消息显示"匿名用户" | 未设置呼号或表不存在 | 检查user_profiles表和RPC函数 |

### 5.2 导航问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 点击频道进不去 | 缺少NavigationStack | MessageCenterView内添加NavigationStack |
| NavigationStack报错 | 嵌套了多个NavigationStack | 确保只在一个地方有NavigationStack |
| navigationDestination不生效 | NavigationStack在外层 | 移除内层的NavigationStack |

### 5.3 逻辑问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 消息中心为空 | 未加载订阅频道 | 检查loadSubscribedChannels()调用 |
| PTT按钮不响应 | canSend条件不满足 | 检查设备、内容、频道是否都有值 |
| 官方频道不置顶 | 排序逻辑错误 | 检查getChannelSummaries()的排序代码 |

---

## 六、完成后的预期效果

### 6.1 功能测试结果

| 测试项 | 预期结果 |
|-------|---------|
| 官方频道 | 登录后自动订阅，消息分类正常 |
| 消息中心 | 显示所有频道，官方频道置顶 |
| PTT通话 | 长按发送消息，有震动反馈 |
| 呼号设置 | 可以查看和修改呼号 |

### 6.2 日志输出示例

```
✅ [官方频道] 已自动订阅
✅ [消息聚合] 加载所有频道最新消息
✅ [PTT] 消息已发送
✅ [呼号] 保存成功: BJ-Alpha-001
```

---

## 七、技术总结

### 7.1 核心概念

| 概念 | 说明 |
|------|------|
| **官方频道** | 固定UUID，强制订阅，消息分类 |
| **消息聚合** | 汇总所有频道的最新消息 |
| **NavigationStack** | SwiftUI导航容器 |
| **PTT通话** | 长按按钮发送，像真实对讲机 |
| **呼号系统** | 用户电台身份标识 |

### 7.2 代码行数统计

| 模块 | 行数 |
|------|------|
| MessageCategory 枚举 | ~30 |
| 官方频道逻辑 | ~40 |
| 消息聚合逻辑 | ~50 |
| OfficialChannelDetailView | ~150 |
| MessageCenterView | ~120 |
| MessageRowView | ~80 |
| PTTCallView | ~250 |
| CallsignSettingsSheet | ~150 |
| **总计** | **~870** |

---

## 八、后续扩展

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 未读数量计算 | 显示真实未读数 | 中 |
| 呼号验证 | 检查呼号是否重复 | 低 |
| 消息分类推送 | 不同分类不同通知方式 | 低 |
| PTT语音 | 真实语音通话 | 高 |

---

*Day 36 消息中心与PTT通话开发方案 v1.0*
*包含完整的四步实现方案*

---

## 附录：编译错误记录与解决方案

### 实际开发中遇到的编译错误

在实际开发 Day 36 时遇到的编译错误及解决方案：

#### 错误 1：MessageRowView.swift - nil 类型推断问题
```
'nil' requires a contextual type
```

**原因**：Preview 中初始化 `ChannelMessage` 时，直接写 `nil` 无法推断 Optional 类型

**解决方案**：
```swift
// ❌ 错误写法
location: nil,
metadata: nil,

// ✅ 正确写法
location: nil as ChannelLocation?,
metadata: nil as MessageMetadata?,
```

**最终方案**：简化 Preview，避免创建复杂对象
```swift
lastMessage: nil,  // 直接不显示消息
```

---

#### 错误 2：ChannelMessage 初始化失败
```
Extra arguments at positions #1, #2, #3... in call
'init(from:)' declared here
```

**原因**：`ChannelMessage` 是 `Codable`，只有 `init(from: Decoder)` 初始化器，没有直接的成员初始化器

**解决方案**：在 Preview 中不创建 ChannelMessage 实例，使用 `nil`

---

#### 错误 3：CommunicationChannel 不遵循 Hashable
```
Instance method 'navigationDestination(item:destination:)' requires that 'CommunicationChannel' conform to 'Hashable'
```

**原因**：`navigationDestination(item:)` 需要 item 类型遵循 `Hashable`

**解决方案**：
```swift
// 1. 添加协议遵循
struct CommunicationChannel: Codable, Identifiable, Hashable {

// 2. 让关联类型也遵循 Hashable
struct ChannelLocation: Codable, Hashable {

// 3. 手动实现 Hashable（因为 Date 不是 Hashable）
func hash(into hasher: inout Hasher) {
    hasher.combine(id)
}

static func == (lhs: CommunicationChannel, rhs: CommunicationChannel) -> Bool {
    lhs.id == rhs.id
}
```

---

#### 错误 4：缺少 Auth 模块导入
```
Property 'id' is not available due to missing import of defining module 'Auth'
```

**原因**：访问 `authManager.currentUser?.id` 时缺少 Auth 模块导入

**影响文件**：
- MessageCenterView.swift
- PTTCallView.swift
- CallsignSettingsSheet.swift

**解决方案**：
```swift
import SwiftUI
import Auth  // ✅ 添加这行
```

---

#### 错误 5：sendMessage 方法不存在
```
Cannot call value of non-function type 'Binding<Subject>'
```

**原因**：调用了不存在的 `sendMessage` 方法，实际方法名是 `sendChannelMessage`

**解决方案**：
```swift
// ❌ 错误
await communicationManager.sendMessage(
    channelId: channel.id,
    content: messageText,
    senderId: userId,
    deviceType: deviceType
)

// ✅ 正确
await communicationManager.sendChannelMessage(
    channelId: channel.id,
    content: messageText,
    latitude: location?.latitude,
    longitude: location?.longitude
)
```

---

#### 错误 6：访问私有属性 currentLocation
```
'currentLocation' is inaccessible due to 'private' protection level
```

**原因**：`LocationManager.shared.currentLocation` 是私有属性

**解决方案**：使用公开的 `userLocation` 属性
```swift
// ❌ 错误
let location = LocationManager.shared.currentLocation

// ✅ 正确
let location = LocationManager.shared.userLocation
```

---

#### 错误 7：缺少 CoreLocation 导入
```
Property 'latitude' is not available due to missing import of defining module '_LocationEssentials'
```

**原因**：访问 `CLLocationCoordinate2D` 的 latitude/longitude 属性需要导入 CoreLocation

**解决方案**：
```swift
import SwiftUI
import Auth
import CoreLocation  // ✅ 添加这行
```

---

#### 错误 8-10：缺少 Trade 相关视图
```
Cannot find 'MarketView' in scope
Cannot find 'MyOffersView' in scope
Cannot find 'TradeHistoryView' in scope
```

**原因**：这些是旧代码引用的视图，但文件不存在（非 Day 36 问题）

**解决方案**：创建占位符视图
```swift
struct MarketView: View {
    var body: some View {
        VStack {
            Text("功能开发中")
        }
        .background(ApocalypseTheme.background)
    }
}
```

---

#### 警告：不必要的 nil 合并操作
```
Left side of nil coalescing operator '??' has non-optional type 'String'
```

**原因**：`error.localizedDescription` 已经是 `String` 类型，不需要 `??`

**解决方案**：
```swift
// ❌ 警告
error.localizedDescription ?? "未知错误"

// ✅ 正确
error.localizedDescription
```

---

### 经验总结

#### 1. Codable 类型的初始化
- Codable 类型只有 `init(from: Decoder)` 初始化器
- Preview 中尽量避免创建复杂的 Codable 对象
- 使用 `nil` 或简化的数据结构

#### 2. Hashable 协议实现
- 当类型包含 `Date` 等非 Hashable 成员时，需要手动实现
- 可以仅基于 `id` 来实现 hash 和 equality
- 关联类型也需要遵循 Hashable

#### 3. 模块导入
- `Auth` 模块：访问用户 ID 时需要
- `CoreLocation` 模块：访问位置坐标时需要
- `Supabase` 模块：数据库操作时需要

#### 4. 方法签名检查
- 使用 Grep 搜索方法定义，确认方法名和参数
- 注意方法重载和参数顺序

#### 5. 访问权限
- 检查属性的访问修饰符（private/internal/public）
- 使用公开的 API 而不是私有实现

---

### 调试技巧

1. **使用 Grep 快速定位**
   ```bash
   grep -r "func methodName" path/
   ```

2. **检查类型定义**
   ```bash
   grep "struct ClassName" file.swift
   ```

3. **查看协议遵循**
   ```bash
   grep "struct.*: Codable" file.swift
   ```

4. **分批修复错误**
   - 先修复类型和协议错误
   - 再修复导入问题
   - 最后修复方法调用错误

---

### 编译成功标志

所有 Day 36 功能文件编译通过：
- ✅ CommunicationModels.swift（添加 Hashable）
- ✅ MessageCenterView.swift（添加 Auth 导入）
- ✅ PTTCallView.swift（添加 Auth + CoreLocation 导入）
- ✅ CallsignSettingsSheet.swift（添加 Auth 导入）
- ✅ MessageRowView.swift（简化 Preview）
- ✅ OfficialChannelDetailView.swift
- ✅ DeviceManagementView.swift

