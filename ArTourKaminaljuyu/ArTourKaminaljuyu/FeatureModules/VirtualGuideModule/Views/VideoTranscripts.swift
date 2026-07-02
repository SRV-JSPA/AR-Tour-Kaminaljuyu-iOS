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
        ]

        // TODO: agregar transcripciones con timestamps para los demás videos:
        // "Indicación flecha_final"
        // "Indicación de proximidad_final"
        // "Punto de interés_final"
        // "Despedida_final"
        // "M CII 5_final"
        // "Estructura E_final"
        // "M CII 13_final"
    ]

    static func cues(for videoName: String, language: String = "ES") -> [TranscriptCue]? {
        // Por ahora solo hay transcripciones en español.
        // Cuando se agreguen en inglés, cambiar a estructura `[idioma: [videoName: cues]]`.
        guard language == "ES" else { return nil }
        return transcripts[videoName]
    }
}
