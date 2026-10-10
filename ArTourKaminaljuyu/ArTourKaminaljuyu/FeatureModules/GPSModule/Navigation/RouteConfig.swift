import CoreLocation

// MARK: - RouteConfig

struct RouteConfig {
    
    // MARK: - Identificadores de segmento
    
    static let START_ID = "START"
    
    static func routeKey(from: String, to: String) -> String {
        "\(from)->\(to)"
    }
    
    static func routeKeyStart(to: String) -> String {
        routeKey(from: START_ID, to: to)
    }
    
    static func routeKeyToStart(from: String) -> String {
        routeKey(from: from, to: START_ID)
    }
    
    // MARK: - Mapa de conectores
    
    
    // Waypoints sobre los senderos del parque. Se desactivan con
    // `AppConfig.routeConnectorsEnabled` cuando el recorrido activo no es el del
    // sitio real (por ejemplo el recorrido de prueba en la UVG): sin conectores
    // la navegación va en línea recta de POI a POI.
    static let CONNECTORS: [String: [CLLocationCoordinate2D]] = {
        guard AppConfig.routeConnectorsEnabled else { return [:] }

        var map = [String: [CLLocationCoordinate2D]]()

        map[routeKey(from: "informacion_inicial", to: "monticulo_6")] = [
            CLLocationCoordinate2D(latitude: 14.63141060, longitude: -90.54846954),
            CLLocationCoordinate2D(latitude: 14.63158607, longitude: -90.54853058),
            CLLocationCoordinate2D(latitude: 14.63171482, longitude: -90.54850769),
            CLLocationCoordinate2D(latitude: 14.63184834, longitude: -90.54848480)
        ]
        
        map[routeKey(from: "monticulo_6", to: "acropolis")] = [
            CLLocationCoordinate2D(latitude: 14.63199234, longitude: -90.54843903),
            CLLocationCoordinate2D(latitude: 14.63208675, longitude: -90.54845428),
            CLLocationCoordinate2D(latitude: 14.63213348, longitude: -90.54851532),
            CLLocationCoordinate2D(latitude: 14.63215160, longitude: -90.54857635),
            CLLocationCoordinate2D(latitude: 14.63217735, longitude: -90.54860687),
            CLLocationCoordinate2D(latitude: 14.63232803, longitude: -90.54868317),
            CLLocationCoordinate2D(latitude: 14.63245583, longitude: -90.54875183)
        ]
        
        map[routeKey(from: "acropolis", to: "monticulo_3")] = [
            CLLocationCoordinate2D(latitude: 14.63252068, longitude: -90.54873657),
            CLLocationCoordinate2D(latitude: 14.63262844, longitude: -90.54869843),
            CLLocationCoordinate2D(latitude: 14.63270664, longitude: -90.54861450),
            CLLocationCoordinate2D(latitude: 14.63281822, longitude: -90.54849243),
            CLLocationCoordinate2D(latitude: 14.63291645, longitude: -90.54841614),
            CLLocationCoordinate2D(latitude: 14.63302231, longitude: -90.54831696),
            CLLocationCoordinate2D(latitude: 14.63315487, longitude: -90.54814911)
        ]
        
        map[routeKey(from: "monticulo_3", to: "monticulo_5")] = [
            CLLocationCoordinate2D(latitude: 14.63302803, longitude: -90.54804230),
            CLLocationCoordinate2D(latitude: 14.63293839, longitude: -90.54796600),
            CLLocationCoordinate2D(latitude: 14.63282394, longitude: -90.54795837),
            CLLocationCoordinate2D(latitude: 14.63269615, longitude: -90.54794312),
            CLLocationCoordinate2D(latitude: 14.63256359, longitude: -90.54798889)
        ]
        
        map[routeKey(from: "monticulo_5", to: "monticulo_7")] = [
            CLLocationCoordinate2D(latitude: 14.63241768, longitude: -90.54798126),
            CLLocationCoordinate2D(latitude: 14.63225842, longitude: -90.54789734)
        ]
        
        map[routeKey(from: "monticulo_7", to: "monticulo_8")] = [
            CLLocationCoordinate2D(latitude: 14.63218307, longitude: -90.54788971),
            CLLocationCoordinate2D(latitude: 14.63209438, longitude: -90.54796600),
            CLLocationCoordinate2D(latitude: 14.63202286, longitude: -90.54804993),
            CLLocationCoordinate2D(latitude: 14.63189411, longitude: -90.54812622)
        ]
        
        map[routeKey(from: "monticulo_8", to: "monticulo_12")] = [
            CLLocationCoordinate2D(latitude: 14.63174248, longitude: -90.54814148),
            CLLocationCoordinate2D(latitude: 14.63163948, longitude: -90.54816437),
            CLLocationCoordinate2D(latitude: 14.63151836, longitude: -90.54818726),
            CLLocationCoordinate2D(latitude: 14.63139534, longitude: -90.54819489),
            CLLocationCoordinate2D(latitude: 14.63113403, longitude: -90.54820251)
        ]
        
        map[routeKey(from: "monticulo_12", to: "palangana")] = [
            CLLocationCoordinate2D(latitude: 14.63098431, longitude: -90.54824829),
            CLLocationCoordinate2D(latitude: 14.63087177, longitude: -90.54821014),
            CLLocationCoordinate2D(latitude: 14.63079166, longitude: -90.54817963),
            CLLocationCoordinate2D(latitude: 14.63071537, longitude: -90.54816437),
            CLLocationCoordinate2D(latitude: 14.63071251, longitude: -90.54811096),
            CLLocationCoordinate2D(latitude: 14.63066578, longitude: -90.54807281),
            CLLocationCoordinate2D(latitude: 14.63062763, longitude: -90.54802704),
            CLLocationCoordinate2D(latitude: 14.63066769, longitude: -90.54792023),
            CLLocationCoordinate2D(latitude: 14.63069344, longitude: -90.54781342),
            CLLocationCoordinate2D(latitude: 14.63075733, longitude: -90.54759216)
        ]
        
        map[routeKey(from: "palangana", to: "monticulo_14")] = [
            CLLocationCoordinate2D(latitude: 14.63063622, longitude: -90.54764557),
            CLLocationCoordinate2D(latitude: 14.63058567, longitude: -90.54766846),
            CLLocationCoordinate2D(latitude: 14.63052845, longitude: -90.54768372),
            CLLocationCoordinate2D(latitude: 14.63046169, longitude: -90.54771423),
            CLLocationCoordinate2D(latitude: 14.63039017, longitude: -90.54770660),
            CLLocationCoordinate2D(latitude: 14.63041973, longitude: -90.54763794),
            CLLocationCoordinate2D(latitude: 14.63045216, longitude: -90.54757690),
            CLLocationCoordinate2D(latitude: 14.63045502, longitude: -90.54750824),
            CLLocationCoordinate2D(latitude: 14.63044548, longitude: -90.54742432),
            CLLocationCoordinate2D(latitude: 14.63059425, longitude: -90.54727173),
            CLLocationCoordinate2D(latitude: 14.63068390, longitude: -90.54722595)
        ]
        
        map[routeKey(from: "monticulo_14", to: "monticulo_13")] = [
            CLLocationCoordinate2D(latitude: 14.63066864, longitude: -90.54715729),
            CLLocationCoordinate2D(latitude: 14.63061810, longitude: -90.54702759)
        ]
        
        map[routeKeyToStart(from: "monticulo_13")] = [
            CLLocationCoordinate2D(latitude: 14.63037395, longitude: -90.54730988),
            CLLocationCoordinate2D(latitude: 14.63033676, longitude: -90.54745483),
            CLLocationCoordinate2D(latitude: 14.63038635, longitude: -90.54757690),
            CLLocationCoordinate2D(latitude: 14.63036823, longitude: -90.54768372),
            CLLocationCoordinate2D(latitude: 14.63043118, longitude: -90.54778290),
            CLLocationCoordinate2D(latitude: 14.63052559, longitude: -90.54791260),
            CLLocationCoordinate2D(latitude: 14.63059330, longitude: -90.54804230),
            CLLocationCoordinate2D(latitude: 14.63068295, longitude: -90.54814148),
            CLLocationCoordinate2D(latitude: 14.63072681, longitude: -90.54820251),
            CLLocationCoordinate2D(latitude: 14.63078117, longitude: -90.54824829),
            CLLocationCoordinate2D(latitude: 14.63089085, longitude: -90.54828644),
            CLLocationCoordinate2D(latitude: 14.63104153, longitude: -90.54838562),
            CLLocationCoordinate2D(latitude: 14.63119030, longitude: -90.54845428)
        ]
        
        return map
    }()
}

// MARK: - Funciones constructoras de ruta


func buildRouteWaypoints(
    pois: [POILocation],
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    guard !pois.isEmpty else { return [] }
    
    var result = [CLLocationCoordinate2D]()
    
    for i in 0..<pois.count {
        let current = pois[i]
        result.append(current.coordinate)
        
        if i < pois.count - 1 {
            let next = pois[i + 1]
            let legKey = RouteConfig.routeKey(from: current.id, to: next.id)
            if let legConnectors = connectors[legKey] {
                result.append(contentsOf: legConnectors)
            }
        }
    }
    
    return result
}


func buildStartLeg(
    start: CLLocationCoordinate2D,
    first: POILocation,
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    var result = [start]
    let key = RouteConfig.routeKeyStart(to: first.id)
    if let legConnectors = connectors[key] {
        result.append(contentsOf: legConnectors)
    }
    result.append(first.coordinate)
    return result
}


func buildReturnLeg(
    last: POILocation,
    start: CLLocationCoordinate2D,
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    var result = [last.coordinate]
    let key = RouteConfig.routeKeyToStart(from: last.id)
    if let legConnectors = connectors[key] {
        result.append(contentsOf: legConnectors)
    }
    result.append(start)
    return result
}


func buildFullRouteIncludingStart(
    start: CLLocationCoordinate2D,
    pois: [POILocation],
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    guard !pois.isEmpty else { return [start] }
    
    var full = buildStartLeg(start: start, first: pois[0], connectors: connectors)
    
    let rest = buildRouteWaypoints(pois: pois, connectors: connectors).dropFirst()
    full.append(contentsOf: rest)
    
    return full
}

// MARK: - Helpers de conectores (solo conectores, sin endpoints)

func connectorsForStartLeg(
    first: POILocation,
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    connectors[RouteConfig.routeKeyStart(to: first.id)] ?? []
}

func connectorsForPoiLeg(
    from: POILocation,
    to: POILocation,
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    connectors[RouteConfig.routeKey(from: from.id, to: to.id)] ?? []
}

func connectorsForReturnLeg(
    last: POILocation,
    connectors: [String: [CLLocationCoordinate2D]] = RouteConfig.CONNECTORS
) -> [CLLocationCoordinate2D] {
    connectors[RouteConfig.routeKeyToStart(from: last.id)] ?? []
}
