import SwiftUI

struct TerritoryTabView: View {
    @State private var selectedFilter = 0
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("Territory Archive").font(.title2).bold().foregroundColor(.white)
                    Spacer()
                    Image(systemName: "plus.circle.fill").foregroundColor(brandOrange).font(.title2)
                }.padding(.horizontal).padding(.top, 10)

                ScrollView {
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Territory Overview", systemImage: "chart.pie.fill").foregroundColor(.orange)
                            HStack(spacing: 12) {
                                TStatBox(icon: "flag.fill", value: "4", label: "Total Territories", color: .orange.opacity(0.3))
                                TStatBox(icon: "square.grid.3x3.fill", value: "3.2k", label: "Total Area", color: .blue.opacity(0.3))
                                TStatBox(icon: "archivebox.fill", value: "48", label: "Total Resources", color: .yellow.opacity(0.3))
                            }
                        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15)

                        HStack {
                            FilterTab(title: "All", count: 4, isActive: selectedFilter == 0) { selectedFilter = 0 }
                            FilterTab(title: "Safe", count: 2, isActive: selectedFilter == 1) { selectedFilter = 1 }
                            FilterTab(title: "Warning", count: 1, isActive: selectedFilter == 2) { selectedFilter = 2 }
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Territory List").font(.headline).foregroundColor(.white)
                            // 修复点：确保名字也是本地化 Key
                            TCard(name: "Shelter Alpha", type: "Shelter", status: "Safe", coord: "39.91°, 116.42°", area: "1250 m²", res: "12", time: "1 week ago", isSafe: true)
                            TCard(name: "Resource Beta", type: "Resource Point", status: "Warning", coord: "39.89°, 116.40°", area: "850 m²", res: "23", time: "5 days ago", isSafe: false)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 100)
                }
            }
        }
    }
}

// 辅助组件 (确保所有文本属性都是 LocalizedStringKey)
struct TCard: View {
    let name: LocalizedStringKey // 核心修复：改为本地化类型
    let type: LocalizedStringKey
    let status: LocalizedStringKey
    let coord: String; let area: String; let res: String
    let time: LocalizedStringKey; let isSafe: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: isSafe ? "house.fill" : "box.truck.fill")
                    .padding(8).background(Color.orange.opacity(0.2)).cornerRadius(8).foregroundColor(.orange)
                VStack(alignment: .leading) {
                    Text(name).font(.headline).foregroundColor(.white)
                    Text(type).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text(status).font(.caption).bold().padding(.horizontal, 8).padding(.vertical, 4)
                    .background(isSafe ? Color.green.opacity(0.2) : Color.yellow.opacity(0.2))
                    .foregroundColor(isSafe ? .green : .yellow).cornerRadius(6)
            }
            HStack(spacing: 0) {
                VStack { Text("Coordinates").font(.system(size: 10)).foregroundColor(.gray); Text(coord).font(.system(size: 12)).bold().foregroundColor(.white) }.frame(maxWidth: .infinity)
                VStack { Text("Area").font(.system(size: 10)).foregroundColor(.gray); Text(area).font(.system(size: 12)).bold().foregroundColor(.white) }.frame(maxWidth: .infinity)
                VStack { Text("Resources").font(.system(size: 10)).foregroundColor(.gray); Text("\(res) ↑").font(.system(size: 12)).bold().foregroundColor(.white) }.frame(maxWidth: .infinity)
            }
            HStack { Image(systemName: "clock"); Text("Claimed \(time)"); Spacer(); Image(systemName: "chevron.right") }.font(.caption).foregroundColor(.gray)
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15)
    }
}

struct TStatBox: View {
    let icon: String; let value: String; let label: LocalizedStringKey; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3)
            Text(value).font(.title3).bold()
            Text(label).font(.system(size: 10)).foregroundColor(.gray)
        }.frame(maxWidth: .infinity).padding(.vertical, 15).background(color).cornerRadius(12).foregroundColor(.white)
    }
}

struct FilterTab: View {
    let title: LocalizedStringKey; let count: Int; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title); Text("\(count)").font(.caption).padding(.horizontal, 6).background(Color.black.opacity(0.3)).cornerRadius(10) }
            .padding(.horizontal, 12).padding(.vertical, 8).background(isActive ? Color.orange : Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(20)
        }
    }
}
