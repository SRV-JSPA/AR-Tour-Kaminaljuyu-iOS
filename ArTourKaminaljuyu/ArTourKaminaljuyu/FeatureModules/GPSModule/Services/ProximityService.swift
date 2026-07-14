import Foundation
import CoreLocation
import Combine

// MARK: - Niveles de proximidad
enum ProximityLevel {
    case far
    case visible
    case near
    case arrived
}

// MARK: - Resultado de proximidad
struct ProximityResult {
    let poi: POILocation
    let distanceMeters: Double
    let horizontalAccuracy: Double
    let bearing: Double
    let level: ProximityLevel

    // Distancia para lógica de disparos por cercanía (videos, modelo 3D):
    // compensa el ruido del GPS restando la precisión reportada.
    var effectiveDistanceMeters: Double {
        GeoUtils.compensatedDistance(distanceMeters, horizontalAccuracy: horizontalAccuracy)
    }

    var statusMessage: String {
        switch level {
        case .arrived:
            return "\(poi.name) — \(Int(distanceMeters))m — ¡Llegaste!"
        case .near:
            return "\(poi.name) cerca — \(Int(distanceMeters))m"
        case .visible:
            return "\(poi.name) visible — \(Int(distanceMeters))m — Acércate"
        case .far:
            return "Explora el área para encontrar montículos"
        }
    }
}

// MARK: - ProximityService
final class ProximityService: ObservableObject {

    // MARK: - Publicaciones para SwiftUI / módulo AR
    @Published var nearestPOI: ProximityResult? = nil

    let arrivalPublisher = PassthroughSubject<POILocation, Never>()

    // MARK: - Estado interno
    private let pois: [POILocation]
    private var lastArrivedPOIId: String? = nil

    // MARK: - Init
    init(pois: [POILocation] = POIRegistry.shared.pois) {
        self.pois = pois
    }

    // MARK: - Actualización principal
    func update(userLocation: CLLocationCoordinate2D, horizontalAccuracy: Double = 0) {

        let nearest = pois
            .map { poi -> (POILocation, Double) in
                let distance = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
                print("[Proximity] distancia a \(poi.id): \(distance)m (precisión GPS: \(horizontalAccuracy)m)")
                return (poi, distance)
            }
            .filter { _, distance in distance <= AppConfig.visibilityRadiusMeters }
            .min(by: { $0.1 < $1.1 })
        
        print("[Proximity] userLocation: \(userLocation.latitude), \(userLocation.longitude)")
        print("[Proximity] POIs count: \(pois.count)")

        guard let (poi, distance) = nearest else {
            DispatchQueue.main.async { self.nearestPOI = nil }
            return
        }

        let bearingToPOI = GeoUtils.bearing(from: userLocation, to: poi.coordinate)

        let level = proximityLevel(for: distance)

        let result = ProximityResult(
            poi: poi,
            distanceMeters: distance,
            horizontalAccuracy: horizontalAccuracy,
            bearing: bearingToPOI,
            level: level
        )

        DispatchQueue.main.async { self.nearestPOI = result }
        
        print("[Proximity] level para \(poi.id): \(level), lastArrived: \(String(describing: lastArrivedPOIId))")

        if level == .arrived && lastArrivedPOIId != poi.id {
            lastArrivedPOIId = poi.id
            arrivalPublisher.send(poi)
        }

        if level != .arrived && lastArrivedPOIId == poi.id {
            lastArrivedPOIId = nil
        }
    }

    // MARK: - Clasificación de nivel
    private func proximityLevel(for distance: Double) -> ProximityLevel {
        switch distance {
        case ..<AppConfig.guidedArrivalMeters:   return .arrived
        case ..<20:                               return .near
        case ..<50:                               return .near
        case ..<AppConfig.visibilityRadiusMeters: return .visible   
        default:                                  return .far
        }
    }

    // MARK: - Reset (al salir del tour)
    func reset() {
        lastArrivedPOIId = nil
        DispatchQueue.main.async { self.nearestPOI = nil }
    }
}
