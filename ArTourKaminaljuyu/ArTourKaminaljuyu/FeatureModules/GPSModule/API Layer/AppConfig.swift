enum AppConfig {

    // MARK: - Umbrales de proximidad
    static let guidedArrivalMeters: Double = 25.0

    static let connectorArrivalMeters: Double = 2.0

    static let tourStartRadiusMeters: Double = 20.0

    // MARK: - Umbrales de visibilidad
    static let visibilityRadiusMeters: Double = 100.0

    // MARK: - Conectores de ruta
    //
    // Los conectores de RouteConfig son waypoints trazados sobre los senderos del
    // parque. Con el recorrido de prueba en la UVG apuntarían a coordenadas a
    // kilómetros de distancia y, como el navegador solo avanza al acercarse a
    // `connectorArrivalMeters`, el tour quedaría trabado entre POIs.
    //
    // false -> navegación en línea recta de POI a POI (recorrido de prueba UVG).
    // true  -> conectores del parque (recorrido real en Kaminaljuyú).
    static let routeConnectorsEnabled: Bool = false

    // MARK: - Coordenada de inicio del tour
    //
    // TourManager.startTour() exige estar a menos de `tourStartRadiusMeters` de
    // este punto, y el tramo de regreso termina aquí. Debe coincidir con el
    // primer POI del recorrido activo en POIRegistry.
    //
    // Actual: recorrido de prueba de 11 POIs en la UVG (POI 1, informacion_inicial).
    // Valores anteriores, para restaurar cuando se vuelva al parque:
    //   Parque Kaminaljuyú -> el POI 1 real del sitio
    //   Pruebas en casa    -> (14.6748361, -90.5520308)
    static let tourStartLatitude: Double  = 14.6326436
    static let tourStartLongitude: Double = -90.4627277
    
    
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

