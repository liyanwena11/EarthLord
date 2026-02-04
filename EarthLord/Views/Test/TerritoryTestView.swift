import SwiftUI

struct TerritoryTestView: View {
    @StateObject private var engine = EarthLordEngine.shared
    @ObservedObject var logger = TerritoryLogger.shared
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Status Indicator
            statusIndicator
                .padding()
                .background(Color(.systemGray6))

            Divider()

            // Log Display Area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logger.logText.isEmpty ? "暂无日志。开始圈地后会显示日志。" : logger.logText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("logBottom")
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }

            Divider()

            // Action Buttons
            HStack(spacing: 20) {
                Button(action: {
                    logger.clear()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("清空日志")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(10)
                }

                ShareLink(item: logger.export()) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出日志")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("领地轨迹日志")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: logger.logText) {
            withAnimation {
                scrollProxy?.scrollTo("logBottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)

            Text("GPS 日志查看器")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Text("POI: \(engine.nearbyPOIs.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
