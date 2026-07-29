import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {

    static let shared = POIRegistry()
    private init() {}

    lazy var pois: [POILocation] = {
        [
            POILocation(
                id: "informacion_inicial",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.6047420,
                    longitude: -90.4894056
                ),
                name: "KaminalJuyú",
                modelPath: "Assets/Models/Monticulo3.obj",
                baseScale: 1.0,
                baseAltitudeMeters: 0.0,
                description: """
                Kaminal Juyú es uno de los sitios arqueológicos mayas más importantes de las tierras altas de Guatemala.
                """,
                images: ["inicio"]
            ),

            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.6044315,
                    longitude: -90.4891856
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
                    latitude: 14.6048319,
                    longitude: -90.4889184
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
            ),

            POILocation(
                id: "monticulo_3",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.6052874,
                    longitude: -90.4885500
                ),
                name: "Montículo C-II-3",
                modelPath: "Assets/Models/Monticulo13.obj",
                texturePath: "Assets/Textures/ColoBase.jpeg",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                description: """
                Hallazgos:

                • Clásico tardío (575-900 d. C.): Cerámica y construcción de dos pisos, un apisonado, rellenos constructivos y gradas.
                • Cerámica del clásico temprano (250-575 d. C.).
                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Depósito cerámico y construcción de gradas, un piso, un apisonado y rellenos constructivos.
                """
            ),

            POILocation(
                id: "monticulo_5",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632555675181031,
                    longitude: -90.54807733211727
                ),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/informacion/Oval_Loc_OBJ_Format.obj",
                texturePath: "models/textures/Oval_Loc_Red.png",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos:

                • Clásico tardío (575-900 d. C.): Construcción de cinco pisos de barro.
                • Rellenos de barro y suelo.
                • Preclásico tardío (350-100 a. C.): Construcción de una plataforma de 2.2 m de altura.
                • Cerámica del preclásico tardío (350-100 a. C.), preclásico tardío-terminal (100 a. C.-250 d. C.), clásico temprano (250-575 d. C.) y clásico tardío (575-900 d. C.).
                """
            ),

            POILocation(
                id: "monticulo_7",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632234919514932,
                    longitude: -90.54800651965228
                ),
                name: "Montículo C-II-7",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos:

                • El edificio talud-tablero que se está visualizando data del clásico temprano (425-575 d. C.).
                • Debajo del edificio se hallaron dos pisos y cerámica que datan del preclásico tardío-terminal (100 a. C.-250 d. C.), clásico temprano (250-575 d. C.) y clásico tardío (575-900 d. C.).
                """,
                parts: [
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Rancho_techo.obj",
                        texturePath: "models/textures/reed_roof_03_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Puerta.obj",
                        texturePath: "models/textures/fondo-textura-madera-abstracta_23-2148931508.png",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Plane004.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Plane003.obj",
                        texturePath: "models/textures/reed_roof_03_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Plane002.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Plane001.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-7/monticulo-7-Plane.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    )
                ]
            ),

            POILocation(
                id: "monticulo_8",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.631888413377396,
                    longitude: -90.54808529662705
                ),
                name: "Montículo C-II-8",
                modelPath: "Assets/Models/informacion/Oval_Loc_OBJ_Format.obj",
                texturePath: "models/textures/Oval_Loc_Red.png",
                baseScale: 0.2,
                baseAltitudeMeters: -1.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos:

                • Clásico tardío (575-900 d. C.): Figurillas y depósito cerámico de uso doméstico.
                • Preclásico tardío-terminal (350 a. C.-250 d. C.): Construcción de un canal y fragmentos de un monumento.
                • Depósito cultural conformado por un fragmento de vasija e incensario y una punta de lanza de obsidiana. También se hallaron dos mandíbulas, dientes y un fragmento de cráneo, los cuales pudieron estar relacionados con alguna actividad ritual. Los materiales del depósito datan desde el preclásico tardío-terminal (100 a. C.-250 d. C.) hasta el clásico tardío (575-900 d. C.).
                """,
                images: ["c_ii_8"]
            ),

            POILocation(
                id: "monticulo_12",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.631110755220972,
                    longitude: -90.54816619269748
                ),
                name: "Montículo C-II-12",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos:

                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Plataforma con escalones de barro, figurillas de mujeres embarazadas, pigmentos y un depósito conformado por vasijas finas y utilitarias, lascas de obsidiana, una piedra con huella de trabajo, dos vasijas miniatura, huesos humanos y de animal.
                • La plataforma que está visualizando fue una residencia de élite, en la cual se realizaron rituales para la fertilidad.
                """,
                images: ["c_ii_12", "c_ii_12_2"],
                parts: [
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Rancho_techo.obj",
                        texturePath: "models/textures/reed_roof_03_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Puerta.obj",
                        texturePath: "models/textures/fondo-textura-madera-abstracta_23-2148931508.png",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Rancho.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Templo_3.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Templo_1_y_2.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Gradas.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-12/monticulo-12-Escalinatas.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    )
                ]
            ),

            POILocation(
                id: "palangana",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630813964263574,
                    longitude: -90.54760512338584
                ),
                name: "Estructura E",
                baseScale: 0.5,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 90.0,
                description: """
                Clásico tardío (575-900 d. C.)

                Etapa 5:
                • Al sur del recinto se depositó cerámica y esculturas de etapas constructivas anteriores.

                Etapa 4:
                • Es la etapa constructiva actualmente expuesta, conformada por un drenaje en el interior del recinto y una estructura de adobe que cubre el estilo talud-tablero. Al frente del recinto se construyó una plataforma del mismo material, la cual fue destruida durante las investigaciones realizadas a inicios del siglo pasado.

                Clásico temprano (425-575 d. C.)

                Etapa 3: Funcionó como residencia de élite o edificio administrativo.
                • Subetapa 3-c: Es la construcción virtual que observamos ahora. En esta subetapa se modificó el atrio y se construyeron nuevas gradas en la parte frontal del recinto; solo a través de estas se pudo acceder a la plataforma.
                • Subetapa 3-b: En el recinto se aplicó el estilo talud-tablero y se construyó una grada en el centro del lado sur. Además, se remodeló la escalinata de la plataforma, se incrementó la altura del atrio y se construyeron gradas en los lados este y oeste.
                • Subetapa 3-a: Se agregó una plataforma con estilo talud-tablero, que presentó en su parte superior agujeros de poste utilizados para sostener una superestructura de materiales perecederos. Asimismo, se construyó un atrio que conectó la plataforma con el recinto remodelado. Durante esta subetapa se hallaron dos tumbas dedicatorias que contenían individuos sentados, acompañados de ofrendas cerámicas. La tumba 2 se localizó en el recinto, mientras que la tumba 3 se construyó con piedras y se ubicó en la esquina noreste de la plataforma.

                Etapa 2: Funcionó como un centro ritual o fue reutilizado para alguna otra actividad pública.
                • Subetapa 2-c: En el interior del recinto se modificaron las gradas y se incorporó un talud. En la parte sur del exterior se ampliaron las gradas de acceso y se construyeron dos adiciones rectangulares.
                • Subetapa 2-b: Aumentó la altura del recinto y se construyeron gradas en el interior y exterior.
                • Subetapa 2-a: Construcción de un recinto hundido al norte de la primera etapa constructiva.

                Etapa 1: Funcionó como altar dedicatorio.
                • Pequeña pirámide con una base en forma de talud y paredes de tipo tablero. Esta primera etapa se edificó sobre la tumba 1, que contenía restos humanos, estelas lisas y una escultura tallada.
                """,
                images: [
                    "e",
                    "etapa3",
                    "etapa3a",
                    "etapa2a",
                    "etapa2b",
                    "etapa2c",
                    "etapa1"
                ],
                parts: [
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-Talud-1.2.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-tablero-1.1.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-pasillo.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-palangana.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-gradas.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-escalinatas.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-bloque-largo.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-bloque-2.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/palangana/palangana-bloque-1.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    )
                ]
            ),

            POILocation(
                id: "monticulo_14",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630593990926299,
                    longitude: -90.54696166473626
                ),
                name: "Montículo C-II-14",
                modelPath: "Assets/Models/monticulo-14/monticulo-14.obj",
                texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos y funciones:

                • Clásico tardío (575-900 d. C.): Hallazgo de vasijas utilitarias e incensarios y construcción de una estructura de piedra que consiste en una base inclinada (talud) y escalinatas con alfardas. En la plataforma se realizaron actividades ceremoniales.
                • Clásico temprano (250-575 d. C.): Hallazgo de cerámica doméstica.
                  1. Plataforma con escalinata de barro, con acceso único del lado este.
                  2. Plataforma con escalinatas de piedrín de los lados este y oeste.
                  3. Plataforma con remanentes de paredes de piedrín.
                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Es la etapa constructiva más antigua, en la cual se construyeron gradas de acceso en el lado oeste de la estructura y se hallaron vasijas. La estructura funcionó como una residencia de élite.
                """
            ),

            POILocation(
                id: "monticulo_13",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630643799200827,
                    longitude: -90.5469887688274
                ),
                name: "Montículo C-II-13",
                baseScale: 0.2,
                baseAltitudeMeters: -3.0,
                baseYawDeg: 0.0,
                description: """
                Hallazgos y funciones:

                • Clásico tardío (575-900 d. C.): Construcción de la plataforma de barro que se está visualizando, en la cual se realizaron actividades rituales, debido al hallazgo de incensarios quebrados y vasijas con restos de material quemado. También se colocó el Monumento 224, tallado en sus cuatro lados. Las escenas representadas incluyen once círculos, un individuo arrodillado y otro de pie, una serpiente o pescado y una lengua bífida. El monumento data del Preclásico y se reutilizó durante el Clásico tardío, porque Kaminaljuyú experimentó una descentralización del poder, lo que impulsó un retorno a la ideología pasada.
                • Clásico temprano (250-575 d. C.): Construcción de tres escalinatas superpuestas, doce apisonados y ocho pisos de barro.
                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Construcción de dos drenajes de piedra, deposición de huesos humanos y una vasija en forma de cuerpo humano esqueletizado.
                """,
                images: ["c_ii_13", "c_ii_13_2", "c_ii_13_3"],
                parts: [
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Plane004.obj",
                        texturePath: "models/textures/reed_roof_03_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Plane003.obj",
                        texturePath: "models/textures/114009464-textura-de-palo-de-pino-fondo-de-madera-de-pinos-para-diseño.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Plane002.obj",
                        texturePath: "models/textures/red_plaster_weathered_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Plane001.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Plane.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    ),
                    ModelPart(
                        modelPath: "Assets/Models/monticulo-13/monticulo-13-Gradas.obj",
                        texturePath: "models/textures/clay_plaster_diff_4k.jpg",
                        baseScale: 0.8
                    )
                ]
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