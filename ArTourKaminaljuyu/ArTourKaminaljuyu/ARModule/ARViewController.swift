import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    // MARK: - AR
    private var sceneView:    ARSCNView!
    private var sceneManager: ARSceneManager!

    // MARK: - State
    private var cancellables:     Set<AnyCancellable> = []
    private var activePOI:        POILocation?
    private var lastHeading:      Double              = 0
    private var lastUserLocation: CLLocationCoordinate2D?
    private var hasPlacedModel:   Bool                = false
    private var currentPOIIndex:  Int                 = 0

    // MARK: - Gestures
    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Buttons
    private var repositionButton: UIButton!
    private var siguienteButton:  UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupGestures()
        setupButtons()
        subscribeToGPS()
        preloadModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()

        if let proximity = GPSModuleInterface.shared.nearestPOI,
           proximity.level == .arrived {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.activateModel(for: proximity.poi)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Setup: SceneView
    private func setupSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.automaticallyUpdatesLighting = false

        let ambientLight       = SCNLight()
        ambientLight.type      = .ambient
        ambientLight.intensity = 1000
        ambientLight.color     = UIColor.white
        let ambientNode        = SCNNode()
        ambientNode.light      = ambientLight
        sceneView.scene.rootNode.addChildNode(ambientNode)

        let directionalLight        = SCNLight()
        directionalLight.type       = .directional
        directionalLight.intensity  = 800
        directionalLight.color      = UIColor.white
        let directionalNode         = SCNNode()
        directionalNode.light       = directionalLight
        directionalNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        sceneView.scene.rootNode.addChildNode(directionalNode)

        view.addSubview(sceneView)
        sceneManager = ARSceneManager(sceneView: sceneView)
        sceneView.session.delegate = self
    }

    // MARK: - Setup: Gestures
    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGesture)

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

        panGesture.delegate   = self
        pinchGesture.delegate = self
    }

    // MARK: - Setup: Buttons
    private func setupButtons() {
        // Reposition button — left side
        repositionButton = UIButton(type: .system)
        repositionButton.setTitle("⟳ Reposicionar", for: .normal)
        repositionButton.backgroundColor    = UIColor.systemBlue.withAlphaComponent(0.85)
        repositionButton.setTitleColor(.white, for: .normal)
        repositionButton.titleLabel?.font   = .boldSystemFont(ofSize: 15)
        repositionButton.layer.cornerRadius = 10
        repositionButton.translatesAutoresizingMaskIntoConstraints = false
        repositionButton.addTarget(self, action: #selector(repositionModel), for: .touchUpInside)
        repositionButton.isHidden = true
        view.addSubview(repositionButton)

        // Siguiente button — right side
        siguienteButton = UIButton(type: .system)
        siguienteButton.setTitle("Siguiente ›", for: .normal)
        siguienteButton.backgroundColor    = UIColor.systemGreen.withAlphaComponent(0.85)
        siguienteButton.setTitleColor(.white, for: .normal)
        siguienteButton.titleLabel?.font   = .boldSystemFont(ofSize: 15)
        siguienteButton.layer.cornerRadius = 10
        siguienteButton.translatesAutoresizingMaskIntoConstraints = false
        siguienteButton.addTarget(self, action: #selector(goToNextPOI), for: .touchUpInside)
        siguienteButton.isHidden = true
        view.addSubview(siguienteButton)

        NSLayoutConstraint.activate([
            repositionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            repositionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            repositionButton.widthAnchor.constraint(equalToConstant: 160),
            repositionButton.heightAnchor.constraint(equalToConstant: 44),

            siguienteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            siguienteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            siguienteButton.widthAnchor.constraint(equalToConstant: 130),
            siguienteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - AR Session
    private func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    // MARK: - GPS
    private func subscribeToGPS() {
        GPSModuleInterface.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.lastUserLocation = location
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.$userHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                self?.lastHeading = heading
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.proximityArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.poiArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                self?.activateModel(for: poi)
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .returning, .completed:
                    self?.sceneManager.hideModel()
                    self?.activePOI = nil
                    self?.hasPlacedModel = false
                    self?.currentPOIIndex = 0
                    self?.repositionButton.isHidden = true
                    self?.siguienteButton.isHidden  = true
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Preload
    private func preloadModels() {
        let pois = GPSModuleInterface.shared.allPOIs
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let first = pois.first {
                self.sceneManager.preloadAssets(for: first)
            }
        }
    }

    // MARK: - Activate model
    private func activateModel(for poi: POILocation) {
        if activePOI?.id == poi.id && hasPlacedModel {
            print("[AR] '\(poi.id)' already placed — skip")
            return
        }

        let pois = GPSModuleInterface.shared.allPOIs
        if let index = pois.firstIndex(where: { $0.id == poi.id }) {
            currentPOIIndex = index
        }

        activePOI = poi
        hasPlacedModel = false
        sceneManager.preloadAssets(for: poi)
        waitForTrackingThenPlace(poi: poi, retries: 12)
    }

    // MARK: - Wait for tracking
    private func waitForTrackingThenPlace(poi: POILocation, retries: Int) {
        guard retries > 0 else {
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
            let origin = frame.camera.transform.columns.3
            guard origin.x != 0 || origin.y != 0 || origin.z != 0 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
                }
                return
            }
            placeModelNow(poi: poi)
        default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: retries - 1)
            }
        }
    }

    // MARK: - Place once
    private func placeModelNow(poi: POILocation) {
        guard !hasPlacedModel else { return }
        guard let frame = sceneView.session.currentFrame else { return }
        guard let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation else {
            print("[place] no GPS")
            return
        }

        sceneManager.placeModel(
            for:             poi,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )

        hasPlacedModel = true
        sceneManager.resetUserTransforms()

        let pois = GPSModuleInterface.shared.allPOIs
        repositionButton.isHidden = false
        siguienteButton.isHidden  = currentPOIIndex >= pois.count - 1
    }

    // MARK: - Siguiente
    @objc private func goToNextPOI() {
        let pois = GPSModuleInterface.shared.allPOIs
        let nextIndex = currentPOIIndex + 1
        guard nextIndex < pois.count else {
            siguienteButton.isHidden = true
            return
        }
        guard let frame = sceneView.session.currentFrame,
              let userLocation = lastUserLocation else { return }

        let nextPOI = pois[nextIndex]
        currentPOIIndex = nextIndex
        activePOI = nextPOI
        hasPlacedModel = false

        sceneManager.switchToPOI(
            nextPOI,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )

        hasPlacedModel = true
        sceneManager.resetUserTransforms()
        siguienteButton.isHidden = nextIndex >= pois.count - 1
        print("[AR] switched to POI[\(nextIndex)] '\(nextPOI.id)'")
    }

    // MARK: - Reposition
    @objc private func repositionModel() {
        guard let poi = activePOI,
              let frame = sceneView.session.currentFrame,
              let userLocation = lastUserLocation else { return }

        hasPlacedModel = false
        sceneManager.resetUserTransforms()
        sceneManager.forcePlaceModel(
            for:             poi,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )
        hasPlacedModel = true
    }

    // MARK: - Gesture handlers
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard activePOI != nil, g.state == .changed else { return }
        let t = g.translation(in: sceneView)
        sceneManager.applyRotation(delta: Float(t.x) * 0.1)
        sceneManager.applyVerticalTranslation(delta: Float(-t.y) * 0.0005)
        g.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard activePOI != nil, g.state == .changed else { return }
        let dampened = 1.0 + (Float(g.scale) - 1.0) * 0.3
        sceneManager.applyScale(factor: dampened)
        g.scale = 1.0
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ARViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ g: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

// MARK: - ARSessionDelegate
extension ARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionWasInterrupted(_ session: ARSession) {
        sceneManager.hideModel()
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.resetTracking])

        if let poi = activePOI {
            hasPlacedModel = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.waitForTrackingThenPlace(poi: poi, retries: 12)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let t = frame.timestamp
        guard Int(t) % 5 == 0, t.truncatingRemainder(dividingBy: 1) < 0.05 else { return }
        switch frame.camera.trackingState {
        case .normal: print("[ARSession] tracking:normal  anchors:\(frame.anchors.count)")
        default: break
        }
    }
}
