//
//  ARViewController.swift
//  ArTourKaminaljuyu
//
//  Created by Jose Pereira on 3/16/26.
//


//
//  ARViewController.swift
//  ArTourKaminaljuyu
//
//  Módulo AR — Controlador principal
//  Equivalente iOS de: HelloGeoActivity.kt + HelloGeoRenderer.kt (sin UI)
//
//  Lo que hace este archivo:
//    1. Inicia la sesión ARKit (ARGeoTrackingConfiguration o fallback WorldTracking)
//    2. Se suscribe a GPSModuleInterface para recibir eventos de llegada a POIs
//    3. Pre-carga todos los modelos .obj al arrancar
//    4. Activa / oculta el modelo 3D según el estado del tour guiado
//    5. Maneja los gestos de rotación y zoom sobre el modelo activo
//
//  Lo que NO hace:
//    • Mostrar labels, botones, overlays o cualquier elemento de UI → eso va en tu propio módulo
//

import UIKit
import ARKit
import SceneKit
import Combine
import CoreLocation

final class ARViewController: UIViewController {

    // MARK: - AR

    /// Vista que combina la cámara ARKit con el renderizado SceneKit.
    /// Equivalente Android: GLSurfaceView gestionado por SampleRender
    private var sceneView: ARSCNView!

    /// Gestiona anclas y nodos SceneKit (carga .obj, crea ARGeoAnchors, aplica transforms).
    /// Equivalente Android: EarthObjectManager
    private var sceneManager: ARSceneManager!

    /// Configuración activa (ARGeoTracking o WorldTracking como fallback)
    private var arConfiguration: ARConfiguration?

    // MARK: - GPS Integration (Combine)

    /// Suscripciones activas al módulo GPS.
    /// ⚠️ CRÍTICO: deben mantenerse vivas aquí — si se liberan, Combine cancela la suscripción.
    private var cancellables = Set<AnyCancellable>()

    /// POI cuyo modelo está actualmente activo en escena
    private var activePOI: POILocation?

    // MARK: - Gestos

    /// Pan horizontal → rotar modelo en Y
    /// Equivalente Android: GestureDetector → updateRotation() en HelloGeoRenderer
    private var panRecognizer: UIPanGestureRecognizer!

    /// Pinch → escalar modelo
    /// Equivalente Android: ScaleGestureDetector → updateScale() en HelloGeoRenderer
    private var pinchRecognizer: UIPinchGestureRecognizer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configurarSceneView()
        configurarGestos()
        suscribirseAlModuloGPS()    // 🔑 Integración con módulo GPS
        preCargarModelos()          // Carga assets en background antes de que el usuario llegue
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
        // Pan → rotación del modelo activo
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panRecognizer)

        // Pinch → zoom del modelo activo
        pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
    }

    // MARK: - AR Session

    private func iniciarSesionAR() {
        if ARGeoTrackingConfiguration.isSupported {
            // ARGeoTracking: anclas en coordenadas GPS reales — igual que ARCore Geospatial API en Android
            let config = ARGeoTrackingConfiguration()
            config.planeDetection = []
            arConfiguration = config
            sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
            print("✅ ARViewController: ARGeoTrackingConfiguration activa")
        } else {
            // Fallback WorldTracking: modelos posicionados relativos a la cámara
            // (menos preciso pero funciona en todos los dispositivos)
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = []
            arConfiguration = config
            sceneView.session.run(config, options: [.removeExistingAnchors, .resetTracking])
            print("⚠️ ARViewController: fallback a ARWorldTrackingConfiguration")
        }
    }

    // MARK: - 🔑 Integración con Módulo GPS

    /// Suscripción al módulo GPS de Santi.
    /// Este método es el único punto de acoplamiento entre los dos módulos.
    private func suscribirseAlModuloGPS() {

        // ── 1. Usuario llegó a un POI ────────────────────────────────────────
        // GPSModuleInterface emite el POILocation cuando el usuario entra
        // en el radio de llegada (~15m) del montículo activo del tour guiado.
        // Equivalente Android: la condición de proximidad en onDrawFrame de HelloGeoRenderer
        GPSModuleInterface.shared.arrivalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] poi in
                self?.activarModelo(para: poi)
            }
            .store(in: &cancellables)

        // ── 2. Cambio de estado del tour ─────────────────────────────────────
        // .idle / .returning / .completed → ocultar todos los modelos
        // .active → ya manejado por arrivalPublisher arriba
        // Equivalente Android: if (returningToStart) → no renderizar ningún POI
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

    /// Pre-carga los assets de todos los POIs en un hilo de background.
    /// Equivalente Android: EarthObjectManager.ensureAssetsLoaded() llamado en onSurfaceCreated
    private func preCargarModelos() {
        let pois = GPSModuleInterface.shared.allPOIs
        DispatchQueue.global(qos: .background).async { [weak self] in
            for poi in pois {
                self?.sceneManager.preloadAssets(for: poi)
            }
            print("✅ ARViewController: \(pois.count) modelos pre-cargados")
        }
    }

    // MARK: - Activar modelo 3D

    /// Activa el modelo 3D del POI al que el usuario acaba de llegar.
    ///
    /// Replica la lógica de renderCompassAtAnchor en HelloGeoRenderer:
    ///   1. Resetear transforms (modelScale = 1f, modelRotationY = 0f)
    ///   2. Colocar ancla en las coordenadas GPS del POI
    ///   3. Hacer visible el nodo del POI
    private func activarModelo(para poi: POILocation) {
        activePOI = poi

        // Resetear transforms — equivalente Android: modelScale = 1f; modelRotationY = 0f en nextPoi()
        sceneManager.resetUserTransforms()

        if arConfiguration is ARGeoTrackingConfiguration,
           let frame = sceneView.session.currentFrame {
            // Usar altitud de la cámara para calcular la del ancla
            // Equivalente Android: val cameraAlt = earth.cameraGeospatialPose.altitude
            let cameraAlt = frame.camera.transform.columns.3.y  // altitud relativa (metros sobre el suelo)
            sceneManager.placeGeoAnchor(
                for: poi,
                in: sceneView.session,
                cameraAltitude: Double(cameraAlt)
            )
        } else {
            // Fallback: modelo frente a la cámara
            if let transform = sceneView.session.currentFrame?.camera.transform {
                sceneManager.placeWorldAnchor(for: poi, in: sceneView.session, cameraTransform: transform)
            }
        }

        // Hacer visible el nodo de este POI, ocultar los demás
        // Equivalente Android: solo se renderiza el POI con id == currentGuidedPoi.id
        sceneManager.showModel(for: poi.id)

        print("🎯 ARViewController: modelo activo → \(poi.name)")
    }

    // MARK: - Gestos (rotación y zoom)

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard activePOI != nil else { return }
        let delta = gesture.translation(in: sceneView)
        // Equivalente Android: updateRotation(deltaDegrees) — conversión px→grados
        sceneManager.applyRotation(delta: Float(delta.x) * 0.3)
        gesture.setTranslation(.zero, in: sceneView)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard activePOI != nil else { return }
        // Equivalente Android: updateScale(scaleFactor)
        sceneManager.applyScale(factor: Float(gesture.scale))
        gesture.scale = 1.0
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARSession: \(error.localizedDescription)")
        // Reintentar con WorldTracking como fallback
        let fallback = ARWorldTrackingConfiguration()
        fallback.planeDetection = []
        arConfiguration = fallback
        session.run(fallback, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reiniciar tracking al volver al primer plano
        if let config = arConfiguration {
            session.run(config, options: [.removeExistingAnchors, .resetTracking])
        }
    }

    /// Estado del geo-tracking (solo con ARGeoTrackingConfiguration).
    /// Equivalente Android: earth.trackingState en HelloGeoRenderer
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        print("🌍 ARGeoTracking estado: \(geoTrackingStatus.state.rawValue)")
        // Si la localización se pierde, ocultar modelos hasta que se recupere
        if geoTrackingStatus.state != .localized {
            sceneManager.hideAllModels()
        } else if let poi = activePOI {
            // Se recuperó el tracking → restaurar el modelo activo
            sceneManager.showModel(for: poi.id)
        }
    }
}