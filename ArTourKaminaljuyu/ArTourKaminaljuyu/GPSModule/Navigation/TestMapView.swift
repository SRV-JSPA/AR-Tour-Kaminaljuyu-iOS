import SwiftUI
import CoreLocation

// MARK: - TestMapView

struct TestMapView: View {
    
    // MARK: - Servicios
    
    @StateObject private var locationService  = LocationService()
    @StateObject private var proximityService = ProximityService()
    @StateObject private var tourManager      = TourManager()
    
    // MARK: - Estado de UI
    
    @State private var userLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(
        latitude: AppConfig.tourStartLatitude,
        longitude: AppConfig.tourStartLongitude
    )
    @State private var userHeading: Double = 0
    
    private let testPois: [POILocation] = POIRegistry.shared.pois
    
    // MARK: - Computed helpers de estado del tour
    
    private var tourActive: Bool {
        switch tourManager.state {
        case .idle, .completed: return false
        default: return true
        }
    }
    
    private var currentPOIIndex: Int {
        switch tourManager.state {
        case .navigatingToPOI(let i), .atPOI(let i): return i
        default: return 0
        }
    }
    
    private var isAtLastPOI: Bool {
        if case .atPOI(let i) = tourManager.state {
            return i == testPois.count - 1
        }
        return false
    }
    
    private var isReturning: Bool {
        if case .returning = tourManager.state { return true }
        return false
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: Encabezado de estado
            VStack(alignment: .leading, spacing: 4) {
                Text("Prueba")
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            
            // MARK: Vista del mapa

            MapViewRepresentable(
                userLocation: $userLocation,
                userHeading: $userHeading,
                routeCoordinates: .constant(tourManager.routeCoordinates),
                highlightedPOIId: .constant(tourManager.currentPOI?.id),
                pois: testPois
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: Panel de controles de prueba
            VStack(spacing: 12) {
                
                HStack(spacing: 8) {
                    Button(tourActive ? "Detener" : "Iniciar Tour") {
                        if tourActive { stopTour() } else { startTour() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tourActive ? .red : .green)
                    
                    Button("➡ Siguiente") {
                        tourManager.advanceToNextPOI()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!tourActive || isReturning || isAtLastPOI)
                    
                    if isAtLastPOI {
                        Button("🔙 Regresar") {
                            tourManager.startReturnPhase()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("Heading:")
                        .font(.caption)
                    Slider(value: $userHeading, in: 0...360, step: 5)
                    Text("\(Int(userHeading))°")
                        .font(.caption)
                        .frame(width: 40)
                }
                
                if let poi = tourManager.currentPOI {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.orange)
                        Text("Objetivo: \(poi.name)")
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("\(currentPOIIndex + 1)/\(testPois.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if tourActive, !tourManager.distanceToTarget.isNaN {
                    HStack {
                        Image(systemName: "location.north.fill")
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(tourManager.bearingToTarget))
                        Text("Distancia: \(Int(tourManager.distanceToTarget))m")
                            .font(.caption)
                        Spacer()
                        Text("↑ \(Int(tourManager.bearingToTarget))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let proximity = proximityService.nearestPOI {
                    HStack {
                        Image(systemName: proximityIcon(for: proximity.level))
                            .foregroundColor(proximityColor(for: proximity.level))
                        Text("\(proximity.poi.name) — \(Int(proximity.distanceMeters))m")
                            .font(.caption)
                        Spacer()
                        Text(proximityLabel(for: proximity.level))
                            .font(.caption2)
                            .foregroundColor(proximityColor(for: proximity.level))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .onAppear {
            locationService.startTracking()
        }
        .onReceive(locationService.$currentLocation) { newLocation in
            guard let coord = newLocation?.coordinate else { return }
            userLocation = coord
            proximityService.update(userLocation: coord)
            tourManager.update(userLocation: coord)
        }
        .onReceive(locationService.$currentHeading) { newHeading in
            guard let heading = newHeading?.trueHeading, heading >= 0 else { return }
            userHeading = heading
        }
        .onReceive(proximityService.arrivalPublisher) { poi in
            print("📍 ProximityService: cerca de \(poi.name)")
        }
        .onReceive(tourManager.poiArrivedPublisher) { poi in
            print("TourManager: llegaste a \(poi.name)")
        }
        .onReceive(tourManager.tourCompletedPublisher) { _ in
            print("Tour completado")
        }
    }
    
    // MARK: - Texto de estado
    
    var statusText: String {
        switch tourManager.state {
        case .idle:
            return "Tour no iniciado. Pulsa 'Iniciar Tour' para comenzar."
        case .navigatingToStart:
            return "Camina hacia el punto de inicio del recorrido."
        case .navigatingToPOI(let i):
            return "Navegando → \(testPois[i].name)"
        case .atPOI(let i):
            return " En \(testPois[i].name) — Pulsa 'Siguiente' para continuar."
        case .returning:
            return " Regresando al punto de inicio..."
        case .completed:
            return " ¡Recorrido completado!"
        }
    }
    
    // MARK: - Acciones
    
    func startTour() {
        let startCoord = CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )
        userLocation = startCoord
        proximityService.reset()
        tourManager.startTour(userLocation: startCoord)
    }
    
    func stopTour() {
        tourManager.stopTour()
        proximityService.reset()
    }
    
    // MARK: - Helpers de UI para proximidad
    
    private func proximityIcon(for level: ProximityLevel) -> String {
        switch level {
        case .arrived: return "checkmark.circle.fill"
        case .near:    return "mappin.circle.fill"
        case .visible: return "eye.circle"
        case .far:     return "map"
        }
    }
    
    private func proximityColor(for level: ProximityLevel) -> Color {
        switch level {
        case .arrived: return .green
        case .near:    return .orange
        case .visible: return .blue
        case .far:     return .gray
        }
    }
    
    private func proximityLabel(for level: ProximityLevel) -> String {
        switch level {
        case .arrived: return "¡Llegaste!"
        case .near:    return "Cerca"
        case .visible: return "Visible"
        case .far:     return "Lejos"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TestMapView_Previews: PreviewProvider {
    static var previews: some View {
        TestMapView()
    }
}
#endif
