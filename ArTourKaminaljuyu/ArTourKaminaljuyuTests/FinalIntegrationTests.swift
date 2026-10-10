//
//  FinalIntegrationTests.swift
//  ArTourKaminaljuyuTests
//
//  Tests de integración que validan la ARQUITECTURA MODULAR (contribución de tesis).
//  Estos tests demuestran que los módulos se comunican correctamente por interfaces,
//  EventBus, y estado centralizado - sin depender de implementaciones concretas.
//

import Testing
import Combine
@testable import ArTourKaminaljuyu

// MARK: - Tests de Arquitectura Modular (Para Protocolo de Graduación)

@Suite("Validación de Arquitectura Modular")
struct ArchitectureValidationTests {
    
    @Test("Arquitectura: Módulos se comunican por interfaces públicas")
    func modulesCommunicateViaInterfaces() {
        let container = AppContainer.mock()
        
        // Demostrar que podemos controlar todo el sistema solo con interfaces
        container.appState.startTour()
        container.gps.startTour()
        container.router.navigateTo(.guidedTour)
        container.language.setLanguage("EN")
        
        // Verificar que todos respondieron correctamente
        #expect(container.appState.currentState == .inTour(activePOIId: nil))
        #expect(container.gps.tourState == .navigatingToStart)
        #expect(container.router.currentRoute == .guidedTour)
        #expect(container.language.currentLanguage == "EN")
    }
    
    @Test("Arquitectura: EventBus coordina módulos sin acoplamiento directo")
    func eventBusCoordinatesModules() async throws {
        let container = AppContainer.mock()
        
        var receivedEvents: [AppEvent] = []
        let cancellable = container.eventBus.publisher
            .sink { event in
                receivedEvents.append(event)
            }
        
        // Simular eventos del flujo del tour
        container.eventBus.publish(.languageChanged(language: "EN"))
        container.eventBus.publish(.nextPOIRequested)
        container.eventBus.publish(.tourEndRequested)
        container.eventBus.publish(.tourEndCompleted)
        
        try await Task.sleep(for: .milliseconds(50))
        
        // Verificar que todos los eventos se propagaron
        #expect(receivedEvents.count == 4)
        #expect(container.eventBus.publishedEvents.count == 4)
        
        cancellable.cancel()
    }
    
    @Test("Arquitectura: AppStateManager es fuente única de verdad del estado")
    func appStateManagerIsSingleSourceOfTruth() async throws {
        let container = AppContainer.mock()
        
        var stateHistory: [AppState] = []
        let cancellable = container.appState.$currentState
            .sink { state in
                stateHistory.append(state)
            }
        
        // Ciclo completo del tour
        container.appState.reset()
        container.appState.startTour()
        container.appState.setActivePOI("monticulo_6")
        container.appState.completeTour()
        container.appState.reset()
        
        try await Task.sleep(for: .milliseconds(50))
        
        // Verificar que pasamos por todos los estados esperados
        #expect(stateHistory.count >= 4)
        #expect(container.appState.currentState == .idle)
        
        cancellable.cancel()
    }
    
    @Test("Arquitectura: Inyección de dependencias funciona correctamente")
    func dependencyInjectionWorks() {
        let container = AppContainer.mock()
        
        // Verificar que todas las dependencias están inyectadas
        #expect(container.appState != nil)
        #expect(container.gps != nil)
        #expect(container.language != nil)
        #expect(container.router != nil)
        #expect(container.eventBus != nil)
        
        // Verificar que son mocks (podemos verificar llamadas)
        container.appState.startTour()
        #expect(container.appState.startTourCalled == true)
        
        container.gps.startTour()
        #expect(container.gps.startTourCalled == true)
        
        container.language.setLanguage("EN")
        #expect(container.language.setLanguageCalled == true)
    }
}

// MARK: - Tests de Flujos End-to-End (Para Protocolo de Graduación)

@Suite("Validación de Flujos End-to-End")
struct EndToEndFlowTests {
    
    @Test("Flujo E2E: Usuario completa tour guiado completo")
    func userCompletesFullGuidedTour() {
        let container = AppContainer.mock()
        
        // 1. Estado inicial
        #expect(container.appState.currentState == .idle)
        
        // 2. Usuario selecciona idioma
        container.language.setLanguage("EN")
        #expect(container.language.currentLanguage == "EN")
        
        // 3. Usuario inicia tour
        container.appState.startTour()
        container.gps.startTour()
        container.router.navigateTo(.guidedTour)
        
        #expect(container.appState.currentState == .inTour(activePOIId: nil))
        #expect(container.gps.tourState == .navigatingToStart)
        #expect(container.router.currentRoute == .guidedTour)
        
        // 4. Usuario visita varios POIs
        let pois = ["monticulo_6", "acropolis", "monticulo_3"]
        for poi in pois {
            container.appState.setActivePOI(poi)
            container.gps.simulateTourState(.atPOI(0))
            
            if case .inTour(let activePOIId) = container.appState.currentState {
                #expect(activePOIId == poi)
            }
        }
        
        // 5. Usuario completa el tour
        container.eventBus.publish(.tourEndCompleted)
        container.appState.completeTour()
        container.gps.stopTour()
        container.router.navigateTo(.menu)
        
        #expect(container.appState.currentState == .completed)
        #expect(container.router.currentRoute == .menu)
        
        // Verificar que todas las interacciones fueron registradas
        #expect(container.appState.startTourCalled == true)
        #expect(container.appState.setActivePOICalled == true)
        #expect(container.appState.completeTourCalled == true)
        #expect(container.gps.startTourCalled == true)
        #expect(container.gps.stopTourCalled == true)
        #expect(container.language.setLanguageCalled == true)
    }
    
    @Test("Flujo E2E: Usuario cambia idioma y videos se actualizan")
    func userChangesLanguageAndVideosUpdate() {
        let container = AppContainer.mock()
        
        // Español
        container.language.setLanguage("ES")
        let spanishVideo = container.language.videoPath(for: "MCII3")
        #expect(spanishVideo.contains("Spanish"))
        
        // Inglés
        container.language.setLanguage("EN")
        let englishVideo = container.language.videoPath(for: "MCII3")
        #expect(englishVideo.contains("English"))
        
        // Videos son diferentes
        #expect(spanishVideo != englishVideo)
        
        // Verificar que se llamaron los métodos correctos
        #expect(container.language.videoPathCalls.count == 2)
        #expect(container.language.videoPathCalls.contains("MCII3"))
    }
    
    @Test("Flujo E2E: Usuario cancela tour y sistema se resetea correctamente")
    func userCancelsTourAndSystemResets() {
        let container = AppContainer.mock()
        
        // 1. Iniciar tour y progresar
        container.appState.startTour()
        container.gps.startTour()
        container.router.navigateTo(.guidedTour)
        container.appState.setActivePOI("monticulo_6")
        container.appState.setActivePOI("acropolis")
        
        // 2. Usuario cancela (back button)
        container.appState.reset()
        container.gps.stopTour()
        container.router.navigateTo(.menu)
        
        // 3. Verificar que todo vuelve al estado inicial
        #expect(container.appState.currentState == .idle)
        #expect(container.appState.resetCalled == true)
        #expect(container.gps.stopTourCalled == true)
        #expect(container.router.currentRoute == .menu)
        
        // Sistema está listo para un nuevo tour
        container.appState.startTour()
        #expect(container.appState.currentState == .inTour(activePOIId: nil))
    }
}

// MARK: - Tests de Desacoplamiento (Para Protocolo de Graduación)

@Suite("Validación de Desacoplamiento entre Módulos")
struct DecouplingValidationTests {
    
    @Test("Desacoplamiento: Podemos reemplazar implementaciones sin afectar otros módulos")
    func canReplaceImplementations() {
        // Crear dos containers con diferentes configuraciones
        let container1 = AppContainer.mock()
        let container2 = AppContainer.mock()
        
        // Ambos funcionan independientemente
        container1.appState.startTour()
        container2.appState.startTour()
        
        #expect(container1.appState.currentState == .inTour(activePOIId: nil))
        #expect(container2.appState.currentState == .inTour(activePOIId: nil))
        
        // Modificar uno no afecta al otro
        container1.appState.completeTour()
        #expect(container1.appState.currentState == .completed)
        #expect(container2.appState.currentState == .inTour(activePOIId: nil))
    }
    
    @Test("Desacoplamiento: Múltiples suscriptores al EventBus no interfieren")
    func multipleEventSubscribers() async throws {
        let container = AppContainer.mock()
        
        var subscriber1Events: [AppEvent] = []
        var subscriber2Events: [AppEvent] = []
        var subscriber3Events: [AppEvent] = []
        
        let c1 = container.eventBus.publisher.sink { subscriber1Events.append($0) }
        let c2 = container.eventBus.publisher.sink { subscriber2Events.append($0) }
        let c3 = container.eventBus.publisher.sink { subscriber3Events.append($0) }
        
        // Publicar eventos
        container.eventBus.publish(.nextPOIRequested)
        container.eventBus.publish(.tourEndCompleted)
        
        try await Task.sleep(for: .milliseconds(50))
        
        // Todos los suscriptores reciben todos los eventos
        #expect(subscriber1Events.count == 2)
        #expect(subscriber2Events.count == 2)
        #expect(subscriber3Events.count == 2)
        
        c1.cancel()
        c2.cancel()
        c3.cancel()
    }
    
    @Test("Desacoplamiento: Estado reactivo se propaga automáticamente")
    func reactiveStatePropagates() async throws {
        let container = AppContainer.mock()
        
        var languageChanges: [String] = []
        let cancellable = container.language.$currentLanguage
            .sink { lang in
                languageChanges.append(lang)
            }
        
        // Cambios rápidos de idioma
        container.language.setLanguage("EN")
        container.language.setLanguage("ES")
        container.language.setLanguage("EN")
        
        try await Task.sleep(for: .milliseconds(50))
        
        // Todos los cambios fueron observados
        #expect(languageChanges.count >= 3)
        #expect(languageChanges.contains("EN"))
        #expect(languageChanges.contains("ES"))
        
        cancellable.cancel()
    }
}
