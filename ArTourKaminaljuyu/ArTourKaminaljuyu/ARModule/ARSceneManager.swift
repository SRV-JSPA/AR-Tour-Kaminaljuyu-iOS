import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject, ARSCNViewDelegate {

    // MARK: - Dependencies
    private weak var sceneView: ARSCNView?

    // MARK: - Internal state
    private var loadedNodes:   [String: SCNNode]     = [:]
    private var activeAnchors: [String: ARAnchor]    = [:]
    private var nodePOIs:      [String: POILocation] = [:]
    private var visibleNodeID: String?

    var modelRotationY: Float = 0.0
    var modelScale:     Float = 1.0

    // MARK: - Texture map: filename → full bundle URL
    private var bundleTextureMap: [String: URL] = [:]

    // MARK: - Init
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
        buildBundleTextureMap()
        print("[ARSceneManager] init — \(bundleTextureMap.count) textures indexed")
    }

    // MARK: - Scan bundle once and map filename → URL
    private func buildBundleTextureMap() {
        let bundleURL = Bundle.main.bundleURL
        let imageExts: Set<String> = ["jpg","jpeg","png","tga","bmp","tiff","gif"]
        guard let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) else { return }

        for case let path as String in enumerator {
            let ext = (path as NSString).pathExtension.lowercased()
            guard imageExts.contains(ext) else { continue }
            let filename = (path as NSString).lastPathComponent
            let fullURL  = bundleURL.appendingPathComponent(path)
            if bundleTextureMap[filename] == nil {
                bundleTextureMap[filename] = fullURL
            }
            let lower = filename.lowercased()
            if bundleTextureMap[lower] == nil {
                bundleTextureMap[lower] = fullURL
            }
        }
        print("[ARSceneManager] textures in bundle: \(bundleTextureMap.count/2)")
    }

    private func resolveTexture(_ name: String) -> URL? {
        let filename = URL(fileURLWithPath: name).lastPathComponent
        if let u = bundleTextureMap[filename] { return u }
        if let u = bundleTextureMap[filename.lowercased()] { return u }
        let base = (filename as NSString).deletingPathExtension
        let ext  = (filename as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext)
    }

    // MARK: - Parse MTL → [materialName: textureFilename]
    private func parseMTL(forOBJ objURL: URL) -> [String: String] {
        let name   = objURL.deletingPathExtension().lastPathComponent
        var mtlURL = objURL.deletingLastPathComponent()
                           .appendingPathComponent("\(name).mtl")

        if !FileManager.default.fileExists(atPath: mtlURL.path) {
            let bundleURL = Bundle.main.bundleURL
            if let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) {
                for case let path as String in enumerator {
                    if URL(fileURLWithPath: path).lastPathComponent == "\(name).mtl" {
                        mtlURL = bundleURL.appendingPathComponent(path)
                        break
                    }
                }
            }
        }

        guard FileManager.default.fileExists(atPath: mtlURL.path),
              let content = try? String(contentsOf: mtlURL, encoding: .utf8) else {
            print("  [parseMTL] not found for '\(name)'")
            return [:]
        }

        print("  [parseMTL] reading '\(mtlURL.lastPathComponent)'")

        var result:     [String: String] = [:]
        var currentMat: String?          = nil

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("newmtl ") {
                currentMat = String(line.dropFirst("newmtl ".count))
                                .trimmingCharacters(in: .whitespaces)
            } else if line.lowercased().hasPrefix("map_kd "),
                      let mat = currentMat {
                let rawPath  = String(line.dropFirst("map_kd ".count))
                                .trimmingCharacters(in: .whitespaces)
                let filename = URL(fileURLWithPath: rawPath).lastPathComponent
                result[mat]  = filename
                print("  [parseMTL] '\(mat)' → '\(filename)'")
            }
        }
        print("  [parseMTL] \(result.count) mappings found")
        return result
    }

    // MARK: - Force apply textures as UIImage
    private func forceApplyTextures(to modelNode: SCNNode, mtlMap: [String: String]) {
        modelNode.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }
            for material in geometry.materials {
                let matName = material.name ?? ""

                var filename: String?
                if let mapped = mtlMap[matName] {
                    filename = mapped
                } else if let url = material.diffuse.contents as? URL {
                    filename = url.lastPathComponent
                } else if let str = material.diffuse.contents as? String {
                    filename = URL(fileURLWithPath: str).lastPathComponent
                }

                guard let fname = filename, !fname.isEmpty else {
                    print("  [force] '\(matName)' — no mapping")
                    continue
                }

                guard let texURL = resolveTexture(fname) else {
                    print("  [force] '\(matName)' — '\(fname)' NOT in bundle")
                    continue
                }

                guard let image = UIImage(contentsOfFile: texURL.path) else {
                    print("  [force] '\(matName)' — UIImage FAILED")
                    continue
                }

                // Apply everything in one place — nothing overwrites this
                material.diffuse.contents    = image
                material.specular.contents   = UIColor.black
                material.emission.contents   = UIColor.black
                material.ambient.contents    = UIColor.white
                material.isDoubleSided       = true
                material.lightingModel       = .lambert
                material.diffuse.intensity   = 1.0
                material.ambient.intensity   = 1.0

            }
        }
    }

    // MARK: - Preload
    func preloadAssets(for poi: POILocation) {
        guard loadedNodes[poi.id] == nil else {
            print("[preload] '\(poi.id)' already loaded")
            return
        }

        print("\n[preload] '\(poi.id)' model:'\(poi.modelPath)'")

        let rootNode = SCNNode()

        if poi.parts.isEmpty {
            guard !poi.modelPath.isEmpty else {
                print("   no modelPath and no parts")
                return
            }
            if let n = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                rootNode.addChildNode(n)
            } else {
                print("   buildNode FAILED for '\(poi.modelPath)'")
            }
        } else {
            for (i, part) in poi.parts.enumerated() {
                if let n = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    let s = part.baseScale * ARConfig.globalScaleMultiplier
                    n.scale = SCNVector3(s, s, s)
                    rootNode.addChildNode(n)
                    print("   part[\(i)] loaded")
                } else {
                    print("   part[\(i)] FAILED: '\(part.modelPath)'")
                }
            }
        }

        rootNode.eulerAngles.y = poi.baseYawDeg * (.pi / 180)
        rootNode.isHidden      = true
        loadedNodes[poi.id]    = rootNode
        nodePOIs[poi.id]       = poi

        var geos = 0
        rootNode.enumerateHierarchy { n, _ in if n.geometry != nil { geos += 1 } }
        print("[preload] '\(poi.id)' done — geos:\(geos)")
        if geos == 0 { print("WARNING: NO GEOMETRIES") }
    }

    // MARK: - Build node
    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        let bundleURL = Bundle.main.bundleURL
        print("  [buildNode] '\(modelPath)'")

        // ── Find OBJ ──────────────────────────────────────────────────────
        var modelURL: URL?

        for candidate in [
            bundleURL.appendingPathComponent(modelPath),
            bundleURL.appendingPathComponent(
                URL(fileURLWithPath: modelPath).lastPathComponent)
        ] {
            if FileManager.default.fileExists(atPath: candidate.path) {
                modelURL = candidate
                break
            }
        }

        if modelURL == nil {
            let base = ((modelPath as NSString).lastPathComponent as NSString)
                           .deletingPathExtension
            let ext  = (modelPath as NSString).pathExtension
            modelURL = Bundle.main.url(forResource: base, withExtension: ext)
        }

        if modelURL == nil {
            let fn = URL(fileURLWithPath: modelPath).lastPathComponent
            if let en = FileManager.default.enumerator(atPath: bundleURL.path) {
                for case let p as String in en {
                    if URL(fileURLWithPath: p).lastPathComponent == fn {
                        modelURL = bundleURL.appendingPathComponent(p)
                        break
                    }
                }
            }
        }

        guard let objURL = modelURL else {
            print("  [buildNode] NOT FOUND: '\(modelPath)'")
            return nil
        }
        print("  [buildNode] found: \(objURL.path)")

        // ── Parse MTL before loading ──────────────────────────────────────
        let mtlMap = parseMTL(forOBJ: objURL)

        // ── Load scene ────────────────────────────────────────────────────
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
        } catch {
            print("  [buildNode] SCNScene error: \(error)")
            return nil
        }

        // ── Move nodes directly ───────────────────────────────────────────
        let modelNode = SCNNode()
        scene.rootNode.childNodes.forEach { modelNode.addChildNode($0) }

        // ── Apply textures — single pass, nothing runs after this ─────────
        forceApplyTextures(to: modelNode, mtlMap: mtlMap)

        // ── Debug only — no material changes here ─────────────────────────
        var texturedCount = 0
        modelNode.enumerateChildNodes { node, _ in
            guard let geo = node.geometry else { return }
            for mat in geo.materials {
                let ok = mat.diffuse.contents is UIImage || mat.diffuse.contents is URL
                if ok { texturedCount += 1 }
            }
        }
        print("  [buildNode] \(texturedCount) textured materials")

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
        if activeAnchors[poi.id] != nil {
            print("[place] '\(poi.id)' already anchored — skip")
            return
        }
        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)
        let rel  = Float((bear - userHeading) * .pi / 180)
        let dx   = Float(dist) * sin(rel)
        let dz   = -Float(dist) * cos(rel)
        let dy   = poi.baseAltitudeMeters - Float(ARConfig.cameraEyeHeightMeters)

        var t = matrix_identity_float4x4
        t.columns.3.x = cameraTransform.columns.3.x + dx
        t.columns.3.y = cameraTransform.columns.3.y + dy
        t.columns.3.z = cameraTransform.columns.3.z + dz
        t.columns.3.w = 1

        let anchor = ARAnchor(name: poi.id, transform: t)
        session.add(anchor: anchor)
        activeAnchors[poi.id] = anchor
        print("[place] '\(poi.id)' anchored")
    }

    func forceReplaceModel(
        for poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {
        if let old = activeAnchors[poi.id] {
            session.remove(anchor: old)
            activeAnchors.removeValue(forKey: poi.id)
        }
        placeModel(
            for: poi,
            userLocation: userLocation,
            userHeading: userHeading,
            cameraTransform: cameraTransform,
            in: session
        )
    }

    // MARK: - Visibility
    func showModel(for poiId: String) {
        if let prev = visibleNodeID, prev != poiId {
            loadedNodes[prev]?.isHidden = true
        }
        if let node = loadedNodes[poiId] {
            node.isHidden = false
            print("[show] '\(poiId)' inScene:\(node.parent != nil)")
        } else {
            print("[show] WARNING: no node for '\(poiId)'")
        }
        visibleNodeID = poiId
    }

    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    // MARK: - Gestures
    func applyRotation(delta: Float) {
        modelRotationY = (modelRotationY + delta).truncatingRemainder(dividingBy: 360)
        applyUserTransforms()
    }

    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
    }

    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        applyUserTransforms()
    }

    // MARK: - Clear
    func clear(session: ARSession) {
        activeAnchors.values.forEach { session.remove(anchor: $0) }
        activeAnchors.removeAll()
        loadedNodes.values.forEach { $0.removeFromParentNode() }
        loadedNodes.removeAll()
        nodePOIs.removeAll()
        visibleNodeID = nil
    }

    // MARK: - Transforms
    private func applyUserTransforms() {
        guard let id  = visibleNodeID,
              let n   = loadedNodes[id],
              let poi = nodePOIs[id] else { return }
        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        n.scale         = SCNVector3(s, s, s)
        n.eulerAngles.y = modelRotationY * (.pi / 180)
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let name = anchor.name,
              let node = loadedNodes[name],
              let poi  = nodePOIs[name] else {
            print("[nodeFor] no node for '\(anchor.name ?? "?")'")
            return SCNNode()
        }
        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        node.scale = SCNVector3(s, s, s)
        var g = 0
        node.enumerateHierarchy { n, _ in if n.geometry != nil { g += 1 } }
        print("[nodeFor] '\(name)' geos:\(g) scale:\(s)")
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let p = anchor.transform.columns.3
        print("[didAdd] '\(anchor.name ?? "?")' x:\(String(format:"%.2f",p.x)) y:\(String(format:"%.2f",p.y)) z:\(String(format:"%.2f",p.z))")
    }
}
