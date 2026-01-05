import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var trackingPath: [CLLocationCoordinate2D]
    var pathUpdateVersion: Int

    // MARK: - 创建地图视图
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // 设置代理
        mapView.delegate = context.coordinator

        // 显示用户位置蓝点
        mapView.showsUserLocation = true

        // ⚠️ 关键修复：开启所有交互功能
        mapView.isScrollEnabled = true      // 允许手指拖动
        mapView.isZoomEnabled = true        // 允许双指缩放
        mapView.isRotateEnabled = true      // 允许旋转
        mapView.isPitchEnabled = false      // 禁用倾斜（保持俯视）

        // ⚠️ 关键修复：初始追踪模式设为 .none，避免强制回弹
        // 后续通过 Coordinator 手动实现首次居中
        mapView.userTrackingMode = .none

        // 地图样式（废土风格）
        mapView.mapType = .hybrid           // 卫星图 + 道路标签
        mapView.pointOfInterestFilter = .excludingAll  // 隐藏 POI
        mapView.showsBuildings = false      // 隐藏 3D 建筑

        return mapView
    }

    // MARK: - 更新地图视图
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 只有在版本更新时才重新绘制，节省性能
        updateTrackingPath(on: uiView)
    }

    // MARK: - 更新轨迹绘制
    private func updateTrackingPath(on mapView: MKMapView) {
        // 步骤 1：移除旧的轨迹线
        mapView.removeOverlays(mapView.overlays)

        // 步骤 2：如果点数太少，没法画线
        guard trackingPath.count >= 2 else { return }

        // 步骤 3：将 WGS-84 转换为 GCJ-02 (解决中国地图偏移)
        let gcjPath = trackingPath.map { CoordinateConverter.wgs84ToGcj02($0) }

        // 步骤 4：创建并添加折线
        let polyline = MKPolyline(coordinates: gcjPath, count: gcjPath.count)
        mapView.addOverlay(polyline)
    }

    // MARK: - 创建协调器
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator 协调器
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        private var hasInitialCentered = false  // 防止重复居中

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // ⭐ 用户位置更新时调用
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 仅在首次获得位置时自动居中，之后不再强制居中
            guard !hasInitialCentered,
                  let location = userLocation.location else { return }

            // 创建居中区域（约 1 公里范围）
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            // 平滑居中地图
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true

            print("✅ 地图已居中到用户位置")
        }

        // ⭐ 地图区域改变时调用（用户拖动、缩放时触发）
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 用户手动交互时，不需要做任何处理
            // 地图会保持用户拖动/缩放后的位置，不会自动回弹
        }

        // ⭐ 必须实现此方法，否则轨迹线是透明的！
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .cyan     // 青色
                renderer.lineWidth = 5.0         // 线宽
                renderer.lineCap = .round        // 线头圆润
                renderer.lineJoin = .round       // 连接处圆润
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
