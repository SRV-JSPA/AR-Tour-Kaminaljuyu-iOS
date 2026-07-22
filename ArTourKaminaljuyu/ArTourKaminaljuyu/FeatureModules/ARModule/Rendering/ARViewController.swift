import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation
import SwiftUI

final class ARViewController: UIViewController {

    // MARK: - AR
    private var sceneView:    ARSCNView!
    private var sceneManager: ARSceneManager!
    private var infoButton:   UIButton!

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

        guideArrow = ARGuideArrowManager(sceneView: sceneView)
    }

    // MARK: - Setup: Gestures
    
    @objc private func backTapped() {
        let confirmView = BackConfirmationView(
            onConfirm: { [weak self] in
                self?.dismiss(animated: true) {
                    GPSModuleInterface.shared.stopTour()
                    AppRouter.shared.navigateTo(.menu)
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true)
            }
        )

        let host = UIHostingController(rootView: confirmView)
        host.modalPresentationStyle = .overFullScreen
        host.modalTransitionStyle = .crossDissolve
        host.view.backgroundColor = .clear
        present(host, animated: true)
    }

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
    
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor         = UIColor(red: 0.96, green: 0.92, blue: 0.84, alpha: 0.95) // warm cream
        v.layer.cornerRadius      = 20
        v.layer.shadowColor       = UIColor.black.cgColor
        v.layer.shadowOpacity     = 0.15
        v.layer.shadowOffset      = CGSize(width: 0, height: 3)
        v.layer.shadowRadius      = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeCircleButton(icon: String) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.tintColor             = UIColor(red: 0.75, green: 0.38, blue: 0.10, alpha: 1) // warm orange-brown
        btn.backgroundColor       = UIColor(red: 0.91, green: 0.76, blue: 0.58, alpha: 1) // light tan
        btn.layer.cornerRadius    = 28
        btn.layer.borderWidth     = 2.5
        btn.layer.borderColor     = UIColor(red: 0.75, green: 0.38, blue: 0.10, alpha: 0.6).cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func setupButtons() {
        // ── Left card: Back button (single) ─────────────────────────
        let backCard = makeCard()
        let backBtn  = makeCircleButton(icon: "arrow.uturn.left")
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backCard.addSubview(backBtn)
        view.addSubview(backCard)

        NSLayoutConstraint.activate([
            backBtn.centerXAnchor.constraint(equalTo: backCard.centerXAnchor),
            backBtn.centerYAnchor.constraint(equalTo: backCard.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 56),
            backBtn.heightAnchor.constraint(equalToConstant: 56),

            backCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backCard.widthAnchor.constraint(equalToConstant: 80),
            backCard.heightAnchor.constraint(equalToConstant: 80),
        ])

        // ── Right card: Info + Next stacked ─────────────────────────

        let rightCard = makeCard()

        infoButton = makeCircleButton(icon: "info")
        nextModelButton = makeCircleButton(icon: "play.fill")

        infoButton.isHidden = true

        nextModelButton.addTarget(self,
                                  action: #selector(nextModelTapped),
                                  for: .touchUpInside)

        infoButton.addTarget(self,
                             action: #selector(infoTapped),
                             for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            infoButton,
            nextModelButton
        ])

        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        rightCard.addSubview(stack)
        view.addSubview(rightCard)

        NSLayoutConstraint.activate([

            // button sizes
            infoButton.widthAnchor.constraint(equalToConstant: 56),
            infoButton.heightAnchor.constraint(equalToConstant: 56),

            nextModelButton.widthAnchor.constraint(equalToConstant: 56),
            nextModelButton.heightAnchor.constraint(equalToConstant: 56),

            // stack padding inside card
            stack.topAnchor.constraint(equalTo: rightCard.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: rightCard.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: rightCard.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: rightCard.trailingAnchor, constant: -12),

            // card position
            rightCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            rightCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
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

    // MARK: - GPS

    private func subscribeToGPS() {
        GPSModuleInterface.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }
                self.lastUserLocation = location
                self.sceneManager.updateVisibility(
                    userLocation: location,
                    horizontalAccuracy: GPSModuleInterface.shared.userHorizontalAccuracy
                )
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
                case .idle, .returning, .completed:
                    self.sceneManager.clearAll(session: self.sceneView.session)
                    self.hasPlacedModel  = false
                    self.currentPOIIndex = 0
                    self.infoButton.isHidden = true
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

        let isFirstTap = !hasPlacedModel

        if hasPlacedModel {
            let next = currentPOIIndex + 1
            if next >= pois.count {
                print("[AR] checkmark en último POI — disparando Despedida")
                EventBus.shared.publish(.tourEndRequested)
                return
            }
            currentPOIIndex = next
        }

        let poi = pois[currentPOIIndex]

        sceneManager.placeModel(
            for:             poi,
            userLocation:    userLocation,
            userHeading:     lastHeading,
            cameraTransform: frame.camera.transform,
            in:              sceneView.session
        )

        hasPlacedModel = true
        infoButton.isHidden = false   // ← show info button once model is placed
        updateNextModelButton()

        print("[AR] placed POI[\(currentPOIIndex)] '\(poi.id)'")

        if isFirstTap {
            EventBus.shared.publish(.tourStarted)
        } else {
            EventBus.shared.publish(.nextPOIRequested)
        }
    }

    // MARK: - Info

    @objc private func infoTapped() {
        let pois = GPSModuleInterface.shared.allPOIs
        guard currentPOIIndex < pois.count else { return }
        showPOIInfo(pois[currentPOIIndex])
    }

    private func showPOIInfo(_ poi: POILocation) {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        func makeLabel(_ text: String, font: UIFont, color: UIColor = .label) -> UILabel {
            let l = UILabel()
            l.text          = text
            l.font          = font
            l.textColor     = color
            l.numberOfLines = 0
            return l
        }

        // Title
        stack.addArrangedSubview(makeLabel(poi.name, font: .boldSystemFont(ofSize: 22)))

        // Description
        if !poi.description.isEmpty {
            stack.addArrangedSubview(makeLabel(poi.description,
                                               font: .systemFont(ofSize: 16),
                                               color: .secondaryLabel))
        }

        // Optional extra fields — add only if your POILocation has them
        // Uncomment whichever fields exist on your model:
        //
        // if !poi.constructionPeriod.isEmpty {
        //     stack.addArrangedSubview(makeLabel("Período: \(poi.constructionPeriod)",
        //                                        font: .systemFont(ofSize: 15)))
        // }
        // if !poi.historicalInfo.isEmpty {
        //     stack.addArrangedSubview(makeLabel(poi.historicalInfo,
        //                                        font: .systemFont(ofSize: 15)))
        // }
        // if !poi.culturalSignificance.isEmpty {
        //     stack.addArrangedSubview(makeLabel(poi.culturalSignificance,
        //                                        font: .systemFont(ofSize: 15)))
        // }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 24),
            scroll.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
            scroll.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])

        if let sheet = vc.sheetPresentationController {
            sheet.detents            = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }

        present(vc, animated: true)
    }

    // MARK: - Button state

    private func updateNextModelButton() {
        let pois = GPSModuleInterface.shared.allPOIs
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        if !hasPlacedModel {
            nextModelButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        } else if currentPOIIndex < pois.count - 1 {
            nextModelButton.setImage(UIImage(systemName: "forward.end.fill", withConfiguration: config), for: .normal)
        } else {
            nextModelButton.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
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

// MARK: - BackConfirmationView

struct BackConfirmationView: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @ObservedObject private var languageService = LanguageService.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onCancel() }

            VStack(spacing: 20) {
                Text(languageService.string("back_confirm_title"))
                    .font(.custom("PlusJakartaSans-Bold", size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(languageService.string("back_confirm_message"))
                    .font(.custom("PlusJakartaSans-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                    }

                    Button(action: onConfirm) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color(hex: "#D15B33"))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.black.opacity(0.75))
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}
