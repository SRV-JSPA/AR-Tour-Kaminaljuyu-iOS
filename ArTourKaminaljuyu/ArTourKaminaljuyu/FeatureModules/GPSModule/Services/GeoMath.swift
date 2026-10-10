import CoreLocation
import Foundation

// MARK: - GeoMath
enum GeoMath {

    private static let earthRadius: Double = 6_371_000.0

    // MARK: - Distancia Haversine
    static func distance(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Double {
        let lat1Rad  = origin.latitude.toRadians
        let lat2Rad  = destination.latitude.toRadians
        let deltaLat = (destination.latitude  - origin.latitude).toRadians
        let deltaLon = (destination.longitude - origin.longitude).toRadians

        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    static func distance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        distance(
            from: CLLocationCoordinate2D(latitude: lat1, longitude: lon1),
            to:   CLLocationCoordinate2D(latitude: lat2, longitude: lon2)
        )
    }

    // MARK: - Bearing (azimut)
    static func bearing(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Double {
        let φ1 = origin.latitude.toRadians
        let φ2 = destination.latitude.toRadians
        let Δλ = (destination.longitude - origin.longitude).toRadians

        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)

        var θ = atan2(y, x).toDegrees
        if θ < 0 { θ += 360.0 }
        return θ
    }

    static func bearing(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        bearing(
            from: CLLocationCoordinate2D(latitude: lat1, longitude: lon1),
            to:   CLLocationCoordinate2D(latitude: lat2, longitude: lon2)
        )
    }

    // MARK: - Normalización de ángulos
    static func normalizeDeg180(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < -180.0 { d += 360.0 }
        if d >  180.0 { d -= 360.0 }
        return d
    }

    static func normalizeDeg360(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        return d
    }

    // MARK: - Distancia desde CLLocation
    static func distance(from location: CLLocation, to coordinate: CLLocationCoordinate2D) -> Double {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: target)
    }
}

// MARK: - Double Extensions 
private extension Double {
    var toRadians: Double { self * .pi / 180.0 }
    var toDegrees: Double { self * 180.0 / .pi }
}
