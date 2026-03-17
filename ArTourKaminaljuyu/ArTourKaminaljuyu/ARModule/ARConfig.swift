import Foundation

enum ARConfig {

    // MARK: - Escala del modelo
    static let minScale: Float = 0.2
    static let maxScale: Float = 5.0

    // MARK: - Altura de los ojos del usuario sobre el suelo (metros)
    static let cameraEyeHeightMeters: Double = 1.6

    // MARK: - Iluminación
    static let lightAmbient: Float = 0.9
    static let lightDiffuse: Float = 0.7

    // MARK: - Distancia al frente de la cámara para el fallback (sin ARGeoTracking)
    static let modelPlacementDistanceMeters: Float = 3.0
}
