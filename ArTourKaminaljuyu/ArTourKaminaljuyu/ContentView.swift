import SwiftUI

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
                        }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .guidedTour:
                    VStack(spacing: 0) {
                        Spacer()
                        MapOverlayView()
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.28)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 8)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 24)
                    }
                }
            }
            .onAppear {
                GPSModuleInterface.shared.startTracking()
            }
        }
    }
}
