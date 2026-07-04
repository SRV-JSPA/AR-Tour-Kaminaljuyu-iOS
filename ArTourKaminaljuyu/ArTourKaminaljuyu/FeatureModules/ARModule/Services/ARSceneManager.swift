import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject, ARSCNViewDelegate {

    // MARK: - Dependencies
    private weak var sceneView: ARSCNView?

    // MARK: - Single model state
    private var pivotNode:    SCNNode?
    private(set) var activeAnchor: ARAnchor?
    private var activePOI:    POILocation?

    // MARK: - User gesture accumulators
    var modelRotationY: Float = 0.0
    var modelScale:     Float = 1.0
    var modelOffsetY:   Float = 0.0

    // MARK: - Texture map
    private var bundleTextureMap: [String: URL] = [:]

    // MARK: - Init
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
        buildBundleTextureMap()
        print("[ARSceneManager] init — \(bundleTextureMap.count) textures indexed")
    }

    // MARK: - Active model world position (for guide arrow)

    /// World-space position of the currently placed model anchor.
    /// Returns nil when no model is loaded. Used by ARGuideArrowManager.
    var activeModelWorldPosition: SIMD3<Float>? {
        guard let anchor = activeAnchor else { return nil }
        return SIMD3<Float>(
            anchor.transform.columns.3.x,
            anchor.transform.columns.3.y,
            anchor.transform.columns.3.z
        )
    }

    // MARK: - Bundle texture index

    private func buildBundleTextureMap() {
        let bundleURL = Bundle.main.bundleURL
        let imageExts: Set<String> = ["jpg", "jpeg", "png", "tga", "bmp", "tiff", "gif"]
        guard let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) else { return }
        for case let path as String in enumerator {
            let ext = (path as NSString).pathExtension.lowercased()
            guard imageExts.contains(ext) else { continue }
            let filename = (path as NSString).lastPathComponent
            let fullURL  = bundleURL.appendingPathComponent(path)
            if bundleTextureMap[filename] == nil { bundleTextureMap[filename] = fullURL }
            let lower = filename.lowercased()
            if bundleTextureMap[lower] == nil { bundleTextureMap[lower] = fullURL }
        }
        print("[ARSceneManager] textures in bundle: \(bundleTextureMap.count / 2)")
    }

    private func resolveTexture(_ name: String) -> URL? {
        let filename = URL(fileURLWithPath: name).lastPathComponent
        if let u = bundleTextureMap[filename]              { return u }
        if let u = bundleTextureMap[filename.lowercased()] { return u }
        let base = (filename as NSString).deletingPathExtension
        let ext  = (filename as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext)
    }

    // MARK: - MTL parser

    private func parseMTL(forOBJ objURL: URL) -> [String: String] {
        let name   = objURL.deletingPathExtension().lastPathComponent
        var mtlURL = objURL.deletingLastPathComponent()
                           .appendingPathComponent("\(name).mtl")

        if !FileManager.default.fileExists(atPath: mtlURL.path) {
            let bundleURL = Bundle.main.bundleURL
            if let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) {
                for case let path as String in enumerator
                where URL(fileURLWithPath: path).lastPathComponent == "\(name).mtl" {
                    mtlURL = bundleURL.appendingPathComponent(path); break
                }
            }
        }

        guard FileManager.default.fileExists(atPath: mtlURL.path),
              let content = try? String(contentsOf: mtlURL, encoding: .utf8) else {
            print("  [parseMTL] not found for '\(name)'"); return [:]
        }

        var result: [String: String] = [:]
        var currentMat: String?
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("newmtl ") {
                currentMat = String(line.dropFirst("newmtl ".count)).trimmingCharacters(in: .whitespaces)
            } else if line.lowercased().hasPrefix("map_kd "), let mat = currentMat {
                let rawPath = String(line.dropFirst("map_kd ".count)).trimmingCharacters(in: .whitespaces)
                result[mat] = URL(fileURLWithPath: rawPath).lastPathComponent
            }
        }
        return result
    }

    // MARK: - Force-apply textures

    private func forceApplyTextures(to modelNode: SCNNode, mtlMap: [String: String]) {
        modelNode.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }
            for material in geometry.materials {
                let matName = material.name ?? ""
                var filename: String?
                if let mapped = mtlMap[matName] { filename = mapped }
                else if let url = material.diffuse.contents as? URL { filename = url.lastPathComponent }
                else if let str = material.diffuse.contents as? String { filename = URL(fileURLWithPath: str).lastPathComponent }
                guard let fname = filename, !fname.isEmpty else { continue }
                guard let texURL = resolveTexture(fname) else { continue }
                guard let image = UIImage(contentsOfFile: texURL.path) else { continue }
                material.diffuse.contents  = image
                material.specular.contents = UIColor.black
                material.emission.contents = UIColor.black
                material.ambient.contents  = UIColor.white
                material.isDoubleSided     = true
                material.lightingModel     = .lambert
                material.diffuse.intensity = 1.0
                material.ambient.intensity = 1.0
            }
        }
    }

    // MARK: - Build node from POI

    private func buildPivotNode(for poi: POILocation) -> SCNNode {
        let pivotNode = SCNNode()

        if poi.parts.isEmpty {
            if !poi.modelPath.isEmpty,
               let n = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                pivotNode.addChildNode(n)
            }
        } else {
            for part in poi.parts {
                if let n = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    let s = part.baseScale
                    n.scale = SCNVector3(s, s, s)
                    pivotNode.addChildNode(n)
                }
            }
        }

        let s = poi.baseScale * ARConfig.globalScaleMultiplier
        pivotNode.scale = SCNVector3(s, s, s)
        pivotNode.simdOrientation = simd_quatf(
            angle: poi.baseYawDeg * (.pi / 180),
            axis:  SIMD3<Float>(0, 1, 0)
        )

        var geos = 0
        pivotNode.enumerateHierarchy { n, _ in if n.geometry != nil { geos += 1 } }
        print("[buildPivot] '\(poi.id)' geos:\(geos) scale:\(s)")
        return pivotNode
    }

    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        let bundleURL = Bundle.main.bundleURL
        var modelURL: URL?

        for candidate in [
            bundleURL.appendingPathComponent(modelPath),
            bundleURL.appendingPathComponent(URL(fileURLWithPath: modelPath).lastPathComponent)
        ] {
            if FileManager.default.fileExists(atPath: candidate.path) { modelURL = candidate; break }
        }

        if modelURL == nil {
            let base = ((modelPath as NSString).lastPathComponent as NSString).deletingPathExtension
            let ext  = (modelPath as NSString).pathExtension
            modelURL = Bundle.main.url(forResource: base, withExtension: ext)
        }

        if modelURL == nil {
            let fn = URL(fileURLWithPath: modelPath).lastPathComponent
            if let en = FileManager.default.enumerator(atPath: bundleURL.path) {
                for case let p as String in en
                where URL(fileURLWithPath: p).lastPathComponent == fn {
                    modelURL = bundleURL.appendingPathComponent(p); break
                }
            }
        }

        guard let objURL = modelURL else { return nil }

        let mtlMap = parseMTL(forOBJ: objURL)
        let scene: SCNScene
        do {
            scene = try SCNScene(url: objURL, options: [
                .checkConsistency:     false,
                .convertToYUp:         true,
                .convertUnitsToMeters: true,
                .assetDirectoryURLs: [
                    bundleURL,
                    objURL.deletingLastPathComponent(),
                    bundleURL.appendingPathComponent("Assets/Textures"),
                    bundleURL.appendingPathComponent("Assets")
                ]
            ])
        } catch { return nil }

        let modelNode = SCNNode()
        scene.rootNode.childNodes.forEach { modelNode.addChildNode($0) }
        forceApplyTextures(to: modelNode, mtlMap: mtlMap)
        return modelNode
    }

    // MARK: - Place model

    func placeModel(
        for poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {
        clearAll(session: session)

        let pivot = buildPivotNode(for: poi)
        // Hidden by default: reveal only when user is within
        // ARConfig.modelVisibilityDistanceMeters of the POI.
        pivot.isHidden = true

        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)

        var relDeg = userHeading - bear
        while relDeg >  180 { relDeg -= 360 }
        while relDeg < -180 { relDeg += 360 }
        let rel = Float(bear * .pi / 180)

        let dx = Float(dist) * sin(rel)
        let dz = Float(dist) * -cos(rel)
        let dy = poi.baseAltitudeMeters

        var transform = matrix_identity_float4x4
        transform.columns.3.x = cameraTransform.columns.3.x + dx
        transform.columns.3.y = cameraTransform.columns.3.y + dy
        transform.columns.3.z = cameraTransform.columns.3.z + dz
        transform.columns.3.w = 1

        print("[place] '\(poi.id)' dist:\(String(format:"%.1f",dist))m bear:\(String(format:"%.1f",bear))°")
        print("[place] dx:\(String(format:"%.2f",dx)) dy:\(String(format:"%.2f",dy)) dz:\(String(format:"%.2f",dz))")

        pivotNode    = pivot
        activePOI    = poi
        activeAnchor = ARAnchor(name: poi.id, transform: transform)
        session.add(anchor: activeAnchor!)

        applyUserTransforms()
        updateVisibility(userLocation: userLocation)
    }

    // MARK: - Visibility gating by GPS distance

    /// Show the placed model only when the user is within
    /// `ARConfig.modelVisibilityDistanceMeters` of the active POI.
    /// Call on every GPS update.
    func updateVisibility(userLocation: CLLocationCoordinate2D) {
        guard let pivot = pivotNode, let poi = activePOI else { return }
        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let shouldShow = dist <= ARConfig.modelVisibilityDistanceMeters
        guard pivot.isHidden == shouldShow else { return }
        pivot.isHidden = !shouldShow
        print("[ARSceneManager] visibility -> \(shouldShow ? "shown" : "hidden") dist:\(String(format:"%.1f", dist))m")
    }

    // MARK: - Reset gestures only

    func resetGestures() {
        modelScale     = 1.0
        modelRotationY = 0.0
        modelOffsetY   = 0.0
        applyUserTransforms()
        print("[ARSceneManager] gestures reset")
    }

    // MARK: - Clear everything

    func clearAll(session: ARSession) {
        if let anchor = activeAnchor {
            session.remove(anchor: anchor)
            activeAnchor = nil
        }
        pivotNode?.removeFromParentNode()
        pivotNode  = nil
        activePOI  = nil
        modelScale     = 1.0
        modelRotationY = 0.0
        modelOffsetY   = 0.0
        print("[ARSceneManager] cleared")
    }

    // MARK: - Gesture application

    func applyRotation(delta: Float) {
        let clamped = max(-5.0, min(5.0, delta))
        guard abs(clamped) > 0.001 else { return }
        modelRotationY = (modelRotationY + clamped).truncatingRemainder(dividingBy: 360)
        applyUserTransforms()
    }

    func applyVerticalTranslation(delta: Float) {
        modelOffsetY = max(-1.0, min(1.0, modelOffsetY + delta))
        applyUserTransforms()
    }

    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
    }

    private func applyUserTransforms() {
        guard let pivot = pivotNode, let poi = activePOI else { return }
        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        pivot.scale = SCNVector3(s, s, s)
        let totalYRad = (poi.baseYawDeg + modelRotationY) * (.pi / 180)
        pivot.simdOrientation = simd_quatf(angle: totalYRad, axis: SIMD3<Float>(0, 1, 0))
        pivot.simdPosition = SIMD3<Float>(pivot.simdPosition.x, modelOffsetY, pivot.simdPosition.z)
        print("[gesture] scale:\(modelScale) rotY:\(modelRotationY) offsetY:\(modelOffsetY)")
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor.name == activePOI?.id else { return SCNNode() }
        return SCNNode()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor.name == activePOI?.id,
              let pivot = pivotNode,
              let poi = activePOI else { return }

        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        pivot.scale = SCNVector3(s, s, s)
        pivot.simdOrientation = simd_quatf(
            angle: (poi.baseYawDeg + modelRotationY) * (.pi / 180),
            axis: SIMD3<Float>(0, 1, 0)
        )
        pivot.simdPosition = SIMD3<Float>(0, modelOffsetY, 0)

        node.addChildNode(pivot)
        print("[didAdd] '\(anchor.name ?? "?")' pivot attached to anchor node")
    }
}
