import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil
    @State private var showContactSupport = false

    private let helpCategories: [HelpCategory] = [
        HelpCategory(
            icon: "flag.fill",
            title: "圈地系统",
            items: [
                HelpItem(
                    question: "如何开始圈地？",
                    answer: "点击地图页面的\"开始圈地\"按钮，然后在真实世界中行走。App会记录你的路径，当你走完想要圈占的区域后，点击\"停止圈地\"按钮。系统会自动检测路径是否闭合，并计算圈占的面积。"
                ),
                HelpItem(
                    question: "圈地有什么限制？",
                    answer: "1. 单次圈地面积不能超过10000平方米\n2. 路径必须形成闭环\n3. 不能与他人的领地重叠\n4. 需要在开启GPS后才能圈地"
                ),
                HelpItem(
                    question: "如何查看我的领地？",
                    answer: "进入\"领地\"标签页，可以查看所有已圈占的领地列表。点击某个领地可以查看详细信息，包括面积、位置、建造的建筑等。"
                )
            ]
        ),
        HelpCategory(
            icon: "magnifyingglass.fill",
            title: "探索系统",
            items: [
                HelpItem(
                    question: "什么是POI？",
                    answer: "POI是Point of Interest的缩写，即兴趣点。在游戏中，真实世界中的商店、餐厅、公园等地点会显示为POI标记。探索这些地点可以获得资源。"
                ),
                HelpItem(
                    question: "如何探索POI？",
                    answer: "当你的位置靠近某个POI时（500米内），该POI会在地图上高亮显示。点击该POI标记，然后点击\"探索\"按钮即可获得资源。"
                ),
                HelpItem(
                    question: "探索有次数限制吗？",
                    answer: "是的，每个POI每天只能探索一次。探索后会进入冷却时间，第二天才能再次探索。"
                )
            ]
        ),
        HelpCategory(
            icon: "building.2.fill",
            title: "建造系统",
            items: [
                HelpItem(
                    question: "如何建造建筑？",
                    answer: "进入\"领地\"标签页，选择一个领地，然后点击\"建造\"按钮。选择要建造的建筑类型，确认位置后即可建造。"
                ),
                HelpItem(
                    question: "建造需要什么资源？",
                    answer: "不同建筑需要不同的资源。例如，建造小屋需要木材和石头，建造农场需要木材和种子。你可以通过探索POI获得这些资源。"
                ),
                HelpItem(
                    question: "建筑有什么作用？",
                    answer: "建筑可以提供各种加成：\n• 小屋：增加存储空间\n• 农场：生产食物\n• 工场：生产材料\n• 防御塔：保护领地"
                )
            ]
        ),
        HelpCategory(
            icon: "arrow.left.arrow.right",
            title: "交易系统",
            items: [
                HelpItem(
                    question: "如何交易物品？",
                    answer: "进入\"资源\"标签页，点击\"交易\"按钮。你可以浏览市场上的交易，或创建自己的交易挂单。"
                ),
                HelpItem(
                    question: "交易需要手续费吗？",
                    answer: "是的，每笔交易会收取5%的手续费。"
                )
            ]
        ),
        HelpCategory(
            icon: "figure.walk",
            title: "行走奖励",
            items: [
                HelpItem(
                    question: "如何获得行走奖励？",
                    answer: "只需打开App并携带手机行走，系统会自动记录你的步数和距离。每达到一定里程碑，就能获得奖励。"
                )
            ]
        ),
        HelpCategory(
            icon: "antenna.radiowaves.left.and.right",
            title: "通讯系统",
            items: [
                HelpItem(
                    question: "如何加入频道？",
                    answer: "进入\"通讯\"标签页，可以浏览附近玩家创建的频道。点击\"加入\"即可加入频道。你也可以创建自己的频道。"
                ),
                HelpItem(
                    question: "通讯有距离限制吗？",
                    answer: "是的，频道和消息功能有距离限制。只有在你附近的玩家（5公里内）才能看到你的频道和消息。"
                )
            ]
        ),
        HelpCategory(
            icon: "creditcard",
            title: "充值订阅",
            items: [
                HelpItem(
                    question: "如何购买订阅？",
                    answer: "进入\"个人\"标签页，点击\"订阅\"按钮。选择你想要的订阅计划，确认支付即可。"
                )
            ]
        ),
        HelpCategory(
            icon: "person.fill",
            title: "账号相关",
            items: [
                HelpItem(
                    question: "如何修改密码？",
                    answer: "进入\"设置\" → \"账号设置\" → \"修改密码\"，输入当前密码和新密码即可。"
                ),
                HelpItem(
                    question: "如何删除账号？",
                    answer: "进入\"设置\" → \"账号设置\" → \"删除账号\"。注意：此操作不可恢复，会永久删除所有数据。"
                )
            ]
        )
    ]

    var filteredCategories: [HelpCategory] {
        if searchText.isEmpty {
            return helpCategories
        }

        return helpCategories.compactMap { category in
            let filteredItems = category.items.filter { item in
                item.question.lowercased().contains(searchText.lowercased()) ||
                item.answer.lowercased().contains(searchText.lowercased())
            }

            if filteredItems.isEmpty {
                return nil
            }

            return HelpCategory(
                icon: category.icon,
                title: category.title,
                items: filteredItems
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))

                        TextField("搜索问题", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // 分类列表
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredCategories, id: \.title) { category in
                                CategorySection(category: category)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("帮助中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showContactSupport = true
                    } label: {
                        Image(systemName: "envelope.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showContactSupport) {
            ContactSupportView()
        }
    }
}

struct CategorySection: View {
    let category: HelpCategory
    @State private var expandedItems: Set<String> = []

    var body: some View {
        VStack(spacing: 1) {
            // 分类标题
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(ApocalypseTheme.primary)
                    .font(.system(size: 18))

                Text(category.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(category.items.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)

            // 问题列表
            ForEach(category.items, id: \.question) { item in
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: {
                        withAnimation {
                            if expandedItems.contains(item.question) {
                                expandedItems.remove(item.question)
                            } else {
                                expandedItems.insert(item.question)
                            }
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.question)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)

                                if expandedItems.contains(item.question) {
                                    Text(item.answer)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(3)
                                }
                            }

                            Spacer()

                            Image(systemName: expandedItems.contains(item.question) ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .contentShape(Rectangle())
                }
                .background(Color.white.opacity(0.03))
                .cornerRadius(10)
            }
        }
    }
}

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false

    private let topics = [
        "账号问题",
        "支付问题",
        "游戏玩法",
        "Bug反馈",
        "功能建议",
        "其他"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("问题类型", selection: $selectedTopic) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                } header: {
                    Text("选择问题类型")
                }

                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                } header: {
                    Text("详细描述")
                } footer: {
                    Text("请尽可能详细地描述你遇到的问题，我们会尽快回复。")
                }
            }
            .navigationTitle("联系客服")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发送") {
                        Task {
                            await sendMessage()
                        }
                    }
                    .disabled(selectedTopic.isEmpty || message.isEmpty || isLoading)
                }
            }
            .alert("成功", isPresented: $showSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("你的反馈已发送，我们会尽快回复")
            }
        }
    }

    private func sendMessage() async {
        isLoading = true
        // TODO: 实现发送反馈API调用
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
        showSuccessAlert = true
    }
}

struct HelpCategory {
    let icon: String
    let title: String
    let items: [HelpItem]
}

struct HelpItem {
    let question: String
    let answer: String
}

#Preview {
    HelpCenterView()
}
