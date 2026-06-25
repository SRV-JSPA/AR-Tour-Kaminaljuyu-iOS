import SwiftUI
import Combine

struct GuidedTourOverlay: View {
    @StateObject private var guideVM = VirtualGuideViewModel()
    @State private var cancellables = Set<AnyCancellable>()
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
                if guideVM.player != nil && !guideVM.transcriptLines.isEmpty {
                    TranscriptToggleButton(viewModel: guideVM)
                        .padding(10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
        .onAppear {
            guideVM.start()
            guideVM.playIntroSequence()

            EventBus.shared.publisher
                .receive(on: DispatchQueue.main)
                .sink { event in
                    if case .tourEndCompleted = event {
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
    @StateObject private var router = AppRouter.shared
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
                ARViewControllerWrapper()
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
                            GPSModuleInterface.shared.startTour()
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
                GPSModuleInterface.shared.startTracking()
            }
        }
    }
}
