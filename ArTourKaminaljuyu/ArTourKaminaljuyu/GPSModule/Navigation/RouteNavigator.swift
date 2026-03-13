import CoreLocation

final class RouteNavigator {

    // MARK: - Estado interno
    private let route: [CLLocationCoordinate2D]
    private var index: Int = 0
    private let arrivalThresholdMeters: Double
    private(set) var lastDistanceMeters: Double = .nan

    // MARK: - Init
    init(
        waypoints: [CLLocationCoordinate2D],
        arrivalThresholdMeters: Double = AppConfig.connectorArrivalMeters
    ) {
        self.route = waypoints
        self.arrivalThresholdMeters = arrivalThresholdMeters
    }

    // MARK: - API pública

    var currentIndex: Int { index }

    var isFinished: Bool { !route.indices.contains(index) }

    var currentTarget: CLLocationCoordinate2D? {
        guard route.indices.contains(index) else { return nil }
        return route[index]
    }

    @discardableResult
    func updateAndGetTarget(userLocation: CLLocationCoordinate2D) -> CLLocationCoordinate2D? {
        guard let target = currentTarget else { return nil }

        let distance = GeoUtils.distanceInMeters(from: userLocation, to: target)
        lastDistanceMeters = distance

        if distance <= arrivalThresholdMeters {
            index += 1
        }

        return currentTarget
    }


    func reset() { index = 0 }


    func advance() {
        if route.indices.contains(index) { index += 1 }
    }
}
