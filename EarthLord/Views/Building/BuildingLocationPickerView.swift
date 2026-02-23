//
//  BuildingLocationPickerView.swift
//  EarthLord
//
//  建筑位置选择视图（SwiftUI 包装 UIKit MKMapView）
//

import SwiftUI
import MapKit

struct BuildingLocationPickerView: View {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let existingBuildings: [PlayerBuilding]
    let buildingTemplates: [String: BuildingTemplate]

    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LocationPickerMapView(
                    territoryCoordinates: territoryCoordinates,
                    existingBuildings: existingBuildings,
                    buildingTemplates: buildingTemplates,
                    selectedCoordinate: $selectedCoordinate
                )
                .ignoresSafeArea()
            }
            .navigationTitle("选择建造位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(ApocalypseTheme.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(
                            selectedCoordinate == nil ? ApocalypseTheme.textMuted : ApocalypseTheme.primary
                        )
                        .disabled(selectedCoordinate == nil)
                }
            }
        }
    }
}

// MARK: - UIKit MapView 封装

struct LocationPickerMapView: UIViewRepresentable {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let existingBuildings: [PlayerBuilding]
    let buildingTemplates: [String: BuildingTemplate]
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        LogDebug("🗺️ [BuildingLocationPickerView] 创建地图视图")
        LogDebug("  - 领地坐标数量: \(territoryCoordinates.count)")

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

            LogDebug("✅ [BuildingLocationPickerView] 领地多边形已添加")
        } else {
            LogWarning("⚠️ [BuildingLocationPickerView] 坐标点不足 3 个，无法添加多边形")
        }

        // 已有建筑
        context.coordinator.addExistingBuildings(to: mapView)

        // 点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateSelectedAnnotation(on: mapView, coordinate: selectedCoordinate)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: LocationPickerMapView
        private var selectedAnnotation: MKPointAnnotation?

        init(_ parent: LocationPickerMapView) {
            self.parent = parent
        }

        // 添加已有建筑标记
        func addExistingBuildings(to mapView: MKMapView) {
            for building in parent.existingBuildings {
                guard let coord = building.coordinate else { continue }
                let annotation = MKPointAnnotation()
                annotation.coordinate = coord

                if let template = parent.buildingTemplates[building.templateId] {
                    annotation.title = template.name
                } else {
                    annotation.title = "建筑"
                }
                mapView.addAnnotation(annotation)
            }
        }

        // 更新选中标记
        func updateSelectedAnnotation(on mapView: MKMapView, coordinate: CLLocationCoordinate2D?) {
            if let existing = selectedAnnotation {
                mapView.removeAnnotation(existing)
                selectedAnnotation = nil
            }
            guard let coordinate else { return }

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "建造位置"
            mapView.addAnnotation(annotation)
            selectedAnnotation = annotation
        }

        // 处理点击事件
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)

            // 只允许在领地多边形内选择
            guard LocationPickerMapView.isPointInPolygon(coord, polygon: parent.territoryCoordinates) else { return }

            parent.selectedCoordinate = coord
            updateSelectedAnnotation(on: mapView, coordinate: coord)
        }

        // 多边形渲染
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

    // MARK: - 辅助函数

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

    // 射线法：判断点是否在多边形内
    private static func isPointInPolygon(_ point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var isInside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            if ((yi > point.latitude) != (yj > point.latitude)) &&
                (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi) {
                isInside.toggle()
            }
            j = i
        }

        return isInside
    }
}

