import Foundation
import CoreLocation
import Combine

// MARK: - Estado del tour
enum TourState {
    case idle
    case navigatingToStart
    case navigatingToPOI(Int)
    case atPOI(Int)
    case returning
    case completed
}

// MARK: - TourManager
final class TourManager: ObservableObject {

    // MARK: - Estado publicado para SwiftUI y módulo AR
    @Published private(set) var state: TourState = .idle
    @Published private(set) var currentPOI: POILocation? = nil
    @Published private(set) var targetCoordinate: CLLocationCoordinate2D? = nil
    @Published private(set) var bearingToTarget: Double = 0
    @Published private(set) var distanceToTarget: Double = .nan
    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    let poiArrivedPublisher   = PassthroughSubject<POILocation, Never>()
    let tourCompletedPublisher = PassthroughSubject<Void, Never>()

    // MARK: - Estado interno
    private let pois: [POILocation]
    private var guidedCurrentIndex: Int = 0

    private var startLegNavigator: RouteNavigator?
    private var guidedLegNavigator: RouteNavigator?
    private var returnLegNavigator: RouteNavigator?

    // MARK: - Init
    init(pois: [POILocation] = POIRegistry.shared.pois) {
        self.pois = pois
    }

    // MARK: - Control del tour

    func startTour(userLocation: CLLocationCoordinate2D) {
        guard !pois.isEmpty else { return }

        let startCoord = CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )
        let distToStart = GeoUtils.distanceInMeters(from: userLocation, to: startCoord)
        guard distToStart <= AppConfig.tourStartRadiusMeters else {
            print("[TourManager] Usuario muy lejos del inicio: \(Int(distToStart))m")
            return
        }

        guidedCurrentIndex = 0

        let firstPOI = pois[0]
        let startConnectors = connectorsForStartLeg(first: firstPOI)
        startLegNavigator = startConnectors.isEmpty
            ? nil
            : RouteNavigator(waypoints: startConnectors,
                             arrivalThresholdMeters: AppConfig.connectorArrivalMeters)

        routeCoordinates = buildFullRouteIncludingStart(start: startCoord, pois: pois)

        currentPOI = firstPOI
        state = .navigatingToPOI(0)
    }

    func advanceToNextPOI() {
        guard case .atPOI(let idx) = state else { return }
        let nextIndex = idx + 1

        if nextIndex < pois.count {
            guidedCurrentIndex = nextIndex
            buildGuidedLegNavigator(from: idx, to: nextIndex)
            currentPOI = pois[nextIndex]
            state = .navigatingToPOI(nextIndex)
        }
    }

    func startReturnPhase() {
        guard case .atPOI(let idx) = state, idx == pois.count - 1 else { return }

        let lastPOI = pois[idx]
        let startCoord = CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )

        let returnConnectors = connectorsForReturnLeg(last: lastPOI)
        returnLegNavigator = returnConnectors.isEmpty
            ? nil
            : RouteNavigator(waypoints: returnConnectors,
                             arrivalThresholdMeters: AppConfig.connectorArrivalMeters)

        routeCoordinates = buildReturnLeg(last: lastPOI, start: startCoord)

        state = .returning
    }

    func stopTour() {
        state = .idle
        currentPOI = nil
        targetCoordinate = nil
        routeCoordinates = []
        guidedCurrentIndex = 0
        startLegNavigator = nil
        guidedLegNavigator = nil
        returnLegNavigator = nil
    }

    // MARK: - Actualización por frame
    func update(userLocation: CLLocationCoordinate2D) {
        switch state {

        case .idle, .completed:
            break

        case .navigatingToStart:
            updateStartLeg(userLocation: userLocation)

        case .navigatingToPOI(let idx):
            updateGuidedLeg(userLocation: userLocation, poiIndex: idx)

        case .atPOI:
            break

        case .returning:
            updateReturnLeg(userLocation: userLocation)
        }

        if let target = targetCoordinate {
            distanceToTarget = GeoUtils.distanceInMeters(from: userLocation, to: target)
            bearingToTarget  = GeoUtils.bearing(from: userLocation, to: target)
        }
    }

    // MARK: - Actualización de tramos internos

    private func updateStartLeg(userLocation: CLLocationCoordinate2D) {
        if let nav = startLegNavigator {
            nav.updateAndGetTarget(userLocation: userLocation)
            if nav.isFinished { startLegNavigator = nil }
            targetCoordinate = nav.currentTarget ?? pois.first?.coordinate
        } else {
            targetCoordinate = pois.first?.coordinate
        }
    }

    private func updateGuidedLeg(userLocation: CLLocationCoordinate2D, poiIndex: Int) {
        if let startNav = startLegNavigator {
            startNav.updateAndGetTarget(userLocation: userLocation)
            if startNav.isFinished { startLegNavigator = nil }
            targetCoordinate = startNav.currentTarget ?? pois[poiIndex].coordinate
            return
        }

        if let legNav = guidedLegNavigator {
            legNav.updateAndGetTarget(userLocation: userLocation)
            if legNav.isFinished { guidedLegNavigator = nil }
            targetCoordinate = legNav.currentTarget ?? pois[poiIndex].coordinate
        } else {
            targetCoordinate = pois[poiIndex].coordinate
            let distToPOI = GeoUtils.distanceInMeters(
                from: userLocation,
                to: pois[poiIndex].coordinate
            )
            if distToPOI <= AppConfig.guidedArrivalMeters {
                state = .atPOI(poiIndex)
                poiArrivedPublisher.send(pois[poiIndex])
            }
        }
    }

    private func updateReturnLeg(userLocation: CLLocationCoordinate2D) {
        let startCoord = CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )

        if let returnNav = returnLegNavigator {
            returnNav.updateAndGetTarget(userLocation: userLocation)
            if returnNav.isFinished { returnLegNavigator = nil }
            targetCoordinate = returnNav.currentTarget ?? startCoord
        } else {
            targetCoordinate = startCoord
            let distToStart = GeoUtils.distanceInMeters(from: userLocation, to: startCoord)
            if distToStart <= AppConfig.tourStartRadiusMeters {
                state = .completed
                routeCoordinates = []
                tourCompletedPublisher.send()
            }
        }
    }

    // MARK: - Helpers de conectores

    private func buildGuidedLegNavigator(from fromIndex: Int, to toIndex: Int) {
        let connectors = connectorsForPoiLeg(
            from: pois[fromIndex],
            to: pois[toIndex]
        )
        guidedLegNavigator = connectors.isEmpty
            ? nil
            : RouteNavigator(waypoints: connectors,
                             arrivalThresholdMeters: AppConfig.connectorArrivalMeters)
    }
}
