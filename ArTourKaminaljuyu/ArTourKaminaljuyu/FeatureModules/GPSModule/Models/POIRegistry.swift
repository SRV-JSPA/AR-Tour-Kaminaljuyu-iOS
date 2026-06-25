import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {


    static let shared = POIRegistry()
    private init() {}

    lazy var pois: [POILocation] = {
        return [
            POILocation(
                id: "informacion_inicial",
                coordinate: CLLocationCoordinate2D(latitude: 14.5959034, longitude: -90.6391905),
                
                name: "KaminalJuyú",
                modelPath: "poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: 0.0,
                description: "Kaminal Juyú es uno de los sitios arqueológicos mayas más importantes de las tierras altas de Guatemala.",
                images: ["inicio"]
            ),


            POILocation(
                id: "monticulo_5",
                coordinate: CLLocationCoordinate2D(latitude: 14.5952074, longitude: -90.6392505),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo14.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            POILocation(
                id: "palangana",
                coordinate: CLLocationCoordinate2D(latitude: 14.5948726, longitude: -90.6396525),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/palangana.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),
            

            POILocation(
                id: "monticulo_13",
                coordinate: CLLocationCoordinate2D(latitude: 14.5945592, longitude: -90.6400515),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo13.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
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
        pois[0].coordinate
    }
}
