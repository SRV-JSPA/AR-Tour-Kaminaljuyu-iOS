import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    // MARK: - AR

    private var sceneView: ARSCNView!

    private var sceneManager: ARSceneManager!

    private var arConfiguration: ARConfiguration?

    // MARK: - GPS Integration (Combine)

    private var cancellables = Set<AnyCancellable>()

    private var activePOI: POILocation?

    // MARK: - Gestos

    private var panRecognizer: UIPanGestureRecognizer!

    private var pinchRecognizer: UIPinchGestureRecognizer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let bundlePath = Bundle.main.bundleURL.path
        print("Bundle root: \(bundlePath)")
        if let enumerator = FileManager.default.enumerator(atPath: bundlePath) {
            for case let path as String in enumerator {
                if path.hasSuffix(".obj") || path.hasSuffix(".jpeg") || path.hasSuffix(".jpg") {
                    print("\(path)")
                }
            }
        }

        configurarSceneView()
        configurarGestos()
        suscribirseAlModuloGPS()
        preCargarModelos()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        iniciarSesionAR()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Setup: SceneView

    private func configurarSceneView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask      = [.flexibleWidth, .flexibleHeight]
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)

        sceneManager = ARSceneManager(sceneView: sceneView)
        sceneView.session.delegate = self
    }

    // MARK: - Setup: Gestos

    private func configurarGestos() {
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panRecognizer)

        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
    }

    // MARK: - AR Session

    private func iniciarSesionAR() {
        if ARGeoTrackingConfiguration.isSupported {
            let config = ARGeoTrackingConfiguration()
            config.planeDetection = []
            arConfiguration = config
            sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
            print("ARViewController: ARGeoTrackingConfiguration activa")
        } else {            let config = ARWorldTrackingConfiguration()
            config.planeDetection = []
            arConfiguration = config
            sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
            print("ARViewController: fallback a ARWorldTrackingConfiguration")
        }
    }

    // MARK: - Integración con Módulo GPS

    private func suscribirseAlModuloGPS() {
        GPSModuleInterface.shared.poiArrivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                self?.activarModelo(para: poi)
            }
            .store(in: &cancellables)

        GPSModuleInterface.shared.$tourState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle, .returning, .completed:
                    self.sceneManager.hideAllModels()
                    self.activePOI = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func preCargarModelos() {
        let pois = GPSModuleInterface.shared.allPOIs
        DispatchQueue.global(qos: .background).async { [weak self] in
            for poi in pois {
                self?.sceneManager.preloadAssets(for: poi)
            }
            print("ARViewController: \(pois.count) modelos pre-cargados")
        }
    }

    // MARK: - Activar modelo 3D

    private func activarModelo(para poi: POILocation) {
        activePOI = poi

        sceneManager.resetUserTransforms()

        if arConfiguration is ARGeoTrackingConfiguration,
           let frame = sceneView.session.currentFrame {
            let cameraAlt = frame.camera.transform.columns.3.y
            sceneManager.placeGeoAnchor(
                for: poi,
                in: sceneView.session,
                cameraAltitude: Double(cameraAlt)
            )
        } else {
            if let transform = sceneView.session.currentFrame?.camera.transform {
                sceneManager.placeWorldAnchor(for: poi, in: sceneView.session, cameraTransform: transform)
            }
        }

        sceneManager.showModel(for: poi.id)

        print("ARViewController: modelo activo → \(poi.name)")
    }

    // MARK: - Gestos (rotación y zoom)

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard activePOI != nil else { return }
        let delta = gesture.translation(in: sceneView)
        sceneManager.applyRotation(delta: Float(delta.x) * 0.3)
        gesture.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard activePOI != nil else { return }
        sceneManager.applyScale(factor: Float(gesture.scale))
        gesture.scale = 1.0
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession: \(error.localizedDescription)")
        let fallback = ARWorldTrackingConfiguration()
        fallback.planeDetection = []
        arConfiguration = fallback
        session.run(fallback, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        if let config = arConfiguration {
            session.run(config, options: [.removeExistingAnchors, .resetTracking])
        }
    }

    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        print("ARGeoTracking estado: \(geoTrackingStatus.state.rawValue)")
        if geoTrackingStatus.state != .localized {
            sceneManager.hideAllModels()
        } else if let poi = activePOI {
            sceneManager.showModel(for: poi.id)
        }
    }
}
