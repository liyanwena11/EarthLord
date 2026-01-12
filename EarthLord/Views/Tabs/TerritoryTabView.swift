import SwiftUI

struct TerritoryTabView: View {
    @State private var myTerritories: [Territory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTerritory: Territory?
    @State private var showDetailSheet = false

    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var totalArea: Double {
        myTerritories.reduce(0) { $0 + $1.area }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("My Territories")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            loadTerritories()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(brandOrange)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else if let errorMessage = errorMessage {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                loadTerritories()
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(brandOrange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 25) {
                                // Statistics Overview
                                VStack(alignment: .leading, spacing: 15) {
                                    Label("Territory Overview", systemImage: "chart.pie.fill")
                                        .foregroundColor(brandOrange)
                                        .font(.headline)

                                    HStack(spacing: 12) {
                                        StatCard(
                                            icon: "flag.fill",
                                            value: "\(myTerritories.count)",
                                            label: "Total Territories"
                                        )
                                        StatCard(
                                            icon: "square.grid.3x3.fill",
                                            value: formatArea(totalArea),
                                            label: "Total Area"
                                        )
                                        StatCard(
                                            icon: "mappin.circle.fill",
                                            value: "\(myTerritories.reduce(0) { $0 + ($1.pointCount ?? 0) })",
                                            label: "Total Points"
                                        )
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(15)

                                // Territory List
                                if myTerritories.isEmpty {
                                    VStack(spacing: 15) {
                                        Image(systemName: "map")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                        Text("No territories yet")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Go out and claim your first territory!")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 50)
                                } else {
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Territory List")
                                            .font(.headline)
                                            .foregroundColor(.white)

                                        ForEach(myTerritories) { territory in
                                            TerritoryCard(territory: territory)
                                                .onTapGesture {
                                                    selectedTerritory = territory
                                                    showDetailSheet = true
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .onAppear {
                loadTerritories()
            }
            .sheet(isPresented: $showDetailSheet) {
                if let territory = selectedTerritory {
                    TerritoryDetailView(territory: territory, onDelete: {
                        loadTerritories()
                    })
                }
            }
        }
    }

    // MARK: - Load Territories

    private func loadTerritories() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let territories = try await TerritoryManager.shared.loadMyTerritories()
                await MainActor.run {
                    self.myTerritories = territories
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Format Area

    private func formatArea(_ area: Double) -> String {
        if area >= 1_000_000 {
            return String(format: "%.1fkm²", area / 1_000_000)
        } else {
            return String(format: "%.0fm²", area)
        }
    }
}

// MARK: - Territory Card

struct TerritoryCard: View {
    let territory: Territory
    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(brandOrange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "map.fill")
                        .foregroundColor(brandOrange)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(territory.name ?? "Unnamed Territory")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 5) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.caption2)
                        Text(formatArea(territory.area))
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            // Points count
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                Text("\(territory.pointCount ?? 0) points tracked")
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func formatArea(_ area: Double) -> String {
        if area >= 1_000_000 {
            return String(format: "%.1fkm²", area / 1_000_000)
        } else {
            return String(format: "%.0fm²", area)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
