import SwiftUI

struct TerritoryTestView: View {

    @EnvironmentObject var locationManager: LocationManager
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
                    Text(logger.logText.isEmpty ? "No logs yet. Start tracking to see logs." : logger.logText)
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
                        Text("Clear Logs")
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
                        Text("Export Logs")
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
        .navigationTitle("Territory Test")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: logger.logText) { oldValue, newValue in
            // Auto-scroll to bottom when new log arrives
            withAnimation {
                scrollProxy?.scrollTo("logBottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(locationManager.isTracking ? Color.green : Color.gray)
                .frame(width: 12, height: 12)

            Text(locationManager.isTracking ? "● Tracking" : "○ Not Tracking")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(locationManager.isTracking ? .green : .secondary)

            Spacer()
        }
    }
}
