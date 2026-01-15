import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var trackingPath: [CLLocationCoordinate2D]
    @Binding var isPathClosed: Bool
    var pathUpdateVersion: Int

    // ✅ 定义成都龙泉驿桃花源为唯一中心
    private let chengduBase = CLLocationCoordinate2D(latitude: 30.565, longitude: 104.265)

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // 🚀 核心修复：强制初始化镜头对准成都，解决“北京”偏移问题
        let region = MKCoordinateRegion(
            center: chengduBase,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: false)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 1. 绘制当前行走轨迹线
        updateTrackingPolyline(on: mapView)
        
        // 2. 绘制所有领地
        updateTerritoryPolygons(on: mapView)
        
        // 3. 圈地时镜头跟随
        if locationManager.isTracking, let userLoc = locationManager.userLocation?.coordinate {
            let region = MKCoordinateRegion(center: userLoc, span: mapView.region.span)
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - 内部绘图逻辑 (已修复坐标转换报错)

    private func updateTrackingPolyline(on mapView: MKMapView) {
        let oldLines = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(oldLines)
        
        guard !trackingPath.isEmpty else { return }
        let polyline = MKPolyline(coordinates: trackingPath, count: trackingPath.count)
        mapView.addOverlay(polyline)
    }

    private func updateTerritoryPolygons(on mapView: MKMapView) {
        let oldPolygons = mapView.overlays.filter { $0 is MKPolygon }
        mapView.removeOverlays(oldPolygons)
        
        for territory in TerritoryManager.shared.territories {
            let wgs84Coords = territory.toCoordinates()
            
            // ✅ 核心修复：直接把对象丢进去，不带任何 latitude/longitude 标签
            // 这是为了适配你项目中 CoordinateConverter 的具体定义
            let gcj02Coords = wgs84Coords.map { coord in
                CoordinateConverter.wgs84ToGcj02(coord)
            }
            
            var coordinates = gcj02Coords
            let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
            
            // ✅ 颜色区分逻辑修复：只有 player_1 是自己的领地（绿色），其他都是敌军（橙色）
            let isMine = territory.userId.lowercased() == "player_1"
            polygon.title = isMine ? "mine" : "enemy"
            
            mapView.addOverlay(polygon)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        init(_ parent: MapViewRepresentable) { self.parent = parent }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue; renderer.lineWidth = 4
                return renderer
            }
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                if polygon.title == "mine" {
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.5)
                    renderer.strokeColor = .green
                } else {
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.6)
                    renderer.strokeColor = .orange
                }
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
