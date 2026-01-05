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
                            Label("Territory Overview", systemImage: "chart.pie.fill").foregroundColor(brandOrange)
                            HStack(spacing: 12) {
                                TStat(icon: "flag.fill", value: "4", label: "Total Territories")
                                TStat(icon: "square.grid.3x3.fill", value: "3.2k", label: "Total Area")
                                TStat(icon: "archivebox.fill", value: "48", label: "Total Resources")
                            }
                        }.padding().background(Color.white.opacity(0.05)).cornerRadius(15)

                        HStack {
                            FilterBtn(title: "All", count: 4, isActive: selectedFilter == 0) { selectedFilter = 0 }
                            FilterBtn(title: "Safe", count: 2, isActive: selectedFilter == 1) { selectedFilter = 1 }
                            FilterBtn(title: "Warning", count: 1, isActive: selectedFilter == 2) { selectedFilter = 2 }
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Territory List").font(.headline).foregroundColor(.white)
                            TListItem(name: "Shelter Alpha", type: "Shelter", status: "Safe", isSafe: true, time: "1 week ago")
                            TListItem(name: "Resource Beta", type: "Resource Point", status: "Warning", isSafe: false, time: "5 days ago")
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 100)
                }
            }
        }
    }
}

// --- 补全下方组件 ---
struct TListItem: View {
    let name: LocalizedStringKey; let type: LocalizedStringKey; let status: LocalizedStringKey
    let isSafe: Bool; let time: LocalizedStringKey

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
                    .background(isSafe ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(isSafe ? .green : .red).cornerRadius(6)
            }
            HStack {
                Image(systemName: "clock")
                Text("Claimed \(time)") // 修复了之前的 Tex 错误
                Spacer()
                Image(systemName: "chevron.right")
            }.font(.caption).foregroundColor(.gray)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(15)
    }
}

struct TStat: View {
    let icon: String; let value: String; let label: LocalizedStringKey
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(.white)
            Text(value).font(.title3).bold().foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(.gray)
        }.frame(maxWidth: .infinity).padding(.vertical, 15).background(Color.white.opacity(0.1)).cornerRadius(12)
    }
}

struct FilterBtn: View {
    let title: LocalizedStringKey; let count: Int; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title); Text("\(count)").font(.caption).padding(.horizontal, 6).background(Color.black.opacity(0.3)).cornerRadius(10) }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isActive ? Color.orange : Color.white.opacity(0.1))
            .foregroundColor(.white).cornerRadius(20)
        }
    }
}
