//
//  QuickLootResultView.swift
//  EarthLord
//
//  快速搜刮结果展示视图
//  用于显示从 POI 搜刮到的物品
//

import SwiftUI

struct QuickLootResultView: View {
    let lootItems: [BackpackItem]
    @Environment(\.dismiss) var dismiss
    private var manager = ExplorationManager.shared

    // ✅ 核心修复：显式声明公开的初始化方法
    init(lootItems: [BackpackItem]) {
        self.lootItems = lootItems
    }

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.08, blue: 0.12).edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Image(systemName: "box.truck.fill").font(.system(size: 60)).foregroundColor(.orange)
                    Text("快捷搜刮完成").font(.title.bold()).foregroundColor(.white)
                }
                .padding(.top, 40)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(lootItems) { item in
                            HStack {
                                Image(systemName: item.icon).foregroundColor(.blue)
                                    .frame(width: 40, height: 40).background(Color.blue.opacity(0.1)).cornerRadius(8)
                                Text(item.name).foregroundColor(.white)
                                Spacer()
                                Text("x\(item.quantity)").bold().foregroundColor(.orange)
                            }
                            .padding().background(Color.white.opacity(0.05)).cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    manager.updateWeight()
                    dismiss()
                }) {
                    Text("全部存入背包")
                        .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Color.orange).cornerRadius(15)
                }
                .padding(30)
            }
        }
    }
}
