import Foundation
import Supabase

/// AI 废土物品生成器
/// 调用 Supabase Edge Function (qwen-flash) 生成独特物品
/// 失败时静默降级为预设物品
@MainActor
class AIItemGenerator {
    static let shared = AIItemGenerator()
    private let supabase = supabaseClient
    private let functionURL: String = "https://lkekxzssfrspkyxtqysx.supabase.co/functions/v1/generate-ai-item"

    private init() {}

    // MARK: - AI 物品生成

    /// 调用 Edge Function 生成 AI 物品
    func generateItems(for poi: POIModel) async -> [BackpackItem] {
        do {
            let session = try await supabase.auth.session
            let token = session.accessToken

            // 构建请求
            guard let url = URL(string: functionURL) else {
                print("❌ [AI] URL 无效")
                return fallbackItems(for: poi)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // 映射 POI 稀有度到危险等级
            let dangerLevel: Int
            switch poi.rarity {
            case .common: dangerLevel = 1
            case .rare: dangerLevel = 3
            case .epic: dangerLevel = 4
            case .legendary: dangerLevel = 5
            }

            // 随机 POI 类型名
            let poiTypes = ["废弃超市", "废弃医院", "加油站遗址", "药店废墟", "工厂残骸", "仓库", "学校废墟"]
            let poiType = poiTypes.randomElement() ?? "废墟"

            let body: [String: Any] = [
                "poiType": poiType,
                "dangerLevel": dangerLevel,
                "poiName": poi.name
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("❌ [AI] 服务端错误 HTTP \(statusCode)")
                return fallbackItems(for: poi)
            }

            // 解析响应
            let result = try JSONDecoder().decode(AIResponse.self, from: data)
            let items = result.items.map { aiItem -> BackpackItem in
                BackpackItem(
                    id: UUID().uuidString,
                    itemId: "ai_\(UUID().uuidString.prefix(8))",
                    name: aiItem.name,
                    category: guessCategory(aiItem.name),
                    quantity: 1,
                    weight: aiItem.weight,
                    quality: nil,
                    icon: validateSFSymbol(aiItem.icon),
                    backstory: aiItem.backstory,
                    isAIGenerated: true,
                    itemRarity: mapRarity(aiItem.rarity)
                )
            }

            print("🤖 [AI] 生成 \(items.count) 件物品：\(items.map { $0.name }.joined(separator: ", "))")
            return items

        } catch {
            print("❌ [AI] 生成失败：\(error.localizedDescription)，使用预设物品")
            return fallbackItems(for: poi)
        }
    }

    // MARK: - 静默降级：预设物品

    private func fallbackItems(for poi: POIModel) -> [BackpackItem] {
        print("🔄 [AI] 降级：使用预设物品列表")

        let pool: [(id: String, name: String, cat: ItemCategory, w: Double, icon: String, story: String)]

        switch poi.rarity {
        case .common:
            pool = [
                ("fb_water", "浑浊的瓶装水", .water, 0.5, "drop.fill",
                 "瓶身上的标签早已模糊，但里面的水看起来还算清澈。在末日之后，这已经算是奢侈品了。"),
                ("fb_cracker", "发霉的饼干", .food, 0.2, "rectangle.compress.vertical",
                 "包装袋裂开了一角，饼干边缘泛着绿色，但饥饿让人无暇顾及这些。"),
            ]
        case .rare:
            pool = [
                ("fb_med", "过期急救包", .medical, 0.3, "cross.case.fill",
                 "红十字标志已经褪色，里面的绷带和碘伏却保存完好。末日里，这就是黄金。"),
                ("fb_can", "军用罐头", .food, 0.4, "square.stack.3d.up.fill",
                 "橄榄绿的罐身上印着部队番号。这批物资本该送往前线，如今却散落在废墟中。"),
                ("fb_torch", "改装手电", .tool, 0.3, "flashlight.on.fill",
                 "有人用电池和LED灯珠自制的手电筒，做工粗糙但亮度惊人。"),
            ]
        case .epic:
            pool = [
                ("fb_antibio", "未拆封抗生素", .medical, 0.05, "syringe.fill",
                 "密封包装完好无损的阿莫西林。在没有医疗系统的末日，这比子弹更有价值。"),
                ("fb_fuel", "高纯度燃料", .material, 2.0, "fuelpump.fill",
                 "从炼油厂深处找到的航空煤油，纯度极高，一罐够发电机运行三天。"),
            ]
        case .legendary:
            pool = [
                ("fb_serum", "实验血清", .medical, 0.1, "syringe.fill",
                 "标签上写着「Project EDEN - 第七代抗体」。没人知道这是什么，但所有势力都在寻找它。"),
                ("fb_core", "微型聚变核心", .material, 1.5, "bolt.fill",
                 "拳头大小的金属球体，表面散发着微弱的蓝光。据说这是灾变前最后一批量产的清洁能源核心。"),
                ("fb_map", "避难所坐标图", .tool, 0.05, "map.fill",
                 "一张手绘的地图，标注了三个地下避难所的精确位置。纸张边缘沾着干涸的血迹。"),
            ]
        }

        let count = min(Int.random(in: 1...2), pool.count)
        let selected = pool.shuffled().prefix(count)

        return selected.map { item in
            BackpackItem(
                id: UUID().uuidString,
                itemId: item.id,
                name: item.name,
                category: item.cat,
                quantity: 1,
                weight: item.w,
                quality: nil,
                icon: item.icon,
                backstory: item.story,
                isAIGenerated: false,
                itemRarity: poi.rarity
            )
        }
    }

    // MARK: - Helpers

    private func guessCategory(_ name: String) -> ItemCategory {
        if name.contains("水") || name.contains("饮") { return .water }
        if name.contains("食") || name.contains("罐") || name.contains("饼") { return .food }
        if name.contains("药") || name.contains("绷") || name.contains("血") || name.contains("医") { return .medical }
        if name.contains("工具") || name.contains("电") || name.contains("绳") || name.contains("地图") { return .tool }
        return .material
    }

    private func mapRarity(_ str: String) -> POIRarity {
        switch str.lowercased() {
        case "common", "普通": return .common
        case "rare", "稀有": return .rare
        case "epic", "史诗": return .epic
        case "legendary", "传说": return .legendary
        default: return .common
        }
    }

    private func validateSFSymbol(_ name: String) -> String {
        let validIcons = [
            "drop.fill", "cross.case.fill", "pills.fill", "syringe.fill",
            "flashlight.on.fill", "wrench.fill", "bolt.fill", "shield.fill",
            "cube.fill", "square.stack.3d.up.fill", "fuelpump.fill",
            "rectangle.stack.fill", "link", "map.fill", "flame.fill",
            "battery.100.bolt", "antenna.radiowaves.left.and.right",
            "square.fill", "rectangle.compress.vertical", "bag.fill",
            "key.fill", "lock.fill", "doc.text.fill", "book.fill"
        ]
        return validIcons.contains(name) ? name : "shippingbox.fill"
    }
}

// MARK: - AI 响应模型

private struct AIResponse: Decodable {
    let items: [AIItem]
}

private struct AIItem: Decodable {
    let name: String
    let rarity: String
    let backstory: String
    let weight: Double
    let icon: String
}
