import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject, ARSCNViewDelegate {

    // MARK: - Dependencies
    private weak var sceneView: ARSCNView?

    // MARK: - Internal state
    private var loadedNode:   SCNNode?
    private var activeAnchor: ARAnchor?
    private var activePOI:    POILocation?

    // User gesture accumulators
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

    // MARK: - Preload
    func preloadAssets(for poi: POILocation) {
        guard activePOI?.id != poi.id || loadedNode == nil else {
            print("[preload] '\(poi.id)' already loaded — skip")
            return
        }

        print("\n[preload] '\(poi.id)'")
        let pivotNode = SCNNode()

        if poi.parts.isEmpty {
            guard !poi.modelPath.isEmpty else { return }
            if let n = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
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
        pivotNode.isHidden = true

        loadedNode = pivotNode
        activePOI  = poi

        var geos = 0
        pivotNode.enumerateHierarchy { n, _ in if n.geometry != nil { geos += 1 } }
        print("[preload] '\(poi.id)' done — geos:\(geos) scale:\(s)")
    }

    // MARK: - Build node
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
        clearPlacement(session: session)

        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)

        var relDeg = bear - userHeading
        while relDeg >  180 { relDeg -= 360 }
        while relDeg < -180 { relDeg += 360 }
        let rel = Float(relDeg * .pi / 180)

        let clampedDist = min(Float(dist), 15.0) + 5.0
        let dx =  clampedDist * sin(rel)
        let dz = -clampedDist * cos(rel)
        let dy:  Float = poi.baseAltitudeMeters

        var t = matrix_identity_float4x4
        t.columns.3.x = cameraTransform.columns.3.x + dx
        t.columns.3.y = cameraTransform.columns.3.y + dy
        t.columns.3.z = cameraTransform.columns.3.z + dz
        t.columns.3.w = 1

        print("[place] dist:\(String(format:"%.1f",dist))m bear:\(String(format:"%.1f",bear))° relDeg:\(String(format:"%.1f",relDeg))°")
        print("[place] dx:\(String(format:"%.2f",dx)) dy:\(String(format:"%.2f",dy)) dz:\(String(format:"%.2f",dz))")
        print("[place] anchor pos: \(t.columns.3)")

        let anchor = ARAnchor(name: poi.id, transform: t)
        session.add(anchor: anchor)
        activeAnchor = anchor
    }

    // MARK: - Force re-place
    func forcePlaceModel(
        for poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {
        print("[forcePlace] re-placing '\(poi.id)'")
        placeModel(for: poi, userLocation: userLocation, userHeading: userHeading,
                   cameraTransform: cameraTransform, in: session)
    }

    // MARK: - Switch POI (clears current, loads and places new)
    func switchToPOI(
        _ poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {
        print("[switch] clearing current, loading '\(poi.id)'")
        clear(session: session)
        preloadAssets(for: poi)
        placeModel(for: poi, userLocation: userLocation, userHeading: userHeading,
                   cameraTransform: cameraTransform, in: session)
    }

    // MARK: - Show / Hide
    func showModel() {
        guard let node = loadedNode else { return }
        node.isHidden = false
        print("[show] inScene:\(node.parent != nil)")
    }

    func hideModel() {
        loadedNode?.isHidden = true
    }

    // MARK: - Clear placement only
    private func clearPlacement(session: ARSession) {
        if let anchor = activeAnchor {
            session.remove(anchor: anchor)
            activeAnchor = nil
        }
        loadedNode?.removeFromParentNode()
    }

    // MARK: - Full clear
    func clear(session: ARSession) {
        clearPlacement(session: session)
        loadedNode = nil
        activePOI  = nil
        modelScale     = 1.0
        modelRotationY = 0.0
        modelOffsetY   = 0.0
    }

    // MARK: - Gestures
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

    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        modelOffsetY   = 0.0
        applyUserTransforms()
    }

    // MARK: - Apply transforms
    private func applyUserTransforms() {
        guard let pivot = loadedNode, let poi = activePOI else { return }
        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        pivot.scale = SCNVector3(s, s, s)
        let totalYRad = (poi.baseYawDeg + modelRotationY) * (.pi / 180)
        pivot.simdOrientation = simd_quatf(angle: totalYRad, axis: SIMD3<Float>(0, 1, 0))
        pivot.simdPosition = SIMD3<Float>(pivot.simdPosition.x, modelOffsetY, pivot.simdPosition.z)
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let name = anchor.name,
              name == activePOI?.id,
              let pivot = loadedNode,
              let poi = activePOI else {
            return SCNNode()
        }

        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        pivot.scale = SCNVector3(s, s, s)
        pivot.simdOrientation = simd_quatf(
            angle: (poi.baseYawDeg + modelRotationY) * (.pi / 180),
            axis:  SIMD3<Float>(0, 1, 0)
        )
        pivot.simdPosition = SIMD3<Float>(0, modelOffsetY, 0)
        pivot.isHidden = false

        print("[nodeFor] '\(name)' attached, scale:\(s)")
        return pivot
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let p = anchor.transform.columns.3
        print("[didAdd] '\(anchor.name ?? "?")'  x:\(String(format:"%.2f",p.x))  y:\(String(format:"%.2f",p.y))  z:\(String(format:"%.2f",p.z))")
    }
}
