import SwiftUI

struct MailboxView: View {
    @StateObject private var mailbox = MailboxManager.shared
    @StateObject private var inventory = InventoryManager.shared
    private let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.bottom, 12)

                if mailbox.isLoading {
                    Spacer()
                    ProgressView().tint(brandOrange)
                    Spacer()
                } else if mailbox.pendingItems.isEmpty {
                    emptyState
                } else {
                    // Capacity warning
                    capacityBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Item list
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(mailbox.pendingItems) { item in
                                MailboxItemRow(item: item) {
                                    Task { await mailbox.claimItem(item) }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }

                    // Claim All button
                    claimAllButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("邮箱")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("领取提示", isPresented: .constant(mailbox.errorMessage != nil)) {
            Button("确定") { mailbox.errorMessage = nil }
        } message: {
            Text(mailbox.errorMessage ?? "")
        }
        .task { await mailbox.loadPendingItems() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .foregroundColor(brandOrange)
                Text("待领取物资")
                    .font(.headline).foregroundColor(.white)
                Spacer()
                if mailbox.pendingCount > 0 {
                    Text("\(mailbox.pendingCount) 件")
                        .font(.caption.bold())
                        .foregroundColor(brandOrange)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(brandOrange.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Text("物资永不过期，随时领取")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Capacity Bar

    private var capacityBar: some View {
        let current = inventory.totalItemCount
        let max = inventory.maxCapacity
        let percentage = Double(current) / Double(max)
        let color: Color = percentage > 0.9 ? .red : percentage > 0.7 ? .orange : .green

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "archivebox.fill").font(.caption2).foregroundColor(color)
                Text("背包容量").font(.caption2).foregroundColor(.gray)
                Spacer()
                Text("\(current) / \(max)").font(.caption2.bold()).foregroundColor(color)
            }
            ProgressView(value: min(Double(current), Double(max)), total: Double(max))
                .tint(color)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }

    // MARK: - Claim All Button

    private var claimAllButton: some View {
        let isFull = inventory.totalItemCount >= inventory.maxCapacity
        return Button(action: {
            Task { await mailbox.claimAll() }
        }) {
            HStack {
                Image(systemName: isFull ? "xmark.circle" : "arrow.down.circle.fill")
                Text(isFull ? "背包已满" : "全部领取")
                    .fontWeight(.bold)
            }
            .foregroundColor(isFull ? .gray : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFull ? Color.white.opacity(0.1) : brandOrange)
            .cornerRadius(14)
        }
        .disabled(isFull || mailbox.isLoading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color.white.opacity(0.2))
            Text("邮箱空空如也")
                .foregroundColor(.gray)
                .font(.subheadline)
            Text("购买物资包后，物资会在此等待领取")
                .foregroundColor(Color.white.opacity(0.3))
                .font(.caption)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}


