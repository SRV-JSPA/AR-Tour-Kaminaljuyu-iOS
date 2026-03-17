import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TestMapView()
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }

            ARViewControllerWrapper()
                .ignoresSafeArea()
                .tabItem {
                    Label("AR", systemImage: "camera")
                }
        }
    }
}

struct ARViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController()
    }
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}
