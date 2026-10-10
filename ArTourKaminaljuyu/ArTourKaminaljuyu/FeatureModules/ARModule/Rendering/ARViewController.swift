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
                    AppStateManager.shared.reset()
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
        config.planeDetection = [.horizontal, .vertical]
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
                // Recolocar el modelo desde la cámara actual + delta GPS. Esto
                // evita el drift acumulado de ARKit sobre distancias largas.
                if let frame = self.sceneView.session.currentFrame {
                    let camPos = SIMD3<Float>(
                        frame.camera.transform.columns.3.x,
                        frame.camera.transform.columns.3.y,
                        frame.camera.transform.columns.3.z
                    )
                    self.sceneManager.updateModelPositionFromGPS(
                        userLocation: location,
                        cameraWorldPosition: camPos
                    )
                }
                self.sceneManager.updateVisibility(
                    userLocation: location,
                    horizontalAccuracy: GPSModuleInterface.shared.userHorizontalAccuracy
                )
                // El botón de avanzar depende de si el modelo ya se reveló, así
                // que se reevalúa con cada lectura de GPS mientras el usuario camina.
                self.updateNextModelButton()
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

        // El botón Next se destraba por dos señales del VirtualGuide:
        //   introSequenceCompleted: la secuencia de intro terminó (o se saltó).
        //   currentPOIVideoCompleted: el video del POI activo ya terminó.
        VirtualGuideModuleInterface.shared.$introSequenceCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateNextModelButton() }
            .store(in: &cancellables)

        VirtualGuideModuleInterface.shared.$currentPOIVideoCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateNextModelButton() }
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

        // Ningún tap procede hasta que termine la secuencia de intro. El primer
        // tap coloca el modelo del POI activo; los siguientes avanzan al POI
        // N+1 sólo si (a) el video del POI actual ya terminó y (b) el usuario
        // está dentro del radio de llegada al POI actual.
        guard VirtualGuideModuleInterface.shared.introSequenceCompleted else {
            print("[AR] Next bloqueado: intros aún en curso")
            return
        }

        let isFirstTap = !hasPlacedModel

        if hasPlacedModel {
            guard VirtualGuideModuleInterface.shared.currentPOIVideoCompleted else {
                print("[AR] Next bloqueado: video del POI actual sigue en curso")
                return
            }

            let currentPOI = pois[currentPOIIndex]
            let dist = GeoUtils.distanceInMeters(from: userLocation, to: currentPOI.coordinate)
            guard dist <= AppConfig.guidedArrivalMeters else {
                print("[AR] Next bloqueado: usuario a \(Int(dist))m del POI actual (radio \(Int(AppConfig.guidedArrivalMeters))m)")
                return
            }

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

        // .tourStarted es ahora derivado por AppStateManager (state observation) —
        // ARModule solo publica solicitudes explícitas del usuario.
        if !isFirstTap {
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
        stack.addArrangedSubview(makeLabel(poi.localizedName, font: .boldSystemFont(ofSize: 22)))

        // Fotos del montículo, entre el título y el texto. El set NO depende del
        // idioma: las mismas imágenes se muestran en español y en inglés, y se
        // agregan antes que la descripción para que aparezcan aunque ese idioma
        // todavía no tenga transcripción cargada.
        if let gallery = makePOIImagesSection(for: poi) {
            stack.addArrangedSubview(gallery)
        }

        // Description
        let desc = VirtualGuideModuleInterface.shared.poiDescription(forPOIId: poi.id)
        if !desc.isEmpty {
            stack.addArrangedSubview(makeLabel(desc,
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

    // MARK: - POI images

    /// Fotos de cada montículo, en el orden en que se muestran en la ficha.
    /// La llave es el `id` del POI tal como está en `POIRegistry`.
    ///
    /// Las imágenes son independientes del idioma: este mismo set se usa en
    /// español y en inglés, solo cambia el texto que las acompaña.
    ///
    /// La correspondencia sale de las transcripciones de cada video en
    /// `VideoTranscripts.swift`, que describen exactamente lo que ilustra cada
    /// foto (p. ej. el monumento 224 de C-II-13 "tallado en sus cuatro lados"
    /// es `c_ii_13.jpg`, con las cuatro caras numeradas 1-4 en la imagen).
    ///
    /// Las `etapa*` son las etapas constructivas de la Estructura E
    /// (`palangana`), ordenadas de la más antigua a la más reciente. El video
    /// las narra al revés (de la más reciente a la más antigua): para seguir ese
    /// orden basta con invertir el array.
    private static let poiImageNames: [String: [String]] = [
        "acropolis": [
            "Assets/Images/c_ii_4.png"      // diagrama talud-tablero
        ],
        "monticulo_8": [
            "Assets/Images/c_ii_8.png"      // fragmento de monumento
        ],
        "monticulo_12": [
            "Assets/Images/c_ii_12.png",    // depósito cultural
            "Assets/Images/c_ii_12_2.png"   // figurilla
        ],
        "monticulo_13": [
            "Assets/Images/c_ii_13.jpg",    // monumento 224, sus cuatro lados
            "Assets/Images/c_ii_13_2.png",  // escalinatas superpuestas
            "Assets/Images/c_ii_13_3.jpg"   // drenajes + vasija esqueletizada
        ],
        "palangana": [
            "Assets/Images/etapa1.png",     // Etapa 1
            "Assets/Images/etapa2a.png",    // Subetapa 2-A
            "Assets/Images/etapa2b.png",    // Subetapa 2-B
            "Assets/Images/etapa2c.png",    // Subetapa 2-C
            "Assets/Images/etapa3a.png",    // Subetapa 3-A
            "Assets/Images/etapa3.png"      // Subetapa 3-C
        ]
    ]

    /// Acepta nombres de asset catalog ("c_ii_4"), rutas relativas dentro del
    /// bundle ("Assets/Images/etapa1.png") y archivos sueltos ("etapa1.png").
    /// El proyecto usa carpetas sincronizadas de Xcode, así que un recurso puede
    /// quedar con su ruta o aplanado en la raíz del bundle: se prueban ambas y,
    /// como último recurso, se recorre el bundle buscando por nombre de archivo
    /// (mismo enfoque que ARSceneManager usa para modelos y texturas).
    private func resolvePOIImage(named name: String) -> UIImage? {
        if let image = UIImage(named: name) { return image }

        let base = (name as NSString).deletingPathExtension
        if base != name, let image = UIImage(named: base) { return image }

        let bundleURL = Bundle.main.bundleURL
        let filename  = (name as NSString).lastPathComponent

        for candidate in [
            bundleURL.appendingPathComponent(name),
            bundleURL.appendingPathComponent(filename)
        ] where FileManager.default.fileExists(atPath: candidate.path) {
            if let image = UIImage(contentsOfFile: candidate.path) { return image }
        }

        let ext = (name as NSString).pathExtension
        if let url = Bundle.main.url(forResource: (filename as NSString).deletingPathExtension,
                                     withExtension: ext.isEmpty ? "png" : ext),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        if let enumerator = FileManager.default.enumerator(atPath: bundleURL.path) {
            for case let path as String in enumerator
            where (path as NSString).lastPathComponent == filename {
                return UIImage(contentsOfFile: bundleURL.appendingPathComponent(path).path)
            }
        }
        return nil
    }

    /// Alto de las miniaturas cuando el montículo tiene más de una foto.
    private static let poiThumbnailHeight: CGFloat = 150

    /// Construye la sección de fotos de la ficha con las imágenes que le
    /// corresponden a este POI. Una sola foto ocupa el ancho completo; con
    /// varias se arma una fila horizontal desplazable. Devuelve `nil` si el POI
    /// no tiene fotos asignadas o si ninguna se pudo cargar, para no dejar un
    /// hueco vacío en la ficha.
    private func makePOIImagesSection(for poi: POILocation) -> UIView? {
        let names = Self.poiImageNames[poi.id] ?? []
        guard !names.isEmpty else { return nil }

        let images = names.compactMap { name -> UIImage? in
            guard let image = resolvePOIImage(named: name) else {
                print("[AR] no se pudo cargar la imagen '\(name)'")
                return nil
            }
            return image
        }
        guard !images.isEmpty else { return nil }
        guard images.count > 1 else { return makePOIImageView(images[0]) }

        let row = UIStackView(arrangedSubviews: images.map { makePOIThumbnail($0) })
        row.axis      = .horizontal
        row.spacing   = 8
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            scroll.heightAnchor.constraint(equalToConstant: Self.poiThumbnailHeight)
        ])
        return scroll
    }

    /// Miniatura de alto fijo para la fila horizontal; el ancho sale de la
    /// proporción de la foto, así ninguna se deforma. Igual que la versión de
    /// ancho completo, al tapearla se abre a pantalla completa con zoom.
    private func makePOIThumbnail(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode        = .scaleAspectFit
        imageView.clipsToBounds      = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let ratio = image.size.height > 0 ? image.size.width / image.size.height : 1
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: Self.poiThumbnailHeight),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor,
                                             multiplier: ratio)
        ])

        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(poiImageTapped(_:)))
        )
        return imageView
    }

    private func makePOIImageView(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode     = .scaleAspectFit
        imageView.clipsToBounds   = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Equivalente a un <img> con width:100%; height:auto — la foto se ve
        // completa y conserva su proporción, sin recortes ni franjas vacías.
        if image.size.width > 0, image.size.height > 0 {
            imageView.heightAnchor.constraint(
                equalTo:    imageView.widthAnchor,
                multiplier: image.size.height / image.size.width
            ).isActive = true
        } else {
            imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        }

        // Al tapearla se abre a pantalla completa y con zoom.
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(poiImageTapped(_:)))
        )
        return imageView
    }

    @objc private func poiImageTapped(_ gesture: UITapGestureRecognizer) {
        guard let image = (gesture.view as? UIImageView)?.image else { return }

        let viewer = POIImageViewerController(image: image)
        viewer.modalPresentationStyle = .fullScreen
        viewer.modalTransitionStyle   = .crossDissolve

        // La ficha del POI ya está presentada sobre este controller, así que hay
        // que presentar desde la de más arriba y no desde `self`.
        var top: UIViewController = self
        while let presented = top.presentedViewController { top = presented }
        top.present(viewer, animated: true)
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

        // Reglas de habilitación del botón Next:
        //   - Los intros deben haber terminado (o sido saltados).
        //   - Primer tap (colocar modelo): sólo requiere intros listos. Sin
        //     modelo colocado la flecha guía no tiene ancla, así que este tap
        //     no depende de proximidad ni de video de POI.
        //   - Taps siguientes (avanzar): además exigen que el video del POI
        //     activo terminó y que el usuario esté dentro del radio de llegada.
        //     Esas condiciones se re-chequean en nextModelTapped para no depender
        //     sólo del estado de UI.
        let guide = VirtualGuideModuleInterface.shared
        let introsReady = guide.introSequenceCompleted

        let canAdvance: Bool
        if !hasPlacedModel {
            canAdvance = introsReady
        } else {
            canAdvance = introsReady
                && guide.currentPOIVideoCompleted
                && isUserWithinArrivalRadiusOfActivePOI()
        }
        nextModelButton.isEnabled = canAdvance
        nextModelButton.alpha     = canAdvance ? 1.0 : 0.4
    }

    private func isUserWithinArrivalRadiusOfActivePOI() -> Bool {
        let pois = GPSModuleInterface.shared.allPOIs
        guard currentPOIIndex < pois.count,
              let userLocation = lastUserLocation ?? GPSModuleInterface.shared.userLocation
        else { return false }
        let dist = GeoUtils.distanceInMeters(from: userLocation, to: pois[currentPOIIndex].coordinate)
        return dist <= AppConfig.guidedArrivalMeters
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
        config.planeDetection = [.horizontal, .vertical]
        config.worldAlignment = .gravityAndHeading
        session.run(config, options: [.removeExistingAnchors, .resetTracking])
    }

    func sessionWasInterrupted(_ session: ARSession) {}

    func sessionInterruptionEnded(_ session: ARSession) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
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

// MARK: - POIImageViewerController

/// Visor a pantalla completa de una foto de la ficha del montículo.
/// Pinch o doble tap para acercar, un tap (o la X) para cerrar.
final class POIImageViewerController: UIViewController, UIScrollViewDelegate {

    private let image: UIImage
    private let scrollView = UIScrollView()
    private let imageView  = UIImageView()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no soportado")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.delegate                       = self
        scrollView.minimumZoomScale               = 1.0
        scrollView.maximumZoomScale               = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator   = false
        view.addSubview(scrollView)

        imageView.image       = image
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleClose))
        singleTap.require(toFail: doubleTap)   // sin esto, el doble tap cerraría el visor
        scrollView.addGestureRecognizer(singleTap)

        setupCloseButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        // Solo se reencuadra sin zoom: hacerlo con zoom aplicado pelearía con el
        // transform que UIScrollView le pone a la vista que está ampliando.
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            imageView.frame        = scrollView.bounds
            scrollView.contentSize = scrollView.bounds.size
        }
    }

    private func setupCloseButton() {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor          = .white
        button.backgroundColor    = UIColor.black.withAlphaComponent(0.45)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func handleDoubleTap() {
        let zoomedOut = scrollView.zoomScale <= scrollView.minimumZoomScale
        scrollView.setZoomScale(zoomedOut ? scrollView.maximumZoomScale / 2
                                          : scrollView.minimumZoomScale,
                                animated: true)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
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
