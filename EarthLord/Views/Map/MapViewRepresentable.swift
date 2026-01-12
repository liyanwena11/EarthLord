import SwiftUI
  import MapKit

  struct MapViewRepresentable: UIViewRepresentable {
      @ObservedObject var locationManager: LocationManager
      @Binding var trackingPath: [CLLocationCoordinate2D]
      @Binding var isPathClosed: Bool
      var pathUpdateVersion: Int

      func makeUIView(context: Context) -> MKMapView {
          let mapView = MKMapView()
          mapView.delegate = context.coordinator
          mapView.showsUserLocation = true
          mapView.userTrackingMode = .follow

          print("🗺️ [MapView] makeUIView called - initializing map")

          // 延迟加载领地数据，确保 userId 已初始化
          Task {
              // 等待 userId 加载完成
              await context.coordinator.waitForUserId()
              print("🗺️ [MapView] User ID ready, loading territories...")
              await loadTerritories(mapView: mapView, userId: context.coordinator.currentUserId)
          }

          return mapView
      }

      func updateUIView(_ mapView: MKMapView, context: Context) {
          // 更新追踪路径
          updateTrackingPath(mapView: mapView)

          // 刷新领地显示
          if context.coordinator.shouldRefreshTerritories {
              print("🔄 [MapView] Refresh territories triggered")
              Task {
                  await context.coordinator.waitForUserId()
                  await loadTerritories(mapView: mapView, userId: context.coordinator.currentUserId)
              }
              context.coordinator.shouldRefreshTerritories = false
          }
      }

      func makeCoordinator() -> Coordinator {
          Coordinator(self)
      }

      // MARK: - Load Territories

      private func loadTerritories(mapView: MKMapView, userId: String?) async {
          print("🗺️ [MapView] loadTerritories called with userId: \(userId ?? "nil")")

          do {
              let loadedTerritories = try await TerritoryManager.shared.loadAllTerritories()
              print("🗺️ [MapView] Loaded \(loadedTerritories.count) territories from database")

              await MainActor.run {
                  // 移除旧的领地覆盖物
                  let oldOverlays = mapView.overlays.filter { overlay in
                      if let polygon = overlay as? MKPolygon {
                          return polygon.title?.starts(with: "territory_") ?? false
                      }
                      return false
                  }
                  print("🗺️ [MapView] Removing \(oldOverlays.count) old territory overlays")
                  mapView.removeOverlays(oldOverlays)

                  // 绘制新的领地
                  print("🗺️ [MapView] Drawing territories on map...")
                  drawTerritories(territories: loadedTerritories, on: mapView, userId: userId)

                  TerritoryLogger.shared.log("地图已加载 \(loadedTerritories.count) 个领地", type: .info)
              }
          } catch {
              print("❌ [MapView] Failed to load territories: \(error.localizedDescription)")
              TerritoryLogger.shared.log("加载领地失败: \(error.localizedDescription)", type: .error)
          }
      }

      // MARK: - Draw Territories

      private func drawTerritories(territories: [Territory], on mapView: MKMapView, userId: String?) {
          print("🎨 [MapView] drawTerritories called with \(territories.count) territories")
          print("🎨 [MapView] Current user ID: \(userId ?? "nil")")

          guard let currentUserId = userId else {
              print("❌ [MapView] No user ID available, cannot draw territories")
              return
          }

          var drawnCount = 0

          for territory in territories {
              print("🎨 [MapView] Processing territory: \(territory.id)")
              print("  - Territory user ID: \(territory.userId)")
              print("  - Territory name: \(territory.name ?? "Unnamed")")

              // 将数据库坐标转换为 CLLocationCoordinate2D
              let wgs84Coords = territory.toCoordinates()
              print("  - Converted \(wgs84Coords.count) WGS-84 coordinates")

              guard !wgs84Coords.isEmpty else {
                  print("  ⚠️ No coordinates, skipping")
                  continue
              }

              // ⚠️ WGS-84 → GCJ-02 坐标转换（防止偏移）
              let gcj02Coords = wgs84Coords.map { coord in
                  CoordinateConverter.wgs84ToGcj02(coord)
              }
              print("  - Converted to \(gcj02Coords.count) GCJ-02 coordinates")
              print("  - First coord: \(gcj02Coords.first?.latitude ?? 0), \(gcj02Coords.first?.longitude ?? 0)")

              // 创建多边形
              var coordinates = gcj02Coords
              let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)

              // ⚠️ 颜色区分：统一小写比较
              let isMine = territory.userId.lowercased() == currentUserId.lowercased()
              polygon.title = "territory_\(territory.id)_\(isMine ? "mine" : "others")"

              print("  - Is mine: \(isMine)")
              print("  - Polygon title: \(polygon.title ?? "nil")")

              mapView.addOverlay(polygon)
              drawnCount += 1
              print("  ✅ Added overlay to map")
          }

          print("🎨 [MapView] ✅ Successfully drew \(drawnCount) polygons on map")
      }

      // MARK: - Update Tracking Path

      private func updateTrackingPath(mapView: MKMapView) {
          // 移除旧的追踪路径
          let oldTrackingOverlays = mapView.overlays.filter { overlay in
              if let polyline = overlay as? MKPolyline {
                  return polyline.title == "tracking_path"
              }
              return false
          }
          mapView.removeOverlays(oldTrackingOverlays)

          // 添加新的追踪路径
          guard !trackingPath.isEmpty else { return }

          var coordinates = trackingPath
          let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
          polyline.title = "tracking_path"
          mapView.addOverlay(polyline)
      }

      // MARK: - Coordinator

      class Coordinator: NSObject, MKMapViewDelegate {
          var parent: MapViewRepresentable
          var shouldRefreshTerritories = false
          var currentUserId: String?
          private var isUserIdReady = false

          init(_ parent: MapViewRepresentable) {
              self.parent = parent
              super.init()

              print("🔐 [Coordinator] Initializing, fetching user ID...")

              // 异步获取用户 ID
              Task {
                  do {
                      let session = try await supabaseClient.auth.session
                      let userId = session.user.id.uuidString
                      print("🔐 [Coordinator] User ID fetched: \(userId)")

                      await MainActor.run {
                          self.currentUserId = userId
                          self.isUserIdReady = true
                      }
                  } catch {
                      print("❌ [Coordinator] Failed to fetch user ID: \(error.localizedDescription)")
                      TerritoryLogger.shared.log("获取用户ID失败: \(error.localizedDescription)", type: .error)
                  }
              }
          }

          /// Wait for user ID to be ready
          func waitForUserId() async {
              print("⏳ [Coordinator] Waiting for user ID...")
              while !isUserIdReady {
                  try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
              }
              print("✅ [Coordinator] User ID is ready: \(currentUserId ?? "nil")")
          }

          // MARK: - Renderer for Overlays

          func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
              print("🎨 [Renderer] rendererFor overlay called")

              // 追踪路径渲染
              if let polyline = overlay as? MKPolyline, polyline.title == "tracking_path" {
                  print("🎨 [Renderer] Rendering tracking path (blue)")
                  let renderer = MKPolylineRenderer(polyline: polyline)
                  renderer.strokeColor = .systemBlue
                  renderer.lineWidth = 3
                  return renderer
              }

              // ⚠️ 领地多边形渲染
              if let polygon = overlay as? MKPolygon,
                 let title = polygon.title,
                 title.starts(with: "territory_") {

                  print("🎨 [Renderer] Rendering territory polygon: \(title)")

                  let renderer = MKPolygonRenderer(polygon: polygon)

                  // 颜色区分：我的领地 vs 别人的领地
                  if title.hasSuffix("_mine") {
                      // 我的领地：绿色
                      print("🎨 [Renderer] → GREEN (my territory)")
                      renderer.fillColor = UIColor.green.withAlphaComponent(0.6)
                      renderer.strokeColor = UIColor.green
                  } else {
                      // 别人的领地：橙色
                      print("🎨 [Renderer] → ORANGE (other's territory)")
                      renderer.fillColor = UIColor.orange.withAlphaComponent(0.6)
                      renderer.strokeColor = UIColor.orange
                  }

                  renderer.lineWidth = 2

                  return renderer
              }

              print("⚠️ [Renderer] No matching renderer, returning default")
              return MKOverlayRenderer(overlay: overlay)
          }
      }
  }

