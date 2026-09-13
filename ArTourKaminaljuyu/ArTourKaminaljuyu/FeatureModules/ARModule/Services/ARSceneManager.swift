import ARKit
import SceneKit
import CoreLocation
import simd

final class ARSceneManager: NSObject, ARSCNViewDelegate {

    // MARK: - Dependencies
    private weak var sceneView: ARSCNView?

    // MARK: - Single model state
    //
    // El modelo del POI se cuelga directamente del sceneRoot (world space) y su
    // simdWorldPosition se recalcula en cada update de GPS a partir de
    // (cameraWorldPosition + delta_GPS). No usamos ARAnchor para el modelo
    // porque en distancias largas (>50m) el drift acumulado de ARKit y el
    // error inicial de heading hacen que la ancla y el POI real se desalineen.
    // El GPS sigue siendo la fuente autoritativa de la posición del POI.
    private var pivotNode:    SCNNode?
    private var activePOI:    POILocation?

    /// True cuando el modelo colocado ya se reveló, es decir, el usuario entró
    /// al radio de `ARConfig.modelVisibilityDistanceMeters`. La UI de AR lo usa
    /// para no dejar avanzar al siguiente montículo sin haber visto el actual.
    private(set) var isActiveModelRevealed: Bool = false

    // MARK: - User gesture accumulators
    var modelRotationY: Float = 0.0
    var modelScale:     Float = 1.0
    var modelOffsetY:   Float = 0.0

    // NOTA: no se aplica escalado adicional por distancia. La perspectiva 3D
    // natural de ARKit ya reduce el tamaño aparente del modelo cuando el
    // usuario está lejos y lo agranda al acercarse — un lerp de escala encima
    // se siente como una animación artificial. Si el modelo se ve "demasiado
    // grande" al llegar al POI, ajustar poi.baseScale en POIRegistry.

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

    /// World-space position of the currently placed model.
    /// Returns nil when no model is loaded. Used by ARGuideArrowManager.
    var activeModelWorldPosition: SIMD3<Float>? {
        guard let pivot = pivotNode else { return nil }
        return pivot.simdWorldPosition
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

        centerPivotContentsHorizontally(pivotNode)

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

    // MARK: - Horizontal centering
    //
    // OBJ meshes are authored with an arbitrary origin (often a corner, not
    // the geometric center), but the pivot's origin is where the AR anchor
    // sits — and the guide arrow points straight at that anchor. Any X/Z gap
    // between mesh origin and mesh center reads as a small angular error from
    // far away, but becomes an obvious "arrow points beside the model" once
    // the user is standing close to it.
    //
    // This recenters the pivot's children on the X/Z plane only (leaving Y
    // untouched, since baseAltitudeMeters per POI is already hand-tuned
    // against the original vertical origin).
    private func centerPivotContentsHorizontally(_ pivotNode: SCNNode) {
        var minV = SCNVector3(Float.greatestFiniteMagnitude, 0, Float.greatestFiniteMagnitude)
        var maxV = SCNVector3(-Float.greatestFiniteMagnitude, 0, -Float.greatestFiniteMagnitude)
        var found = false

        for child in pivotNode.childNodes {
            let (childMin, childMax) = child.boundingBox
            let corners = [
                SCNVector3(childMin.x, 0, childMin.z),
                SCNVector3(childMin.x, 0, childMax.z),
                SCNVector3(childMax.x, 0, childMin.z),
                SCNVector3(childMax.x, 0, childMax.z),
            ]
            for corner in corners {
                let p = child.convertPosition(corner, to: pivotNode)
                minV.x = min(minV.x, p.x); maxV.x = max(maxV.x, p.x)
                minV.z = min(minV.z, p.z); maxV.z = max(maxV.z, p.z)
                found = true
            }
        }
        guard found else { return }

        let centerX = (minV.x + maxV.x) / 2
        let centerZ = (minV.z + maxV.z) / 2
        guard abs(centerX) > 0.0001 || abs(centerZ) > 0.0001 else { return }

        for child in pivotNode.childNodes {
            child.position = SCNVector3(
                child.position.x - centerX,
                child.position.y,
                child.position.z - centerZ
            )
        }
        print("[buildPivot] horizontal recenter applied: offset=(\(centerX), \(centerZ))")
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

        // Posición inicial derivada de GPS + cámara actual. Los siguientes
        // ticks de GPS la re-actualizan vía updateModelPositionFromGPS().
        let camPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let worldPos = worldPositionFromGPS(userLocation: userLocation, cameraWorldPosition: camPos, poi: poi)

        pivot.simdPosition = worldPos
        sceneView?.scene.rootNode.addChildNode(pivot)

        pivotNode = pivot
        activePOI = poi

        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)
        print("[place] '\(poi.id)' dist:\(String(format:"%.1f",dist))m bear:\(String(format:"%.1f",bear))° worldPos:(\(worldPos.x), \(worldPos.y), \(worldPos.z))")

        applyUserTransforms()
        updateVisibility(userLocation: userLocation)
    }

    // MARK: - Recolocación por GPS

    /// Debe llamarse en cada update de GPS mientras haya un modelo colocado.
    /// Recalcula la posición world del modelo como (cámara_actual + delta_GPS),
    /// eliminando el drift acumulado de ARKit.
    func updateModelPositionFromGPS(userLocation: CLLocationCoordinate2D, cameraWorldPosition: SIMD3<Float>) {
        guard let pivot = pivotNode, let poi = activePOI else { return }
        pivot.simdPosition = worldPositionFromGPS(
            userLocation: userLocation,
            cameraWorldPosition: cameraWorldPosition,
            poi: poi
        )
    }

    private func worldPositionFromGPS(
        userLocation: CLLocationCoordinate2D,
        cameraWorldPosition: SIMD3<Float>,
        poi: POILocation
    ) -> SIMD3<Float> {
        let dist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        let bear = GeoUtils.bearing(from: userLocation, to: poi.coordinate)
        let rel = Float(bear * .pi / 180)
        let dx = Float(dist) * sin(rel)
        let dz = Float(dist) * -cos(rel)

        let x = cameraWorldPosition.x + dx
        let z = cameraWorldPosition.z + dz

        // Altura: si la detección de planos ya encontró un plano horizontal bajo
        // el punto, esa es la altura real del suelo y se usa tal cual. Si no —lo
        // habitual mientras el usuario está lejos, porque ARKit solo detecta
        // planos a pocos metros de la cámara— se cae a la baseAltitude del POI
        // relativa a la cámara. En ambos casos se respeta el ajuste vertical
        // manual del usuario (modelOffsetY).
        let y: Float
        if let groundY = detectedGroundY(nearX: x, z: z) {
            y = groundY + modelOffsetY
        } else {
            y = cameraWorldPosition.y + poi.baseAltitudeMeters + modelOffsetY
        }

        return SIMD3<Float>(x, y, z)
    }

    /// Radio horizontal alrededor del punto dentro del cual se acepta un plano
    /// como "el suelo de este montículo".
    private static let planeSearchRadiusMeters: Float = 5.0

    /// Y (world space) del plano horizontal detectado más cercano al punto, o
    /// `nil` si la detección todavía no encontró ninguno dentro del radio.
    /// Solo refina la altura: x/z siguen saliendo del bearing y la distancia
    /// GPS, que son la fuente autoritativa de la posición del POI.
    private func detectedGroundY(nearX x: Float, z: Float) -> Float? {
        guard let anchors = sceneView?.session.currentFrame?.anchors else { return nil }

        var best: (y: Float, distance: Float)?
        for case let plane as ARPlaneAnchor in anchors where plane.alignment == .horizontal {
            // `center` es relativo al transform del plano, por eso se suman.
            let planeX = plane.transform.columns.3.x + plane.center.x
            let planeY = plane.transform.columns.3.y + plane.center.y
            let planeZ = plane.transform.columns.3.z + plane.center.z

            let distance = simd_length(SIMD2<Float>(planeX - x, planeZ - z))
            guard distance <= Self.planeSearchRadiusMeters else { continue }
            if best == nil || distance < best!.distance {
                best = (planeY, distance)
            }
        }
        return best?.y
    }

    // MARK: - Visibility gating by GPS distance

    /// Show the placed model only when the user is within
    /// `ARConfig.modelVisibilityDistanceMeters` of the active POI.
    /// Call on every GPS update.
    func updateVisibility(userLocation: CLLocationCoordinate2D, horizontalAccuracy: Double = 0) {
        guard let pivot = pivotNode, let poi = activePOI else { return }
        let rawDist = GeoUtils.distanceInMeters(from: userLocation, to: poi.coordinate)
        // La distancia cruda nunca baja del ruido del GPS (~precisión), así que
        // un umbral de 5m sería inalcanzable sin compensar la precisión.
        let dist = GeoUtils.compensatedDistance(rawDist, horizontalAccuracy: horizontalAccuracy)

        let shouldShow = dist <= ARConfig.modelVisibilityDistanceMeters
        isActiveModelRevealed = shouldShow
        guard pivot.isHidden == shouldShow else { return }
        pivot.isHidden = !shouldShow
        print("[ARSceneManager] visibility -> \(shouldShow ? "shown" : "hidden") cruda:\(String(format:"%.1f", rawDist))m efectiva:\(String(format:"%.1f", dist))m")
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
        pivotNode?.removeFromParentNode()
        pivotNode  = nil
        activePOI  = nil
        isActiveModelRevealed = false
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
        // La Y world del pivot la controla worldPositionFromGPS (baseAltitude +
        // modelOffsetY). Aquí solo se aplican escala y rotación.
        print("[gesture] scale:\(modelScale) rotY:\(modelRotationY) offsetY:\(modelOffsetY)")
    }

    // ARSCNViewDelegate ya no maneja anclas del modelo (se colgó del sceneRoot).
    // Se conserva la conformidad para futuros usos (planos, imágenes) pero por
    // ahora no se implementan callbacks.
}
