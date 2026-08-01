//
//  VirtualGuideModuleInterface.swift
//  ArTourKaminaljuyu
//
//  Puerta pública única del VirtualGuideModule. Consumidores externos NO
//  deben instanciar servicios internos ni observar el estado directamente;
//  deben usar `VirtualGuideModuleInterface.shared`.
//
//  Ruta A del refactor (facade): esta clase ES la interfaz pública del módulo.
//  En un futuro (Ruta B) su lógica interna puede descomponerse en servicios
//  aislados (VideoPlaybackService, VideoQueueManager, ProximityPlaybackController,
//  TranscriptService) sin cambiar la superficie pública expuesta aquí.
//

import SwiftUI
import AVFoundation
import Combine

final class VirtualGuideModuleInterface: ObservableObject {

    static let shared = VirtualGuideModuleInterface()
    private init() {}

    @Published var player: AVPlayer? = nil
    @Published var showsVideo: Bool = false
    @Published var hasPlayedIntro: Bool = false
    @Published var hasStartedWalking: Bool = false

    @Published var transcriptLines: [TranscriptLine] = []
    @Published var currentLineIndex: Int = -1
    @Published var showsTranscript: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var endObserver: NSObjectProtocol?
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?

    private struct QueuedVideo {
        let name: String
        let poiId: String?
        let skipIfCloserThan: Double?
    }

    private var queue: [QueuedVideo] = []
    private var currentVideoName: String? = nil

    private var proximityFired: Set<String> = []
    private var interesFired: Set<String> = []
    private var specificFired: Set<String> = []

    private let proximityTriggerMeters: Double = 15.0
    private let interesTriggerMeters: Double = 10.0
    private let arrivalTriggerMeters: Double = 5.0
    // Debe ser mayor que proximityTriggerMeters: si queda por debajo, entre
    // ambos radios los flags se resetean y el video de proximidad se repite.
    private let resetDistanceMeters: Double = 20.0

    private let videoMap: [String: String] = [
        "monticulo_6": "M CII 5_final",
        "acropolis": "Estructura E_final",
        "monticulo_3": "M CII 13_final"
    ]

    private let videoProximity = "Indicación de proximidad_final"
    private let videoInteres   = "Punto de interés_final"
    private let videoFlecha    = "Indicación flecha_final"
    private let videoDatosGen  = "Datos generales_final"
    private let videoDatosArq  = "Datos arqueológicos_final"
    private let videoDespedida = "Despedida_final"

    private struct LocalizedVideoFile {
        let name: String
        let ext: String
    }

    private let videoLocalizations: [String: [String: LocalizedVideoFile]] = [
        "Datos generales_final": [
            "ES": LocalizedVideoFile(name: "Datos generales_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Importantdata_final", ext: "mov")
        ],
        "Datos arqueológicos_final": [
            "ES": LocalizedVideoFile(name: "Datos arqueológicos_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Archaeologicaldata_final", ext: "mov")
        ],
        "Indicación flecha_final": [
            "ES": LocalizedVideoFile(name: "Indicación flecha_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Arrowindication_final", ext: "mov")
        ],
        "Indicación de proximidad_final": [
            "ES": LocalizedVideoFile(name: "Indicación de proximidad_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Proximityindication_final", ext: "mov")
        ],
        "Punto de interés_final": [
            "ES": LocalizedVideoFile(name: "Punto de interés_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Pointofinterest_final", ext: "mov")
        ],
        "Despedida_final": [
            "ES": LocalizedVideoFile(name: "Despedida_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "Goodbye_final", ext: "mov")
        ],
        "M CII 5_final": [
            "ES": LocalizedVideoFile(name: "M CII 5_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "MCII5_en_final", ext: "mov")
        ],
        "Estructura E_final": [
            "ES": LocalizedVideoFile(name: "Estructura E_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "StructureE_final", ext: "mov")
        ],
        "M CII 13_final": [
            "ES": LocalizedVideoFile(name: "M CII 13_final", ext: "mov"),
            "EN": LocalizedVideoFile(name: "MCII13_en_final", ext: "mov")
        ]
    ]

    private func resolveVideoURL(forKey key: String) -> URL? {
        let lang = LanguageService.shared.currentLanguage
        guard let localized = videoLocalizations[key]?[lang] else {
            print("[VirtualGuide] ⚠ no hay versión en idioma \(lang) para clave: \(key)")
            return nil
        }
        return Bundle.main.url(forResource: localized.name, withExtension: localized.ext)
    }

    private var endingTour: Bool = false

    func start() {
        guard cancellables.isEmpty else { return }
        print("[VirtualGuide] start() — suscribiendo a proximidad + EventBus + AppState")
        configureAudioSession()

        GPSModuleInterface.shared.$nearestPOI
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleProximityUpdate(result)
            }
            .store(in: &cancellables)

        EventBus.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .nextPOIRequested:
                    print("[VirtualGuide] nextPOIRequested — deteniendo video actual y limpiando cola")
                    self.clearQueueAndStop()
                case .tourEndRequested:
                    print("[VirtualGuide] tourEndRequested — reproduciendo despedida")
                    self.playDespedida()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Observación reactiva de AppState — reemplaza al viejo evento .tourStarted.
        // Cuando el tour entra a .inTour (desde ContentView.onStartTour →
        // AppStateManager.startTour()), disparamos startWalking() una sola vez.
        AppStateManager.shared.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                if case .inTour = state, !self.hasStartedWalking {
                    print("[VirtualGuide] AppState -> .inTour — startWalking()")
                    self.startWalking()
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        clearQueueAndStop()
        proximityFired.removeAll()
        interesFired.removeAll()
        specificFired.removeAll()
        hasPlayedIntro = false
        hasStartedWalking = false
        endingTour = false
    }

    func toggleView() {
        guard player != nil else { return }
        showsVideo.toggle()
        print("[VirtualGuide] toggleView -> showsVideo=\(showsVideo)")
    }

    func toggleTranscript() {
        guard player != nil else { return }
        showsTranscript.toggle()
        print("[VirtualGuide] toggleTranscript -> showsTranscript=\(showsTranscript)")
    }

    private func loadTranscript(for videoName: String) {
        let lang = LanguageService.shared.currentLanguage
        guard let cues = VideoTranscripts.cues(for: videoName, language: lang), !cues.isEmpty else {
            print("[VirtualGuide] sin transcripción para \(videoName) en idioma \(lang)")
            DispatchQueue.main.async { [weak self] in
                self?.transcriptLines = []
                self?.currentLineIndex = -1
            }
            return
        }
        let lines = cues.map {
            TranscriptLine(text: $0.text, startTime: $0.startTime, endTime: $0.endTime)
        }
        print("[VirtualGuide] transcript cargado para \(videoName) (\(lang)): \(lines.count) líneas con timestamps reales")
        DispatchQueue.main.async { [weak self] in
            self?.transcriptLines = lines
            self?.currentLineIndex = -1
        }
    }

    private func updateCurrentLine(at seconds: Double) {
        guard !transcriptLines.isEmpty else { return }
        var newIndex = -1
        for (i, line) in transcriptLines.enumerated() {
            if seconds >= line.startTime && seconds < line.endTime {
                newIndex = i
                break
            }
        }
        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
        }
    }

    func playIntroSequence() {
        guard !hasPlayedIntro else { return }
        hasPlayedIntro = true
        print("[VirtualGuide] playIntroSequence — Datos generales + Datos arqueológicos")
        enqueue(videoDatosGen)
        enqueue(videoDatosArq)
    }

    func startWalking() {
        guard !hasStartedWalking else { return }
        hasStartedWalking = true
        print("[VirtualGuide] startWalking — Indicación flecha")

        if let result = GPSModuleInterface.shared.nearestPOI {
            let id = result.poi.id
            let dist = result.effectiveDistanceMeters
            if dist <= proximityTriggerMeters {
                proximityFired.insert(id)
                print("[VirtualGuide] startWalking — POI=\(id) ya está a \(Int(dist))m (≤\(Int(proximityTriggerMeters))m): salto Indicación proximidad")
            }
            if dist <= interesTriggerMeters {
                interesFired.insert(id)
                print("[VirtualGuide] startWalking — POI=\(id) ya está a \(Int(dist))m (≤\(Int(interesTriggerMeters))m): salto Punto de interés")
            }
            if dist <= arrivalTriggerMeters {
                specificFired.insert(id)
                print("[VirtualGuide] startWalking — POI=\(id) ya está a \(Int(dist))m (≤\(Int(arrivalTriggerMeters))m): salto video específico")
            }
        }

        enqueue(videoFlecha)
    }

    private func playDespedida() {
        guard !endingTour else { return }
        endingTour = true
        queue.removeAll()
        clearPlayer()
        enqueue(videoDespedida)
    }

    private func handleProximityUpdate(_ result: ProximityResult?) {
        guard hasStartedWalking, let result = result else { return }
        let id = result.poi.id
        let dist = result.effectiveDistanceMeters

        let fase1 = proximityFired.contains(id) ? "✓" : "·"
        let fase2 = interesFired.contains(id) ? "✓" : "·"
        let fase3 = specificFired.contains(id) ? "✓" : "·"
        print(String(format: "[VirtualGuide] update POI=%@ cruda=%.2fm precisión=%.1fm efectiva=%.2fm umbrales[%@%d/%@%d/%@%d]", id, result.distanceMeters, result.horizontalAccuracy, dist, fase1, Int(proximityTriggerMeters), fase2, Int(interesTriggerMeters), fase3, Int(arrivalTriggerMeters)))

        if dist > resetDistanceMeters {
            if proximityFired.contains(id) || interesFired.contains(id) || specificFired.contains(id) {
                print("[VirtualGuide] reset flags POI=\(id) (dist=\(Int(dist))m > \(Int(resetDistanceMeters))m)")
            }
            proximityFired.remove(id)
            interesFired.remove(id)
            specificFired.remove(id)
            return
        }

        if dist <= proximityTriggerMeters && !proximityFired.contains(id) {
            proximityFired.insert(id)
            print("[VirtualGuide] >>> fase 1 dispara (dist=\(Int(dist))m ≤ \(Int(proximityTriggerMeters))m) POI=\(id) -> Indicación proximidad")
            enqueue(videoProximity, for: id, skipIfCloserThan: interesTriggerMeters)
        }

        if dist <= interesTriggerMeters && !interesFired.contains(id) {
            interesFired.insert(id)
            print("[VirtualGuide] >>> fase 2 dispara (dist=\(Int(dist))m ≤ \(Int(interesTriggerMeters))m) POI=\(id) -> Punto de interés")
            enqueue(videoInteres, for: id, skipIfCloserThan: arrivalTriggerMeters)
        }

        if dist <= arrivalTriggerMeters && !specificFired.contains(id) {
            specificFired.insert(id)
            if let videoName = videoMap[id] {
                print("[VirtualGuide] >>> fase 3 dispara (dist=\(Int(dist))m ≤ \(Int(arrivalTriggerMeters))m) POI=\(id) -> \(videoName)")
                enqueue(videoName, for: id, skipIfCloserThan: nil)
            } else {
                print("[VirtualGuide] >>> fase 3 dispara (dist=\(Int(dist))m ≤ \(Int(arrivalTriggerMeters))m) POI=\(id) sin video específico mapeado")
            }
        }
    }

    private func enqueue(_ videoName: String, for poiId: String? = nil, skipIfCloserThan: Double? = nil) {
        queue.append(QueuedVideo(name: videoName, poiId: poiId, skipIfCloserThan: skipIfCloserThan))
        playNextIfIdle()
    }

    private func playNextIfIdle() {
        guard currentVideoName == nil else { return }
        while !queue.isEmpty {
            let entry = queue.removeFirst()
            if let skipThreshold = entry.skipIfCloserThan,
               let poiId = entry.poiId,
               let result = GPSModuleInterface.shared.nearestPOI,
               result.poi.id == poiId,
               result.effectiveDistanceMeters < skipThreshold {
                print(String(format: "[VirtualGuide] saltando %@: usuario a %.1fm efectivos < %.0fm (fuera de banda relevante)", entry.name, result.effectiveDistanceMeters, skipThreshold))
                continue
            }
            startVideo(named: entry.name)
            return
        }
        if player != nil {
            print("[VirtualGuide] cola vacía después de skips — limpiando player y volviendo al mapa")
            clearPlayer()
        }
    }

    private func clearQueueAndStop() {
        queue.removeAll()
        clearPlayer()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            try session.overrideOutputAudioPort(.speaker)
            let outputs = session.currentRoute.outputs.map { "\($0.portName)/\($0.portType.rawValue)" }.joined(separator: ",")
            print("[VirtualGuide] AVAudioSession OK — cat=\(session.category.rawValue) mode=\(session.mode.rawValue) outputs=[\(outputs)] otherPlaying=\(session.isOtherAudioPlaying)")
        } catch {
            print("[VirtualGuide] ✗ No se pudo configurar AVAudioSession: \(error)")
        }
    }

    private func clearPlayer() {
        print("[VirtualGuide] clearPlayer — player=nil, showsVideo=false")
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        if let obs = periodicTimeObserver {
            player?.removeTimeObserver(obs)
            periodicTimeObserver = nil
        }
        player?.pause()
        currentVideoName = nil
        DispatchQueue.main.async { [weak self] in
            self?.player = nil
            self?.showsVideo = false
            self?.showsTranscript = false
            self?.transcriptLines = []
            self?.currentLineIndex = -1
        }
    }

    private func startVideo(named name: String) {
        guard let url = resolveVideoURL(forKey: name) else {
            print("[VirtualGuide] ✗ Video NO disponible en idioma actual o no encontrado en bundle: \(name)")
            currentVideoName = nil
            playNextIfIdle()
            return
        }
        let t0 = Date()
        print("[VirtualGuide] ▶︎ solicitud de reproducir: \(name).mov")
        currentVideoName = name

        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        if let obs = periodicTimeObserver {
            player?.removeTimeObserver(obs)
            periodicTimeObserver = nil
        }
        player?.pause()

        DispatchQueue.main.async { [weak self] in
            self?.showsTranscript = false
            self?.transcriptLines = []
            self?.currentLineIndex = -1
        }

        configureAudioSession()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = false
        newPlayer.volume = 1.0

        let videoName = name
        loadTranscript(for: videoName)
        itemStatusObserver = item.observe(\.status, options: [.initial, .new]) { item, _ in
            let elapsed = Int(Date().timeIntervalSince(t0) * 1000)
            switch item.status {
            case .readyToPlay:
                print("[VirtualGuide] ✓ item READY_TO_PLAY (\(elapsed)ms): \(videoName)")
            case .failed:
                print("[VirtualGuide] ✗ item FAILED (\(elapsed)ms): \(videoName) — \(item.error?.localizedDescription ?? "desconocido")")
            case .unknown:
                print("[VirtualGuide] · item UNKNOWN (\(elapsed)ms): \(videoName)")
            @unknown default:
                break
            }
        }

        timeControlObserver = newPlayer.observe(\.timeControlStatus, options: [.initial, .new]) { player, _ in
            let elapsed = Int(Date().timeIntervalSince(t0) * 1000)
            let label: String
            switch player.timeControlStatus {
            case .paused: label = "PAUSED"
            case .waitingToPlayAtSpecifiedRate:
                label = "WAITING (reason=\(player.reasonForWaitingToPlay?.rawValue ?? "?"))"
            case .playing: label = "▶︎ PLAYING_REAL"
            @unknown default: label = "?"
            }
            print("[VirtualGuide] timeControlStatus[\(videoName)] @\(elapsed)ms = \(label)")
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            print("[VirtualGuide] ⏹ FIN: \(videoName)")
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentVideoName = nil
                if self.queue.isEmpty {
                    self.clearPlayer()
                    if self.endingTour && videoName == self.videoDespedida {
                        self.endingTour = false
                        EventBus.shared.publish(.tourEndCompleted)
                    }
                } else {
                    self.playNextIfIdle()
                }
            }
        }

        let observerInterval = CMTime(seconds: 0.2, preferredTimescale: 600)
        periodicTimeObserver = newPlayer.addPeriodicTimeObserver(forInterval: observerInterval, queue: .main) { [weak self] time in
            self?.updateCurrentLine(at: time.seconds)
        }

        DispatchQueue.main.async { [weak self] in
            self?.player = newPlayer
            self?.showsVideo = true
            let elapsed = Int(Date().timeIntervalSince(t0) * 1000)
            print("[VirtualGuide] llamando play() (\(elapsed)ms) para \(videoName)")
            newPlayer.play()

            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            print("[VirtualGuide] 📳 vibración háptica disparada para \(videoName)")
        }
    }
}
