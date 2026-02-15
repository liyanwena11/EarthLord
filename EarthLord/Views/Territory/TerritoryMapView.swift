//
//  TerritoryMapView.swift
//  EarthLord
//
//  领地详情使用的全屏地图视图（MKMapView + MKPolygon + 建筑标注）
//

import SwiftUI
import MapKit

struct TerritoryMapView: UIViewRepresentable {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let buildings: [PlayerBuilding]
    let templates: [String: BuildingTemplate]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .hybrid
        mapView.showsUserLocation = true

        // 领地多边形
        if territoryCoordinates.count >= 3 {
            var coords = territoryCoordinates
            let polygon = MKPolygon(coordinates: &coords, count: coords.count)
            mapView.addOverlay(polygon)

            let region = regionForPolygon(territoryCoordinates)
            mapView.setRegion(region, animated: false)
        }

        updateBuildingAnnotations(on: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateBuildingAnnotations(on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Annotation & Overlay

    private func updateBuildingAnnotations(on mapView: MKMapView) {
        let old = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(old)

        for building in buildings {
            guard let coord = building.coordinate else { continue }

            // 数据库中的坐标已经是 GCJ-02，直接使用
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            if let template = templates[building.templateId] {
                annotation.title = template.name
            } else {
                annotation.title = "建筑"
            }
            mapView.addAnnotation(annotation)
        }
    }

    private func regionForPolygon(_ coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coords.first?.latitude ?? 0
        var maxLat = minLat
        var minLon = coords.first?.longitude ?? 0
        var maxLon = minLon

        for c in coords {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: TerritoryMapView

        init(_ parent: TerritoryMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
                renderer.strokeColor = .systemGreen
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

