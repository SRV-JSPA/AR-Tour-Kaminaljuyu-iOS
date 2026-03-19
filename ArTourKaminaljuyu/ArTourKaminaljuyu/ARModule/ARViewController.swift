import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    private var sceneView:    ARSCNView!
    private var sceneManager: ARSceneManager!
    private var cancellables = Set<AnyCancellable>()
    private var activePOI:   POILocation?
    private var lastHeading: Double = 0

    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("\n [ARViewController] viewDidLoad")
        setupSceneView()
        setupGestures()
        subscribeToGPS()
        preloadModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()

        // Si ya hay un POI cercano al entrar a la pestaña AR, mostrarlo
        if let proximity = GPSModuleInterface.shared.nearestPOI,
           proximity.level == .arrived {
            print("[ARViewController] POI ya cercano al aparecer: '\(proximity.poi.id)'")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.activateModel(for: proximity.poi)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        print(" [ARViewController] sesión AR pausada")
    }

    // MARK: - Setup

    private func setupSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask             = [.flexibleWidth, .flexibleHeight]
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
        sceneManager = ARSceneManager(sceneView: sceneView)
        sceneView.session.delegate = self
        print(" [ARViewController] ARSCNView configurado")
    }

    private func setupGestures() {
        panGesture   = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(pinchGesture)
    }

    private func startARSession() {
        let config            = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravity
        sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
        print("[ARViewController] ARWorldTrackingConfiguration iniciada")
    }

    // MARK: - Suscripción al módulo GPS

    private func subscribeToGPS() {
        print("[ARViewController] configurando suscripciones GPS...")

        // ── Heading ─────────────────────────────────────────────────────
        GPSModuleInterface.shared.$userHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                guard let self else { return }
                let changed = abs(heading - self.lastHeading) > 5
                self.lastHeading = heading
                if changed {
                    print("[GPS→AR] heading: \(String(format:"%.1f",heading))°")
                }
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.proximityArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("\n[GPS→AR] proximityArrivedPublisher → '\(poi.id)' '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.poiArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("\n[GPS→AR] poiArrivedPublisher (TourManager) → '\(poi.id)' '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        // ── Estado del tour ─────────────────────────────────────────────
        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                print("[GPS→AR] tourState: \(Self.stateDescription(state))")
                switch state {
                case .returning, .completed:
                    // Al volver o terminar ocultamos el modelo activo
                    self.sceneManager.hideAllModels()
                    self.activePOI = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // ── Distancia y bearing (log cada ~5m de cambio) ─────────────────
        GPSModuleInterface.shared.$distanceToTarget
            .combineLatest(GPSModuleInterface.shared.$bearingToTarget)
            .receive(on: DispatchQueue.main)
            .filter { dist, _ in !dist.isNaN }
            .removeDuplicates { a, b in abs(a.0 - b.0) < 5.0 }
            .sink { dist, bearing in
                print(" [GPS→AR] dist:\(String(format:"%.1f",dist))m bearing:\(String(format:"%.1f",bearing))°")
            }
            .store(in: &cancellables)

        print("📡 [ARViewController] suscripciones GPS OK ")
    }

    // MARK: - Pre-carga

    private func preloadModels() {
        let pois = GPSModuleInterface.shared.allPOIs
        print(" [ARViewController] pre-cargando \(pois.count) modelos...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for poi in pois {
                self?.sceneManager.preloadAssets(for: poi)
            }
            print(" [ARViewController] pre-carga completada (\(pois.count) POIs)")
        }
    }

    // MARK: - Activar modelo

    private func activateModel(for poi: POILocation) {
        // Evitar reactivar el mismo POI si ya está visible
        if activePOI?.id == poi.id {
            print("   ↳ '\(poi.id)' ya activo — skip")
            return
        }

        print("\n [ARViewController] activateModel('\(poi.id)')")
        activePOI = poi
        sceneManager.resetUserTransforms()

        // Esperar a que el tracking esté listo antes de anclar
        waitForTrackingThenPlace(poi: poi, retries: 10)
    }

    /// Reintenta colocar el modelo hasta que el tracking sea .normal.
    /// Máximo `retries` intentos con 0.5s de espera entre cada uno.
    private func waitForTrackingThenPlace(poi: POILocation, retries: Int) {
        guard retries > 0 else {
            print(" Timeout esperando tracking normal — colocando de todos modos")
            placeModelNow(poi: poi)
            return
        }

        guard let frame = sceneView.session.currentFrame else {
            print("  Sin frame AR — reintentando (\(retries) intentos restantes)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
            return
        }

        switch frame.camera.trackingState {
        case .normal:
            placeModelNow(poi: poi)
        case .limited, .notAvailable:
            let state = ARViewController.trackingStateDescription(frame.camera.trackingState)
            print("   tracking:\(state) — reintentando (\(retries) restantes)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
        @unknown default:
            placeModelNow(poi: poi)
        }
    }

    private func placeModelNow(poi: POILocation) {
        guard let frame = sceneView.session.currentFrame else {
            print("  Sin frame al colocar")
            return
        }

        let trackingState = ARViewController.trackingStateDescription(frame.camera.trackingState)
        print("   trackingState al colocar: \(trackingState)")

        // Calcular bearing GPS al POI
        let bearingToPOI: Double
        if let userLocation = GPSModuleInterface.shared.userLocation {
            bearingToPOI = GeoUtils.bearing(from: userLocation, to: poi.coordinate)
            print("   bearingToPOI (GPS): \(String(format:"%.1f",bearingToPOI))°")
        } else {
            bearingToPOI = GPSModuleInterface.shared.bearingToTarget
            print("   userLocation nil — usando bearingToTarget: \(String(format:"%.1f",bearingToPOI))°")
        }

        print("   lastHeading: \(String(format:"%.1f",lastHeading))°")

        sceneManager.placeModel(
            for:             poi,
            in:              sceneView.session,
            cameraTransform: frame.camera.transform,
            userHeading:     lastHeading,
            bearingToPOI:    bearingToPOI
        )

        sceneManager.showModel(for: poi.id)
    }

    // MARK: - Gestos

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard activePOI != nil else { return }
        let d = g.translation(in: sceneView)
        sceneManager.applyRotation(delta: Float(d.x) * 0.3)
        g.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard activePOI != nil else { return }
        sceneManager.applyScale(factor: Float(g.scale))
        g.scale = 1.0
    }

    // MARK: - Helpers

    private static func stateDescription(_ state: TourState) -> String {
        switch state {
        case .idle:                   return "idle"
        case .navigatingToStart:      return "navigatingToStart"
        case .navigatingToPOI(let i): return "navigatingToPOI(\(i))"
        case .atPOI(let i):           return "atPOI(\(i))"
        case .returning:              return "returning"
        case .completed:              return "completed"
        }
    }

    private static func trackingStateDescription(_ s: ARCamera.TrackingState) -> String {
        switch s {
        case .normal:                          return "normal"
        case .notAvailable:                    return "notAvailable"
        case .limited(.initializing):          return "limited(initializing)"
        case .limited(.relocalizing):          return "limited(relocalizing)"
        case .limited(.excessiveMotion):       return "limited(excessiveMotion)"
        case .limited(.insufficientFeatures):  return "limited(insufficientFeatures)"
        default:                               return "unknown"
        }
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        print(" [ARSession] error: \(error.localizedDescription)")
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []; config.worldAlignment = .gravity
        session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print("[ARSession] interrumpida")
        sceneManager.hideAllModels()
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print("[ARSession] reanudada")
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []; config.worldAlignment = .gravity
        session.run(config, options: [.removeExistingAnchors, .resetTracking])
        
        if let poi = activePOI {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.activePOI = nil   // forzar reactivación
                self?.activateModel(for: poi)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    
        let t = frame.timestamp
        if Int(t) % 5 == 0 && t.truncatingRemainder(dividingBy: 1) < 0.05 {
            let ts = ARViewController.trackingStateDescription(frame.camera.trackingState)
            print("[ARSession] tracking:\(ts)  anchors:\(frame.anchors.count)")
        }
    }
}
