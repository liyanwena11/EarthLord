import SwiftUI

struct BackpackView: View {
    // ✅ 核心修复：单例必须用 @ObservedObject，不能用 @StateObject
    // @StateObject 会创建新实例，@ObservedObject 用于观察已存在的实例
    @ObservedObject private var manager = ExplorationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 实时负重显示卡
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "scalemass.fill").foregroundColor(.orange)
                    Text("背包当前负重").font(.headline)
                    Spacer()
                    // ✅ 修复点：直接访问 manager.totalWeight，不加 $
                    Text("\(String(format: "%.1f", manager.totalWeight)) / \(Int(manager.maxCapacity)) kg")
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(manager.totalWeight > 90 ? .red : .primary)
                }
                
                // 进度条
                ProgressView(value: manager.totalWeight, total: manager.maxCapacity)
                    .tint(manager.totalWeight > 90 ? .red : .green)
                    .scaleEffect(x: 1, y: 1.5)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .padding()

            // 2. 动态物品列表
            if manager.backpackItems.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "shippingbox").font(.system(size: 60)).foregroundColor(.gray)
                    Text("背包空空如也").foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(manager.backpackItems) { item in
                        HStack(spacing: 15) {
                            // 物品图标
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.1)).frame(width: 50, height: 50)
                                Image(systemName: item.icon).foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.headline)
                                Text("\(String(format: "%.1f", item.weight))kg / 每单位").font(.caption).foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("x\(item.quantity)").bold().foregroundColor(.orange)
                                
                                // ✅ 修复点：点击动作，不加 $
                                Button(action: {
                                    withAnimation {
                                        manager.useItem(item: item)
                                    }
                                }) {
                                    Text("使用")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color.orange).foregroundColor(.white).cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("物资背包")
        // ✅ Day 22：每次页面出现时强制刷新重量计算，确保数据同步
        .onAppear {
            manager.updateWeight()
            print("📦 [BackpackView] 页面出现，当前 \(manager.backpackItems.count) 种物品")
        }
        // ✅ 使用 id 强制 SwiftUI 在数据变化时重建列表
        .id(manager.backpackItems.count)
    }
}
