import SwiftUI

struct MailboxItemRow: View {
    let item: DBMailboxItem
    let onClaim: () -> Void
    
    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rarityColor(item.rarity).opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(itemIcon(item.item_id))
                    .font(.title)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Text("数量: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    rarityBadge(item.rarity)
                }
            }
            
            Spacer()
            
            // Claim button
            Button(action: onClaim) {
                Text("领取")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .frame(width: 60, height: 32)
                    .background(brandOrange)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(brandOrange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func itemIcon(_ itemId: String) -> String {
        let icons: [String: String] = [
            "water": "💧",
            "canned_food": "🍱",
            "wood": "🪵",
            "stone": "🪨",
            "metal": "🔩",
            "glass": "🔍",
            "cloth": "🧶",
            "bandage": "🩹",
            "first_aid_kit": "🩺",
            "electronic_part": "⚡",
            "mechanical_part": "🔧",
            "solar_panel": "☀️",
            "satellite_module": "🛰️",
            "ancient_tech": "🔮",
            "rifle": "🔫",
            "armor": "🛡️",
            "water_bottle": "💧"
        ]
        return icons[itemId] ?? "📦"
    }
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "common":
            return .gray
        case "rare":
            return .blue
        case "epic":
            return .purple
        case "legendary":
            return Color(red: 1, green: 0.8, blue: 0)
        default:
            return .gray
        }
    }
    
    private func rarityBadge(_ rarity: String) -> some View {
        let color = rarityColor(rarity)
        let text: String
        
        switch rarity {
        case "common":
            text = "普通"
        case "rare":
            text = "稀有"
        case "epic":
            text = "史诗"
        case "legendary":
            text = "传说"
        default:
            text = "普通"
        }
        
        return Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(8)
    }
}
