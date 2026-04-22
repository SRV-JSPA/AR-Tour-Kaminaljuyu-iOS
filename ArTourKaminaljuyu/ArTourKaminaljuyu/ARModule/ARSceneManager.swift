import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject, ARSCNViewDelegate {

    // MARK: - Dependencies
    private weak var sceneView: ARSCNView?

    // MARK: - Internal state
    // pivotNode owns ALL transforms (scale + Y rotation).
    // It is what SceneKit attaches to the ARAnchor.
    // Child nodes only ever hold part-proportion scale, set once at preload.
    private var loadedNodes:   [String: SCNNode]     = [:]   // poiId → pivotNode
    private var activeAnchors: [String: ARAnchor]    = [:]   // poiId → anchor
    private var nodePOIs:      [String: POILocation] = [:]   // poiId → poi
    private var visibleNodeID: String?

    // User gesture accumulators — reset whenever a new POI activates
    var modelRotationY: Float = 0.0   // degrees
    var modelScale:     Float = 1.0   // multiplier on top of poi.baseScale
    var modelOffsetY:   Float = 0.0   // metres, clamped to -1…+1

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
                    mtlURL = bundleURL.appendingPathComponent(path)
                    break
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
        var currentMat: String?

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("newmtl ") {
                currentMat = String(line.dropFirst("newmtl ".count))
                                .trimmingCharacters(in: .whitespaces)
            } else if line.lowercased().hasPrefix("map_kd "), let mat = currentMat {
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

    // MARK: - Force-apply textures (single pass, nothing runs after this)

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
    //
    // Architecture:
    //   pivotNode  ← attached to ARAnchor by SceneKit
    //     └─ childNode(s)  ← geometry only; scale = part.baseScale (proportion only)
    //
    // globalScaleMultiplier is applied ONCE to pivotNode here.
    // It is NEVER re-applied in applyUserTransforms — that would double-multiply.

    func preloadAssets(for poi: POILocation) {
        guard loadedNodes[poi.id] == nil else {
            print("[preload] '\(poi.id)' already loaded — skip")
            return
        }

        print("\n[preload] '\(poi.id)' model:'\(poi.modelPath)'")

        let pivotNode = SCNNode()

        if poi.parts.isEmpty {
            guard !poi.modelPath.isEmpty else {
                print("   no modelPath and no parts — abort")
                return
            }
            if let n = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                // Child has no extra scale; pivot owns it entirely
                pivotNode.addChildNode(n)
            } else {
                print("   buildNode FAILED for '\(poi.modelPath)'")
            }
        } else {
            for (i, part) in poi.parts.enumerated() {
                if let n = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    // Only bake the inter-part proportion, NOT globalScaleMultiplier
                    let s = part.baseScale
                    n.scale = SCNVector3(s, s, s)
                    pivotNode.addChildNode(n)
                    print("   part[\(i)] loaded — partScale:\(s)")
                } else {
                    print("   part[\(i)] FAILED: '\(part.modelPath)'")
                }
            }
        }

        // Initial pivot scale = baseScale × globalScaleMultiplier (applied once, here)
        let initialScale = poi.baseScale * ARConfig.globalScaleMultiplier
        pivotNode.scale = SCNVector3(initialScale, initialScale, initialScale)

        // Initial yaw via quaternion — no euler angles on pivotNode
        pivotNode.simdOrientation = simd_quatf(
            angle: poi.baseYawDeg * (.pi / 180),
            axis:  SIMD3<Float>(0, 1, 0)
        )
        pivotNode.isHidden = true

        loadedNodes[poi.id] = pivotNode
        nodePOIs[poi.id]    = poi

        var geos = 0
        pivotNode.enumerateHierarchy { n, _ in if n.geometry != nil { geos += 1 } }
        print("[preload] '\(poi.id)' done — geos:\(geos) initialScale:\(initialScale)")
        if geos == 0 { print(" WARNING: NO GEOMETRIES for '\(poi.id)'") }
    }

    // MARK: - Build node from OBJ file

    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        let bundleURL = Bundle.main.bundleURL
        print("  [buildNode] '\(modelPath)'")

        // 1. Locate OBJ — try several strategies
        var modelURL: URL?

        for candidate in [
            bundleURL.appendingPathComponent(modelPath),
            bundleURL.appendingPathComponent(URL(fileURLWithPath: modelPath).lastPathComponent)
        ] {
            if FileManager.default.fileExists(atPath: candidate.path) {
                modelURL = candidate; break
            }
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

        guard let objURL = modelURL else {
            print("  [buildNode] NOT FOUND: '\(modelPath)'")
            return nil
        }
        print("  [buildNode] found: \(objURL.path)")

        // 2. Parse MTL before loading scene
        let mtlMap = parseMTL(forOBJ: objURL)

        // 3. Load SCNScene
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

        // 4. Collect geometry into a single node
        let modelNode = SCNNode()
        scene.rootNode.childNodes.forEach { modelNode.addChildNode($0) }

        // 5. Single texture pass — nothing modifies materials after this
        forceApplyTextures(to: modelNode, mtlMap: mtlMap)

        // 6. Debug count
        var texturedCount = 0
        modelNode.enumerateChildNodes { node, _ in
            guard let geo = node.geometry else { return }
            for mat in geo.materials where mat.diffuse.contents is UIImage { texturedCount += 1 }
        }
        print("  [buildNode] \(texturedCount) textured materials")

        return modelNode
    }

    // MARK: - Place model (one-shot — anchor position never changes)

    func placeModel(
        for poi: POILocation,
        userLocation: CLLocationCoordinate2D,
        userHeading: Double,
        cameraTransform: simd_float4x4,
        in session: ARSession
    ) {
        guard activeAnchors[poi.id] == nil else {
            print("[place] '\(poi.id)' already anchored — skip")
            return
        }

        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)
        let rel  = Float((bear - userHeading) * .pi / 180)
        let adjustedDist = Float(dist) + 5.0  // push it 5m further away
        let dx   =  adjustedDist * sin(rel)
        let dz   = -adjustedDist * cos(rel)
        let dy   = poi.baseAltitudeMeters - Float(ARConfig.cameraEyeHeightMeters)

        var t = matrix_identity_float4x4
        t.columns.3.x = cameraTransform.columns.3.x + dx
        t.columns.3.y = cameraTransform.columns.3.y + dy
        t.columns.3.z = cameraTransform.columns.3.z + dz
        t.columns.3.w = 1

        let anchor = ARAnchor(name: poi.id, transform: t)
        session.add(anchor: anchor)
        activeAnchors[poi.id] = anchor
        print("[place] '\(poi.id)' anchored — dx:\(String(format:"%.2f",dx)) dy:\(String(format:"%.2f",dy)) dz:\(String(format:"%.2f",dz))")
    }

    /// Remove the existing anchor and place a new one at the current position.
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
        // Detach from scene so SceneKit can re-attach it cleanly to the new anchor
        loadedNodes[poi.id]?.removeFromParentNode()

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
            print("[show] no node for '\(poiId)'")
        }
        visibleNodeID = poiId
    }

    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    // MARK: - Gesture interface

    /// Pan delta (pre-scaled by caller, e.g. × 0.1).
    /// Internally clamped to ±5° per call to survive fast swipes.
    func applyRotation(delta: Float) {
        let clamped = max(-5.0, min(5.0, delta))
        guard abs(clamped) > 0.001 else { return }
        modelRotationY = (modelRotationY + clamped).truncatingRemainder(dividingBy: 360)
        applyUserTransforms()
    }

    /// Vertical pan delta in metres (negative = down, positive = up). Clamped to ±1 m.
    func applyVerticalTranslation(delta: Float) {
        modelOffsetY = max(-0.1, min(0.1, modelOffsetY + delta))
        applyUserTransforms()
    }

    /// Pinch factor is a delta (caller resets g.scale = 1.0 each event).
    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
    }

    /// Called when a new POI becomes active.
    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        modelOffsetY   = 0.0
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

    // MARK: - Apply transforms (private)
    //
    // Rules:
    //   • Only pivotNode is touched — never children.
    //   • Scale formula: poi.baseScale × globalScaleMultiplier × modelScale
    //     (globalScaleMultiplier appears once; it was NOT baked into initial pivot scale,
    //      so it belongs here to keep the formula consistent with preload.)
    //
    //   Wait — actually globalScaleMultiplier IS baked at preload time so the formula
    //   here is: poi.baseScale × globalScaleMultiplier × modelScale.
    //   Both preload and applyUserTransforms must agree, so we always compute
    //   the full formula here and let the pivot override whatever preload set.
    //
    //   • Rotation: quaternion around world Y — no gimbal lock, no X/Z bleed.

    private func applyUserTransforms() {
        guard let id    = visibleNodeID,
              let pivot = loadedNodes[id],
              let poi   = nodePOIs[id] else { return }

        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        pivot.scale = SCNVector3(s, s, s)

        let totalYRad = (poi.baseYawDeg + modelRotationY) * (.pi / 180)
        pivot.simdOrientation = simd_quatf(angle: totalYRad, axis: SIMD3<Float>(0, 1, 0))

        // FIX: Set absolute Y, don't accumulate with +=
        pivot.simdPosition = SIMD3<Float>(
            pivot.simdPosition.x,
            modelOffsetY,   // absolute, not +=
            pivot.simdPosition.z
        )
    }

    // MARK: - ARSCNViewDelegate

    /// SceneKit calls this to get the node for a newly added anchor.
    /// We return the already-loaded pivotNode with its current transforms.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let name  = anchor.name,
              let pivot = loadedNodes[name],
              let poi   = nodePOIs[name] else {
            return SCNNode()
        }

        // Clone so each anchor owns its own node instance
        let clone = pivot.clone()

        let s = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        clone.scale           = SCNVector3(s, s, s)
        clone.simdOrientation = simd_quatf(
            angle: (poi.baseYawDeg + modelRotationY) * (.pi / 180),
            axis:  SIMD3<Float>(0, 1, 0)
        )
        clone.simdPosition = SIMD3<Float>(0, modelOffsetY, 0)
        clone.isHidden = pivot.isHidden

        // Replace the tracked node with the clone so gestures affect the right instance
        loadedNodes[name] = clone

        return clone
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let p = anchor.transform.columns.3
        print("[didAdd] '\(anchor.name ?? "?")'  x:\(String(format:"%.2f",p.x))  y:\(String(format:"%.2f",p.y))  z:\(String(format:"%.2f",p.z))")
    }
}
