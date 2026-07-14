enum AppConfig {

    // MARK: - Umbrales de proximidad
    static let guidedArrivalMeters: Double = 25.0

    static let connectorArrivalMeters: Double = 2.0

    static let tourStartRadiusMeters: Double = 20.0

    // MARK: - Umbrales de visibilidad
    static let visibilityRadiusMeters: Double = 100.0

    // MARK: - Coordenada de inicio del tour

    static let tourStartLatitude: Double  = 14.6748361
    static let tourStartLongitude: Double = -90.5520308
    
    
    // MARK: - Calidad del GPS
    static let accuracyGoodMeters: Double = 5.0

    // Lecturas con precisión peor que esto se descartan por completo.
    // En campo abierto con árboles el iPhone suele reportar 10-30m; si el
    // límite es muy bajo la posición se congela mientras el usuario camina.
    static let maxUsableHorizontalAccuracyMeters: Double = 30.0

    // Los umbrales de disparo (8/6/5m) están debajo del ruido del GPS: parado
    // sobre el POI con precisión de 10m la distancia cruda lee ~8-12m. Se resta
    // la precisión reportada (con este tope) para que los disparos ocurran a la
    // distancia física esperada o antes, nunca cuando ya estás encima del punto.
    static let accuracyCompensationCapMeters: Double = 10.0
}

