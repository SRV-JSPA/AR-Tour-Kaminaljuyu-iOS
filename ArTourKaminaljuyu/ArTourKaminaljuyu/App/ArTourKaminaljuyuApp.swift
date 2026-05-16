import SwiftUI
import GoogleMaps

@main
struct ArTourKaminaljuyuApp: App {
    init() {
        let apiKey = Bundle.main.infoDictionary?["GoogleMapsAPIKey"] as? String ?? ""
        GMSServices.provideAPIKey(apiKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
