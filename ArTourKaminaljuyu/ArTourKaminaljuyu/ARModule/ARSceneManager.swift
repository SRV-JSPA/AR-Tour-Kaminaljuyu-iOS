import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject {

    // MARK: - Dependencias
    private weak var sceneView: ARSCNView?

    // MARK: - Estado interno
    private var loadedNodes:   [String: SCNNode]  = [:]
    private var activeAnchors: [String: ARAnchor] = [:]
    private var nodePOIs:      [String: POILocation] = [:]
    private var visibleNodeID: String?

    var modelRotationY: Float = 0.0
    var modelScale:     Float = 1.0

    // MARK: - Init
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
        print("[ARSceneManager] init OK")
    }

    // MARK: - Preload

    func preloadAssets(for poi: POILocation) {
        print("\n[preloadAssets] '\(poi.id)' parts:\(poi.parts.count) model:'\(poi.modelPath)'")
        guard loadedNodes[poi.id] == nil else {
            print("   ↳ already loaded")
            return
        }

        let rootNode    = SCNNode()
        var partsLoaded = 0

        if poi.parts.isEmpty {
            guard !poi.modelPath.isEmpty else {
                print("   no modelPath and no parts")
                return
            }
            if let n = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                rootNode.addChildNode(n)
                partsLoaded = 1
            }
        } else {
            for (i, part) in poi.parts.enumerated() {
                if let n = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    let s = part.baseScale * ARConfig.globalScaleMultiplier
                    n.scale = SCNVector3(s, s, s)
                    rootNode.addChildNode(n)
                    partsLoaded += 1
                    print("   part[\(i)]: '\(part.modelPath)'")
                } else {
                    print("   part[\(i)] failed: '\(part.modelPath)'")
                }
            }
        }

        rootNode.eulerAngles.y = poi.baseYawDeg * (.pi / 180)
        rootNode.isHidden      = true

        loadedNodes[poi.id] = rootNode
        nodePOIs[poi.id]    = poi

        var geos = 0
        rootNode.enumerateHierarchy { n, _ in if n.geometry != nil { geos += 1 } }
        let expectedScale = poi.baseScale * ARConfig.globalScaleMultiplier
        print("   parts:\(partsLoaded)  geos:\(geos)  expectedFinalScale:\(expectedScale)")
        if geos == 0 { print("NO GEOMETRIES — model won't be visible") }
    }

    // MARK: - Colocar modelo usando posición GPS relativa

    func placeModel(
        for poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {

        if activeAnchors[poi.id] != nil {
            print("[placeModel] '\(poi.id)' ya tiene anchor fijo — skip")
            return
        }

        print("\n[placeModel] '\(poi.id)' — colocando por primera vez")
        print("   userLocation: \(userLocation.latitude), \(userLocation.longitude)")
        print("   heading:\(String(format: "%.1f", userHeading))°")

        if let n = loadedNodes[poi.id] {
            var g = 0
            n.enumerateHierarchy { c, _ in if c.geometry != nil { g += 1 } }
            print("   node preloaded — geos:\(g)  hidden:\(n.isHidden)")
        } else {
            print("NODE NOT PRELOADED")
        }

        let distanceMeters  = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bearingToPoiDeg = GeoUtils.bearing(from: userLocation, to: poi.coordinate)

        print("   distancia GPS: \(String(format: "%.1f", distanceMeters))m")
        print("   bearing al POI: \(String(format: "%.1f", bearingToPoiDeg))°")

        let bearingRelativeDeg = bearingToPoiDeg - userHeading
        let bearingRelativeRad = Float(bearingRelativeDeg * .pi / 180.0)

        print("   bearingRelativo: \(String(format: "%.1f", bearingRelativeDeg))°")

        let dx = Float(distanceMeters) * sin(bearingRelativeRad)
        let dz = -Float(distanceMeters) * cos(bearingRelativeRad)
        let dy = poi.baseAltitudeMeters - Float(ARConfig.cameraEyeHeightMeters)

        print("   offset AR → x:\(String(format: "%.2f", dx)) y:\(String(format: "%.2f", dy)) z:\(String(format: "%.2f", dz))")

        var anchorTransform = matrix_identity_float4x4
        anchorTransform.columns.3.x = cameraTransform.columns.3.x + dx
        anchorTransform.columns.3.y = cameraTransform.columns.3.y + dy
        anchorTransform.columns.3.z = cameraTransform.columns.3.z + dz
        anchorTransform.columns.3.w = 1.0

        let c = cameraTransform.columns.3
        let a = anchorTransform.columns.3
        print("   camPos  x:\(String(format: "%.2f", c.x)) y:\(String(format: "%.2f", c.y)) z:\(String(format: "%.2f", c.z))")
        print("   anchPos x:\(String(format: "%.2f", a.x)) y:\(String(format: "%.2f", a.y)) z:\(String(format: "%.2f", a.z))")

        let anchor = ARAnchor(name: poi.id, transform: anchorTransform)
        session.add(anchor: anchor)
        activeAnchors[poi.id] = anchor
        print("[placeModel] ARAnchor fijo añadido para '\(poi.id)'")
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
            print("[forceReplace] anchor anterior eliminado para '\(poi.id)'")
        }
        placeModel(
            for: poi,
            userLocation: userLocation,
            userHeading: userHeading,
            cameraTransform: cameraTransform,
            in: session
        )
    }

    // MARK: - Visibilidad

    func showModel(for poiId: String) {
        print("\n[showModel] '\(poiId)'")
        if let prev = visibleNodeID, prev != poiId {
            loadedNodes[prev]?.isHidden = true
        }
        if let node = loadedNodes[poiId] {
            node.isHidden = false
            print("   isHidden→false  inScene:\(node.parent != nil)")
        } else {
            print("no node for '\(poiId)'")
        }
        visibleNodeID = poiId
    }

    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    // MARK: - Gestos

    func applyRotation(delta: Float) {
        modelRotationY = (modelRotationY + delta).truncatingRemainder(dividingBy: 360)
        applyUserTransforms()
    }

    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
        print("[gesture] userScale multiplier: \(String(format: "%.5f", modelScale))")
    }

    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        applyUserTransforms()
    }

    // MARK: - Limpieza

    func clear(session: ARSession) {
        activeAnchors.values.forEach { session.remove(anchor: $0) }
        activeAnchors.removeAll()
        loadedNodes.values.forEach { $0.removeFromParentNode() }
        loadedNodes.removeAll()
        nodePOIs.removeAll()
        visibleNodeID = nil
    }

    // MARK: - Privado: construcción de nodo

    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        let bundleURL = Bundle.main.bundleURL
        print("   buildNode: '\(modelPath)'")

        var modelURL = bundleURL.appendingPathComponent(modelPath)

        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let fn = URL(fileURLWithPath: modelPath).lastPathComponent
            modelURL = bundleURL.appendingPathComponent(fn)
        }

        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let base = ((modelPath as NSString).lastPathComponent as NSString).deletingPathExtension
            let ext  = (modelPath as NSString).pathExtension
            if let r = Bundle.main.url(forResource: base, withExtension: ext) {
                modelURL = r
            } else {
                print("modelo no encontrado: '\(modelPath)'")
                return nil
            }
        }

        // Give SceneKit multiple directories to search for textures at load time
        let texturesURL = bundleURL.appendingPathComponent("Textures")
        let modelFolderURL = modelURL.deletingLastPathComponent()

        let scene: SCNScene
        do {
            scene = try SCNScene(url: modelURL, options: [
                .checkConsistency: false,
                .convertToYUp: true,
                .convertUnitsToMeters: true,
                .assetDirectoryURLs: [
                    bundleURL,
                    texturesURL,
                    modelFolderURL
                ]
            ])
        } catch {
            print("SCNScene error: \(error)")
            return nil
        }

        let modelNode = SCNNode()
        scene.rootNode.childNodes.forEach { modelNode.addChildNode($0.clone()) }

        // Fix up all material texture slots
        modelNode.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }

            for material in geometry.materials {
                fixMaterialSlot(material.diffuse,            bundleURL: bundleURL)
                fixMaterialSlot(material.specular,           bundleURL: bundleURL)
                fixMaterialSlot(material.normal,             bundleURL: bundleURL)
                fixMaterialSlot(material.ambientOcclusion,   bundleURL: bundleURL)
                fixMaterialSlot(material.emission,           bundleURL: bundleURL)

                material.isDoubleSided = true
                material.lightingModel = .phong

                // Keep ambient at full brightness so model isn't dark
                material.ambient.contents = UIColor(white: 1.0, alpha: 1.0)
            }
        }

        // Debug: log what each material's diffuse resolved to
        modelNode.enumerateChildNodes { node, _ in
            guard let geo = node.geometry else { return }
            for mat in geo.materials {
                let diffuse = mat.diffuse.contents
                print("   MAT '\(mat.name ?? "?")' diffuse → type:\(type(of: diffuse)) value:\(String(describing: diffuse))")
            }
        }

        // Fallback: if texturePath provided and no material resolved a URL, apply it globally
        if !texturePath.isEmpty {
            var anyTextured = false
            modelNode.enumerateChildNodes { n, _ in
                if let mat = n.geometry?.firstMaterial,
                   mat.diffuse.contents is URL {
                    anyTextured = true
                }
            }

            if !anyTextured {
                print("   modelo sin texturas resueltas — aplicando fallback: '\(texturePath)'")
                if let tURL = findTexture(named: texturePath, in: bundleURL) {
                    let mat = SCNMaterial()
                    mat.diffuse.contents  = tURL
                    mat.isDoubleSided     = true
                    mat.lightingModel     = .phong
                    mat.ambient.contents  = UIColor(white: 1.0, alpha: 1.0)
                    modelNode.enumerateChildNodes { n, _ in
                        if n.geometry != nil { n.geometry?.materials = [mat] }
                    }
                    print("   fallback texture applied")
                } else {
                    print("   fallback texture NOT found: '\(texturePath)'")
                }
            }
        }

        return modelNode
    }

    // MARK: - Fix a single SCNMaterialProperty slot

    private func fixMaterialSlot(
        _ slot: SCNMaterialProperty,
        bundleURL: URL
    ) {
        // Case 1: already a valid URL → nothing to do
        if let url = slot.contents as? URL {
            if FileManager.default.fileExists(atPath: url.path) { return }
            // URL exists but file is missing → try to recover by filename only
            let filename = url.lastPathComponent
            if let fixed = findTexture(named: filename, in: bundleURL) {
                slot.contents = fixed
                print("   slot re-resolved from broken URL: '\(filename)'")
            } else {
                print("   slot broken URL, texture NOT found: '\(filename)'")
            }
            return
        }

        // Case 2: string path — happens when SceneKit can't resolve at load time
        if let contents = slot.contents as? String {
            // Strip Windows absolute paths or any relative prefix — keep only filename
            let filename = URL(fileURLWithPath: contents).lastPathComponent
            if let fixed = findTexture(named: filename, in: bundleURL) {
                slot.contents = fixed
                print("   slot resolved '\(contents)' → '\(filename)'")
            } else {
                print("   slot NOT resolved: '\(contents)' (filename: '\(filename)')")
            }
        }
    }

    // MARK: - Texture search

    private func findTexture(named name: String, in bundleURL: URL) -> URL? {
        // 1. Exact path from bundle root
        let direct = bundleURL.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: direct.path) { return direct }

        // 2. Just the filename at bundle root
        let fileName = URL(fileURLWithPath: name).lastPathComponent
        let directFileName = bundleURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: directFileName.path) { return directFileName }

        // 3. In Textures subfolder
        let inTextures = bundleURL.appendingPathComponent("Textures/\(fileName)")
        if FileManager.default.fileExists(atPath: inTextures.path) { return inTextures }

        // 4. Bundle.main resource lookup by name + extension
        let base = (fileName as NSString).deletingPathExtension
        let ext  = (fileName as NSString).pathExtension
        if let found = Bundle.main.url(forResource: base, withExtension: ext) {
            return found
        }

        // 5. Recursive search through entire bundle
        print("\n=== BUNDLE CONTENTS ===")
        if let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) {
            for case let path as String in enumerator {
                if path.contains("oloBase") || path.contains("reed") ||
                   path.contains("plaster") || path.contains("madera") ||
                   path.contains("clay") || path.contains("Color") {
                    print("   BUNDLE: \(path)")
                }
            }
        }
        print("=== END BUNDLE ===\n")

        return nil
    }

    // MARK: - Privado: transforms del usuario

    private func applyUserTransforms() {
        guard let id  = visibleNodeID,
              let n   = loadedNodes[id],
              let poi = nodePOIs[id] else { return }

        let finalScale  = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        n.scale         = SCNVector3(finalScale, finalScale, finalScale)
        n.eulerAngles.y = modelRotationY * (.pi / 180)
    }
}

// MARK: - ARSCNViewDelegate

extension ARSceneManager: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let name = anchor.name ?? "(none)"
        print("\n[nodeFor anchor] '\(name)'")

        guard let anchorName = anchor.name,
              let node = loadedNodes[anchorName],
              let poi  = nodePOIs[anchorName] else {
            print("   no node/poi for '\(name)' — available: [\(loadedNodes.keys.joined(separator: ", "))]")
            return SCNNode()
        }

        let finalScale = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        node.scale     = SCNVector3(finalScale, finalScale, finalScale)

        var g = 0
        node.enumerateHierarchy { n, _ in if n.geometry != nil { g += 1 } }
        print("   node found — geos:\(g)  hidden:\(node.isHidden)")
        print("   scale: baseScale:\(poi.baseScale) × globalMult:\(ARConfig.globalScaleMultiplier) × userMult:\(modelScale) = \(finalScale)")
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let p = anchor.transform.columns.3
        print("[didAdd] '\(anchor.name ?? "?")'")
        print("   pos x:\(String(format: "%.2f", p.x)) y:\(String(format: "%.2f", p.y)) z:\(String(format: "%.2f", p.z))")
        print("   children:\(node.childNodes.count)")

        if let name = anchor.name, let n = loadedNodes[name] {
            print("   confirmedScale: \(n.scale)")
        }
    }
}
