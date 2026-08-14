
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
    // The anchor is placed at the POI's real GPS position as soon as the user
    // taps "Next", but the mesh stays hidden until the user is this close.
    static let modelVisibilityDistanceMeters: Double = 10.0
}
