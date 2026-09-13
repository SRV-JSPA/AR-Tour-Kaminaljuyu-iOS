import SwiftUI
import SwiftUI
import Combine

private struct SkipIntrosButton: View {
    @ObservedObject var viewModel: VirtualGuideModuleInterface
    @EnvironmentObject var languageService: LanguageService
    
    var body: some View {
        Button {
            viewModel.skipIntros()
        } label: {
            Label(languageService.string("skip_intros"), systemImage: "forward.end.fill")
                .font(.custom("PlusJakartaSans-Bold", size: 12))
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

struct GuidedTourOverlay: View {
    @EnvironmentObject var guideVM: VirtualGuideModuleInterface
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var gps: GPSModuleInterface
    @State private var cancellables = Set<AnyCancellable>()
    // El aviso del gesto video/mapa se enseña una sola vez por recorrido,
    // al arrancar el primer video.
    @State private var showsToggleHint = false
    @State private var hasShownToggleHint = false
    private let toggleHintDurationSeconds: Double = 6
    var onTourEnded: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Group {
                if guideVM.player != nil && guideVM.showsVideo {
                    VirtualGuideView(viewModel: guideVM)
                } else {
                    MapOverlayView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.28)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 8)
            .overlay {
                if guideVM.player != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { guideVM.toggleView() }
                }
            }
            .overlay(alignment: .topTrailing) {
                if guideVM.player != nil {
                    VStack(alignment: .trailing, spacing: 8) {
                        if !guideVM.transcriptLines.isEmpty {
                            TranscriptToggleButton(viewModel: guideVM)
                        }
                        VideoMapToggleButton(viewModel: guideVM)
                    }
                    .padding(10)
                }
            }
            .overlay {
                if showsToggleHint {
                    VideoMapToggleHintView()
                        .transition(.opacity)
                }
            }
            #if DEBUG
            .overlay(alignment: .topLeading) {
                if guideVM.player != nil && !guideVM.introSequenceCompleted {
                    SkipIntrosButton(viewModel: guideVM)
                        .padding(10)
                }
            }
            #endif
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
        .onChange(of: guideVM.showsVideo) { _, shows in
            if shows {
                guard !hasShownToggleHint else { return }
                hasShownToggleHint = true
                withAnimation(.easeOut(duration: 0.35)) { showsToggleHint = true }
            } else if showsToggleHint {
                // El usuario ya usó el gesto (o terminó el video): el aviso sobra.
                withAnimation(.easeOut(duration: 0.25)) { showsToggleHint = false }
            }
        }
        .task(id: showsToggleHint) {
            guard showsToggleHint else { return }
            try? await Task.sleep(for: .seconds(toggleHintDurationSeconds))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) { showsToggleHint = false }
        }
        .onAppear {
            // Orden importante: primero se encolan los videos de intro; luego start()
            // subscribe a AppState y, si ya está en .inTour, dispara startWalking()
            // que encola el video de flecha DESPUÉS de los intros.
            guideVM.playIntroSequence()
            guideVM.start()

            EventBus.shared.publisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .tourEndCompleted = event {
                        appState.completeTour()
                        gps.stopTour()
                        onTourEnded()
                    }
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            guideVM.stop()
            cancellables.removeAll()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var gps: GPSModuleInterface
    @State private var isLoading = true
    @State private var showInstructions = false
    @State private var showTerms = false

    var body: some View {
        if isLoading {
            SplashView()
                .task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoading = false
                    }
                }
        } else {
            ZStack {
                // AR always loaded in background
                ARModuleView()
                    .ignoresSafeArea()

                // Navigation on top
                switch router.currentRoute {
                case .menu:
                    NavigationStack {
                        MainMenuView(
                            onGuidedTour: { router.navigateTo(.tourControls) },
                            onFreeTour: {},
                            onInstructions: { showInstructions = true },
                            onTerms: { showTerms = true }
                        )
                        .navigationDestination(isPresented: $showInstructions) {
                            InstructionsView(onBack: { showInstructions = false })
                        }
                        .navigationDestination(isPresented: $showTerms) {
                            TermsView(onBack: { showTerms = false })
                        }
                    }
                    .navigationBarHidden(true)

                case .tourControls:
                    TourControlsView(
                        onBack: { router.navigateTo(.menu) },
                        onStartTour: {
                            // AppStateManager es la fuente autoritativa del inicio del tour.
                            // VirtualGuide observa AppState.currentState y reacciona.
                            appState.startTour()
                            gps.startTour()
                            router.navigateTo(.guidedTour)
                        },
                        onFinalize: {
                            router.navigateTo(.guidedTour)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                EventBus.shared.publish(.tourEndRequested)
                            }
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .guidedTour:
                    GuidedTourOverlay(onTourEnded: { router.navigateTo(.menu) })
                }
            }
            .onAppear {
                gps.startTracking()
            }
        }
    }
}
