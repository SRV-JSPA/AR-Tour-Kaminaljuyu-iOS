import ARKit
import SceneKit
import CoreLocation

final class ARSceneManager: NSObject {

    // MARK: - Dependencias

    private weak var sceneView: ARSCNView?

    // MARK: - Estado interno


    private var loadedNodes: [String: SCNNode] = [:]


    private var activeAnchors: [String: ARAnchor] = [:]

    private var visibleNodeID: String?

    var modelRotationY: Float = 0.0

    var modelScale: Float = 1.0

    // MARK: - Init

    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
    }

    // MARK: - Carga de assets

    func preloadAssets(for poi: POILocation) {
        guard loadedNodes[poi.id] == nil else { return }

        let rootNode = SCNNode()

        if poi.parts.isEmpty {
            if let node = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                rootNode.addChildNode(node)
            }
        } else {
            for part in poi.parts {
                if let partNode = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    let s = Float(part.baseScale)
                    partNode.scale = SCNVector3(s, s, s)
                    rootNode.addChildNode(partNode)
                }
            }
        }

        applyBasePOITransforms(to: rootNode, poi: poi)

        rootNode.isHidden = true

        loadedNodes[poi.id] = rootNode
        print("ARSceneManager: assets cargados para \(poi.id)")
    }

    // MARK: - Anclas GPS

    func placeGeoAnchor(for poi: POILocation, in session: ARSession, cameraAltitude: Double) {
        if let old = activeAnchors[poi.id] {
            session.remove(anchor: old)
        }

        let targetAltitude = (cameraAltitude - ARConfig.cameraEyeHeightMeters)
                           + Double(poi.baseAltitudeMeters)

        let coordinate = CLLocationCoordinate2D(
            latitude: poi.coordinate.latitude,		
            longitude: poi.coordinate.longitude
        )
        let geoAnchor = ARGeoAnchor(
            name: poi.id,
            coordinate: coordinate,
            altitude: targetAltitude
        )
        session.add(anchor: geoAnchor)
        activeAnchors[poi.id] = geoAnchor

        print("ARSceneManager: ancla colocada para \(poi.id) alt=\(String(format: "%.2f", targetAltitude))m")
    }

    func placeWorldAnchor(for poi: POILocation, in session: ARSession, cameraTransform: simd_float4x4) {
        if let old = activeAnchors[poi.id] {
            session.remove(anchor: old)
        }
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -ARConfig.modelPlacementDistanceMeters
        let anchorTransform = matrix_multiply(cameraTransform, translation)
        let anchor = ARAnchor(name: poi.id, transform: anchorTransform)
        session.add(anchor: anchor)
        activeAnchors[poi.id] = anchor
    }

    // MARK: - Visibilidad del modelo activo

    func showModel(for poiId: String) {
        if let prev = visibleNodeID, prev != poiId {
            loadedNodes[prev]?.isHidden = true
        }
        loadedNodes[poiId]?.isHidden = false
        visibleNodeID = poiId
    }

    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    // MARK: - Transforms controlados por el usuario (gestos)

    func applyRotation(delta: Float) {
        modelRotationY = (modelRotationY + delta).truncatingRemainder(dividingBy: 360.0)
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

    // MARK: - Privado: construcción de nodo

    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {

        let bundleRoot = Bundle.main.bundleURL
        var modelURL = bundleRoot.appendingPathComponent(modelPath)

        if !FileManager.default.fileExists(atPath: modelURL.path) {
            let fileName = URL(fileURLWithPath: modelPath).lastPathComponent
            modelURL = bundleRoot.appendingPathComponent(fileName)
        }

        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            print("ARSceneManager: modelo no encontrado → \(modelPath)")
            return nil
        }

        let scene: SCNScene
        do {
            scene = try SCNScene(url: modelURL, options: [
                .checkConsistency: false,
                .convertToYUp: true,
                .convertUnitsToMeters: true
            ])
        } catch {
            print("ARSceneManager: error cargando \(modelPath): \(error)")
            return nil
        }

        let modelNode = SCNNode()
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child.clone())
        }

        var textureURL = bundleRoot.appendingPathComponent(texturePath)
        if !FileManager.default.fileExists(atPath: textureURL.path) {
            let texFileName = URL(fileURLWithPath: texturePath).lastPathComponent
            textureURL = bundleRoot.appendingPathComponent(texFileName)
        }

        if FileManager.default.fileExists(atPath: textureURL.path) {
            let material = SCNMaterial()
            material.diffuse.contents  = textureURL
            material.isDoubleSided     = true
            material.lightingModel     = .phong
            material.ambient.contents  = UIColor(white: CGFloat(ARConfig.lightAmbient), alpha: 1.0)

            modelNode.enumerateChildNodes { node, _ in
                node.geometry?.materials = [material]
            }
        } else {
            print("ARSceneManager: textura no encontrada → \(texturePath)")
        }

        return modelNode
    }

    // MARK: - Privado: transformaciones

    private func applyBasePOITransforms(to node: SCNNode, poi: POILocation) {
        let s = Float(poi.baseScale)
        node.scale         = SCNVector3(s, s, s)
        node.eulerAngles.y = Float(poi.baseYawDeg) * (.pi / 180.0)
    }

    private func applyUserTransforms() {
        guard let id = visibleNodeID, let node = loadedNodes[id] else { return }
        node.scale         = SCNVector3(modelScale, modelScale, modelScale)
        node.eulerAngles.y = modelRotationY * (.pi / 180.0)
    }

    // MARK: - Limpieza

    func clear(session: ARSession) {
        activeAnchors.values.forEach { session.remove(anchor: $0) }
        activeAnchors.removeAll()
        loadedNodes.values.forEach { $0.removeFromParentNode() }
        loadedNodes.removeAll()
        visibleNodeID = nil
    }
}

// MARK: - ARSCNViewDelegate

extension ARSceneManager: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let name = anchor.name, let node = loadedNodes[name] else {
            return SCNNode()  
        }
        print("ARSceneManager: nodo listo para \(name)")
        return node
    }
}
