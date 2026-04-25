import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {


    static let shared = POIRegistry()
    private init() {}

    lazy var pois: [POILocation] = {
        return [
            POILocation(
                id: "informacion_inicial",
                coordinate: CLLocationCoordinate2D(latitude: 14.604981067673345, longitude: -90.48975788426475),
                
                name: "KaminalJuyú",
                modelPath: "Monticulo3.obj",
                baseScale: 1.0,
                baseAltitudeMeters: 0.0,
                description: "Kaminal Juyú es uno de los sitios arqueológicos mayas más importantes de las tierras altas de Guatemala.",
                images: ["inicio"]
            ),

            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(latitude: 14.631895407440561, longitude: -90.54859084940932),
                name: "Montículo C-II-6",
                modelPath: "Monticulo7.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: "Estructura del Preclásico Tardío-Terminal al Clásico Tardío.",
                images: ["inicio"]
            ),

            POILocation(
                id: "acropolis",
                coordinate: CLLocationCoordinate2D(latitude: 14.632549261303337, longitude: -90.54889359532447),
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
                coordinate: CLLocationCoordinate2D(latitude: 14.633263117257021, longitude: -90.54812859260066),
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
                coordinate: CLLocationCoordinate2D(latitude: 14.632555675181031, longitude: -90.54807733211727),
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
                coordinate: CLLocationCoordinate2D(latitude: 14.632234919514932, longitude: -90.54800651965228),
                name: "Montículo C-II-7",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                parts: [
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Rancho_techo.obj",
                              texturePath: "models/textures/reed_roof_03_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Puerta.obj",
                              texturePath: "models/textures/fondo-textura-madera.png", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Plane004.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Plane003.obj",
                              texturePath: "models/textures/reed_roof_03_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Plane002.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Plane001.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-7/monticulo-7-Plane.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8)
                ],
                description: "Estructura con rancho reconstructivo multi-parte.",
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío"
            ),

            POILocation(
                id: "monticulo_8",
                coordinate: CLLocationCoordinate2D(latitude: 14.631888413377396, longitude: -90.54808529662705),
                name: "Montículo C-II-8",
                modelPath: "models/informacion/Oval_Loc_OBJ_Format.obj",
                texturePath: "models/textures/Oval_Loc_Red.png",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: "Montículo del sector central del parque.",
                constructionPeriod: "Preclásico Tardío - Clásico Tardío",
                images: ["c_ii_8"]
            ),

            POILocation(
                id: "monticulo_12",
                coordinate: CLLocationCoordinate2D(latitude: 14.631110755220972, longitude: -90.54816619269748),
                name: "Montículo C-II-12",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                parts: [
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Rancho_techo.obj",
                              texturePath: "models/textures/reed_roof_03_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Puerta.obj",
                              texturePath: "models/textures/fondo-textura-madera.png", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Rancho.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Templo_3.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Templo_1_y_2.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Gradas.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-12/monticulo-12-Escalinatas.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8)
                ],
                description: "Estructura con escalinatas y templo reconstructivo.",
                constructionPeriod: "Preclásico Tardío-Terminal",
                images: ["c_ii_12", "c_ii_12_2"]
            ),

            POILocation(
                id: "palangana",
                coordinate: CLLocationCoordinate2D(latitude: 14.630813964263574, longitude: -90.54760512338584),
                name: "La Palangana",
                baseScale: 0.5,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 90.0,
                parts: [
                    ModelPart(modelPath: "models/palangana/palangana-Talud-1.2.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-tablero-1.1.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-pasillo.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-palangana.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-gradas.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-escalinatas.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-bloque-largo.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-bloque-2.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/palangana/palangana-bloque-1.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8)
                ],
                description: "Complejo arquitectónico con múltiples etapas constructivas del Clásico.",
                constructionPeriod: "Clásico Temprano - Clásico Tardío",
                images: ["e", "etapa3", "etapa3a", "etapa2a", "etapa2b", "etapa2c", "etapa1"]
            ),

            POILocation(
                id: "monticulo_14",
                coordinate: CLLocationCoordinate2D(latitude: 14.630593990926299, longitude: -90.54696166473626),
                name: "Montículo C-II-14",
                modelPath: "models/monticulo-14/monticulo-14.obj",
                texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                description: "Estructura del Preclásico Tardío-Terminal al Clásico Tardío.",
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío"
            ),

            POILocation(
                id: "monticulo_13",
                coordinate: CLLocationCoordinate2D(latitude: 14.630643799200827, longitude: -90.54698876882740),
                name: "Montículo C-II-13",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                parts: [
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Plane004.obj",
                              texturePath: "models/textures/reed_roof_03_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Plane003.obj",
                              texturePath: "models/textures/114009464-textura-de-palo.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Plane002.obj",
                              texturePath: "models/textures/red_plaster_weathered_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Plane001.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Plane.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8),
                    ModelPart(modelPath: "models/monticulo-13/monticulo-13-Gradas.obj",
                              texturePath: "models/textures/clay_plaster_diff_4k.jpg", baseScale: 0.8)
                ],
                description: "Estructura con gradas reconstructivas.",
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío",
                images: ["c_ii_13", "c_ii_13_2", "c_ii_13_3"]
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
