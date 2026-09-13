//
//  AppStateManagerTests.swift
//  ArTourKaminaljuyuTests
//

import Testing
@testable import ArTourKaminaljuyu

@Suite("AppStateManager", .serialized)
struct AppStateManagerTests {

    // Nota: AppStateManager.shared es singleton. Cada test resetea al inicio y final.
    
    init() {
        // Setup: resetear antes de cada test
        AppStateManager.shared.reset()
    }

    @Test("Estado inicial es .idle tras reset")
    func initialStateIsIdle() async throws {
        AppStateManager.shared.reset()
        
        // Dar tiempo para que la actualización del @Published se propague
        try await Task.sleep(for: .milliseconds(10))

        if case .idle = AppStateManager.shared.currentState {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Estado inicial debería ser .idle")
        }
        #expect(AppStateManager.shared.activePOIId == nil)
    }

    @Test("startTour transiciona a .inTour(nil)")
    func startTourTransition() async throws {
        AppStateManager.shared.reset()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.startTour()
        try await Task.sleep(for: .milliseconds(10))

        if case .inTour(let poi) = AppStateManager.shared.currentState {
            #expect(poi == nil)
        } else {
            #expect(Bool(false), "startTour debería llevar a .inTour")
        }

        AppStateManager.shared.reset()
    }

    @Test("setActivePOI actualiza activePOIId y el estado")
    func setActivePOIUpdatesState() async throws {
        AppStateManager.shared.reset()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.startTour()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.setActivePOI("MCII3")
        try await Task.sleep(for: .milliseconds(10))

        #expect(AppStateManager.shared.activePOIId == "MCII3")
        if case .inTour(let poi) = AppStateManager.shared.currentState {
            #expect(poi == "MCII3")
        } else {
            #expect(Bool(false), "Estado debería ser .inTour(MCII3)")
        }

        AppStateManager.shared.reset()
    }

    @Test("completeTour transiciona a .completed y limpia POI")
    func completeTourClearsPOI() async throws {
        AppStateManager.shared.reset()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.startTour()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.setActivePOI("MCII5")
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.completeTour()
        try await Task.sleep(for: .milliseconds(10))

        if case .completed = AppStateManager.shared.currentState {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Estado debería ser .completed")
        }
        #expect(AppStateManager.shared.activePOIId == nil)

        AppStateManager.shared.reset()
    }

    @Test("reset regresa a .idle y limpia POI")
    func resetReturnsToIdle() async throws {
        AppStateManager.shared.startTour()
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.setActivePOI("MCII7")
        try await Task.sleep(for: .milliseconds(10))
        
        AppStateManager.shared.reset()
        try await Task.sleep(for: .milliseconds(10))

        if case .idle = AppStateManager.shared.currentState {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "reset debería llevar a .idle")
        }
        #expect(AppStateManager.shared.activePOIId == nil)
    }
}
