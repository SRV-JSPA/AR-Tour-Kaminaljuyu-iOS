
import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject {

    private weak var sceneView: ARSCNView?
    private var loadedNodes:   [String: SCNNode]    = [:]
    private var activeAnchors: [String: ARAnchor]   = [:]

 
    private var nodePOIs: [String: POILocation] = [:]

    private var visibleNodeID: String?

    var modelRotationY: Float = 0.0
    var modelScale:     Float = 1.0

    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
        print(" [ARSceneManager] init OK")
    }

    // MARK: - Preload

    func preloadAssets(for poi: POILocation) {
        print("\n[preloadAssets] '\(poi.id)' parts:\(poi.parts.count) model:'\(poi.modelPath)'")
        guard loadedNodes[poi.id] == nil else { print("   ↳ already loaded"); return }

        let rootNode    = SCNNode()
        var partsLoaded = 0

        if poi.parts.isEmpty {
            guard !poi.modelPath.isEmpty else {
                print("    no modelPath and no parts"); return
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
                    print("  part[\(i)]: '\(part.modelPath)'")
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
        print("    parts:\(partsLoaded)  geos:\(geos)  expectedFinalScale:\(expectedScale)")
        if geos == 0 { print("   NO GEOMETRIES — model won't be visible") }
    }

    

    func placeModel(
        for poi: POILocation,
        in session: ARSession,
        cameraTransform: simd_float4x4,
        userHeading: Double,
        bearingToPOI: Double
    ) {
        print("\n[placeModel] '\(poi.id)'")
        print("   heading:\(String(format:"%.1f",userHeading))°  bearing:\(String(format:"%.1f",bearingToPOI))°")

        if let n = loadedNodes[poi.id] {
            var g = 0; n.enumerateHierarchy { c,_ in if c.geometry != nil { g+=1 } }
            print("   node preloaded: geos:\(g)  hidden:\(n.isHidden)  currentScale:\(n.scale)")
        } else {
            print("   NODE NOT PRELOADED")
        }

        if let old = activeAnchors[poi.id] {
            session.remove(anchor: old)
            activeAnchors.removeValue(forKey: poi.id)
        }

        let relDeg    = bearingToPOI - userHeading
        let rad       = Float(relDeg * .pi / 180)
        let dist      = ARConfig.modelPlacementDistanceMeters
        let altOffset = poi.baseAltitudeMeters

        print("   relAngle:\(String(format:"%.1f",relDeg))°  dist:\(dist)m  altOffset:\(altOffset)m")

        let localOffset = simd_float4(dist * sin(rad), altOffset, -dist * cos(rad), 0)
        var rotOnly     = cameraTransform; rotOnly.columns.3 = simd_float4(0, 0, 0, 1)
        let worldOff    = rotOnly * localOffset

        var at       = matrix_identity_float4x4
        at.columns.3 = cameraTransform.columns.3
        at.columns.3.x += worldOff.x
        at.columns.3.y += worldOff.y
        at.columns.3.z += worldOff.z

        let c = cameraTransform.columns.3
        let a = at.columns.3
        print("   camPos  x:\(String(format:"%.2f",c.x)) y:\(String(format:"%.2f",c.y)) z:\(String(format:"%.2f",c.z))")
        print("   anchPos x:\(String(format:"%.2f",a.x)) y:\(String(format:"%.2f",a.y)) z:\(String(format:"%.2f",a.z))")

        let anchor = ARAnchor(name: poi.id, transform: at)
        session.add(anchor: anchor)
        activeAnchors[poi.id] = anchor
        print("   ARAnchor added — name:'\(poi.id)'")
    }

    

    func showModel(for poiId: String) {
        print("\n [showModel] '\(poiId)'")
        if let prev = visibleNodeID, prev != poiId {
            loadedNodes[prev]?.isHidden = true
        }
        if let node = loadedNodes[poiId] {
            node.isHidden = false
            print("   isHidden→false  inScene:\(node.parent != nil)")
        } else {
            print("    no node for '\(poiId)'")
        }
        visibleNodeID = poiId
    }

    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    //

    func applyRotation(delta: Float) {
        modelRotationY = (modelRotationY + delta).truncatingRemainder(dividingBy: 360)
        applyUserTransforms()
    }

    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
        print("[gesture] userScale multiplier: \(String(format:"%.5f", modelScale))")
    }

    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        applyUserTransforms()
    }

    func clear(session: ARSession) {
        activeAnchors.values.forEach { session.remove(anchor: $0) }
        activeAnchors.removeAll()
        loadedNodes.values.forEach { $0.removeFromParentNode() }
        loadedNodes.removeAll()
        nodePOIs.removeAll()
        visibleNodeID = nil
    }

    //

    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        let bundleURL = Bundle.main.bundleURL
        print("   buildNode: '\(modelPath)'")

        var modelURL = bundleURL.appendingPathComponent(modelPath)
        print("      [1] exists:\(FileManager.default.fileExists(atPath:modelURL.path))")

        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let fn = URL(fileURLWithPath: modelPath).lastPathComponent
            modelURL = bundleURL.appendingPathComponent(fn)
            print("      [2] exists:\(FileManager.default.fileExists(atPath:modelURL.path))")
        }

        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let base = ((modelPath as NSString).lastPathComponent as NSString).deletingPathExtension
            let ext  = (modelPath as NSString).pathExtension
            if let r = Bundle.main.url(forResource: base, withExtension: ext) {
                modelURL = r
                print("      [3] Bundle.main.url")
            } else {
                print("      [3] not found")
                if let e = FileManager.default.enumerator(atPath: bundleURL.path) {
                    var any = false
                    for case let p as String in e where p.hasSuffix(".obj") {
                        print("         obj: \(p)"); any = true
                    }
                    if !any { print("         (no .obj files in bundle)") }
                }
                return nil
            }
        }

        let scene: SCNScene
        do {
            scene = try SCNScene(url: modelURL, options: [
                .checkConsistency: false,
                .convertToYUp: true,
                .convertUnitsToMeters: true
            ])
        } catch {
            print("       SCNScene error: \(error)"); return nil
        }

        let modelNode = SCNNode()
        print("       SCNScene OK — childNodes:\(scene.rootNode.childNodes.count)")
        scene.rootNode.childNodes.forEach { modelNode.addChildNode($0.clone()) }

        // Texture
        var tURL = bundleURL.appendingPathComponent(texturePath)
        if !FileManager.default.fileExists(atPath: tURL.path) {
            tURL = bundleURL.appendingPathComponent(
                URL(fileURLWithPath: texturePath).lastPathComponent
            )
        }
        if !FileManager.default.fileExists(atPath: tURL.path) {
            let tb = ((texturePath as NSString).lastPathComponent as NSString).deletingPathExtension
            let te = (texturePath as NSString).pathExtension
            if let r = Bundle.main.url(forResource: tb, withExtension: te) { tURL = r }
        }

        if FileManager.default.fileExists(atPath: tURL.path) {
            let mat = SCNMaterial()
            mat.diffuse.contents  = tURL
            mat.isDoubleSided     = true
            mat.lightingModel     = .phong
            mat.ambient.contents  = UIColor(white: CGFloat(ARConfig.lightAmbient), alpha: 1)
            modelNode.enumerateChildNodes { n, _ in n.geometry?.materials = [mat] }
            print("      texture: \(tURL.lastPathComponent)")
        } else {
            print("    texture not found: '\(texturePath)'")
        }

        return modelNode
    }

    private func applyUserTransforms() {
        guard let id  = visibleNodeID,
              let n   = loadedNodes[id],
              let poi = nodePOIs[id] else { return }
        let base = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        n.scale         = SCNVector3(base, base, base)
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
            print("   no node/poi for '\(name)' — available: [\(loadedNodes.keys.joined(separator:", "))]")
            return SCNNode()
        }

     
        let finalScale = poi.baseScale * ARConfig.globalScaleMultiplier * modelScale
        node.scale     = SCNVector3(finalScale, finalScale, finalScale)


        var g = 0; node.enumerateHierarchy { n,_ in if n.geometry != nil { g+=1 } }
        print("   node found — geos:\(g)  hidden:\(node.isHidden)")
        print("    scale set: baseScale:\(poi.baseScale) × globalMult:\(ARConfig.globalScaleMultiplier) × userMult:\(modelScale) = \(finalScale)")
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let p = anchor.transform.columns.3
        print(" [didAdd] '\(anchor.name ?? "?")'")
        print("   pos x:\(String(format:"%.2f",p.x)) y:\(String(format:"%.2f",p.y)) z:\(String(format:"%.2f",p.z))")
        print("   children:\(node.childNodes.count)")

     
        if let name = anchor.name, let n = loadedNodes[name] {
            print("   confirmedScale: \(n.scale)")
        }
    }
}
