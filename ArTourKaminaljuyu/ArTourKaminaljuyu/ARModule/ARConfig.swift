
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

    static let globalScaleMultiplier: Float = 1
}
