//
//  TourStatePerformanceTests.swift
//  ArTourKaminaljuyuTests
//
//  Pruebas de rendimiento del estado del recorrido (XCTest + measure).
//
//  Simulan un recorrido completo: iniciar, avanzar por todos los montículos de
//  POIRegistry y finalizar. Usan los dobles de prueba de MockServices.swift
//  (MockGPSModuleInterface, MockAppRouter y AppContainer.mock()).
//

import XCTest
@testable import ArTourKaminaljuyu

final class TourStatePerformanceTests: XCTestCase {

    /// Recorridos completos simulados por iteración de `measure`.
    private let toursPerIteration = 100

    private var measureOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }

    override func setUp() {
        super.setUp()
        AppStateManager.shared.reset()
    }

    override func tearDown() {
        AppStateManager.shared.reset()
        super.tearDown()
    }

    /// Recorrido completo con el AppStateManager real; GPS y navegación simulados.
    func testCompleteTourWithAppStateManager() {
        let pois = POIRegistry.shared.pois
        XCTAssertFalse(pois.isEmpty, "POIRegistry debe tener montículos")

        let appState = AppStateManager.shared
        let gps = MockGPSModuleInterface()
        let router = MockAppRouter()
        let tours = toursPerIteration

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            for _ in 0..<tours {
                appState.startTour()
                gps.startTour()
                router.navigateTo(.guidedTour)

                for poi in pois {
                    appState.setActivePOI(poi.id)
                }

                appState.completeTour()
                gps.stopTour()
                router.navigateTo(.menu)
                appState.reset()
            }
        }

        XCTAssertEqual(appState.currentState, .idle)
        XCTAssertTrue(gps.startTourCalled)
        XCTAssertTrue(gps.stopTourCalled)
        XCTAssertEqual(router.currentRoute, .menu)
    }

    /// Recorrido completo usando únicamente los dobles de prueba (AppContainer.mock()).
    func testCompleteTourWithMocks() {
        let pois = POIRegistry.shared.pois
        XCTAssertFalse(pois.isEmpty, "POIRegistry debe tener montículos")

        let container = AppContainer.mock()
        let tours = toursPerIteration

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            for _ in 0..<tours {
                container.appState.startTour()
                container.gps.startTour()
                container.router.navigateTo(.guidedTour)

                for poi in pois {
                    container.appState.setActivePOI(poi.id)
                }

                container.appState.completeTour()
                container.gps.stopTour()
                container.router.navigateTo(.menu)
                container.appState.reset()
            }
        }

        XCTAssertEqual(container.appState.currentState, .idle)
        XCTAssertTrue(container.appState.completeTourCalled)
        XCTAssertTrue(container.gps.stopTourCalled)
        XCTAssertEqual(container.router.currentRoute, .menu)
    }
}
