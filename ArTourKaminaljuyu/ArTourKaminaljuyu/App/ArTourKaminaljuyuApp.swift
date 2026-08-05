import SwiftUI
import GoogleMaps

@main
struct ArTourKaminaljuyuApp: App {

    // Contenedor central de dependencias. Inyecta cada servicio en el árbol
    // SwiftUI vía `.environmentObject`; los views consumen los que necesiten
    // con `@EnvironmentObject var xxx: XxxService`.
    private let container = AppContainer.production()

    init() {
        let apiKey = Bundle.main.infoDictionary?["GoogleMapsAPIKey"] as? String ?? ""
        GMSServices.provideAPIKey(apiKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.gps)
                .environmentObject(container.language)
                .environmentObject(container.ar)
                .environmentObject(container.virtualGuide)
                .environmentObject(container.appState)
                .environmentObject(container.router)
                .preferredColorScheme(.dark)
        }
    }
}
