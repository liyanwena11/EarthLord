import SwiftUI
import MapKit

struct TerritoryDetailView: View {
    let territory: Territory
    let onDelete: () -> Void

    @State private var isDeleting = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss

    let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.13)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // Map Preview
                        TerritoryMapPreview(territory: territory)
                            .frame(height: 300)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        // Territory Info
                        VStack(spacing: 20) {
                            // Name
                            InfoRow(
                                icon: "map.fill",
                                label: "Name",
                                value: territory.name ?? "Unnamed Territory"
                            )

                            // Area
                            InfoRow(
                                icon: "square.grid.3x3.fill",
                                label: "Area",
                                value: formatArea(territory.area)
                            )

                            // Points Count
                            InfoRow(
                                icon: "mappin.and.ellipse",
                                label: "Points",
                                value: "\(territory.pointCount ?? 0) tracked"
                            )

                            // Territory ID
                            InfoRow(
                                icon: "number",
                                label: "Territory ID",
                                value: String(territory.id.prefix(8))
                            )
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(15)

                        // Delete Button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Territory")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(isDeleting)
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Territory Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(brandOrange)
                }
            }
            .alert("Delete Territory", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTerritory()
                }
            } message: {
                Text("Are you sure you want to delete this territory? This action cannot be undone.")
            }
        }
    }

    // MARK: - Delete Territory

    private func deleteTerritory() {
        isDeleting = true

        Task {
            do {
                try await TerritoryManager.shared.deleteTerritory(territoryId: territory.id)

                await MainActor.run {
                    isDeleting = false
                    onDelete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    // TODO: Show error alert
                }
            }
        }
    }

    // MARK: - Format Area

    private func formatArea(_ area: Double) -> String {
        if area >= 1_000_000 {
            return String(format: "%.2f km²", area / 1_000_000)
        } else {
            return String(format: "%.0f m²", area)
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
            }

            // Label & Value
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }
}

// MARK: - Territory Map Preview

struct TerritoryMapPreview: UIViewRepresentable {
    let territory: Territory

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Get coordinates from territory
        let wgs84Coords = territory.toCoordinates()

        // Convert WGS-84 to GCJ-02
        let gcj02Coords = wgs84Coords.map { coord in
            CoordinateConverter.wgs84ToGcj02(coord)
        }

        guard !gcj02Coords.isEmpty else { return }

        // Create polygon
        var coordinates = gcj02Coords
        let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)

        // Remove old overlays
        mapView.removeOverlays(mapView.overlays)

        // Add new polygon
        mapView.addOverlay(polygon)

        // Set region to show the territory
        let region = calculateRegion(for: gcj02Coords)
        mapView.setRegion(region, animated: false)

        // Set delegate
        mapView.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.green.withAlphaComponent(0.25)
                renderer.strokeColor = UIColor.green
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    // Calculate region to fit all coordinates
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion()
        }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let spanLat = (maxLat - minLat) * 1.5  // Add 50% padding
        let spanLon = (maxLon - minLon) * 1.5

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
}
