//
//  AppContainer.swift
//  ArTourKaminaljuyu
//
//  Contenedor central de dependencias de la aplicación. Actúa como factory
//  de las interfaces públicas de los módulos feature (GPSModule, ARModule,
//  LanguageModule, VirtualGuideModule) y de los servicios de coordinación
//  (AppStateManager, AppRouter, EventBus).
//
//  ArTourKaminaljuyuApp instancia este contenedor una sola vez y usa sus
//  referencias para inyectar cada ObservableObject individualmente al árbol
//  SwiftUI vía `.environmentObject`. Los views consumen los servicios que
//  necesiten con `@EnvironmentObject var xxx: XxxService`.
//
//  Nota: EventBus no es ObservableObject (no expone estado), por lo que
//  no se inyecta como environment object. Los publicadores usan
//  `EventBus.shared.publish(...)` directo.
//
//  Testing (trabajo futuro): `AppContainer.mock()` producirá instancias
//  con mocks/stubs para aislar unit tests de servicios reales.
//

import Foundation

final class AppContainer {

    // MARK: - Módulos feature (interfaces públicas)
    let gps: GPSModuleInterface
    let language: LanguageService
    let ar: ARModuleInterface
    let virtualGuide: VirtualGuideModuleInterface

    // MARK: - Coordinación / estado global
    let appState: AppStateManager
    let router: AppRouter
    let eventBus: EventBus

    // MARK: - Init privado
    private init(
        gps: GPSModuleInterface,
        language: LanguageService,
        ar: ARModuleInterface,
        virtualGuide: VirtualGuideModuleInterface,
        appState: AppStateManager,
        router: AppRouter,
        eventBus: EventBus
    ) {
        self.gps = gps
        self.language = language
        self.ar = ar
        self.virtualGuide = virtualGuide
        self.appState = appState
        self.router = router
        self.eventBus = eventBus
    }

    // MARK: - Factories

    /// Producción: envuelve las instancias `.shared` reales de cada servicio.
    static func production() -> AppContainer {
        AppContainer(
            gps: .shared,
            language: .shared,
            ar: .shared,
            virtualGuide: .shared,
            appState: .shared,
            router: .shared,
            eventBus: .shared
        )
    }

    // TODO: static func mock() -> AppContainer con implementaciones falsas para tests
}
