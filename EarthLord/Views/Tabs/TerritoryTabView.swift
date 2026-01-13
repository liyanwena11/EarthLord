import SwiftUI

struct TerritoryTabView: View {
    @State private var territories: [Territory] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("我的领地统计") {
                    HStack {
                        Text("总数")
                        Spacer()
                        Text("\(territories.count)")
                    }
                }
                
                Section("领地列表") {
                    if territories.isEmpty {
                        Text("暂无领地，快去圈地吧！")
                    } else {
                        ForEach(territories) { territory in
                            VStack(alignment: .leading) {
                                Text(territory.name ?? "未命名领地").font(.headline)
                                Text("面积: \(Int(territory.area))㎡").font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("领地管理")
            .task {
                // 自动加载假数据
                territories = (try? await TerritoryManager.shared.loadMyTerritories()) ?? []
            }
        }
    }
}
