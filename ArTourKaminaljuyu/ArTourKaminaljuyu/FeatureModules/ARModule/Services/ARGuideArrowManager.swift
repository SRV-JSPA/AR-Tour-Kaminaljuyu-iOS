import ARKit
import SceneKit
import CoreLocation
import simd

final class ARGuideArrowManager {

    // MARK: - Config
    private let depth: Float = 0.5
    private let heightOffset: Float = 0.08
    private let modelScale: Float = 0.08
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
            print("[GuideArrow] flecha.obj not found in bundle")
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
                    objURL.deletingLastPathComponent(),
                    Bundle.main.bundleURL.appendingPathComponent("Assets/Textures"),
                    Bundle.main.bundleURL.appendingPathComponent("Assets")
                ]
            ])
        } catch {
            print("[GuideArrow] SCNScene load error: \(error)")
            return
        }

        // Resolve texture
        let textureImage: UIImage? = {
            if let img = UIImage(named: "Textures/FlechaTexture") { return img }
            if let img = UIImage(named: "FlechaTexture")          { return img }

            let bundleURL = Bundle.main.bundleURL
            guard let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) else { return nil }
            for case let path as String in enumerator {
                let url = URL(fileURLWithPath: path)
                let name = url.deletingPathExtension().lastPathComponent
                let ext  = url.pathExtension.lowercased()
                guard ["jpg","jpeg","png"].contains(ext) else { continue }
                if name == "FlechaTexture" || name.lowercased() == "flechatexture" {
                    let fullPath = bundleURL.appendingPathComponent(path).path
                    print("[GuideArrow] found texture at: \(fullPath)")
                    return UIImage(contentsOfFile: fullPath)
                }
            }
            return nil
        }()

        print("[GuideArrow] texture: \(textureImage != nil ? "found" : "nil")")

        // ── Apply texture to scene BEFORE moving nodes to root ──────
        if let image = textureImage {
            var geoCount = 0
            scene.rootNode.enumerateHierarchy { node, _ in
                guard let geometry = node.geometry else { return }
                let newMaterial = SCNMaterial()
                newMaterial.diffuse.contents  = image
                newMaterial.isDoubleSided     = true
                newMaterial.lightingModel     = .constant
                geometry.materials = [newMaterial]
            }
            print("[GuideArrow] texture applied to \(geoCount) geometries on scene.rootNode")
        } else {
            print("[GuideArrow] no texture — arrow will be white")
        }

        // ── Now move nodes to our root ───────────────────────────────
        let root = SCNNode()
        scene.rootNode.childNodes.forEach { root.addChildNode($0) }

        let s = modelScale
        root.scale = SCNVector3(s, s, s)
        root.simdPosition = SIMD3<Float>(0, heightOffset, -depth)
        root.isHidden = true

        arrowNode = root
        print("[GuideArrow] arrow node built, waiting for camera node…")
    }

    // MARK: - Attach to Camera

    func attachToCamera() {
        guard let arrow = arrowNode,
              let pov   = sceneView?.pointOfView else {
            return
        }
        guard arrow.parent == nil else { return }
        pov.addChildNode(arrow)
        print("[GuideArrow] arrow attached to camera (pov) node")
    }

    // MARK: - Update

    func update(modelWorldPosition: SIMD3<Float>?) {
        let hasPOI = modelWorldPosition != nil

        if hasPOI != isVisible {
            isVisible = hasPOI
            DispatchQueue.main.async { self.arrowNode?.isHidden = !hasPOI }
        }

        guard let target = modelWorldPosition,
              let arrow  = arrowNode,
              let pov    = sceneView?.pointOfView else { return }

        let camPos     = pov.simdWorldPosition
        let camFlat    = SIMD3<Float>(camPos.x, 0, camPos.z)
        let targetFlat = SIMD3<Float>(target.x, 0, target.z)
        let diff       = targetFlat - camFlat
        guard simd_length(diff) > 0.01 else { return }

        let worldAngle = -atan2(diff.x, -diff.z)
        let worldQ     = simd_quatf(angle: worldAngle, axis: SIMD3<Float>(0, 1, 0))
        let camWorldQ  = simd_quatf(pov.simdWorldTransform)
        let localQ     = camWorldQ.inverse * worldQ

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.12
        arrow.simdOrientation = localQ
        SCNTransaction.commit()
    }

    // MARK: - Update con GPS
    func updateWithGPS(userLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D) {
        guard let arrow = arrowNode,
              let pov = sceneView?.pointOfView else { return }

        if !isVisible {
            isVisible = true
            DispatchQueue.main.async { self.arrowNode?.isHidden = false }
        }

        let lat1 = userLocation.latitude * .pi / 180
        let lat2 = targetLocation.latitude * .pi / 180
        let dLon = (targetLocation.longitude - userLocation.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = Float(atan2(y, x))

        let worldQ = simd_quatf(angle: bearing, axis: SIMD3<Float>(0, 1, 0))
        let camWorldQ = simd_quatf(pov.simdWorldTransform)
        let localQ = camWorldQ.inverse * worldQ

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
        if let url = Bundle.main.url(forResource: modelName, withExtension: "obj") {
            return url
        }
        let bundleURL = Bundle.main.bundleURL
        guard let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) else {
            return nil
        }
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
