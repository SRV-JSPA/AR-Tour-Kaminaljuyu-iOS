import Foundation
import CoreLocation

enum GeoUtils {

    // MARK: - Distancia Haversine
    static func distanceInMeters(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadius = 6_371_000.0

        let lat1Rad = from.latitude  * .pi / 180
        let lat2Rad = to.latitude    * .pi / 180
        let deltaLat = (to.latitude  - from.latitude)  * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
              + cos(lat1Rad) * cos(lat2Rad)
              * sin(deltaLon / 2) * sin(deltaLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    // MARK: - Bearing (rumbo)
    static func bearing(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = from.latitude  * .pi / 180
        let lat2 = to.latitude    * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }


    static func normalizeDeg180(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d < -180 { d += 360 }
        if d >  180 { d -= 360 }
        return d
    }
}
