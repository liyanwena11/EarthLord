import SwiftUI

struct TerritoryDetailView: View {
    let territory: Territory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(territory.name ?? "领地").font(.title).bold()
            Text("面积: \(Int(territory.area)) ㎡")
            
            Spacer()
            
            Button("放弃领地", role: .destructive) {
                // 救急版本：直接返回
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            
            Button("关闭") { dismiss() }
        }.padding()
    }
}
