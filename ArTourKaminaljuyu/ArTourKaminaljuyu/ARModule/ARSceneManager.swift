//
//  ARSceneManager.swift
//  ArTourKaminaljuyu
//
//  Created by Jose Pereira on 3/16/26.
//


//
//  ARSceneManager.swift
//  ArTourKaminaljuyu
//
//  Módulo AR — Gestión de anclas y modelos 3D
//  Equivalente iOS de: EarthObjectManager.kt + renderCompassAtAnchor() de HelloGeoRenderer.kt
//
//  Responsabilidades (sin UI):
//    • Cargar archivos .obj + texturas de cada POI en memoria
//    • Crear ARGeoAnchor en las coordenadas GPS del montículo
//    • Aplicar las transformaciones del POI: escala, altitud, rotación Y base
//    • Mostrar / ocultar el nodo del POI activo en el tour guiado
//    • Responder a gestos de rotación y zoom sobre el modelo activo
//

import ARKit
import SceneKit
import CoreLocation

final class ARSceneManager: NSObject {

    // MARK: - Dependencias

    private weak var sceneView: ARSCNView?

    // MARK: - Estado interno

    /// Cache de nodos SceneKit ya cargados, indexados por poi.id
    /// Equivalente Android: objectMeshes + objectTextures en EarthObjectManager
    private var loadedNodes: [String: SCNNode] = [:]

    /// Anclas ARKit activas, indexadas por poi.id
    /// Equivalente Android: anchors: HashMap<String, Anchor>
    private var activeAnchors: [String: ARAnchor] = [:]

    /// ID del POI cuyo nodo está actualmente visible
    private var visibleNodeID: String?

    /// Rotación Y aplicada por el usuario (grados)
    /// Equivalente Android: modelRotationY en HelloGeoRenderer
    var modelRotationY: Float = 0.0

    /// Escala multiplicativa aplicada por el usuario
    /// Equivalente Android: modelScale en HelloGeoRenderer
    var modelScale: Float = 1.0

    // MARK: - Init

    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        super.init()
        sceneView.delegate = self
    }

    // MARK: - Carga de assets

    /// Carga en memoria el/los nodo(s) SceneKit de un POI.
    /// Equivalente Android: EarthObjectManager.ensureAssetsLoaded()
    ///
    /// Llamar para cada POI al arrancar la app (pre-carga en background)
    /// para que el modelo esté listo cuando el usuario llegue al montículo.
    func preloadAssets(for poi: POILocation) {
        guard loadedNodes[poi.id] == nil else { return }  // Ya cargado

        let rootNode = SCNNode()

        if poi.parts.isEmpty {
            // ── Modelo simple: un solo .obj + una textura ──
            // Equivalente Android: Mesh.createFromAsset + Texture.createFromAsset
            if let node = buildNode(modelPath: poi.modelPath, texturePath: poi.texturePath) {
                rootNode.addChildNode(node)
            }
        } else {
            // ── Modelo multi-parte: varios .obj ensamblados ──
            // Equivalente Android: poi.parts.forEach { part -> objectMeshes[part.modelPath] }
            for part in poi.parts {
                if let partNode = buildNode(modelPath: part.modelPath, texturePath: part.texturePath) {
                    // Escala específica de la parte
                    // Equivalente Android: part.baseScale aplicado individualmente
                    let s = Float(part.baseScale)
                    partNode.scale = SCNVector3(s, s, s)
                    rootNode.addChildNode(partNode)
                }
            }
        }

        // Aplicar transformaciones base del POI (escala + rotación Y base)
        // Equivalente Android: Matrix.scaleM / Matrix.rotateM con baseScale y baseYawDeg
        //   en renderCompassAtAnchor de HelloGeoRenderer
        applyBasePOITransforms(to: rootNode, poi: poi)

        // Oculto hasta que arrivalPublisher lo active
        rootNode.isHidden = true

        loadedNodes[poi.id] = rootNode
        print("📦 ARSceneManager: assets cargados para \(poi.id)")
    }

    // MARK: - Anclas GPS

    /// Crea un ARGeoAnchor en las coordenadas del POI y lo añade a la sesión.
    /// Equivalente Android: EarthObjectManager.place(earth, poi)
    ///
    /// El cálculo de altitud replica la lógica Android:
    ///   targetAltitude = (cameraAlt - CAMERA_EYE_HEIGHT_METERS) + poi.baseAltitudeMeters
    ///
    /// - Requires: ARGeoTrackingConfiguration activa y estado .localized
    func placeGeoAnchor(for poi: POILocation, in session: ARSession, cameraAltitude: Double) {
        // Quitar ancla anterior del mismo POI si existe
        if let old = activeAnchors[poi.id] {
            session.remove(anchor: old)
        }

        let targetAltitude = (cameraAltitude - ARConfig.cameraEyeHeightMeters)
                           + poi.baseAltitudeMeters

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

        print("📍 ARSceneManager: ancla colocada para \(poi.id) alt=\(String(format: "%.2f", targetAltitude))m")
    }

    /// Fallback sin ARGeoTracking: coloca el ancla 3m al frente de la cámara.
    /// Equivalente Android: no existe — Android siempre usa Earth anchors.
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

    /// Muestra el nodo del POI indicado y oculta todos los demás.
    /// Equivalente Android: la condición `if (renderGuidedPoi)` en onDrawFrame de HelloGeoRenderer —
    /// solo se renderiza el POI actual del tour guiado.
    func showModel(for poiId: String) {
        if let prev = visibleNodeID, prev != poiId {
            loadedNodes[prev]?.isHidden = true
        }
        loadedNodes[poiId]?.isHidden = false
        visibleNodeID = poiId
    }

    /// Oculta todos los modelos (fase de retorno al inicio, o tour no activo).
    /// Equivalente Android: `if (returningToStart)` — no se renderiza ningún POI
    func hideAllModels() {
        loadedNodes.values.forEach { $0.isHidden = true }
        visibleNodeID = nil
    }

    // MARK: - Transforms controlados por el usuario (gestos)

    /// Actualiza la rotación Y del modelo visible.
    /// Equivalente Android: updateRotation(deltaDegrees) en HelloGeoRenderer
    func applyRotation(delta: Float) {
        modelRotationY = (modelRotationY + delta).truncatingRemainder(dividingBy: 360.0)
        applyUserTransforms()
    }

    /// Actualiza la escala del modelo visible.
    /// Equivalente Android: updateScale(scaleFactor) en HelloGeoRenderer
    func applyScale(factor: Float) {
        modelScale = max(ARConfig.minScale, min(ARConfig.maxScale, modelScale * factor))
        applyUserTransforms()
    }

    /// Resetea escala y rotación al cambiar de POI.
    /// Equivalente Android: modelScale = 1f; modelRotationY = 0f en nextPoi()
    func resetUserTransforms() {
        modelScale     = 1.0
        modelRotationY = 0.0
        applyUserTransforms()
    }

    // MARK: - Privado: construcción de nodo

    /// Carga un .obj del bundle y le aplica una textura.
    /// Equivalente Android: Mesh.createFromAsset + Texture.createFromAsset
    private func buildNode(modelPath: String, texturePath: String) -> SCNNode? {
        guard let modelURL = Bundle.main.url(forResource: modelPath, withExtension: nil) else {
            print("⚠️ ARSceneManager: modelo no encontrado → \(modelPath)")
            return nil
        }

        let scene: SCNScene
        do {
            scene = try SCNScene(url: modelURL, options: [
                .checkConsistency: false,
                .convertToYUp: true,         // Ejes consistentes con ARKit (Y hacia arriba)
                .convertUnitsToMeters: true  // .obj suele estar en unidades propias; normalizamos a metros
            ])
        } catch {
            print("❌ ARSceneManager: error cargando \(modelPath): \(error)")
            return nil
        }

        let modelNode = SCNNode()
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child.clone())
        }

        // Aplicar textura
        // Equivalente Android: shader.setTexture("u_Texture", texture)
        if let textureURL = Bundle.main.url(forResource: texturePath, withExtension: nil) {
            let material = SCNMaterial()
            material.diffuse.contents  = textureURL
            material.isDoubleSided     = true
            material.lightingModel     = .phong
            // Equivalente Android: u_Ambient y u_Diffuse en el shader GLSL
            material.ambient.contents  = UIColor(white: CGFloat(ARConfig.lightAmbient), alpha: 1.0)

            modelNode.enumerateChildNodes { node, _ in
                node.geometry?.materials = [material]
            }
        }

        return modelNode
    }

    // MARK: - Privado: transformaciones

    /// Aplica la escala base y la rotación Y base del POI al nodo raíz.
    /// Equivalente Android en renderCompassAtAnchor:
    ///   Matrix.scaleM(modelMatrix, 0, baseScale, baseScale, baseScale)
    ///   Matrix.rotateM(modelMatrix, 0, baseYaw, 0, 1, 0)
    private func applyBasePOITransforms(to node: SCNNode, poi: POILocation) {
        let s = Float(poi.baseScale)
        node.scale         = SCNVector3(s, s, s)
        node.eulerAngles.y = Float(poi.baseYawDeg) * (.pi / 180.0)
    }

    /// Aplica encima la escala y rotación del usuario al nodo actualmente visible.
    /// Equivalente Android:
    ///   val effectiveScale = modelScale * poi.baseScale
    ///   Matrix.rotateM(modelMatrix, 0, modelRotationY, 0, 1, 0)
    private func applyUserTransforms() {
        guard let id = visibleNodeID, let node = loadedNodes[id] else { return }
        node.scale         = SCNVector3(modelScale, modelScale, modelScale)
        node.eulerAngles.y = modelRotationY * (.pi / 180.0)
    }

    // MARK: - Limpieza

    /// Elimina todas las anclas de la sesión y limpia el cache de nodos.
    /// Equivalente Android: EarthObjectManager.clear()
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

    /// Cuando ARKit confirma que un ancla está lista, devuelve el nodo SceneKit precargado.
    /// Equivalente Android: el bloque que en onDrawFrame evalúa anchor.pose y dibuja la malla.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let name = anchor.name, let node = loadedNodes[name] else {
            return SCNNode()  // Nodo vacío para anclas que no son nuestras
        }
        print("🖼️ ARSceneManager: nodo listo para \(name)")
        return node
    }
}