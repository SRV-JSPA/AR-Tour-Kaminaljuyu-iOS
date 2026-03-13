import Foundation
import CoreLocation
import UIKit

class LocationPermissionsHelper: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    var onAuthorizationChanged: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Verificación de permisos

    var hasLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    var isLocationDenied: Bool {
        return locationManager.authorizationStatus == .denied
    }
    
    var isLocationRestricted: Bool {
        return locationManager.authorizationStatus == .restricted
    }
    
    // MARK: - Solicitud de permisos
    

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Navegación a Settings
    

    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    

    var shouldShowRationale: Bool {
        let status = locationManager.authorizationStatus
        return status == .notDetermined || status == .denied
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChanged?(manager.authorizationStatus)
    }
}
