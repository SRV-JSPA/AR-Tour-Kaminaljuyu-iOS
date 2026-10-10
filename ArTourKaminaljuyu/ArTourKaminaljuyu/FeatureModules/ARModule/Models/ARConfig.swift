
import Foundation

enum ARConfig {

    // MARK: - Model scale limits (for pinch gesture)
    static let minScale: Float = 0.1
    static let maxScale: Float = 5.0

    // MARK: - Eye height
    static let cameraEyeHeightMeters: Double = 1.6

    // MARK: - Lighting
    static let lightAmbient: Float = 0.9
    static let lightDiffuse: Float = 0.7

    // MARK: - Distance in front of camera where model is placed
    static let modelPlacementDistanceMeters: Float = 8.0

    // MARK: - Global scale multiplier applied on top of poi.baseScale

    static let globalScaleMultiplier: Float = 0.3

    // MARK: - Distance (meters) within which the placed model becomes visible.
    // El modelo se cuelga del sceneRoot en cuanto el usuario tapea "Next",
    // pero queda oculto hasta que la distancia GPS al POI cae bajo este umbral.
    // Coincide con la fase 2 de proximidad (video "Punto de interés"): el
    // modelo aparece cuando suena ese video, no antes. Una vez visible, la
    // perspectiva 3D natural de ARKit hace que se vea más grande al acercarse.
    static let modelVisibilityDistanceMeters: Double = 10.0
}
