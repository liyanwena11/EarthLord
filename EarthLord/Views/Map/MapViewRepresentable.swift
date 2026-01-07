import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {

    var locationManager: LocationManager
    @Binding var trackingPath: [CLLocationCoordinate2D]
    @Binding var isPathClosed: Bool
    var pathUpdateVersion: Int

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        mapView.userTrackingMode = .none
        mapView.mapType = .hybrid
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = false
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if context.coordinator.lastPathUpdateVersion != pathUpdateVersion {
            context.coordinator.lastPathUpdateVersion = pathUpdateVersion
            context.coordinator.isPathClosed = isPathClosed
            print("Map update triggered - version: \(pathUpdateVersion), closed: \(isPathClosed), points: \(trackingPath.count)")
            updateTrackingPath(on: uiView, context: context)
        }
    }

    private func updateTrackingPath(on mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard trackingPath.count >= 2 else {
            print("Not enough points, skipping render")
            return
        }

        let gcjPath = trackingPath.map { CoordinateConverter.wgs84ToGcj02($0) }

        let polyline = MKPolyline(coordinates: gcjPath, count: gcjPath.count)
        mapView.addOverlay(polyline)
        print("Polyline added - points: \(gcjPath.count)")

        if isPathClosed && gcjPath.count >= 3 {
            let polygon = MKPolygon(coordinates: gcjPath, count: gcjPath.count)
            mapView.addOverlay(polygon)
            print("Polygon added - points: \(gcjPath.count)")
        } else {
            print("Polygon not added - closed: \(isPathClosed), points: \(gcjPath.count)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {

        var lastPathUpdateVersion: Int = -1
        var isPathClosed: Bool = false
        private var hasInitialCentered = false

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !hasInitialCentered, let location = userLocation.location else { return }

            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            mapView.setRegion(region, animated: true)
            hasInitialCentered = true
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = isPathClosed ? .systemGreen : .systemCyan
                renderer.lineWidth = 5.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                print("Rendering polyline - color: \(isPathClosed ? "green" : "cyan")")
                return renderer
            }

            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                renderer.strokeColor = .clear
                print("Rendering polygon - fill: green (0.25 alpha)")
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
