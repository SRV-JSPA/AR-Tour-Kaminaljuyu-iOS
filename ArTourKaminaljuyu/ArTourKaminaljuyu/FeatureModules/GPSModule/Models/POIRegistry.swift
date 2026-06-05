import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {


    static let shared = POIRegistry()
    private init() {}

    lazy var pois: [POILocation] = {
        return [
            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(latitude: 14.6044315, longitude: -90.4891856),
                name: "Montículo C-II-6",
                modelPath: "Monticulo7.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: "Estructura del Preclásico Tardío-Terminal al Clásico Tardío.",
                images: ["inicio"]
            ),
        

            POILocation(
                id: "acropolis",
                coordinate: CLLocationCoordinate2D(latitude: 14.6048319, longitude: -90.4889184),
                name: "Acrópolis",
                modelPath: "Assets/Models/Monticulo12.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Complejo palaciego del período Clásico con múltiples etapas constructivas.",
                constructionPeriod: "Clásico Temprano - Clásico Tardío",
                images: ["c_ii_4"]
            ),
            

            POILocation(
                id: "monticulo_3",
                coordinate: CLLocationCoordinate2D(latitude: 14.6052874, longitude: -90.4885500),
                name: "Montículo C-II-3",
                modelPath: "Assets/Models/Monticulo13.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                description: "Estructura con rancho de caña reconstructivo.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            )
        ]
    }()

    // MARK: - Acceso por ID
    func poi(withId id: String) -> POILocation? {
        pois.first { $0.id == id }
    }

    // MARK: - Coordenada del punto de inicio de la ruta
    var tourStartCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
        latitude: AppConfig.tourStartLatitude, longitude: AppConfig.tourStartLongitude)
    }
}
