//
//  VideoTranscripts.swift
//  ArTourKaminaljuyu
//

import Foundation

struct TranscriptCue {
    let text: String
    let startTime: Double  // segundos desde el inicio del video
    let endTime: Double    // segundos desde el inicio del video
}

enum VideoTranscripts {

    static let transcripts: [String: [TranscriptCue]] = [

        "Datos generales_final": [
            TranscriptCue(
                text: "Kaminaljuyú es un sitio que se ubica en el centro de las Tierras Altas Mayas y se estableció alrededor del Lago Miraflores.",
                startTime: 0.000,
                endTime: 7.400
            ),
            TranscriptCue(
                text: "Fue un centro de intercambio y comercio que controló las rutas de distribución de jade, obsidiana, sal, algodón, resinas y otros productos.",
                startTime: 8.500,
                endTime: 18.380
            )
        ],

        "Datos arqueológicos_final": [
            TranscriptCue(
                text: "Durante el periodo Clásico, 250 a 900 después de Cristo, estableció relaciones con el Altiplano",
                startTime: 0.000,
                endTime: 7.520
            ),
            TranscriptCue(
                text: "mexicano y las Tierras Bajas Mayas. La arquitectura del sitio fue principalmente de barro y destacó",
                startTime: 7.520,
                endTime: 14.580
            ),
            TranscriptCue(
                text: "por la presencia de templos, palacios, juegos de pelota y viviendas. En la época prehispánica,",
                startTime: 14.580,
                endTime: 22.280
            ),
            TranscriptCue(
                text: "tuvo una extensión de 5 kilómetros cuadrados y se conformó de más de 230 montículos,",
                startTime: 22.620,
                endTime: 28.480
            ),
            TranscriptCue(
                text: "la mayoría demolidos por la expansión urbana. En la actualidad se conservan 40 montículos,",
                startTime: 28.480,
                endTime: 35.400
            ),
            TranscriptCue(
                text: "nueve se resguardan en el Parque Arqueológico Kaminaljuyú y los restantes se encuentran",
                startTime: 35.960,
                endTime: 41.380
            ),
            TranscriptCue(
                text: "alrededor de viviendas, centros comerciales, escuelas, colonias, entre otros.",
                startTime: 41.380,
                endTime: 47.120
            )
        ],
        
        "Acrópolis CII 4_final": [
            TranscriptCue(
                text: "Acrópolis C II 4 Hallazgos y Función. La Acrópolis fue constantemente remodelada y representó el",
                startTime: 0.000,
                endTime: 7.520
            ),
            TranscriptCue(
                text: "sector palaciego del sitio. Los palacios se ubicaron en el núcleo de las ciudades y presentaron una",
                startTime: 7.520,
                endTime: 13.760
            ),
            TranscriptCue(
                text: "estructura interna sofisticada, lo que implicó diferentes usos y la existencia de espacios",
                startTime: 7.520,
                endTime: 19.580
            ),
            TranscriptCue(
                text: "privados. Clásico tardío, 575 a 900 d.C. Corresponde a la composición actual de la",
                startTime: 19.580,
                endTime: 28.720
            ),
            TranscriptCue(
                text: "Acrópolis, la cual fue utilizada como residencia para dignatarios importantes. Asimismo, se",
                startTime: 19.580,
                endTime: 35.520
            ),
            TranscriptCue(
                text: "construyeron juegos de pelota y drenajes, y se hallaron comales, cuencos y tazas de comer.",
                startTime: 35.20,
                endTime: 41.580
            ),
            TranscriptCue(
                text: "Durante este periodo varios edificios del Clásico Temprano, 425 a 575 d.C., fueron cubiertos con un",
                startTime: 42.620,
                endTime: 52.400
            ),
            TranscriptCue(
                text: "piso de barro y nuevas estructuras de piedra y barro. Mientras que otros edificios sufrieron",
                startTime: 52.400,
                endTime: 58.260
            ),
            TranscriptCue(
                text: "cambios en la fachada. Clásico Temprano, 425 a 575 d.C. Construcción de más de 20 estructuras",
                startTime: 58.260,
                endTime: 69.600
            ),
            TranscriptCue(
                text: "talud-tablero en la Acrópolis. Durante este periodo se realizaron actividades ceremoniales",
                startTime: 69.600,
                endTime: 75.660
            ),
            TranscriptCue(
                text: "y administrativas, evidenciadas por el hallazgo de incensarios y estructuras talud-tablero. El talud-tablero",
                startTime: 75.660,
                endTime: 83.700
            ),
            TranscriptCue(
                text: "es un estilo arquitectónico que consiste en una base inclinada que es el talud, y sobre este se",
                startTime: 83.700,
                endTime: 90.100
            ),
            TranscriptCue(
                text: "encuentra el tablero, el cual es un bloque rectangular con molduras. Esta técnica constructiva",
                startTime: 90.100,
                endTime: 96.360
            ),
            TranscriptCue(
                text: "es distintiva de Teotihuacán, México. La incorporación del estilo talud-tablero en",
                startTime: 96.360,
                endTime: 102.500
            ),
            TranscriptCue(
                text: "Kaminaljuyú fue una adaptación local, ya que se utilizaron recursos de la región como material de",
                startTime: 102.500,
                endTime: 108.960
            ),
            TranscriptCue(
                text: "origen volcánico y diferentes dimensiones. En Teotihuacán el tablero es tres veces más grande",
                startTime: 108.960,
                endTime: 115.240
            ),
            TranscriptCue(
                text: "que el talud, 3 a 1, mientras que en Kaminaljuyú el talud y tablero son del mismo tamaño, 1 a 1.",
                startTime: 115.240,
                endTime: 123.000
            )
        ],
        
        "Bienvenida": [
            TranscriptCue(
                text: "Hola, bienvenidos al Parque Arqueológico Kaminaljuyú, hoy seré su guía virtual.",
                startTime: 0.000,
                endTime: 4.280
            )
        ],
        
        "Despedida_final": [
            TranscriptCue(
                text: "Ha sido para mí un gusto ser tu guía el día de hoy. Gracias por visitar el Parque Arqueológico Kaminaljuyú. Nos vemos en la próxima.",
                startTime: 0.000,
                endTime: 6.840
            )
        ],
        
        "Estructura E_final": [
            TranscriptCue(
                text: "Estructura E, Clásico Tardío, 575 a 900 d.C.",
                startTime: 0.000,
                endTime: 5.400
            ),
            TranscriptCue(
                text: "Etapa 5. Al sur del recinto se depositó cerámica y esculturas de etapas constructivas anteriores.",
                startTime: 6.060,
                endTime: 13.080
            ),
            TranscriptCue(
                text: "Etapa 4. Es la etapa constructiva actualmente expuesta, conformada por un drenaje en el interior del recinto y una estructura de adobe que cubre el estilo talud-tablero.",
                startTime: 13.700,
                endTime: 24.900
            ),
            TranscriptCue(
                text: "Al frente del recinto se construyó una plataforma del mismo material, la cual fue destruida durante las investigaciones realizadas a inicios del siglo pasado.",
                startTime: 24.900,
                endTime: 35.480
            ),
            TranscriptCue(
                text: "Clásico Temprano, 425 a 575 d.C. Etapa 3. Funcionó como residencia de élite o edificio administrativo.",
                startTime: 36.140,
                endTime: 46.940
            ),
            TranscriptCue(
                text: "Subetapa 3-C. Es la construcción virtual que observamos ahora. En esta subetapa se modificó el atrio y se construyó nuevas gradas en la parte frontal del recinto.",
                startTime: 46.940,
                endTime: 59.240
            ),
            TranscriptCue(
                text: "Solo a través de esta se pudo acceder a la plataforma.",
                startTime: 59.880,
                endTime: 62.920
            ),
            TranscriptCue(
                text: "Subetapa 3-B. En el recinto se aplicó el estilo talud-tablero y se construyó una grada en el centro del lado sur.",
                startTime: 62.920,
                endTime: 71.840
            ),
            TranscriptCue(
                text: "Además, se remodeló la escalinata de la plataforma, se incrementó la altura del atrio y se construyeron gradas en los lados este y oeste.",
                startTime: 72.920,
                endTime: 81.860
            ),
            TranscriptCue(
                text: "Subetapa 3-A. Se agregó una plataforma con estilo talud-tablero que presentó en su parte superior agujeros de poste utilizados para sostener una superestructura de materiales perecederos.",
                startTime: 81.860,
                endTime: 95.640
            ),
            TranscriptCue(
                text: "Asimismo, se construyó un atrio que conectó la plataforma con el recinto remodelado.",
                startTime: 96.540,
                endTime: 101.960
            ),
            TranscriptCue(
                text: "Durante esta subetapa se hallaron dos tumbas dedicatorias que contenían individuos sentados, acompañados de ofrendas cerámicas.",
                startTime: 103.060,
                endTime: 111.020
            ),
            TranscriptCue(
                text: "La tumba 2 se localizó en el recinto, mientras que la tumba 3 se construyó con piedras y se ubicó en la esquina noreste de la plataforma.",
                startTime: 111.860,
                endTime: 119.440
            ),
            TranscriptCue(
                text: "Etapa 2. Funcionó como un centro ritual o fue reutilizado para alguna otra actividad pública.",
                startTime: 120.640,
                endTime: 127.400
            ),
            TranscriptCue(
                text: "Subetapa 2-C. En el interior del recinto se modificaron las gradas y se incorporó un talud.",
                startTime: 128.680,
                endTime: 134.800
            ),
            TranscriptCue(
                text: "En la parte sur del exterior se ampliaron las gradas de acceso y se construyeron dos adiciones rectangulares.",
                startTime: 134.980,
                endTime: 141.740
            ),
            TranscriptCue(
                text: "Subetapa 2-B. Aumentó de altura del recinto y se construyeron gradas en el interior y exterior.",
                startTime: 141.860,
                endTime: 148.920
            ),
            TranscriptCue(
                text: "Subetapa 2-A. Construcción de un recinto hundido al norte de la primera etapa constructiva.",
                startTime: 150.080,
                endTime: 155.980
            ),
            TranscriptCue(
                text: "Etapa 1. Funcionó como altar dedicatorio.",
                startTime: 156.820,
                endTime: 159.960
            ),
            TranscriptCue(
                text: "Pequeña pirámide con una base en forma de talud y paredes de tipo tablero.",
                startTime: 159.960,
                endTime: 165.520
            ),
            TranscriptCue(
                text: "Esta primera etapa se edificó sobre la tumba 1 que contenía restos humanos, estelas lisas y una escultura tallada.",
                startTime: 166.480,
                endTime: 175.520
            )
        ],
        
        "Indicación de proximidad_final": [
            TranscriptCue(
                text: "Te encuentras a pocos metros de un punto de interés, sigue avanzando.",
                startTime: 0.000,
                endTime: 3.840
            )
        ],
        
        "Indicación flecha_final": [
            TranscriptCue(
                text: "Ahora avanza conforme la flecha lo vaya indicando para llegar a un punto de interés.",
                startTime: 0.000,
                endTime: 4.480
            )
        ],
        
        "M CII 3_final": [
            TranscriptCue(
                text: "Montículo C II 3 Hallazgos, Clásico Tardío, 575 a 900 d.C.",
                startTime: 0.000,
                endTime: 7.060
            ),
            TranscriptCue(
                text: "Cerámica y construcción de dos pisos, un apisonado, rellenos constructivos y gradas.",
                startTime: 8.080,
                endTime: 13.780
            ),
            TranscriptCue(
                text: "Cerámica del Clásico Temprano, 250 a 575 d.C.",
                startTime: 14.960,
                endTime: 20.700
            ),
            TranscriptCue(
                text: "Preclásico Tardío Terminal, 100 a.C. a 250 d.C.",
                startTime: 21.880,
                endTime: 28.040
            ),
            TranscriptCue(
                text: "Depósito Cerámico y construcción de gradas, un piso, un apisonado y rellenos constructivos.",
                startTime: 28.040,
                endTime: 36.000
            )
        ],
        
        "M CII 5_final": [
            TranscriptCue(
                text: "Montículo C II 5 hallazgos. Clásico tardío, 575 a 900 d.C. Construcción de 5 pisos de barro,",
                startTime: 0.000,
                endTime: 9.780
            ),
            TranscriptCue(
                text: "rellenos de barro y suelo. Preclásico tardío, 350 a 100 a.C. Construcción de una plataforma",
                startTime: 10.380,
                endTime: 18.620
            ),
            TranscriptCue(
                text: "de 2,2 metros de altura. Cerámica del preclásico tardío, 350 a 100 a.C. Preclásico tardío",
                startTime: 18.620,
                endTime: 28.700
            ),
            TranscriptCue(
                text: "terminal, 100 a.C. a 250 d.C. Clásico temprano, 250 a 575 d.C. y clásico tardío, 575 a 900 d.C.",
                startTime: 28.700,
                endTime: 46.180
            )
        ],
        
        "M CII 6_final": [
            TranscriptCue(
                text: "Montículo C II 6 Hallazgos. Clásico tardío, 575 a 900 d.C.",
                startTime: 0.000,
                endTime: 6.980
            ),
            TranscriptCue(
                text: "Depósito cerámico y construcción de tres rellenos, un canal, un piso, un apisonado,",
                startTime: 7.860,
                endTime: 14.000
            ),
            TranscriptCue(
                text: "una superficie formada por piedras tipo laja, canto rodado y pómez.",
                startTime: 14.500,
                endTime: 19.280
            ),
            TranscriptCue(
                text: "Preclásico tardío terminal, 100 a.C. a 250 d.C.",
                startTime: 20.100,
                endTime: 25.840
            ),
            TranscriptCue(
                text: "Depósito cerámico conformado por una vasija completa que pudo funcionar como ofrenda.",
                startTime: 25.840,
                endTime: 32.040
            )
        ],
        
        "M CII 7_final": [
            TranscriptCue(
                text: "Montículo C II 7 Hallazgos",
                startTime: 0.000,
                endTime: 2.240
            ),
            TranscriptCue(
                text: "El edificio Talud Tablero que se está visualizando data del Clásico Temprano, 425 a 575 d.C.",
                startTime: 2.240,
                endTime: 11.660
            ),
            TranscriptCue(
                text: "Debajo del edificio se halló dos pisos y cerámica que datan del Preclásico Tardío Terminal, 100 a.C. a 250 d.C.,",
                startTime: 12.380,
                endTime: 22.400
            ),
            TranscriptCue(
                text: "Clásico Temprano, 250 a 575 d.C. y Clásico Tardío, 575 a 900 d.C.",
                startTime: 22.400,
                endTime: 32.860
            )
        ],
        
        "M CII 8_final": [
            TranscriptCue(
                text: "Montículo C II 8 Hallazgos",
                startTime: 0.000,
                endTime: 2.260
            ),
            TranscriptCue(
                text: "Clásico Tardío, 575 a 900 d.C.",
                startTime: 2.260,
                endTime: 7.100
            ),
            TranscriptCue(
                text: "Figurillas y depósito cerámico de uso doméstico",
                startTime: 7.920,
                endTime: 11.200
            ),
            TranscriptCue(
                text: "Preclásico Tardío Terminal, 350 a.C. a 250 d.C.",
                startTime: 11.200,
                endTime: 19.760
            ),
            TranscriptCue(
                text: "Construcción de un canal y fragmentos de un monumento",
                startTime: 20.800,
                endTime: 24.000
            ),
            TranscriptCue(
                text: "Depósito cultural conformado por un fragmento de vasija e incensario",
                startTime: 24.760,
                endTime: 29.000
            ),
            TranscriptCue(
                text: "y una punta de lanza de obsidiana",
                startTime: 29.000,
                endTime: 31.720
            ),
            TranscriptCue(
                text: "También se hallaron dos mandíbulas, dientes y un fragmento de cráneo",
                startTime: 31.720,
                endTime: 37.100
            ),
            TranscriptCue(
                text: "los cuales pudieron estar relacionados con alguna actividad ritual",
                startTime: 37.100,
                endTime: 41.020
            ),
            TranscriptCue(
                text: "Los materiales del depósito datan desde el Preclásico Tardío Terminal",
                startTime: 41.020,
                endTime: 46.000
            ),
            TranscriptCue(
                text: "100 a.C. a 250 d.C.",
                startTime: 46.520,
                endTime: 50.460
            ),
            TranscriptCue(
                text: "hasta el Clásico Tardío, 575 a 900 d.C.",
                startTime: 50.900,
                endTime: 56.480
            )
        ],
        
        "M CII 12_final": [
            TranscriptCue(
                text: "Montículo C II 12 Hallazgos",
                startTime: 0.000,
                endTime: 2.220
            ),
            TranscriptCue(
                text: "Preclásico Tardío Terminal",
                startTime: 2.220,
                endTime: 5.060
            ),
            TranscriptCue(
                text: "100 a.C. a. 250 d.C.",
                startTime: 5.060,
                endTime: 8.980
            ),
            TranscriptCue(
                text: "Plataforma con escalones de barro",
                startTime: 9.800,
                endTime: 11.960
            ),
            TranscriptCue(
                text: "Figurillas de mujeres embarazadas",
                startTime: 11.960,
                endTime: 14.420
            ),
            TranscriptCue(
                text: "Pigmentos",
                startTime: 14.420,
                endTime: 15.800
            ),
            TranscriptCue(
                text: "Y un depósito conformado por vasijas finas y utilitarias,",
                startTime: 15.800,
                endTime: 19.760
            ),
            TranscriptCue(
                text: "lascas de obsidiana,",
                startTime: 19.760,
                endTime: 21.280
            ),
            TranscriptCue(
                text: "una piedra con huella de trabajo,",
                startTime: 21.280,
                endTime: 23.460
            ),
            TranscriptCue(
                text: "sos vasijas miniatura,",
                startTime: 23.460,
                endTime: 25.400
            ),
            TranscriptCue(
                text: "huesos humanos y de animal",
                startTime: 25.400,
                endTime: 27.640
            ),
            TranscriptCue(
                text: "La plataforma que está visualizando fue una residencia de élite",
                startTime: 27.640,
                endTime: 32.340
            ),
            TranscriptCue(
                text: "En la cual se realizaron rituales para la fertilidad",
                startTime: 32.340,
                endTime: 35.360
            )
        ],
        
        "M CII 13_final": [
            TranscriptCue(
                text: "Montículo C II 13. Hallazgos y funciones. Clásico tardío, 575 a 900 d.C. Construcción de plataforma",
                startTime: 0.000,
                endTime: 10.080
            ),
            TranscriptCue(
                text: "de barro que están visualizando, en la cual se realizaron actividades rituales debido al",
                startTime: 10.080,
                endTime: 15.720
            ),
            TranscriptCue(
                text: "hallazgo de incensarios quebrados y vasijas con restos de material quemado. También se colocó",
                startTime: 15.720,
                endTime: 21.560
            ),
            TranscriptCue(
                text: "el monumento 224, tallado en sus cuatro lados. Las escenas representadas incluyen 11 círculos,",
                startTime: 21.560,
                endTime: 29.100
            ),
            TranscriptCue(
                text: "1. Un individuo arrodillado y otro de pie. 2. Serpiente barra pescado. 3. Y una lengua bífida.",
                startTime: 29.100,
                endTime: 37.340
            ),
            TranscriptCue(
                text: "4. El monumento data del Preclásico y se reutilizó durante el Clásico tardío porque Kaminaljuyú",
                startTime: 37.340,
                endTime: 44.400
            ),
            TranscriptCue(
                text: "experimentó una descentralización de poder, lo que impulsó un retorno a la ideología pasada.",
                startTime: 44.400,
                endTime: 50.060
            ),
            TranscriptCue(
                text: "Clásico temprano, 250 a 575 d.C. Construcción de tres escalinatas",
                startTime: 51.080,
                endTime: 58.660
            ),
            TranscriptCue(
                text: "superpuestas, 12 apisonados y ocho pisos de barro. Preclásico tardío terminal, 100 a.C. a 250 d.C.",
                startTime: 58.660,
                endTime: 68.900
            ),
            TranscriptCue(
                text: "Construcción de dos drenajes de piedra, deposición de huesos humanos y una vasija en forma de cuerpo",
                startTime: 69.940,
                endTime: 76.060
            ),
            TranscriptCue(
                text: "humano esqueletizado.",
                startTime: 76.060,
                endTime: 77.200
            )
        ],
        
        "M CII 14_final": [
            TranscriptCue(
                text: "Montículo C II 14 Hallazgos y Funciones",
                startTime: 0.000,
                endTime: 3.040
            ),
            TranscriptCue(
                text: "Clásico Tardío, 575 a 900 d.C.",
                startTime: 3.040,
                endTime: 7.620
            ),
            TranscriptCue(
                text: "Hallazgo de vasijas utilitarias e incensarios",
                startTime: 8.580,
                endTime: 11.340
            ),
            TranscriptCue(
                text: "y construcción de estructura de piedra que consiste en una base inclinada,",
                startTime: 11.340,
                endTime: 15.700
            ),
            TranscriptCue(
                text: "talud y escalinatas con alfardas.",
                startTime: 16.060,
                endTime: 18.360
            ),
            TranscriptCue(
                text: "En la plataforma se realizaron actividades ceremoniales.",
                startTime: 18.880,
                endTime: 21.780
            ),
            TranscriptCue(
                text: "Clásico Temprano, 250 a 575 d.C.",
                startTime: 22.360,
                endTime: 27.160
            ),
            TranscriptCue(
                text: "Hallazgo de cerámica doméstica.",
                startTime: 27.820,
                endTime: 29.940
            ),
            TranscriptCue(
                text: "1. Plataforma con escalinata de barro con acceso único del lado oeste.",
                startTime: 30.420,
                endTime: 34.720
            ),
            TranscriptCue(
                text: "2. Plataforma con escalinatas de piedrín del lado oeste y oeste.",
                startTime: 35.200,
                endTime: 39.080
            ),
            TranscriptCue(
                text: "3. Plataforma con remanentes de paredes de piedrín.",
                startTime: 39.580,
                endTime: 42.840
            ),
            TranscriptCue(
                text: "Preclásico Tardío Terminal, 100 a.C. a 250 d.C.",
                startTime: 43.320,
                endTime: 48.760
            ),
            TranscriptCue(
                text: "Es la etapa constructiva más antigua,",
                startTime: 49.260,
                endTime: 51.960
            ),
            TranscriptCue(
                text: "en la cual se construyeron gradas de acceso en el lado oeste de la estructura",
                startTime: 51.960,
                endTime: 56.440
            ),
            TranscriptCue(
                text: "y se hallaron vasijas.",
                startTime: 56.440,
                endTime: 58.140
            ),
            TranscriptCue(
                text: "La estructura funcionó como una residencia de élite.",
                startTime: 58.140,
                endTime: 61.800
            )
        ],
        
        "Punto de interés_final": [
            TranscriptCue(
                text: "¿Has llegado a un punto de interés?",
                startTime: 0.000,
                endTime: 1.700
            ),
            TranscriptCue(
                text: "Levanta tu teléfono para poder visualizar el punto de interés.",
                startTime: 1.980,
                endTime: 5.340
            )
        ],
        
        "AcropolisCII4_en_final": [
            TranscriptCue(
                text: "Acropolis C II 4",
                startTime: 0.000,
                endTime: 2.360
            ),
            TranscriptCue(
                text: "Findings and Function",
                startTime: 2.360,
                endTime: 4.160
            ),
            TranscriptCue(
                text: "The Acropolis was constantly remodeled",
                startTime: 4.160,
                endTime: 7.060
            ),
            TranscriptCue(
                text: "and represented the palatial sector of the site.",
                startTime: 7.060,
                endTime: 9.440
            ),
            TranscriptCue(
                text: "The palaces were located in the heart of the cities",
                startTime: 10.300,
                endTime: 12.400
            ),
            TranscriptCue(
                text: "and exhibited a sophisticated internal structure,",
                startTime: 12.400,
                endTime: 14.860
            ),
            TranscriptCue(
                text: "implying different uses and existence of private spaces.",
                startTime: 15.240,
                endTime: 17.780
            ),
            TranscriptCue(
                text: "Late Classic 575-900 A.D",
                startTime: 18.640,
                endTime: 21.720
            ),
            TranscriptCue(
                text: "This corresponds to the current composition of the Acropolis,",
                startTime: 21.720,
                endTime: 25.040
            ),
            TranscriptCue(
                text: "which was used as a residence for important dignitaries.",
                startTime: 25.040,
                endTime: 27.860
            ),
            TranscriptCue(
                text: "Ball courts and drainage systems were also built,",
                startTime: 27.860,
                endTime: 30.640
            ),
            TranscriptCue(
                text: "and kamals, bowls, and eating cups were found.",
                startTime: 31.400,
                endTime: 33.520
            ),
            TranscriptCue(
                text: "During this period, several Early Classic, 425-575 A.D. buildings",
                startTime: 34.320,
                endTime: 39.860
            ),
            TranscriptCue(
                text: "were covered with mud floors and new stone and mud structures.",
                startTime: 39.860,
                endTime: 42.880
            ),
            TranscriptCue(
                text: "Other buildings underwent change to their facades.",
                startTime: 44.080,
                endTime: 46.400
            ),
            TranscriptCue(
                text: "Early Classic, 425-575 A.D.",
                startTime: 47.380,
                endTime: 50.960
            ),
            TranscriptCue(
                text: "Construction of more than 20 talud tablero structures on the Acropolis",
                startTime: 50.960,
                endTime: 54.860
            ),
            TranscriptCue(
                text: "During this period, ceremonial and administrative activities took place,",
                startTime: 54.860,
                endTime: 59.200
            ),
            TranscriptCue(
                text: "as evidenced by the discovery of incense burners",
                startTime: 59.540,
                endTime: 61.460
            ),
            TranscriptCue(
                text: "and talud tablero structures.",
                startTime: 61.460,
                endTime: 62.700
            ),
            TranscriptCue(
                text: "The talud tablero is an architectural style",
                startTime: 63.500,
                endTime: 66.040
            ),
            TranscriptCue(
                text: "consisting of a sloping base,",
                startTime: 66.040,
                endTime: 67.540
            ),
            TranscriptCue(
                text: "the talud, upon which rests the tablero,",
                startTime: 67.920,
                endTime: 70.040
            ),
            TranscriptCue(
                text: "a rectangular block with moldings.",
                startTime: 70.300,
                endTime: 71.640
            ),
            TranscriptCue(
                text: "This construction technique is distinctive of Teotihuacan, Mexico.",
                startTime: 72.160,
                endTime: 74.960
            ),
            TranscriptCue(
                text: "The incorporation of the talud tablero style in Kaminaljuyu",
                startTime: 75.700,
                endTime: 78.420
            ),
            TranscriptCue(
                text: "was local adaptation,",
                startTime: 78.420,
                endTime: 79.620
            ),
            TranscriptCue(
                text: "utilizing regional resources such as volcanic material",
                startTime: 80.140,
                endTime: 82.480
            ),
            TranscriptCue(
                text: "in varying dimensions.",
                startTime: 82.480,
                endTime: 83.520
            ),
            TranscriptCue(
                text: "In Teotihuacan, the tablero is three times larger than the talud,",
                startTime: 84.360,
                endTime: 87.420
            ),
            TranscriptCue(
                text: "three to one,",
                startTime: 87.720,
                endTime: 88.280
            ),
            TranscriptCue(
                text: "while in Kaminaljuyu,",
                startTime: 88.740,
                endTime: 89.620
            ),
            TranscriptCue(
                text: "the talud and tablero are the same size,",
                startTime: 90.040,
                endTime: 91.840
            ),
            TranscriptCue(
                text: "one to one.",
                startTime: 92.200,
                endTime: 92.720
            )
        ],
        
        "Archaeologicaldata_final": [
            TranscriptCue(
                text: "During the Classic Period, 250 to 900 A.D., it established relations with Mexican highlands and the Maya lowlands.",
                startTime: 0.000,
                endTime: 6.900
            ),
            TranscriptCue(
                text: "The site's architecture was primarily made of mud and was notable for the presence of temples, palaces, ball courts, and houses.",
                startTime: 7.640,
                endTime: 14.420
            ),
            TranscriptCue(
                text: "In pre-Hispanic times, Kaminaljuyu covered an area of 5 square kilometers and consisted of more than 230 mounds, most of which were demolished due to urban expansion.",
                startTime: 15.220,
                endTime: 24.280
            ),
            TranscriptCue(
                text: "Currently, 40 mounds are preserved, 9 are protected within the Parque Arqueologico Kaminaljuyu, and rest of the mounds are located around housed, malls, schools, neighborhoods, and other places.",
                startTime: 24.280,
                endTime: 35.340
            )
        ],
        
        "Arrowindication_final": [
            TranscriptCue(
                text: "Now move forward, following the arrow to reach a point of interest.",
                startTime: 0.000,
                endTime: 3.000
            )
        ],
        
        "Goodbye_final": [
            TranscriptCue(
                text: "It has been a pleasure to be your guide today.",
                startTime: 0.000,
                endTime: 1.800
            ),
            TranscriptCue(
                text: "Thank you for visiting Kaminaljuyu.",
                startTime: 2.320,
                endTime: 3.660
            ),
            TranscriptCue(
                text: "See you next time.",
                startTime: 3.960,
                endTime: 4.740
            )
        ],
        
        "Importantdata_final": [
            TranscriptCue(
                text: "Kaminaljuyu, this site is located in the heart of the Maya Highlands and was established around Lake Miraflores.",
                startTime: 0.000,
                endTime: 5.820
            ),
            TranscriptCue(
                text: "It was a center of exchange and trade that controlled the distribution routes for jade, obsidian, salt, cotton, resins, and other products.",
                startTime: 5.820,
                endTime: 14.560
            )
        ],
        
        "MCII3_en_final": [
            TranscriptCue(
                text: "Mount C II 3. Findings. Late Classic, 575 to 900 A.D. Ceramic and construction of two floors,",
                startTime: 0.000,
                endTime: 8.820
            ),
            TranscriptCue(
                text: "a compacted layer, construction fills, and steps. Early Classic, 250 to 575 A.D. Ceramics",
                startTime: 8.820,
                endTime: 17.560
            ),
            TranscriptCue(
                text: "Late Terminal preclassic, 100 BC to 250 A.D. Ceramic deposit and construction of steps,",
                startTime: 18.160,
                endTime: 24.500
            ),
            TranscriptCue(
                text: "a floor, a compacted layer, and construction fills.",
                startTime: 24.960,
                endTime: 27.600
            )
        ],
        
        "MCII5_en_final": [
            TranscriptCue(
                text: "Mound C II 5 findings.",
                startTime: 0.000,
                endTime: 1.860
            ),
            TranscriptCue(
                text: "Late Classic, 575 to 900 A.D.",
                startTime: 2.720,
                endTime: 6.080
            ),
            TranscriptCue(
                text: "Construction of five mud floors, mud and soil fill.",
                startTime: 7.180,
                endTime: 10.360
            ),
            TranscriptCue(
                text: "Late prelassic, 350 to 100 BC.",
                startTime: 11.400,
                endTime: 14.740
            ),
            TranscriptCue(
                text: "Construction of a 2.2 meter high platform.",
                startTime: 15.460,
                endTime: 17.580
            ),
            TranscriptCue(
                text: "Pottery from Late preclassic, 350 to 100 B.C.",
                startTime: 18.600,
                endTime: 22.120
            ),
            TranscriptCue(
                text: "Late Terminal preclassic, 100 B.C. to 250 A.D.",
                startTime: 22.320,
                endTime: 26.680
            ),
            TranscriptCue(
                text: "Early Classic, 250 to 575 A.D.",
                startTime: 26.680,
                endTime: 31.360
            ),
            TranscriptCue(
                text: "And Late Classic, 575 to 900 A.D.",
                startTime: 32.320,
                endTime: 35.520
            )
        ],
        
        "MCII6_en_final": [
            TranscriptCue(
                text: "Mound C II 6 findings, late classic, 575 to 900 A.D., ceramic deposit and construction of three fills, a channel, a floor, a compacted layer, and a surface made of flagstones, river pebbles, and pumice.",
                startTime: 0.000,
                endTime: 16.020
            ),
            TranscriptCue(
                text: "Later terminal preclassic, on 100 BC to 250 A.D., ceramic deposit consisting of a complete vessel that may have served as an offering.",
                startTime: 17.280,
                endTime: 26.120
            )
        ],
        
        "MCII7_en_final": [
            TranscriptCue(
                text: "Mound C II 7 Findings",
                startTime: 0.000,
                endTime: 2.080
            ),
            TranscriptCue(
                text: "The talud tablero building, currently visible,",
                startTime: 2.080,
                endTime: 4.820
            ),
            TranscriptCue(
                text: "dates from the Early Classic, 425 to 575 A.D.",
                startTime: 5.400,
                endTime: 10.200
            ),
            TranscriptCue(
                text: "Beneath the building were found two floors and ceramics,",
                startTime: 10.940,
                endTime: 13.740
            ),
            TranscriptCue(
                text: "dating from the Late Terminal preclassic, 100 B.C. to 250 A.D.,",
                startTime: 14.200,
                endTime: 18.960
            ),
            TranscriptCue(
                text: "Early Classic, 250 to 575 A.D.,",
                startTime: 18.960,
                endTime: 23.060
            ),
            TranscriptCue(
                text: "and Late Classic, 575 to 900 A.D.",
                startTime: 23.060,
                endTime: 16.640
            )
        ],
        
        "MCII8_en_final": [
            TranscriptCue(
                text: "Mount C II 8 Findings, Late Classic, 575-900 A.D., figurines and ceramic deposit for domestic use,",
                startTime: 0.000,
                endTime: 9.120
            ),
            TranscriptCue(
                text: "Late Terminal preclassic, 100 BC-250 A.D., construction of a canal and fragments of a monument,",
                startTime: 9.940,
                endTime: 17.440
            ),
            TranscriptCue(
                text: "cultural deposit, consisting of a vessel fragment, an incense burner, and an obsidian spear point.",
                startTime: 17.700,
                endTime: 22.880
            ),
            TranscriptCue(
                text: "two mandibles, teeth, and a skull fragment were also found, which may have been related to some",
                startTime: 23.580,
                endTime: 28.380
            ),
            TranscriptCue(
                text: "ritual activity. The deposit materials date from Late Terminal preclassic, 100 BC to 250 A.D.,",
                startTime: 28.380,
                endTime: 34.620
            ),
            TranscriptCue(
                text: "to the Late Classic, 575 to 900 A.D..",
                startTime: 35.120,
                endTime: 38.540
            )
        ],
        
        "MCII12_en_final": [
            TranscriptCue(
                text: "Mound C II 12, late terminal preclassic, 100 B.C. to 250 A.D.,",
                startTime: 0.000,
                endTime: 6.200
            ),
            TranscriptCue(
                text: "platform with mud steps, figurines of pregnant women, pigments,",
                startTime: 6.200,
                endTime: 9.940
            ),
            TranscriptCue(
                text: "and a deposit consisting of fine and utilitarian vessels,",
                startTime: 10.320,
                endTime: 12.800
            ),
            TranscriptCue(
                text: "obsidian flakes, a stone with a tool mark,",
                startTime: 13.380,
                endTime: 15.740
            ),
            TranscriptCue(
                text: "two miniature vessels, and human and animal bones.",
                startTime: 16.260,
                endTime: 18.620
            ),
            TranscriptCue(
                text: "The platform you are viewing was an elite residence",
                startTime: 19.220,
                endTime: 21.880
            ),
            TranscriptCue(
                text: "where fertility rituals were performed.",
                startTime: 21.880,
                endTime: 23.520
            )
        ],
        
        "MCII13_en_final": [
            TranscriptCue(
                text: "Mound C II 3, Findings and Functions, Late Classic, 575-900 A.D., Construction of the",
                startTime: 0.000,
                endTime: 9.060
            ),
            TranscriptCue(
                text: "mud platform you are seeing, on which ritual activities were performed, as evidenced by",
                startTime: 9.060,
                endTime: 13.580
            ),
            TranscriptCue(
                text: "the discover of broken incense burners and vessels with traces of burnt material.",
                startTime: 13.580,
                endTime: 17.240
            ),
            TranscriptCue(
                text: "Monument 224 was also placed there, carved on all four sides.",
                startTime: 18.060,
                endTime: 21.940
            ),
            TranscriptCue(
                text: "The scenes represented include 11 circles, 1, a kneeling individual and a standing individual,",
                startTime: 22.680,
                endTime: 27.720
            ),
            TranscriptCue(
                text: "2, a serpent-slash-fish, 3, and a forked tongue, 4.",
                startTime: 27.720,
                endTime: 31.960
            ),
            TranscriptCue(
                text: "The monument dates from the preclassic period and was reused during the late classic period",
                startTime: 33.180,
                endTime: 37.280
            ),
            TranscriptCue(
                text: "because Kaminaljuyu experienced a decentralization of power, which impulse a return to past ideality.",
                startTime: 37.280,
                endTime: 42.920
            ),
            TranscriptCue(
                text: "Early Classic, 250-575 A.D., Construction of three superimposed staircases, 12 compacted earth",
                startTime: 44.120,
                endTime: 51.620
            ),
            TranscriptCue(
                text: "layers, and eight mud floors.",
                startTime: 51.620,
                endTime: 53.140
            ),
            TranscriptCue(
                text: "Late Terminal Classic, 100 B.C. to 250 A.D., Construction of two stone drains, deposition",
                startTime: 53.140,
                endTime: 60.860
            ),
            TranscriptCue(
                text: "of human bones, and a vessel in the shape of a skeletonized human body.",
                startTime: 60.860,
                endTime: 64.260
            )
        ],
        
        "MCII14_en_final": [
            TranscriptCue(
                text: "Mound C II 4, Findings and Functions, Late Classic, 575-900 A.D., discover of utilitarian",
                startTime: 0.000,
                endTime: 8.640
            ),
            TranscriptCue(
                text: "vessels and incense burners, and construction of a stone structure, consisting of a sloping",
                startTime: 8.640,
                endTime: 13.040
            ),
            TranscriptCue(
                text: "base, talud, and staircases with balustrades.",
                startTime: 13.040,
                endTime: 16.060
            ),
            TranscriptCue(
                text: "Ceremonial Activities took place on the platform.",
                startTime: 16.820,
                endTime: 18.860
            ),
            TranscriptCue(
                text: "Early Classic, 250-575 A.D., discovery of domestic pottery and three construction phases,",
                startTime: 20.280,
                endTime: 27.880
            ),
            TranscriptCue(
                text: "1. Platform with a mud staircase with a single access point on the East side.",
                startTime: 27.880,
                endTime: 34.260
            ),
            TranscriptCue(
                text: "2. Platform with piedrín staircase on the East and West sides.",
                startTime: 34.260,
                endTime: 39.600
            ),
            TranscriptCue(
                text: "3. Platform with remnants of piedrín walls.",
                startTime: 39.600,
                endTime: 44.200
            ),
            TranscriptCue(
                text: "Late Terminal preclassic, 100 BC to 250 A.D., this is the oldest construction phase in which",
                startTime: 44.200,
                endTime: 51.700
            ),
            TranscriptCue(
                text: "access steps were built on the west side of the structure and vessels were found.",
                startTime: 51.700,
                endTime: 55.380
            ),
            TranscriptCue(
                text: "The structure functioned as an elite residence.",
                startTime: 55.380,
                endTime: 58.200
            )
        ],
        
        "Pointofinterest_final": [
            TranscriptCue(
                text: "You have reached a point of interest? Raise your phone to view the point of interest.",
                startTime: 0.000,
                endTime: 4.000
            ),
        ],
        
        "Proximityindication_final": [
            TranscriptCue(
                text: "You are a few meters away from a point of interest. Keep moving forward.",
                startTime: 0.000,
                endTime: 3.320
            ),
        ],
        
        "StructureE_final": [
            TranscriptCue(
                text: "Structure E, Late Classic, 575 to 900 A.D.",
                startTime: 0.000,
                endTime: 4.720
            ),
            TranscriptCue(
                text: "Stage 5, ceramics and sculptures",
                startTime: 5.660,
                endTime: 7.820
            ),
            TranscriptCue(
                text: "from earlier construction stages",
                startTime: 7.820,
                endTime: 9.340
            ),
            TranscriptCue(
                text: "were deposited to the south of the enclosure.",
                startTime: 9.340,
                endTime: 11.600
            ),
            TranscriptCue(
                text: "Stage 4, this is the currently exposed construction stage",
                startTime: 12.520,
                endTime: 15.680
            ),
            TranscriptCue(
                text: "consisting of a drainage system inside the enclosure",
                startTime: 15.680,
                endTime: 18.140
            ),
            TranscriptCue(
                text: "and an adobe structure covering the talud tablero style.",
                startTime: 18.140,
                endTime: 21.380
            ),
            TranscriptCue(
                text: "A platform of the same material",
                startTime: 22.220,
                endTime: 23.440
            ),
            TranscriptCue(
                text: "was built in front of the enclosure,",
                startTime: 23.440,
                endTime: 25.020
            ),
            TranscriptCue(
                text: "which was destroyed during investigations carried out",
                startTime: 25.500,
                endTime: 27.640
            ),
            TranscriptCue(
                text: "at the beginning of the last century.",
                startTime: 27.640,
                endTime: 29.140
            ),
            TranscriptCue(
                text: "Early Classic, 250 to 575 A.D.",
                startTime: 30.000,
                endTime: 33.780
            ),
            TranscriptCue(
                text: "Stage 3, it functioned as an elite residence",
                startTime: 34.680,
                endTime: 37.260
            ),
            TranscriptCue(
                text: "or administrative building.",
                startTime: 37.260,
                endTime: 38.860
            ),
            TranscriptCue(
                text: "Substage 3, C, this is the virtual construction we observe now.",
                startTime: 40.260,
                endTime: 44.280
            ),
            TranscriptCue(
                text: "In this substage, the atrium was modified",
                startTime: 45.000,
                endTime: 46.980
            ),
            TranscriptCue(
                text: "and new steps were built at the front of the enclosure.",
                startTime: 46.980,
                endTime: 49.460
            ),
            TranscriptCue(
                text: "These were the only way to access the platform.",
                startTime: 50.000,
                endTime: 51.920
            ),
            TranscriptCue(
                text: "Substage 3, B, the talud tablero was applied to the enclosure",
                startTime: 53.260,
                endTime: 57.360
            ),
            TranscriptCue(
                text: "and a stepped platform was built in the center of the south side.",
                startTime: 57.360,
                endTime: 60.620
            ),
            TranscriptCue(
                text: "Additionally, the platform stairway was remodeled,",
                startTime: 61.860,
                endTime: 64.180
            ),
            TranscriptCue(
                text: "the height of the atrium was increased,",
                startTime: 64.620,
                endTime: 65.960
            ),
            TranscriptCue(
                text: "and steps were constructed on the east and west sides.",
                startTime: 66.480,
                endTime: 68.920
            ),
            TranscriptCue(
                text: "Substage 3A, a talud tablero style platform was added,",
                startTime: 69.580,
                endTime: 72.740
            ),
            TranscriptCue(
                text: "featuring post holes at its top",
                startTime: 63.140,
                endTime: 74.460
            ),
            TranscriptCue(
                text: "used to support a superstructure of perishable materials.",
                startTime: 74.460,
                endTime: 77.000
            ),
            TranscriptCue(
                text: "An atrium was also built, connecting the platform to the remodeled enclosure.",
                startTime: 77.000,
                endTime: 81.240
            ),
            TranscriptCue(
                text: "During this substage, two dedicatory tombs were found",
                startTime: 82.000,
                endTime: 84.540
            ),
            TranscriptCue(
                text: "containing seated individuals, accompanied by ceramic offerings.",
                startTime: 84.540,
                endTime: 87.560
            ),
            TranscriptCue(
                text: "Tomb 2 was located within the enclosure,",
                startTime: 88.560,
                endTime: 90.200
            ),
            TranscriptCue(
                text: "while Tomb 3 was constructed of stone",
                startTime: 90.700,
                endTime: 92.780
            ),
            TranscriptCue(
                text: "and located in the northeast corner of the platform.",
                startTime: 92.780,
                endTime: 95.140
            ),
            TranscriptCue(
                text: "Stage 2, it functioned as a ritual center",
                startTime: 95.140,
                endTime: 98.680
            ),
            TranscriptCue(
                text: "or was reused for some other public activity.",
                startTime: 98.680,
                endTime: 101.020
            ),
            TranscriptCue(
                text: "Substage 2, C, inside the enclosure,",
                startTime: 102.380,
                endTime: 105.280
            ),
            TranscriptCue(
                text: "the steps were modified and a talud was added.",
                startTime: 105.700,
                endTime: 107.660
            ),
            TranscriptCue(
                text: "On the southern exterior, the access steps were expanded",
                startTime: 108.800,
                endTime: 111.340
            ),
            TranscriptCue(
                text: "and two rectangular additions were constructed.",
                startTime: 111.340,
                endTime: 113.460
            ),
            TranscriptCue(
                text: "Substage 2, B, the height of the enclosure was increased",
                startTime: 114.560,
                endTime: 118.060
            ),
            TranscriptCue(
                text: "and steps were built both inside and outside.",
                startTime: 118.060,
                endTime: 120.860
            ),
            TranscriptCue(
                text: "Substage 2A, construction of a sunken enclosure",
                startTime: 120.860,
                endTime: 125.400
            ),
            TranscriptCue(
                text: "to the north of the first construction stage.",
                startTime: 125.400,
                endTime: 127.260
            ),
            TranscriptCue(
                text: "Stage 1, functioned as a dedicatory altar.",
                startTime: 128.120,
                endTime: 130.600
            ),
            TranscriptCue(
                text: "Small pyramid with a sloping base and tablero, like walls.",
                startTime: 131.760,
                endTime: 135.440
            ),
            TranscriptCue(
                text: "This is the first stage was built over Tomb 1,",
                startTime: 136.620,
                endTime: 138.920
            ),
            TranscriptCue(
                text: "which contained human remains, plain stele,",
                startTime: 139.280,
                endTime: 141.400
            ),
            TranscriptCue(
                text: "and a carved sculpture.",
                startTime: 141.760,
                endTime: 142.500
            )
        ],
        
        "Welcome_final": [
            TranscriptCue(
                text: "Hello, welcome to Kaminaljuyu. Today I will be your virtual guide.",
                startTime: 0.000,
                endTime: 3.760
            )
        ]
    ]

    // Mapeo: nombre del video en español → nombre del video en inglés.
        // Si un video no está acá, se usa el mismo nombre para ambos idiomas.
    private static let spanishToEnglishNames: [String: String] = [
        "Datos generales_final":          "Importantdata_final",
        "Datos arqueológicos_final":      "Archaeologicaldata_final",
        "Acrópolis CII 4_final":          "AcropolisCII4_en_final",
        "Despedida_final":                "Goodbye_final",
        "Estructura E_final":             "StructureE_final",
        "Indicación de proximidad_final": "Proximityindication_final",
        "Indicación flecha_final":        "Arrowindication_final",
        "M CII 3_final":                  "MCII3_en_final",
        "M CII 5_final":                  "MCII5_en_final",
        "M CII 6_final":                  "MCII6_en_final",
        "M CII 7_final":                  "MCII7_en_final",
        "M CII 8_final":                  "MCII8_en_final",
        "M CII 12_final":                 "MCII12_en_final",
        "M CII 13_final":                 "MCII13_en_final",
        "M CII 14_final":                 "MCII14_en_final",
        "Punto de interés_final":         "Pointofinterest_final"
        // Nota: "Welcome_final" no tiene versión en español en el archivo.
        // Si agregás una "Bienvenida_final" en español, sumala acá también:
        // "Bienvenida_final": "Welcome_final",
    ]
     
    static func cues(for videoName: String, language: String = "ES") -> [TranscriptCue]? {
        // Si el idioma es inglés, buscamos el nombre equivalente en inglés.
        // Si no existe en el mapeo, usamos el mismo nombre (por si ya venía en inglés).
        let resolvedName: String
        if language == "EN" {
            resolvedName = spanishToEnglishNames[videoName] ?? videoName
        } else {
            resolvedName = videoName
        }
        return transcripts[resolvedName]
    }
}
