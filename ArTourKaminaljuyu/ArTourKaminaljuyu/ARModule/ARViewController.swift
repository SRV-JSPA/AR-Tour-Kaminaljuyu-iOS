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
    private var lastHeading:      Double              = 0
    private var lastUserLocation: CLLocationCoordinate2D?
    private var hasPlacedModel:   Bool                = false
    private var currentPOIIndex:  Int                 = 0

    // MARK: - Gestures
    private var panGesture:   UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!

    // MARK: - Buttons
    private var repositionButton: UIButton!
    private var nextModelButton:  UIButton!

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
        // Next Model — top right
        nextModelButton = UIButton(type: .system)
        nextModelButton.backgroundColor     = UIColor.systemIndigo.withAlphaComponent(0.90)
        nextModelButton.setTitleColor(.white, for: .normal)
        nextModelButton.titleLabel?.font    = .boldSystemFont(ofSize: 15)
        nextModelButton.layer.cornerRadius  = 10
        nextModelButton.layer.shadowColor   = UIColor.black.cgColor
        nextModelButton.layer.shadowOpacity = 0.25
        nextModelButton.layer.shadowOffset  = CGSize(width: 0, height: 2)
        nextModelButton.layer.shadowRadius  = 4
        nextModelButton.translatesAutoresizingMaskIntoConstraints = false
        nextModelButton.addTarget(self, action: #selector(nextModelTapped), for: .touchUpInside)
        view.addSubview(nextModelButton)

        // Reposition — bottom left
        repositionButton = UIButton(type: .system)
        repositionButton.setTitle("⟳ Reposicionar", for: .normal)
        repositionButton.backgroundColor    = UIColor.systemBlue.withAlphaComponent(0.85)
        repositionButton.setTitleColor(.white, for: .normal)
        repositionButton.titleLabel?.font   = .boldSystemFont(ofSize: 15)
        repositionButton.layer.cornerRadius = 10
        repositionButton.translatesAutoresizingMaskIntoConstraints = false
        repositionButton.addTarget(self, action: #selector(repositionTapped), for: .touchUpInside)
        repositionButton.isHidden = true
        view.addSubview(repositionButton)

        NSLayoutConstraint.activate([
            nextModelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            nextModelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextModelButton.widthAnchor.constraint(equalToConstant: 130),
            nextModelButton.heightAnchor.constraint(equalToConstant: 44),

            repositionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            repositionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            repositionButton.widthAnchor.constraint(equalToConstant: 160),
            repositionButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        updateNextModelButton()
    }

    // MARK: - AR Session

    private func startARSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    // MARK: - GPS (location + heading only, zero auto-placement)

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

        // Only clear model if tour ends
        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .returning, .completed:
                    self.sceneManager.clearAll(session: self.sceneView.session)
                    self.hasPlacedModel  = false
                    self.currentPOIIndex = 0
                    self.repositionButton.isHidden = true
                    self.updateNextModelButton()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Next Model

    @objc private func nextModelTapped() {
        let pois = GPSModuleInterface.shared.allPOIs
        guard !pois.isEmpty else { return }

        guard let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation else {
            print("[AR] no GPS location yet"); return
        }
        guard let frame = sceneView.session.currentFrame else {
            print("[AR] no AR frame yet"); return
        }

        // Advance to next POI only after first model is placed
        if hasPlacedModel {
            let next = currentPOIIndex + 1
            guard next < pois.count else {
                print("[AR] already at last POI"); return
            }
            currentPOIIndex = next
        }

        let poi = pois[currentPOIIndex]

        // clearAll + fresh node + new anchor — one call does it all
        sceneManager.placeModel(
            for:             poi,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )

        hasPlacedModel            = true
        repositionButton.isHidden = false
        updateNextModelButton()

        print("[AR] placed POI[\(currentPOIIndex)] '\(poi.id)'")
    }

    // MARK: - Reposition = reset gestures only

    @objc private func repositionTapped() {
        sceneManager.resetGestures()
        print("[AR] gestures reset")
    }

    // MARK: - Button title/color

    private func updateNextModelButton() {
        let pois = GPSModuleInterface.shared.allPOIs
        if !hasPlacedModel {
            nextModelButton.setTitle("▶ Ver Modelo", for: .normal)
            nextModelButton.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.90)
        } else if currentPOIIndex < pois.count - 1 {
            nextModelButton.setTitle("Siguiente ›", for: .normal)
            nextModelButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        } else {
            nextModelButton.setTitle("✓ Último", for: .normal)
            nextModelButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.75)
        }
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
        let t = frame.timestamp
        guard Int(t) % 5 == 0, t.truncatingRemainder(dividingBy: 1) < 0.05 else { return }
        switch frame.camera.trackingState {
        case .normal: print("[ARSession] tracking:normal  anchors:\(frame.anchors.count)")
        default: break
        }
    }
}
