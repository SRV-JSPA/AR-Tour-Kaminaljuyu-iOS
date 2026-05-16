import ARKit
import SceneKit
import CoreLocation
import simd

/// Loads "flecha.obj" from the bundle and attaches it as a child of the AR camera node
/// so it always floats centred at the top of the viewport in camera space.
/// The node rotates around Y to point toward the current target POI.
final class ARGuideArrowManager {

    // MARK: - Config

    /// How far in front of the camera the arrow sits (metres, camera-space Z).
    private let depth: Float = 0.5

    /// How far above the camera centre the arrow floats (metres, camera-space Y).
    private let heightOffset: Float = 0.30

    /// Base scale applied to the loaded model.
    private let modelScale: Float = 0.08

    /// Name of the OBJ asset (without extension) — change if your file is named differently.
    private let modelName = "flecha"

    // MARK: - State

    private weak var sceneView: ARSCNView?
    private var arrowNode: SCNNode?
    private var isVisible = false

    // MARK: - Init

    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        buildArrowNode()
    }

    // MARK: - Build

    private func buildArrowNode() {
        guard let objURL = resolveOBJ() else {
            print("[GuideArrow] ⚠️ flecha.obj not found in bundle")
            return
        }

        let scene: SCNScene
        do {
            scene = try SCNScene(url: objURL, options: [
                .checkConsistency:     false,
                .convertToYUp:         true,
                .convertUnitsToMeters: true,
                .assetDirectoryURLs: [
                    Bundle.main.bundleURL,
                    objURL.deletingLastPathComponent()
                ]
            ])
        } catch {
            print("[GuideArrow] SCNScene load error: \(error)")
            return
        }

        let root = SCNNode()
        scene.rootNode.childNodes.forEach { root.addChildNode($0) }

        let s = modelScale
        root.scale = SCNVector3(s, s, s)

        // Position in camera space: slightly above centre, straight ahead
        root.simdPosition = SIMD3<Float>(0, heightOffset, -depth)

        // Start hidden until we have a GPS target
        root.isHidden = true

        arrowNode = root
        print("[GuideArrow] arrow node built, waiting for camera node…")
    }

    /// Called once the AR session is running and the camera node exists.
    /// Attaches the arrow as a child of the point-of-view (camera) node so it
    /// moves with the camera but stays at a fixed camera-space offset.
    func attachToCamera() {
        guard let arrow = arrowNode,
              let pov   = sceneView?.pointOfView else {
            print("[GuideArrow] attachToCamera: pov not ready yet")
            return
        }
        guard arrow.parent == nil else { return }   // already attached

        pov.addChildNode(arrow)
        print("[GuideArrow] arrow attached to camera (pov) node")
    }

    // MARK: - Update (call every frame from ARSessionDelegate)

    /// Call every AR frame with the world-space position of the placed 3-D model.
    /// The arrow rotates to point directly at that position in AR space — no GPS math needed.
    func update(modelWorldPosition: SIMD3<Float>?) {

        let hasPOI = modelWorldPosition != nil

        // Show/hide
        if hasPOI != isVisible {
            isVisible = hasPOI
            DispatchQueue.main.async { self.arrowNode?.isHidden = !hasPOI }
        }

        guard let target = modelWorldPosition,
              let arrow  = arrowNode,
              let pov    = sceneView?.pointOfView else { return }

        // Camera world position
        let camPos = pov.simdWorldPosition

        // Flatten both to XZ plane (ignore vertical difference — we only want horizontal pointing)
        let camFlat    = SIMD3<Float>(camPos.x, 0, camPos.z)
        let targetFlat = SIMD3<Float>(target.x, 0, target.z)

        let diff = targetFlat - camFlat
        guard simd_length(diff) > 0.01 else { return }   // too close to compute a direction

        // Angle in world XZ: atan2 gives us the angle from +X axis counter-clockwise.
        // We negate Z because ARKit's -Z is "forward/north".
        let worldAngle = -atan2(diff.x, -diff.z)   // clockwise from -Z (world north)

        // Convert world angle → camera-local orientation (same inverse-camera trick)
        let worldQ    = simd_quatf(angle: worldAngle, axis: SIMD3<Float>(0, 1, 0))
        let camWorldQ = simd_quatf(pov.simdWorldTransform)
        let localQ    = camWorldQ.inverse * worldQ

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.12
        arrow.simdOrientation = localQ
        SCNTransaction.commit()
    }

    // MARK: - Show / Hide

    func show() {
        isVisible = true
        arrowNode?.isHidden = false
    }

    func hide() {
        isVisible = false
        arrowNode?.isHidden = true
    }

    // MARK: - Bundle resolution

    private func resolveOBJ() -> URL? {
        // 1. Direct bundle resource lookup
        if let url = Bundle.main.url(forResource: modelName, withExtension: "obj") {
            return url
        }
        // 2. Full bundle walk (handles sub-folders like Assets/Models/)
        let bundleURL = Bundle.main.bundleURL
        guard let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) else { return nil }
        for case let path as String in enumerator {
            let url = URL(fileURLWithPath: path)
            if url.deletingPathExtension().lastPathComponent.lowercased() == modelName,
               url.pathExtension.lowercased() == "obj" {
                return bundleURL.appendingPathComponent(path)
            }
        }
        return nil
    }
}
