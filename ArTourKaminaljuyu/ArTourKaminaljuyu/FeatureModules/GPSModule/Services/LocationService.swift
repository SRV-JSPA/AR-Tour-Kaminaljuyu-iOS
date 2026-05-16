import Foundation
import CoreLocation
import Combine

// MARK: - LocationService


class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Propiedades publicadas

    @Published var currentLocation: CLLocation?
    

    @Published var currentHeading: CLHeading?
    

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
 
    @Published var isLocationReady: Bool = false
    
    // MARK: - Propiedades privadas
    
    private let locationManager = CLLocationManager()
    private let permissionsHelper = LocationPermissionsHelper()
    
    // MARK: - Constantes de configuración

    private let accuracyThresholdMeters: Double = 5.0
    
    // MARK: - Inicialización
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
 
        locationManager.distanceFilter = 1.0
        

        locationManager.showsBackgroundLocationIndicator = true
        

        locationManager.allowsBackgroundLocationUpdates = false
        
        permissionsHelper.onAuthorizationChanged = { [weak self] status in
            self?.handleAuthorizationChange(status)
        }
    }
    
    // MARK: - Control del servicio
    

    func startTracking() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
        case .notDetermined:

            permissionsHelper.requestLocationPermission()
            
        case .denied:

            print("[LocationService] Permiso denegado. El usuario debe habilitarlo en Configuración.")
            
        case .restricted:
            print("[LocationService] Ubicación restringida por política del dispositivo.")
            
        @unknown default:
            break
        }
    }
    

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isLocationReady = false
    }

    func enableBackgroundTracking() {
        guard locationManager.authorizationStatus == .authorizedAlways else {
            permissionsHelper.requestAlwaysPermission()
            return
        }
        locationManager.allowsBackgroundLocationUpdates = true
    }
    

    func disableBackgroundTracking() {
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    // MARK: - Propiedades de conveniencia

    var latitude: Double? {
        currentLocation?.coordinate.latitude
    }
    

    var longitude: Double? {
        currentLocation?.coordinate.longitude
    }

    var altitude: Double? {
        currentLocation?.altitude
    }
    

    var horizontalAccuracy: Double? {
        currentLocation?.horizontalAccuracy
    }
    

    var headingDegrees: Double? {
        currentHeading?.trueHeading
    }
    
    var hasPermission: Bool {
        permissionsHelper.hasLocationPermission
    }
    
    // MARK: - CLLocationManagerDelegate
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        

        guard latest.horizontalAccuracy > 0,
              latest.horizontalAccuracy < 50 else { return }
        
        currentLocation = latest

        isLocationReady = latest.horizontalAccuracy <= accuracyThresholdMeters
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {

        guard newHeading.trueHeading >= 0 else { return }
        currentHeading = newHeading
    }
    

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                stopTracking()
            case .locationUnknown:
                print("[LocationService] Ubicación temporalmente no disponible.")
            default:
                print("[LocationService] Error de CLLocationManager: \(clError.localizedDescription)")
            }
        }
    }
    
    // MARK: - Lógica interna

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            
        case .denied, .restricted:
            stopTracking()
            
        case .notDetermined:
            break
            
        @unknown default:
            break
        }
    }
}
