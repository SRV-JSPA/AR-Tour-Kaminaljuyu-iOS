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
    private var cancellables:       Set<AnyCancellable>          = []
    private var activePOI:          POILocation?
    private var lastHeading:        Double                       = 0
    private var lastUserLocation:   CLLocationCoordinate2D?

    // MARK: - Gestures
    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Test button
    private var testButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("\n [ARViewController] viewDidLoad")
        setupSceneView()
        setupGestures()
        setupTestButton()
        subscribeToGPS()
        preloadModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()

        // If we're already near a POI when the AR tab appears, activate it
        if let proximity = GPSModuleInterface.shared.nearestPOI,
           proximity.level == .arrived {
            print(" [AR] POI already nearby on appear: '\(proximity.poi.id)'")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.activateModel(for: proximity.poi)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        print("⏸ [ARViewController] AR session paused")
    }

    // MARK: - Setup: SceneView

    private func setupSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Manual lighting — gives consistent texture brightness regardless of environment
        sceneView.automaticallyUpdatesLighting = false

        let ambientLight       = SCNLight()
        ambientLight.type      = .ambient
        ambientLight.intensity = 1000
        ambientLight.color     = UIColor.white
        let ambientNode        = SCNNode()
        ambientNode.light      = ambientLight
        sceneView.scene.rootNode.addChildNode(ambientNode)

        let directionalLight       = SCNLight()
        directionalLight.type      = .directional
        directionalLight.intensity = 800
        directionalLight.color     = UIColor.white
        let directionalNode        = SCNNode()
        directionalNode.light      = directionalLight
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        sceneView.scene.rootNode.addChildNode(directionalNode)

        view.addSubview(sceneView)
        sceneManager = ARSceneManager(sceneView: sceneView)
        sceneView.session.delegate = self
        print(" [ARViewController] ARSCNView configured")
    }

    // MARK: - Setup: Gestures

    private func setupGestures() {
        // Pan → rotate model around Y axis
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGesture)

        // Pinch → scale model
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

        // Allow both gestures to fire simultaneously
        panGesture.delegate   = self
        pinchGesture.delegate = self
    }

    // MARK: - Setup: Test Button

    private func setupTestButton() {
        testButton = UIButton(type: .system)
        testButton.setTitle(" Test AR", for: .normal)
        testButton.backgroundColor     = UIColor.systemBlue.withAlphaComponent(0.85)
        testButton.setTitleColor(.white, for: .normal)
        testButton.titleLabel?.font    = .boldSystemFont(ofSize: 15)
        testButton.layer.cornerRadius  = 10
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(testARModel), for: .touchUpInside)
        view.addSubview(testButton)

        NSLayoutConstraint.activate([
            testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
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
        print(" [AR] ARWorldTracking with gravityAndHeading started")
    }

    // MARK: - GPS Subscriptions

    private func subscribeToGPS() {
        print(" [ARViewController] setting up GPS subscriptions...")

        // ── Cache user location ──────────────────────────────────────────
        GPSModuleInterface.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.lastUserLocation = location
            }
            .store(in: &cancellables)

        // ── Cache heading ────────────────────────────────────────────────
        GPSModuleInterface.shared.$userHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                self?.lastHeading = heading
            }
            .store(in: &cancellables)

        // ── Proximity arrived ────────────────────────────────────────────
        GPSModuleInterface.shared.proximityArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("📍 [GPS→AR] proximityArrived → '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        // ── Tour manager arrived ─────────────────────────────────────────
        GPSModuleInterface.shared.poiArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                print("📍 [GPS→AR] poiArrived (tour) → '\(poi.name)'")
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        // ── Tour state ───────────────────────────────────────────────────
        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .returning, .completed:
                    self.sceneManager.hideAllModels()
                    self.activePOI = nil
                    print(" [Tour] hiding models")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Preload

    private func preloadModels() {
        let pois = GPSModuleInterface.shared.allPOIs
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            pois.forEach { self.sceneManager.preloadAssets(for: $0) }
        }
    }

    // MARK: - Activate model

    private func activateModel(for poi: POILocation) {
        guard activePOI?.id != poi.id else {
            print("   ↳ '\(poi.id)' already active — skip")
            return
        }

        activePOI = poi
        // Reset gesture state so each new POI starts at default size/rotation
        sceneManager.resetUserTransforms()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.sceneManager.preloadAssets(for: poi)
            DispatchQueue.main.async {
                self.waitForTrackingThenPlace(poi: poi, retries: 12)
            }
        }
    }

    // MARK: - Wait for .normal tracking, then place

    private func waitForTrackingThenPlace(poi: POILocation, retries: Int) {
        guard retries > 0 else {
            print(" [AR] tracking timeout — placing anyway")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
        }
    }

    // MARK: - Place model now

    private func placeModelNow(poi: POILocation) {
        guard let frame = sceneView.session.currentFrame else {
            print(" [place] no current AR frame")
            return
        }

        guard let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation else {
            print(" [place] no GPS — using camera fallback")
            placeFallbackInFrontOfCamera(poi: poi, frame: frame)
            return
        }

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

    // MARK: - Fallback: place 5 m in front of camera when GPS is unavailable

    private func placeFallbackInFrontOfCamera(poi: POILocation, frame: ARFrame) {
        var t = matrix_identity_float4x4
        t.columns.3.z = -5.0
        let anchorTransform = matrix_multiply(frame.camera.transform, t)
        let anchor = ARAnchor(name: poi.id, transform: anchorTransform)
        sceneView.session.add(anchor: anchor)
        sceneManager.showModel(for: poi.id)
    }

    // MARK: - Test button action

    @objc private func testARModel() {
        guard let poi = GPSModuleInterface.shared.allPOIs.first else {
            print(" [test] no POIs available")
            return
        }
        activePOI = nil   // force re-activation even for the same POI
        activateModel(for: poi)
    }

    // MARK: - Gesture handlers

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        // Only rotate/translate while a POI is active and the gesture is moving
        guard activePOI != nil, g.state == .changed else { return }
        let translation = g.translation(in: sceneView)
        // Horizontal → rotate around Y axis
        sceneManager.applyRotation(delta: Float(translation.x) * 0.1)
        // Vertical → move model up/down, clamped to ±1 m
        sceneManager.applyVerticalTranslation(delta: Float(-translation.y) * 0.0005)
        g.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard activePOI != nil else { return }

        if g.state == .changed {
            // g.scale is relative to the last reset, so pass it as a delta factor
            let dampened = 1.0 + (Float(g.scale) - 1.0) * 0.3
            sceneManager.applyScale(factor: dampened)
            // Reset so the next event gives a fresh delta, not a cumulative one
            g.scale = 1.0
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ARViewController: UIGestureRecognizerDelegate {
    /// Allow pan and pinch to fire at the same time (e.g. rotate while scaling)
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool { true }
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
        print("[ARSession] interrupted")
        sceneManager.hideAllModels()
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print("[ARSession] resumed")
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.resetTracking])

        // Re-activate the last POI after a short stabilisation delay
        if let poi = activePOI {
            activePOI = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.activateModel(for: poi)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Log tracking state every ~5 seconds (cheap modulo check)
        let t = frame.timestamp
        guard Int(t) % 5 == 0, t.truncatingRemainder(dividingBy: 1) < 0.05 else { return }

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
