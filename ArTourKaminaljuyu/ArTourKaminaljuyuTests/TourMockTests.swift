//
//  TourMockTests.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 12/09/26.
//

import Testing
@testable import ArTourKaminaljuyu

@Suite("Tests E2E con Mocks")
struct TourMockTests {
    
    @Test("Mock: Flujo completo del tour")
    func completeTourFlow() {
        let c = AppContainer.mock()
        
        // Iniciar
        c.appState.startTour()
        c.gps.startTour()
        #expect(c.appState.currentState == .inTour(activePOIId: nil))
        #expect(c.gps.tourState == .navigatingToStart)
        
        // Completar
        c.appState.completeTour()
        c.gps.stopTour()
        #expect(c.appState.currentState == .completed)
    }
    
    @Test("Mock: Cambio de idioma")
    func languageChange() {
        let c = AppContainer.mock()
        c.language.setLanguage("EN")
        
        #expect(c.language.currentLanguage == "EN")
        #expect(c.language.setLanguageCalled == true)
        
        let path = c.language.videoPath(for: "test")
        #expect(path.contains("English"))
    }
}
