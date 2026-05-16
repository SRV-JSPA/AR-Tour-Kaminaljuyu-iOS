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
            NavigationStack {
                switch router.currentRoute {
                case .menu:
                    MainMenuView(
                        onGuidedTour: { router.navigateTo(.guidedTour) },
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

                case .guidedTour:
                    ARTourView()
                        .navigationBarHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
