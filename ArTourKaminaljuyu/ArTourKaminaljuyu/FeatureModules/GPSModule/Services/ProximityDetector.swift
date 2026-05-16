import CoreLocation
import Foundation

// MARK: - ProximityDetectorDelegate

protocol ProximityDetectorDelegate: AnyObject {

    func proximityDetector(_ detector: ProximityDetector, didArriveAt poi: POILocation)

    func proximityDetector(_ detector: ProximityDetector, didLeave poi: POILocation)

    func proximityDetectorDidEnterStartRadius(_ detector: ProximityDetector)

    func proximityDetectorDidExitStartRadius(_ detector: ProximityDetector)

    func proximityDetector(
        _ detector: ProximityDetector,
        didUpdateDistances distances: [String: Double],
        distanceToStart: Double
    )
}

extension ProximityDetectorDelegate {
    func proximityDetector(_ detector: ProximityDetector, didLeave poi: POILocation) {}
    func proximityDetectorDidExitStartRadius(_ detector: ProximityDetector) {}
    func proximityDetector(
        _ detector: ProximityDetector,
        didUpdateDistances distances: [String: Double],
        distanceToStart: Double
    ) {}
}

// MARK: - ProximityDetector
final class ProximityDetector {

    weak var delegate: ProximityDetectorDelegate?

    var tourStartRadiusMeters: Double = 20.0

    private(set) var monitoredPOIs: [POILocation]

    private let startCoordinate: CLLocationCoordinate2D

    private var isMonitoring = false

    private var currentlyNearPOIIds: Set<String> = []

    private var wasInsideStartRadius = false

    // MARK: - Inicializador
    init(
        pois: [POILocation] = POIRegistry.shared.pois,
        startCoordinate: CLLocationCoordinate2D? = nil
    ) {
        self.monitoredPOIs = pois
        self.startCoordinate = startCoordinate ?? POIRegistry.shared.tourStartCoordinate
    }

    // MARK: - Control
    func startMonitoring() {
        isMonitoring = true
        currentlyNearPOIIds.removeAll()
        wasInsideStartRadius = false
    }

    func stopMonitoring() {
        isMonitoring = false
        currentlyNearPOIIds.removeAll()
        wasInsideStartRadius = false
    }

    // MARK: - Actualización de posición
    func update(with location: CLLocation) {
        guard isMonitoring else { return }

        let userCoord = location.coordinate
        var distanceMap: [String: Double] = [:]

        for poi in monitoredPOIs {
            let distance = GeoMath.distance(from: location, to: poi.coordinate)
            distanceMap[poi.id] = distance

            let isNearNow = distance <= poi.arrivalThresholdMeters
            let wasNear   = currentlyNearPOIIds.contains(poi.id)

            if isNearNow && !wasNear {
                currentlyNearPOIIds.insert(poi.id)
                delegate?.proximityDetector(self, didArriveAt: poi)

            } else if !isNearNow && wasNear {
                currentlyNearPOIIds.remove(poi.id)
                delegate?.proximityDetector(self, didLeave: poi)
            }
        }

        let distToStart = GeoMath.distance(
            from: userCoord,
            to: startCoordinate
        )
        let isInsideStartNow = distToStart <= tourStartRadiusMeters

        if isInsideStartNow && !wasInsideStartRadius {
            wasInsideStartRadius = true
            delegate?.proximityDetectorDidEnterStartRadius(self)
        } else if !isInsideStartNow && wasInsideStartRadius {
            wasInsideStartRadius = false
            delegate?.proximityDetectorDidExitStartRadius(self)
        }

        delegate?.proximityDetector(
            self,
            didUpdateDistances: distanceMap,
            distanceToStart: distToStart
        )
    }

    // MARK: - Consultas sincrónicas
    func distance(to poi: POILocation, from location: CLLocation) -> Double {
        GeoMath.distance(from: location, to: poi.coordinate)
    }

    func nearestPOI(from location: CLLocation) -> POILocation? {
        monitoredPOIs.min {
            GeoMath.distance(from: location, to: $0.coordinate) <
            GeoMath.distance(from: location, to: $1.coordinate)
        }
    }

    func isNear(poiId: String) -> Bool {
        currentlyNearPOIIds.contains(poiId)
    }

    var currentlyNearPOIs: [POILocation] {
        monitoredPOIs.filter { currentlyNearPOIIds.contains($0.id) }
    }
}
