//
//  MockServices.swift
//  ArTourKaminaljuyuTests
//
//  Mocks de los servicios principales para testing aislado.
//  Estos mocks permiten testear la lógica sin depender de singletons
//  compartidos que causan race conditions en tests paralelos.
//

import Foundation
import Combine
import CoreLocation
@testable import ArTourKaminaljuyu

// MARK: - Mock AppStateManager

final class MockAppStateManager: ObservableObject {
    @Published var currentState: AppState = .idle
    @Published var activePOIId: String? = nil
    
    var startTourCalled = false
    var setActivePOICalled = false
    var completeTourCalled = false
    var resetCalled = false
    
    func startTour() {
        startTourCalled = true
        currentState = .inTour(activePOIId: nil)
    }
    
    func setActivePOI(_ poiId: String?) {
        setActivePOICalled = true
        activePOIId = poiId
        currentState = .inTour(activePOIId: poiId)
    }
    
    func completeTour() {
        completeTourCalled = true
        currentState = .completed
        activePOIId = nil
    }
    
    func reset() {
        resetCalled = true
        currentState = .idle
        activePOIId = nil
    }
}

// MARK: - Mock LanguageService

final class MockLanguageService: ObservableObject {
    @Published var currentLanguage: String = "ES"
    
    var setLanguageCalled = false
    var lastLanguageSet: String?
    var videoPathCalls: [String] = []
    var stringCalls: [String] = []
    
    func setLanguage(_ language: String) {
        setLanguageCalled = true
        lastLanguageSet = language
        currentLanguage = language
    }
    
    func videoPath(for poiId: String) -> String {
        videoPathCalls.append(poiId)
        let folder = currentLanguage == "ES" ? "Spanish" : "English"
        return "LanguageModule/Resources/\(folder)/\(poiId)"
    }
    
    func string(_ key: String) -> String {
        stringCalls.append(key)
        
        // Simular LocalizedStrings básico
        let strings: [String: [String: String]] = [
            "ES": [
                "guided_tour": "Tour Guiado",
                "free_tour": "Tour Libre",
                "terms": "Términos y\nCondiciones"
            ],
            "EN": [
                "guided_tour": "Guided Tour",
                "free_tour": "Free Tour",
                "terms": "Terms &\nConditions"
            ]
        ]
        
        return strings[currentLanguage]?[key] ?? key
    }
}

// MARK: - Mock EventBus

final class MockEventBus {
    private let subject = PassthroughSubject<AppEvent, Never>()
    
    var publishedEvents: [AppEvent] = []
    
    var publisher: AnyPublisher<AppEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func publish(_ event: AppEvent) {
        publishedEvents.append(event)
        subject.send(event)
    }
    
    func reset() {
        publishedEvents.removeAll()
    }
}

// MARK: - Mock GPSModuleInterface

final class MockGPSModuleInterface: ObservableObject {
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var tourState: TourState = .idle
    @Published var nearestPOI: ProximityResult? = nil
    
    var startTourCalled = false
    var stopTourCalled = false
    var startTrackingCalled = false
    var stopTrackingCalled = false
    
    func startTour() {
        startTourCalled = true
        tourState = .navigatingToStart
    }
    
    func stopTour() {
        stopTourCalled = true
        tourState = .idle
    }
    
    func startTracking() {
        startTrackingCalled = true
    }
    
    func stopTracking() {
        stopTrackingCalled = true
    }
    
    // Helpers para simular estados en tests
    func simulateLocation(_ location: CLLocationCoordinate2D) {
        userLocation = location
    }
    
    func simulateTourState(_ state: TourState) {
        tourState = state
    }
}

// MARK: - Mock AppRouter

final class MockAppRouter: ObservableObject {
    @Published var currentRoute: AppRoute = .menu
    
    var navigateCalls: [AppRoute] = []
    
    func navigateTo(_ route: AppRoute) {
        navigateCalls.append(route)
        currentRoute = route
    }
    
    func goBack() {
        currentRoute = .menu
    }
}

// MARK: - Mock Container

extension AppContainer {
    /// Container con mocks para testing aislado
    static func mock(
        appState: MockAppStateManager = MockAppStateManager(),
        language: MockLanguageService = MockLanguageService(),
        gps: MockGPSModuleInterface = MockGPSModuleInterface(),
        router: MockAppRouter = MockAppRouter(),
        eventBus: MockEventBus = MockEventBus()
    ) -> MockAppContainer {
        MockAppContainer(
            appState: appState,
            language: language,
            gps: gps,
            router: router,
            eventBus: eventBus
        )
    }
}

// MARK: - Mock Container Type

struct MockAppContainer {
    let appState: MockAppStateManager
    let language: MockLanguageService
    let gps: MockGPSModuleInterface
    let router: MockAppRouter
    let eventBus: MockEventBus
}
