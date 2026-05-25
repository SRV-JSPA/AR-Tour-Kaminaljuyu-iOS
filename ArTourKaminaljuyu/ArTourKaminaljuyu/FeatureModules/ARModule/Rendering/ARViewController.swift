import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    // MARK: - AR
    private var sceneView:    ARSCNView!
    private var sceneManager: ARSceneManager!

    // MARK: - Guide arrow (3-D flecha.obj, camera-parented)
    private var guideArrow: ARGuideArrowManager!

    // MARK: - State
    private var cancellables:     Set<AnyCancellable> = []
    private var lastHeading:      Double              = 0
    private var lastUserLocation: CLLocationCoordinate2D?
    private var hasPlacedModel:   Bool                = false
    private var currentPOIIndex:  Int                 = 0

    // MARK: - Gestures
    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Buttons
    private var backButton: UIButton!
    private var playButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupGestures()
        setupButtons()
        subscribeToGPS()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
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
        guideArrow = ARGuideArrowManager(sceneView: sceneView)
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
        // Back button — top left
        backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        backButton.tintColor = UIColor(red: 0.82, green: 0.36, blue: 0.20, alpha: 1.0)
        backButton.backgroundColor = UIColor(red: 0.96, green: 0.90, blue: 0.83, alpha: 1.0)
        backButton.layer.cornerRadius = 16
        backButton.layer.borderWidth = 2
        backButton.layer.borderColor = UIColor(red: 0.82, green: 0.36, blue: 0.20, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // Play button — top right
        playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = UIColor(red: 0.82, green: 0.36, blue: 0.20, alpha: 1.0)
        playButton.backgroundColor = UIColor(red: 0.96, green: 0.90, blue: 0.83, alpha: 1.0)
        playButton.layer.cornerRadius = 16
        playButton.layer.borderWidth = 2
        playButton.layer.borderColor = UIColor(red: 0.82, green: 0.36, blue: 0.20, alpha: 1.0).cgColor
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 56),
            backButton.heightAnchor.constraint(equalToConstant: 56),

            playButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playButton.widthAnchor.constraint(equalToConstant: 56),
            playButton.heightAnchor.constraint(equalToConstant: 56),
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

        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .returning, .completed:
                    self.sceneManager.clearAll(session: self.sceneView.session)
                    self.hasPlacedModel = false
                    self.currentPOIIndex = 0
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Button actions

    @objc private func backTapped() {
        AppRouter.shared.navigateTo(.menu)
    }

    @objc private func playTapped() {
        let pois = GPSModuleInterface.shared.allPOIs
        guard !pois.isEmpty else { return }

        guard let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation else {
            print("[AR] no GPS location yet"); return
        }
        guard let frame = sceneView.session.currentFrame else {
            print("[AR] no AR frame yet"); return
        }

        if hasPlacedModel {
            let next = currentPOIIndex + 1
            guard next < pois.count else {
                print("[AR] already at last POI"); return
            }
            currentPOIIndex = next
        }

        let poi = pois[currentPOIIndex]

        sceneManager.placeModel(
            for: poi,
            userLocation: userLocation,
            userHeading: lastHeading,
            cameraTransform: frame.camera.transform,
            in: sceneView.session
        )

        hasPlacedModel = true
        print("[AR] placed POI[\(currentPOIIndex)] '\(poi.id)'")
    }

    // MARK: - Gesture handlers

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard hasPlacedModel, g.state == .changed else { return }
        let t = g.translation(in: sceneView)
        sceneManager.applyRotation(delta: Float(t.x) * 0.1)
        sceneManager.applyVerticalTranslation(delta: Float(-t.y) * 0.0005)
        g.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard hasPlacedModel, g.state == .changed else { return }
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

    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.resetTracking])
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guideArrow.attachToCamera()
        guideArrow.update(modelWorldPosition: sceneManager.activeModelWorldPosition)

        let t = frame.timestamp
        guard Int(t) % 5 == 0, t.truncatingRemainder(dividingBy: 1) < 0.05 else { return }
        switch frame.camera.trackingState {
        case .normal: print("[ARSession] tracking:normal  anchors:\(frame.anchors.count)")
        default: break
        }
    }
}
