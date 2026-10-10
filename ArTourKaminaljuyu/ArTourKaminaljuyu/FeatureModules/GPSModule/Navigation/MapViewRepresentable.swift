import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - MapViewRepresentable

struct MapViewRepresentable: UIViewRepresentable {
    
    // MARK: - Estado que controla el mapa desde SwiftUI
    
    @Binding var userLocation: CLLocationCoordinate2D?
    
    @Binding var userHeading: Double
    
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    
    @Binding var highlightedPOIId: String?

    let pois: [POILocation]
    let tourStartCoordinate: CLLocationCoordinate2D?

    // MARK: - Colores de marcadores

    private let userMarkerColor = UIColor(red: 0/255, green: 200/255, blue: 80/255, alpha: 1.0)
    private let poiMarkerColor  = UIColor(red: 255/255, green: 80/255, blue: 50/255, alpha: 1.0)
    private let poiHighlightColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
    private let startMarkerColor = UIColor(red: 46/255, green: 125/255, blue: 50/255, alpha: 1.0)
    private let routeLineColor  = UIColor(red: 33/255, green: 150/255, blue: 243/255, alpha: 0.85)
    
    // MARK: - makeUIView
    
    func makeUIView(context: Context) -> GMSMapView {
        let tourStartLat = 14.63131332
        let tourStartLon = -90.54845428
        let camera = GMSCameraPosition.camera(
            withLatitude: tourStartLat,
            longitude: tourStartLon,
            zoom: 18.0
        )
        
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        
        mapView.settings.compassButton = false
        mapView.settings.myLocationButton = false
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.tiltGestures = false
        mapView.settings.rotateGestures = false
        
        mapView.mapType = .normal
        
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    // MARK: - updateUIView
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        let coordinator = context.coordinator

        updateUserMarker(on: mapView, coordinator: coordinator)

        addStartMarkerIfNeeded(on: mapView, coordinator: coordinator)

        addPOIMarkersIfNeeded(on: mapView, coordinator: coordinator)

        updateRoutePolyline(on: mapView, coordinator: coordinator)

        updateHighlightedMarker(coordinator: coordinator)
    }
    
    // MARK: - makeCoordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, GMSMapViewDelegate {

        var userMarker: GMSMarker?

        var poiMarkers: [String: GMSMarker] = [:]

        var startMarker: GMSMarker?

        var routePolyline: GMSPolyline?
        
        var lastRouteCoordinates: [CLLocationCoordinate2D] = []
        
        var currentHighlightedPOIId: String?
        
        var setInitialCameraPosition = false
        
        var cameraIdle = true
        
        // MARK: GMSMapViewDelegate — equivalente a los listeners de Android
        
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            if gesture { cameraIdle = false }
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            cameraIdle = true
        }
    }
}

// MARK: - Métodos privados de actualización del mapa

private extension MapViewRepresentable {
    
    func updateUserMarker(on mapView: GMSMapView, coordinator: Coordinator) {
        guard let location = userLocation else { return }
        
        if coordinator.userMarker == nil {
            let marker = GMSMarker()
            marker.icon = createDirectionArrowIcon(color: userMarkerColor)
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isFlat = true
            marker.map = mapView
            coordinator.userMarker = marker
        }
        
        coordinator.userMarker?.position = location
        coordinator.userMarker?.rotation = userHeading
        coordinator.userMarker?.map = mapView
        
        if coordinator.cameraIdle {
            if !coordinator.setInitialCameraPosition {
                coordinator.setInitialCameraPosition = true
                let camera = GMSCameraPosition.camera(
                    withLatitude: location.latitude,
                    longitude: location.longitude,
                    zoom: 19.0
                )
                mapView.animate(to: camera)
            } else {
                let camera = GMSCameraPosition.camera(
                    withLatitude: location.latitude,
                    longitude: location.longitude,
                    zoom: mapView.camera.zoom
                )
                mapView.animate(to: camera)
            }
        }
    }
    
    func addStartMarkerIfNeeded(on mapView: GMSMapView, coordinator: Coordinator) {
        guard let start = tourStartCoordinate else { return }
        guard coordinator.startMarker == nil else { return }

        let marker = GMSMarker()
        marker.position = start
        marker.title = "Punto de partida"
        marker.icon = createStartMarkerIcon(color: startMarkerColor)
        marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
        marker.zIndex = 2
        marker.map = mapView
        coordinator.startMarker = marker
    }

    func addPOIMarkersIfNeeded(on mapView: GMSMapView, coordinator: Coordinator) {
        for poi in pois {
            guard coordinator.poiMarkers[poi.id] == nil else { continue }
            
            let marker = GMSMarker()
            marker.position = poi.coordinate
            marker.title = poi.name
            
            let isMainMonticulo = !poi.parts.isEmpty
            
            marker.icon = isMainMonticulo
                ? createPOIMarkerIcon(color: poiMarkerColor, isMain: true)
                : createPOIMarkerIcon(color: poiMarkerColor, isMain: false)
            
            marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
            marker.map = mapView
            
            coordinator.poiMarkers[poi.id] = marker
        }
    }
    
    func updateRoutePolyline(on mapView: GMSMapView, coordinator: Coordinator) {
        guard routeCoordinates.count != coordinator.lastRouteCoordinates.count
              || zip(routeCoordinates, coordinator.lastRouteCoordinates).contains(where: { a, b in
                  a.latitude != b.latitude || a.longitude != b.longitude
              }) else { return }
        
        coordinator.routePolyline?.map = nil
        coordinator.routePolyline = nil
        
        guard !routeCoordinates.isEmpty else {
            coordinator.lastRouteCoordinates = []
            return
        }
        
        let path = GMSMutablePath()
        for coordinate in routeCoordinates {
            path.add(coordinate)
        }
        
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 4.0
        polyline.strokeColor = routeLineColor
        polyline.geodesic = true
        polyline.map = mapView
        
        coordinator.routePolyline = polyline
        coordinator.lastRouteCoordinates = routeCoordinates
    }
    

    func updateHighlightedMarker(coordinator: Coordinator) {
        guard coordinator.currentHighlightedPOIId != highlightedPOIId else { return }
        
        if let previousId = coordinator.currentHighlightedPOIId,
           let previousMarker = coordinator.poiMarkers[previousId] {
            previousMarker.icon = createPOIMarkerIcon(color: poiMarkerColor, isMain: true)
            previousMarker.zIndex = 0
        }
        
        if let newId = highlightedPOIId,
           let newMarker = coordinator.poiMarkers[newId] {
            newMarker.icon = createPOIMarkerIcon(color: poiHighlightColor, isMain: true)
            newMarker.zIndex = 1
        }
        
        coordinator.currentHighlightedPOIId = highlightedPOIId
    }
}

// MARK: - Generadores de iconos personalizados

private extension MapViewRepresentable {
    
    func createDirectionArrowIcon(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 16, y: 2))
            path.addLine(to: CGPoint(x: 28, y: 28))
            path.addLine(to: CGPoint(x: 16, y: 22))
            path.addLine(to: CGPoint(x: 4, y: 28))
            path.close()
            
            color.setFill()
            path.fill()
            
            UIColor.white.setStroke()
            path.lineWidth = 2.0
            path.stroke()
        }
    }
    

    func createStartMarkerIcon(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let poleRect = CGRect(x: 8, y: 6, width: 3, height: 32)
            UIColor.white.setFill()
            UIBezierPath(rect: poleRect).fill()

            let flag = UIBezierPath()
            flag.move(to: CGPoint(x: 11, y: 8))
            flag.addLine(to: CGPoint(x: 28, y: 12))
            flag.addLine(to: CGPoint(x: 22, y: 17))
            flag.addLine(to: CGPoint(x: 28, y: 22))
            flag.addLine(to: CGPoint(x: 11, y: 22))
            flag.close()

            color.setFill()
            flag.fill()

            UIColor.white.setStroke()
            flag.lineWidth = 1.5
            flag.stroke()
        }
    }

    func createPOIMarkerIcon(color: UIColor, isMain: Bool) -> UIImage {
        let size = isMain ? CGSize(width: 28, height: 36) : CGSize(width: 20, height: 26)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            let w = size.width
            let h = size.height
            let r = w / 2
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: w / 2, y: h))
            path.addLine(to: CGPoint(x: w * 0.15, y: r + 4))
            path.addArc(
                withCenter: CGPoint(x: w / 2, y: r),
                radius: r - 1,
                startAngle: .pi * 0.8,
                endAngle: .pi * 0.2,
                clockwise: false
            )
            path.close()
            
            color.setFill()
            path.fill()
            
            UIColor.white.setStroke()
            path.lineWidth = 2.0
            path.stroke()
            
            if isMain {
                let dotRect = CGRect(x: w/2 - 4, y: r - 4, width: 8, height: 8)
                UIColor.white.setFill()
                UIBezierPath(ovalIn: dotRect).fill()
            }
        }
    }
}

// MARK: - Vista de prueba 


#if DEBUG
struct MapViewRepresentable_Previews: PreviewProvider {
    
    @State static var location: CLLocationCoordinate2D? = CLLocationCoordinate2D(
        latitude: 14.63131332,
        longitude: -90.54845428
    )
    @State static var heading: Double = 0
    @State static var route: [CLLocationCoordinate2D] = []
    @State static var highlighted: String? = nil
    
    static var previews: some View {
        MapViewRepresentable(
            userLocation: $location,
            userHeading: $heading,
            routeCoordinates: $route,
            highlightedPOIId: $highlighted,
            pois: [],
            tourStartCoordinate: nil
        )
        .frame(height: 300)
        .previewDisplayName("Mapa Kaminaljuyú")
    }
}
#endif
