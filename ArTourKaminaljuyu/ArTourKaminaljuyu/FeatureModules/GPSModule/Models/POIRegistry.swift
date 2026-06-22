import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {


    static let shared = POIRegistry()
    private init() {}

    lazy var pois: [POILocation] = {
        return [
            POILocation(
                id: "informacion_inicial",
                coordinate: CLLocationCoordinate2D(latitude: 14.632698689382275, longitude: -90.46271365264592),
                
                name: "KaminalJuyú",
                modelPath: "poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: 0.0,
                description: "Kaminal Juyú es uno de los sitios arqueológicos mayas más importantes de las tierras altas de Guatemala.",
                images: ["inicio"]
            ),


        
            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(latitude: 14.632634039958822, longitude: -90.46276319574889),
                name: "Montículo C-II-6",
                modelPath: "Monticulo7.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: "Estructura del Preclásico Tardío-Terminal al Clásico Tardío.",
                images: ["inicio"]
            ),
        

            POILocation(
                id: "acropolis",
                coordinate: CLLocationCoordinate2D(latitude: 14.632513288847086, longitude: -90.46281431841246),
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
                coordinate: CLLocationCoordinate2D(latitude: 14.632369260387113, longitude: -90.46284739781102),
                name: "Montículo C-II-3",
                modelPath: "Assets/Models/Monticulo13.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                description: "Estructura con rancho de caña reconstructivo.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            POILocation(
                id: "monticulo_5",
                coordinate: CLLocationCoordinate2D(latitude: 14.632267421991845, longitude: -90.46281281511402),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo14.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            POILocation(
                id: "monticulo_7",
                coordinate: CLLocationCoordinate2D(latitude: 14.632523472584895, longitude: -90.46274364910946),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo7.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),
        
            POILocation(
                id: "monticulo_8",
                coordinate: CLLocationCoordinate2D(latitude: 14.632639430352548, longitude: -90.4627101985017),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo7.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            POILocation(
                id: "palangana",
                coordinate: CLLocationCoordinate2D(latitude: 14.6326814681419, longitude: -90.46269825049967),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/palangana.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),
            
            POILocation(
                id: "monticulo_14",
                coordinate: CLLocationCoordinate2D(latitude: 14.632768696567556, longitude: -90.46267109593205),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/Monticulo14.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Plataforma del Preclásico Tardío al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            POILocation(
                id: "monticulo_13",
                coordinate: CLLocationCoordinate2D(latitude: 14.632919801022863, longitude: -90.4626316786844),
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
