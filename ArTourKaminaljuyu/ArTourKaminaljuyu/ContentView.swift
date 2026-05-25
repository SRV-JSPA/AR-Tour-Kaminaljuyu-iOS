import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter.shared
    @State private var showInstructions = false
    @State private var showTerms = false
    @State private var isLoading = true

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
                // AR siempre cargando en background
                ARTourView()
                    .opacity(router.currentRoute == .guidedTour ? 1 : 0)
                    .allowsHitTesting(router.currentRoute == .guidedTour)
                    .zIndex(-1)

                // Navegación encima
                if router.currentRoute != .guidedTour {
                    NavigationStack {
                        switch router.currentRoute {
                        case .menu:
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

                        case .tourControls:
                            TourControlsView(
                                onBack: { router.navigateTo(.menu) },
                                onStartTour: {
                                    GPSModuleInterface.shared.startTour()
                                    router.navigateTo(.guidedTour)
                                }
                            )
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)

                        default:
                            EmptyView()
                        }
                    }
                    .navigationBarHidden(true)
                }
            }
        }
    }
}

