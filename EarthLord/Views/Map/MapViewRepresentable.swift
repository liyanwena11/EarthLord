import SwiftUI
import MapKit
import Supabase

// MARK: - ✅ Day 22：自定义 POI 标注类
class POIAnnotation: NSObject, MKAnnotation {
    let poi: POIPoint
    var coordinate: CLLocationCoordinate2D { poi.coordinate }
    var title: String? { poi.name }
    var subtitle: String? { poi.isLootable ? poi.type.rawValue : poi.cooldownString }

    init(poi: POIPoint) {
        self.poi = poi
        super.init()
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var trackingPath: [CLLocationCoordinate2D]
    @Binding var isPathClosed: Bool
    var pathUpdateVersion: Int
    @Binding var shouldCenterOnUser: Bool

    // 默认中心点（成都龙泉驿）- 作为回退位置
    private let defaultCenter = CLLocationCoordinate2D(latitude: 30.565, longitude: 104.265)

    func makeUIView(context: Context) -> MKMapView {
        print("🗺️ [MapView] makeUIView 开始创建地图")

        let mapView = MKMapView()

        // ✅ 1. 设置代理
        mapView.delegate = context.coordinator

        // ✅ 2. 强制设置地图类型为标准（确保瓦片加载）
        mapView.mapType = .standard
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)

        // ✅ 3. 显示用户位置
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow  // 自动跟随用户

        // ✅ 4. 启用地图交互
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false

        // ✅ 5. 确保地图视图有正确的布局属性
        mapView.translatesAutoresizingMaskIntoConstraints = false

        // ✅ 6. 设置初始区域（500米范围）
        let initialCenter: CLLocationCoordinate2D
        if let userLoc = locationManager.userLocation?.coordinate {
            initialCenter = userLoc
            print("🗺️ [MapView] 使用用户位置: \(userLoc.latitude), \(userLoc.longitude)")
        } else {
            initialCenter = defaultCenter
            print("🗺️ [MapView] 用户位置不可用，使用默认位置")
        }

        let region = MKCoordinateRegion(
            center: initialCenter,
            latitudinalMeters: 500,  // 500米范围
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: false)

        print("🗺️ [MapView] 地图创建完成，mapType=\(mapView.mapType.rawValue)")
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 1. 绘制当前行走轨迹线
        updateTrackingPolyline(on: mapView)

        // 2. 绘制所有领地
        updateTerritoryPolygons(on: mapView)

        // 3. 首次获取用户位置时自动定位（只执行一次）
        if !context.coordinator.hasInitiallyLocated,
           let userLoc = locationManager.userLocation?.coordinate {
            let region = MKCoordinateRegion(
                center: userLoc,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: true)
            context.coordinator.hasInitiallyLocated = true
            print("🗺️ [MapView] 首次定位到用户位置: \(userLoc.latitude), \(userLoc.longitude)")
        }

        // 4. 定位按钮触发镜头定位
        if shouldCenterOnUser, let userLoc = locationManager.userLocation?.coordinate {
            let region = MKCoordinateRegion(
                center: userLoc,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: true)
            // 重置标志（需要在主线程异步执行避免 SwiftUI 警告）
            DispatchQueue.main.async {
                self.shouldCenterOnUser = false
            }
        }

        // 5. 圈地时镜头跟随
        if locationManager.isTracking, let userLoc = locationManager.userLocation?.coordinate {
            let region = MKCoordinateRegion(center: userLoc, span: mapView.region.span)
            mapView.setRegion(region, animated: true)
        }

        // 6. ✅ Day 22：更新 POI 标注点（优化：仅在数量变化时更新）
        let currentPOICount = mapView.annotations.filter { $0 is POIAnnotation }.count
        let newPOICount = RealPOIService.shared.realPOIs.count
        if currentPOICount != newPOICount {
            updatePOIAnnotations(on: mapView)
        }
    }

    // MARK: - ✅ Day 22：POI 标注点更新逻辑

    private func updatePOIAnnotations(on mapView: MKMapView) {
        // 移除旧的 POI 标注
        let oldAnnotations = mapView.annotations.filter { $0 is POIAnnotation }
        mapView.removeAnnotations(oldAnnotations)

        // 添加新的 POI 标注
        for poi in RealPOIService.shared.realPOIs {
            let annotation = POIAnnotation(poi: poi)
            mapView.addAnnotation(annotation)
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

        // Get current user ID from AuthManager
        let currentUserId = AuthManager.shared.currentUser?.id.uuidString

        for territory in TerritoryManager.shared.territories {
            let wgs84Coords = territory.toCoordinates()

            // Coordinate conversion for China
            let gcj02Coords = wgs84Coords.map { coord in
                CoordinateConverter.wgs84ToGcj02(coord)
            }

            var coordinates = gcj02Coords
            let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)

            // Determine if territory belongs to current user
            let isMine = currentUserId != nil && territory.userId.lowercased() == currentUserId?.lowercased()
            polygon.title = isMine ? "mine" : "enemy"

            mapView.addOverlay(polygon)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var hasInitiallyLocated = false  // ✅ 追踪是否已完成首次定位

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // ✅ 地图加载完成回调
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("🗺️ [MapView] 地图瓦片加载完成")
        }

        // ✅ 地图加载失败回调
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            print("❌ [MapView] 地图加载失败: \(error.localizedDescription)")
        }

        // ✅ 地图渲染完成
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            print("🗺️ [MapView] 地图渲染完成，fullyRendered=\(fullyRendered)")
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
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

        // MARK: - ✅ Day 22：自定义 POI 标注视图

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 跳过用户位置标注
            if annotation is MKUserLocation { return nil }

            // 处理 POI 标注
            guard let poiAnnotation = annotation as? POIAnnotation else { return nil }

            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }

            let poi = poiAnnotation.poi

            // ✅ 根据 POI 类型设置图标
            annotationView?.glyphImage = UIImage(systemName: poi.iconName)

            // ✅ 根据是否可搜刮设置颜色
            if poi.isLootable {
                // 可搜刮：使用类型对应的颜色
                let color = poi.typeColor
                annotationView?.markerTintColor = UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1.0)
                annotationView?.glyphTintColor = .white
            } else {
                // 不可搜刮（冷却中）：灰色
                annotationView?.markerTintColor = .systemGray
                annotationView?.glyphTintColor = .lightGray
            }

            // 显示优先级（可搜刮的优先显示）
            annotationView?.displayPriority = poi.isLootable ? .required : .defaultLow

            return annotationView
        }
    }
}
