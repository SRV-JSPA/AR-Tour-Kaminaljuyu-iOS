import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {

    static let shared = POIRegistry()
    private init() {}

    // El punto de partida del recorrido NO es un POI: es solo la coordenada
    // desde la que arranca el tour (AppConfig.tourStartLatitude/Longitude) y
    // el ancla del video de bienvenida (secuencia de intro). Este array
    // contiene únicamente montículos con hallazgos arqueológicos reales.
    lazy var pois: [POILocation] = {
        [
            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632856,
                    longitude: -90.463771
                ),
                name: "Montículo C-II-6",
                modelPath: "Assets/Models/Monticulo7.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • Clásico tardío (575-900 d. C.): Depósito cerámico y construcción de tres rellenos, un canal, un piso, un apisonado y una superficie formada por piedras tipo laja, canto rodado y pómez.
                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Depósito cerámico conformado por una vasija completa que pudo funcionar como ofrenda.
                """,
                images: ["inicio"]
            ),

            POILocation(
                id: "acropolis",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632662,
                    longitude: -90.463084
                ),
                name: "Acrópolis (C-II-4)",
                modelPath: "Assets/Models/Monticulo12.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                description: """
                Hallazgos y función:

                • La acrópolis fue constantemente remodelada y representó el sector palaciego del sitio. Los palacios se ubicaron en el núcleo de las ciudades y presentaron una estructura interna sofisticada, lo que implicó diferentes usos y la existencia de espacios privados.
                • Clásico tardío (575-900 d. C.): Corresponde a la composición actual de la acrópolis, la cual fue utilizada como residencia para dignatarios importantes. Asimismo, se construyeron juegos de pelota y drenajes, y se hallaron comales, cuencos y tazas de comer. Durante este periodo varios edificios del clásico temprano (425-575 d. C.) fueron cubiertos con un piso de barro y nuevas estructuras de piedra y barro, mientras que otros edificios sufrieron cambios en la fachada.
                • Clásico temprano (425-575 d. C.): Construcción de más de 20 estructuras talud-tablero en la acrópolis. Durante este periodo se realizaron actividades ceremoniales y administrativas, evidenciadas por el hallazgo de incensarios y estructuras talud-tablero.
                • El talud-tablero es un estilo arquitectónico que consiste en una base inclinada, llamada talud, sobre la cual se encuentra el tablero, un bloque rectangular con molduras. Esta técnica constructiva es distintiva de Teotihuacán, México.
                • La incorporación del estilo talud-tablero en Kaminaljuyú fue una adaptación local, ya que se utilizaron recursos de la región, como material de origen volcánico, y diferentes dimensiones. En Teotihuacán el tablero es tres veces más grande que el talud (3:1), mientras que en Kaminaljuyú el talud y el tablero son del mismo tamaño (1:1).
                """,
                images: ["c_ii_4"]
            )
        ]
    }()

    // MARK: - Acceso por ID
    func poi(withId id: String) -> POILocation? {
        pois.first { $0.id == id }
    }

    // MARK: - Coordenada del punto de inicio de la ruta
    // Delega a AppConfig para que el punto de partida sea una fuente única
    // (antes derivaba de pois[0], lo cual dejaba de ser válido al sacar
    // informacion_inicial del array).
    var tourStartCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: AppConfig.tourStartLatitude,
            longitude: AppConfig.tourStartLongitude
        )
    }
}



///
