import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    // MARK: - AR
    private var sceneView:    ARSCNView!
    private var sceneManager: ARSceneManager!

    // MARK: - GPS
    private var cancellables        = Set<AnyCancellable>()
    private var activePOI:          POILocation?
    private var lastHeading:        Double = 0
    private var lastUserLocation:   CLLocationCoordinate2D?

    // MARK: - Gestos
    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Test button
    private var testButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("\n✅ [ARViewController] viewDidLoad")
        setupSceneView()
        setupGestures()
        setupTestButton()
        subscribeToGPS()
        preloadModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()

        // Si ya hay un POI cercano al entrar a la pestaña AR, activarlo
        if let proximity = GPSModuleInterface.shared.nearestPOI,
           proximity.level == .arrived {
            print("📍 [AR] POI ya cercano al aparecer: '\(proximity.poi.id)'")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.activateModel(for: proximity.poi)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        print("⏸ [ARViewController] sesión AR pausada")
    }

    // MARK: - Setup: SceneView

    private func setupSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask             = [.flexibleWidth, .flexibleHeight]
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)

        sceneManager = ARSceneManager(sceneView: sceneView)
        sceneView.session.delegate = self
        print("✅ [ARViewController] ARSCNView configurado")
    }

    // MARK: - Setup: Gestos

    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGesture)

        // Pinch deshabilitado por ahora
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.isEnabled = false
        sceneView.addGestureRecognizer(pinchGesture)
    }

    // MARK: - Setup: Test Button

    private func setupTestButton() {
        testButton = UIButton(type: .system)
        testButton.setTitle("🧪 Test AR", for: .normal)
        testButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
        testButton.setTitleColor(.white, for: .normal)
        testButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        testButton.layer.cornerRadius = 10
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(testARModel), for: .touchUpInside)
        view.addSubview(testButton)

        NSLayoutConstraint.activate([
            testButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 160),
            testButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - AR Session

    private func startARSession() {
        let config            = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
        print("✅ [AR] ARWorldTracking con gravityAndHeading iniciado")
    }

    // MARK: - GPS Subscriptions

    private func subscribeToGPS() {
        print("📡 [ARViewController] configurando suscripciones GPS...")

        // ── Guardar ubicación del usuario ────────────────────────────────
        GPSModuleInterface.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] newLocation in
                guard let self else { return }
                self.lastUserLocation = newLocation
            }
            .store(in: &cancellables)

        // ── Guardar heading del usuario ──────────────────────────────────
        GPSModuleInterface.shared.$userHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                guard let self else { return }
                self.lastHeading = heading
            }
            .store(in: &cancellables)

        // ── Re-colocar modelo cuando GPS cambia más de 1 metro ───────────
        GPSModuleInterface.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .removeDuplicates { a, b in
                GeoUtils.distanceInMeters(from: a, to: b) < 1.0
            }
            .sink { [weak self] newLocation in
                guard let self,
                      let poi = self.activePOI,
                      let frame = self.sceneView.session.currentFrame else { return }

                guard case .normal = frame.camera.trackingState else {
                    print("⚠️ [GPS update] tracking no normal — skip re-place")
                    return
                }

                print("📍 [GPS update] re-colocando '\(poi.id)' dist movida >1m")

                self.sceneManager.placeModel(
                    for:             poi,
                    userLocation:    newLocation,
                    userHeading:     self.lastHeading,
                    cameraTransform: frame.camera.transform,
                    in:              self.sceneView.session
                )
                self.sceneManager.showModel(for: poi.id)
            }
            .store(in: &cancellables)

        // ── Re-colocar modelo cuando heading cambia más de 10° ───────────
        GPSModuleInterface.shared.$userHeading
            .receive(on: DispatchQueue.main)
            .removeDuplicates { abs($0 - $1) < 10.0 }
            .sink { [weak self] newHeading in
                guard let self,
                      let poi = self.activePOI,
                      let frame = self.sceneView.session.currentFrame,
                      let userLocation = self.lastUserLocation else { return }

                guard case .normal = frame.camera.trackingState else {
                    print("⚠️ [Heading update] tracking no normal — skip re-place")
                    return
                }

                print("🧭 [Heading update] re-colocando '\(poi.id)' heading:\(String(format: "%.1f", newHeading))°")

                self.sceneManager.placeModel(
                    for:             poi,
                    userLocation:    userLocation,
                    userHeading:     newHeading,
                    cameraTransform: frame.camera.transform,
                    in:              self.sceneView.session
                )
                self.sceneManager.showModel(for: poi.id)
            }
            .store(in: &cancellables)

        // ── Proximidad: disparado al llegar a <= arrivalThresholdMeters ──
        GPSModuleInterface.shared.proximityArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("📍 [GPS→AR] proximityArrived → '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        // ── Tour manager también puede disparar llegada ──────────────────
        GPSModuleInterface.shared.poiArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("📍 [GPS→AR] poiArrived (tour) → '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        // ── Estado del tour ──────────────────────────────────────────────
        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .returning, .completed:
                    self.sceneManager.hideAllModels()
                    self.activePOI = nil
                    print("🔙 [Tour] ocultando modelos")
                default:
                    break
                }
            }
            .store(in: &cancellables)

        print("✅ [ARViewController] suscripciones GPS configuradas")
    }

    // MARK: - Pre-carga de modelos

    private func preloadModels() {
        let pois = GPSModuleInterface.shared.allPOIs
        print("✅ [AR] pre-cargando \(pois.count) modelos...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            pois.forEach { self?.sceneManager.preloadAssets(for: $0) }
            print("✅ [AR] pre-carga completada (\(pois.count) POIs)")
        }
    }

    // MARK: - Activar modelo

    private func activateModel(for poi: POILocation) {
        guard activePOI?.id != poi.id else {
            print("   ↳ '\(poi.id)' ya activo — skip")
            return
        }

        print("\n🎯 [AR] activateModel('\(poi.id)')")
        activePOI = poi
        sceneManager.resetUserTransforms()

        // Asegurarse de que el asset esté cargado
        sceneManager.preloadAssets(for: poi)

        waitForTrackingThenPlace(poi: poi, retries: 12)
    }

    // MARK: - Esperar tracking normal

    private func waitForTrackingThenPlace(poi: POILocation, retries: Int) {
        guard retries > 0 else {
            print("⚠️ Timeout esperando tracking — colocando igualmente")
            placeModelNow(poi: poi)
            return
        }

        guard let frame = sceneView.session.currentFrame else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
            return
        }

        switch frame.camera.trackingState {
        case .normal:
            placeModelNow(poi: poi)
        default:
            print("⏳ tracking no normal — reintentando (\(retries) restantes)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
        }
    }

    // MARK: - Colocar modelo ahora

    private func placeModelNow(poi: POILocation) {
        guard let frame = sceneView.session.currentFrame else {
            print("❌ Sin currentFrame")
            return
        }

        guard let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation else {
            print("❌ Sin ubicación GPS — usando fallback frente a cámara")
            placeFallbackInFrontOfCamera(poi: poi, frame: frame)
            return
        }

        print("✅ [placeModelNow] '\(poi.id)'")
        print("   userLocation: \(userLocation.latitude), \(userLocation.longitude)")
        print("   heading: \(String(format: "%.1f", lastHeading))°")

        sceneManager.placeModel(
            for:             poi,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )

        sceneManager.showModel(for: poi.id)
    }

    // MARK: - Fallback: frente a la cámara si no hay GPS

    private func placeFallbackInFrontOfCamera(poi: POILocation, frame: ARFrame) {
        var t = matrix_identity_float4x4
        t.columns.3.z = -5.0
        let anchorTransform = matrix_multiply(frame.camera.transform, t)
        let anchor = ARAnchor(name: poi.id, transform: anchorTransform)
        sceneView.session.add(anchor: anchor)
        sceneManager.showModel(for: poi.id)
        print("⚠️ [fallback] modelo colocado 5m frente a la cámara")
    }

    // MARK: - Test button

    @objc private func testARModel() {
        guard let poi = GPSModuleInterface.shared.allPOIs.first else {
            print("❌ No hay POIs")
            return
        }
        print("🧪 [test] forzando render de '\(poi.name)'")
        activePOI = nil // forzar reactivación
        activateModel(for: poi)
    }

    // MARK: - Gestos

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard activePOI != nil else { return }
        let d = g.translation(in: sceneView)
        sceneManager.applyRotation(delta: Float(d.x) * 0.3)
        g.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        // Deshabilitado por ahora
        return
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("[ARSession] error: \(error.localizedDescription)")
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print("[ARSession] interrumpida")
        sceneManager.hideAllModels()
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print(" [ARSession] reanudada")
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.resetTracking])

        if let poi = activePOI {
            activePOI = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.activateModel(for: poi)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Log de tracking cada 5 segundos
        let t = frame.timestamp
        if Int(t) % 5 == 0 && t.truncatingRemainder(dividingBy: 1) < 0.05 {
            let ts: String
            switch frame.camera.trackingState {
            case .normal:                         ts = "normal"
            case .notAvailable:                   ts = "notAvailable"
            case .limited(.initializing):         ts = "limited(initializing)"
            case .limited(.relocalizing):         ts = "limited(relocalizing)"
            case .limited(.excessiveMotion):      ts = "limited(excessiveMotion)"
            case .limited(.insufficientFeatures): ts = "limited(insufficientFeatures)"
            default:                              ts = "unknown"
            }
            print("[ARSession] tracking:\(ts)  anchors:\(frame.anchors.count)")
        }
    }
}
