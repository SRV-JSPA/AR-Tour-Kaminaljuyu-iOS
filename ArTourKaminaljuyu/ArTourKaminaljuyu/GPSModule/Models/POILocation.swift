

import CoreLocation

// MARK: - ModelPart

struct ModelPart: Equatable {
    let modelPath: String
    let texturePath: String
    let baseScale: Float

    init(modelPath: String, texturePath: String, baseScale: Float = 1.0) {
        self.modelPath = modelPath
        self.texturePath = texturePath
        self.baseScale = baseScale
    }
}

// MARK: - POILocation
struct POILocation: Equatable, Identifiable {


    let id: String


    let coordinate: CLLocationCoordinate2D

    let name: String


    let modelPath: String

    let texturePath: String

    let baseScale: Float

    let baseAltitudeMeters: Float

    let baseYawDeg: Float

    let parts: [ModelPart]

    let bobbingEnabled: Bool
    let bobbingAmplitude: Float
    let bobbingSpeed: Float

    let description: String
    let historicalInfo: String
    let constructionPeriod: String
    let height: String
    let archaeologicalFeatures: [String]
    let culturalSignificance: String

    let images: [String]

    let arrivalThresholdMeters: Double

    // MARK: - Inicializador con valores por defecto
    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        name: String,
        modelPath: String = "",
        texturePath: String = "",
        baseScale: Float = 1.0,
        baseAltitudeMeters: Float = 0.0,
        baseYawDeg: Float = 0.0,
        parts: [ModelPart] = [],
        bobbingEnabled: Bool = false,
        bobbingAmplitude: Float = 0.2,
        bobbingSpeed: Float = 1.0,
        description: String = "",
        historicalInfo: String = "",
        constructionPeriod: String = "",
        height: String = "",
        archaeologicalFeatures: [String] = [],
        culturalSignificance: String = "",
        images: [String] = [],
        arrivalThresholdMeters: Double = 10.0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.modelPath = modelPath
        self.texturePath = texturePath
        self.baseScale = baseScale
        self.baseAltitudeMeters = baseAltitudeMeters
        self.baseYawDeg = baseYawDeg
        self.parts = parts
        self.bobbingEnabled = bobbingEnabled
        self.bobbingAmplitude = bobbingAmplitude
        self.bobbingSpeed = bobbingSpeed
        self.description = description
        self.historicalInfo = historicalInfo
        self.constructionPeriod = constructionPeriod
        self.height = height
        self.archaeologicalFeatures = archaeologicalFeatures
        self.culturalSignificance = culturalSignificance
        self.images = images
        self.arrivalThresholdMeters = arrivalThresholdMeters
    }

    // MARK: - Equatable
    static func == (lhs: POILocation, rhs: POILocation) -> Bool {
        guard lhs.id == rhs.id else { return false }
        let latEqual = abs(lhs.coordinate.latitude  - rhs.coordinate.latitude)  < 1e-9
        let lonEqual = abs(lhs.coordinate.longitude - rhs.coordinate.longitude) < 1e-9
        return latEqual && lonEqual
    }

    // MARK: - Helper de conveniencia
    var clLocation: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
