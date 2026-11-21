import CoreLocation

// MARK: - POIRegistry
final class POIRegistry {

    static let shared = POIRegistry()
    private init() {}

    // El punto de partida del recorrido NO es un POI: es solo la coordenada
    // desde la que arranca el tour (AppConfig.tourStartLatitude/Longitude) y
    // el ancla del video de bienvenida (secuencia de intro). Este array
    // contiene únicamente montículos con hallazgos arqueológicos reales.
    //
    // ORDEN DEL RECORRIDO
    // El orden de este array ES el orden del tour guiado: TourManager avanza
    // de pois[i] a pois[i+1], y RouteConfig.CONNECTORS está indexado por
    // pares "fromId->toId" que asumen exactamente esta secuencia. Reordenar
    // aquí sin reordenar los conectores rompe la ruta.
    //
    //   1. monticulo_6     6. monticulo_8
    //   2. acropolis       7. monticulo_12
    //   3. monticulo_3     8. palangana (Estructura E)
    //   4. monticulo_5     9. monticulo_14
    //   5. monticulo_7    10. monticulo_13
    //
    // En el recorrido del Android el POI 1 es `informacion_inicial` (el texto
    // general de Kaminaljuyú). Acá ese contenido no es un POI: lo cubren los
    // videos de intro (Datos generales + Datos arqueológicos), y sus
    // conectores quedaron re-indexados como START->monticulo_6.
    //
    // COORDENADAS
    // Son las coordenadas reales del Parque Arqueológico Kaminaljuyú. Para
    // probar fuera del sitio hay que desplazarlas y poner
    // AppConfig.routeConnectorsEnabled = false (ver el comentario ahí).
    //
    // MODELOS
    // C-II-6, acrópolis, C-II-5 y C-II-8 todavía no tienen reconstrucción 3D:
    // usan `poi.obj` como marcador, igual que el marcador oval del Android.
    // Los demás cargan su .obj y resuelven texturas desde su .mtl, así que
    // `texturePath` se deja vacío a propósito.
    //
    // ESCALA Y ALTURA
    // `baseScale` no es portable desde el Android: acá se multiplica además
    // por ARConfig.globalScaleMultiplier (0.3) y los .obj de iOS son mallas
    // unificadas, no las piezas sueltas del Android. Se parte del único valor
    // calibrado en campo (1.0 sobre un modelo de reconstrucción) y queda
    // pendiente afinar cada uno en el sitio. Como referencia: en el Android
    // la Estructura E va 2.5x más grande que los demás montículos.
    lazy var pois: [POILocation] = {
        [
            // MARK: 1. Montículo C-II-6
            POILocation(
                id: "monticulo_6",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.631895407440561,
                    longitude: -90.54859084940932
                ),
                name: "Montículo C-II-6",
                modelPath: "Assets/Models/poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -1.0,
                description: """
                Hallazgos:

                • Clásico tardío (575-900 d. C.): Depósito cerámico y construcción de tres rellenos, un canal, un piso, un apisonado y una superficie formada por piedras tipo laja, canto rodado y pómez.
                • Preclásico tardío-terminal (100 a. C.-250 d. C.): Depósito cerámico conformado por una vasija completa que pudo funcionar como ofrenda.
                """,
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío"
            ),

            // MARK: 2. Acrópolis (C-II-4)
            POILocation(
                id: "acropolis",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632549261303337,
                    longitude: -90.54889359532447
                ),
                name: "Acrópolis (C-II-4)",
                modelPath: "Assets/Models/poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -1.0,
                description: """
                Hallazgos y función:

                • La acrópolis fue constantemente remodelada y representó el sector palaciego del sitio. Los palacios se ubicaron en el núcleo de las ciudades y presentaron una estructura interna sofisticada, lo que implicó diferentes usos y la existencia de espacios privados.
                • Clásico tardío (575-900 d. C.): Corresponde a la composición actual de la acrópolis, la cual fue utilizada como residencia para dignatarios importantes. Asimismo, se construyeron juegos de pelota y drenajes, y se hallaron comales, cuencos y tazas de comer. Durante este periodo varios edificios del clásico temprano (425-575 d. C.) fueron cubiertos con un piso de barro y nuevas estructuras de piedra y barro, mientras que otros edificios sufrieron cambios en la fachada.
                • Clásico temprano (425-575 d. C.): Construcción de más de 20 estructuras talud-tablero en la acrópolis. Durante este periodo se realizaron actividades ceremoniales y administrativas, evidenciadas por el hallazgo de incensarios y estructuras talud-tablero.
                • El talud-tablero es un estilo arquitectónico que consiste en una base inclinada, llamada talud, sobre la cual se encuentra el tablero, un bloque rectangular con molduras. Esta técnica constructiva es distintiva de Teotihuacán, México.
                • La incorporación del estilo talud-tablero en Kaminaljuyú fue una adaptación local, ya que se utilizaron recursos de la región, como material de origen volcánico, y diferentes dimensiones. En Teotihuacán el tablero es tres veces más grande que el talud (3:1), mientras que en Kaminaljuyú el talud y el tablero son del mismo tamaño (1:1).
                """,
                constructionPeriod: "Clásico Temprano - Clásico Tardío",
                images: ["c_ii_4"]
            ),

            // MARK: 3. Montículo C-II-3
            POILocation(
                id: "monticulo_3",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.633263117257021,
                    longitude: -90.54812859260066
                ),
                name: "Montículo C-II-3",
                modelPath: "Assets/Models/Monticulo3.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • En el Clásico Tardío se construyó dos pisos, un apisonado, rellenos constructivos y gradas.

                • Cerámica del Clásico Tardío (575-900 d.C) y Clásico Temprano (250-575 d.C)

                • En el Preclásico Tardío-Terminal se construyeron gradas, un piso, un apisonado y rellenos constructivos.

                • Depósito cerámico con material del Preclásico Tardío (350-100 a.C) y Preclásico Tardío-Terminal (100 a.C-250 d.C).
                """,
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            // MARK: 4. Montículo C-II-5
            POILocation(
                id: "monticulo_5",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632555675181031,
                    longitude: -90.54807733211727
                ),
                name: "Montículo C-II-5",
                modelPath: "Assets/Models/poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -1.0,
                description: """
                Hallazgos:

                • En el Clásico Tardío se construyeron cinco pisos de barro.

                • Rellenos de barro y suelo.

                • En el Preclásico Tardío se construyó una plataforma de 2.2 m de altura.

                • Cerámica del Preclásico Tardío (350-100 a.C), Preclásico Tardío-Terminal (100 a.C-250 d.C), Clásico Temprano (250-575 d.C) y Clásico Tardío (575-900 d.C)
                """,
                constructionPeriod: "Preclásico Tardío - Clásico Tardío"
            ),

            // MARK: 5. Montículo C-II-7
            POILocation(
                id: "monticulo_7",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.632234919514932,
                    longitude: -90.54800651965228
                ),
                name: "Montículo C-II-7",
                modelPath: "Assets/Models/Monticulo7.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • El edificio talud-tablero que se esta visualizando data del Clásico Temprano (425-575 d.C).

                • Debajo de este edificio se hallaron dos pisos asociados a materiales cerámicos que fechan del Preclásico Tardío-Terminal (100 a.C- 250 d.C), Clásico Temprano (250-575 d.C) y Clásico Tardío (575-900 d.C).
                """,
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío"
            ),

            // MARK: 6. Montículo C-II-8
            POILocation(
                id: "monticulo_8",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.631888413377396,
                    longitude: -90.54808529662705
                ),
                name: "Montículo C-II-8",
                modelPath: "Assets/Models/poi.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -1.0,
                description: """
                Hallazgos:

                • Figurillas y depósito cerámico de uso doméstico, ambos hallazgos corresponden al periodo Clásico Tardío.

                • Fragmentos de un monumento Preclásico, quebrado en el pasado.

                • En el Preclásico Tardío-Terminal se construyó un canal.

                • Depósito cultural conformado por un fragmento de vasija e incensario, una punta de lanza de obsidiana, una lasca de pedernal y 26 huesos humanos de adulto, incluyendo dos mandíbulas, dientes y un fragmento de cráneo pulido. El hallazgo de restos humanos pudo estar relacionado con alguna actividad ritual. Los materiales del depósito corresponden a distintos periodos: Preclásico Tardío-Terminal (100 a.C-250 d.C), Clásico Temprano (250-575 d.C) y Clásico Tardío (575-900 d.C).
                """,
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío",
                images: ["c_ii_8"]
            ),

            // MARK: 7. Montículo C-II-12
            POILocation(
                id: "monticulo_12",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.631110755220972,
                    longitude: -90.54816619269748
                ),
                name: "Montículo C-II-12",
                modelPath: "Assets/Models/Monticulo12.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • Plataforma con escalones de barro del Preclásico Tardío-Terminal.

                • Depósito cultural del Preclásico Tardío-Terminal, conformado por vasijas finas y utilitarias, lascas de obsidiana, dos vasijas miniatura, huesos humanos y de animal y una piedra volcánica con huella de trabajo.

                • Figurillas femeninas que representan mujeres embarazadas y pigmento rojo y verde.
                """,
                historicalInfo: """
                Función:

                • Preclásico Tardío-Terminal (100 a.C-250 d.C): Plataforma residencial de élite, en la cual se realizaron rituales para la fertilidad.
                """,
                constructionPeriod: "Preclásico Tardío-Terminal",
                images: ["c_ii_12", "c_ii_12_2"]
            ),

            // MARK: 8. Estructura E (La Palangana)
            POILocation(
                id: "palangana",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630813964263574,
                    longitude: -90.54760512338584
                ),
                name: "Estructura E",
                modelPath: "Assets/Models/palangana.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                // Único POI con rotación propia: alinea la maqueta con la
                // topografía del recinto, igual que en el Android.
                baseYawDeg: 90.0,
                description: """
                Cuenta con varias etapas constructivas.

                Clásico Tardío (575-900 d.C): Etapas 5 y 4.

                Etapa 5:
                • Al sur del recinto se depositaron fragmentos de cerámica erosionada y esculturas de etapas constructivas anteriores.

                Etapa 4:
                • Es la etapa constructiva actualmente expuesta, conformada por un drenaje en el interior del recinto y una estructura de adobe que cubre el estilo talud-tablero. Al frente del recinto se construyó una plataforma del mismo material, la cual fue destruida durante las investigaciones realizadas a inicios del siglo pasado.
                """,
                historicalInfo: """
                Clásico Temprano (425-575 d.C): Etapas 3, 2 y 1.

                Etapa 3: Se constituye de tres subetapas constructivas.
                • Subetapa 3-c: Es la reconstrucción virtual que observamos ahora, en esta subetapa se modificó el atrio y se construyó nuevas gradas en la parte frontal del recinto, solo a través de estas se pudo acceder a la plataforma.
                • Subetapa 3-b: En el recinto se aplicó el estilo talud-tablero y se construyó una grada en el centro del lado sur. Además, se remodeló la escalinata de la plataforma, se incrementó la altura del atrio y se construyeron gradas en los lados este y oeste.
                • Subetapa 3-a: Se agregó una plataforma con estilo talud-tablero, que presentó en su parte superior agujeros de poste utilizados para sostener una superestructura de materiales perecederos. Asimismo, se construyó un atrio que conectó la plataforma con el recinto remodelado. Durante esta subetapa se hallaron dos tumbas dedicatorias que contenían individuos sentados, acompañados de ofrendas cerámicas. La Tumba 2 se localizó en el recinto, mientras que la Tumba 3 se construyó con piedras y se ubicó en la esquina noreste de la plataforma.

                Etapa 2: Se constituye de tres etapas constructivas.
                • Subetapa 2-c: En el interior del recinto se modificaron las gradas y se incorporó un talud. En la parte sur del exterior, se ampliaron las gradas de acceso y se construyeron dos adiciones rectangulares.
                • Subetapa 2-b: En el recinto se aumentó la altura y se construyeron gradas tanto en el interior como en el exterior.
                • Subetapa 2-a: Se construyó un recinto hundido al norte de la primera etapa constructiva.

                Etapa 1: Es la primera etapa constructiva
                • Pequeña pirámide con una base en forma de talud y paredes tipo tablero. Esta primera etapa se edificó sobre la Tumba 1, que contenía restos humanos, estelas lisas y una escultura tallada.
                """,
                constructionPeriod: "Clásico Temprano - Clásico Tardío",
                culturalSignificance: """
                • Función de etapa 3: Pudo ser utilizada como una residencia de élite o un edificio administrativo.
                • Función de etapa 2: Centro ritual o fue utilizado para alguna otra actividad pública.
                • Función de etapa 1: Altar dedicatorio.
                """,
                images: ["e", "etapa3", "etapa3a", "etapa2a", "etapa2b", "etapa2c", "etapa1"]
            ),

            // MARK: 9. Montículo C-II-14
            POILocation(
                id: "monticulo_14",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630593990926299,
                    longitude: -90.54696166473626
                ),
                name: "Montículo C-II-14",
                modelPath: "Assets/Models/Monticulo14.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • Durante el Clásico Tardío (575-900 d.C) se construyó la estructura de piedra que están visualizando. Esta presenta una base inclinada (talud) y escalinatas con alfardas ubicadas en el lado oeste de la estructura. A este mismo periodo corresponde el hallazgo de vasijas utilitarias e incensarios.

                • Debajo de la estructura de piedra se encuentran otras etapas constructivas del Clásico Temprano (250-575 d.C):
                  1. Plataforma con escalinata de barro, cuyo acceso se realizaba únicamente por el lado este.
                  2. Plataforma con dos escalinatas de piedrín, que permitían el acceso por los lados este y oeste.
                  3. Plataforma con remanentes de paredes de piedrín.

                • La etapa constructiva más antigua corresponde al Preclásico Tardío-Terminal (100 a. C-250 d.C), durante la cual se construyó pisos y gradas de acceso en el lado oeste de la estructura. A este mismo periodo corresponde el hallazgo de vasijas.
                """,
                historicalInfo: """
                Funciones:

                • Clásico Tardío (575-900 d.C): Plataforma residencial en la cual se realizaban actividades ceremoniales, como lo demuestra el hallazgo de vasijas de uso doméstico e incensarios.

                • Preclásico Tardío-Terminal (100 a.C-250 d.C): Plataforma residencial de élite.
                """,
                constructionPeriod: "Preclásico Tardío-Terminal - Clásico Tardío"
            ),

            // MARK: 10. Montículo C-II-13
            POILocation(
                id: "monticulo_13",
                coordinate: CLLocationCoordinate2D(
                    latitude: 14.630643799200827,
                    longitude: -90.5469887688274
                ),
                name: "Montículo C-II-13",
                modelPath: "Assets/Models/Monticulo13.obj",
                baseScale: 1.0,
                baseAltitudeMeters: -2.0,
                description: """
                Hallazgos:

                • Durante el Clásico Tardío (575-900 d.C) se construyó la plataforma de barro que están visualizando y se colocó el Monumento 224; tallado en sus cuatro lados. Las escenas representadas incluyen once círculos (1), dos personajes -uno arrodillado y otro de pie- (2), un animal -serpiente o pescado- (3) y una lengua bífida (4). Este monumento data del Preclásico y fue reutilizado porque Kaminaljuyú atravesaba un proceso de descentralización de poder, lo que impulsó un retorno a la ideología pasada. A este mismo periodo corresponde el hallazgo de vasijas sencillas e incensarios.

                • Durante el Clásico Temprano se construyeron doce apisonados y ocho pisos de barro. Además de tres escalinatas superpuestas.

                • Durante el Preclásico Tardío-Terminal se construyeron dos drenajes de piedra (1), y se depositaron huesos humanos y una vasija en forma de cuerpo humano esqueletizado (2).
                """,
                historicalInfo: """
                Función:

                • Clásico Tardío (575-900 d.C): En la plataforma se realizaron actividades rituales, como lo demuestra el hallazgo de incensarios quebrados y vasijas con restos de material quemado.
                """,
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
