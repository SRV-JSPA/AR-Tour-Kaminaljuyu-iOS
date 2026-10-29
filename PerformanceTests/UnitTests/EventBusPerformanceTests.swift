//
//  EventBusPerformanceTests.swift
//  ArTourKaminaljuyuTests
//
//  Prueba de rendimiento del bus de eventos (XCTest + measure).
//
//  Se publica `.languageChanged` porque ningún módulo de la app reacciona a ese
//  aviso: así el tiempo medido corresponde al bus y a los 4 suscriptores de la
//  prueba, sin disparar lógica del GPS o del guía virtual.
//

import XCTest
import Combine
@testable import ArTourKaminaljuyu

final class EventBusPerformanceTests: XCTestCase {

    private let eventsPerIteration = 10_000
    private let subscriberCount = 4

    private var measureOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }

    /// Tiempo y memoria de publicar 10 000 avisos en EventBus con 4 suscriptores.
    func testPublish10000EventsWithFourSubscribers() {
        let bus = EventBus.shared
        let events = eventsPerIteration
        var cancellables = Set<AnyCancellable>()
        var received = 0

        for _ in 0..<subscriberCount {
            bus.publisher
                .sink { event in
                    if case .languageChanged = event {
                        received += 1
                    }
                }
                .store(in: &cancellables)
        }

        var receivedInLastIteration = 0

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            let before = received
            for _ in 0..<events {
                bus.publish(.languageChanged(language: "ES"))
            }
            receivedInLastIteration = received - before
        }

        // Cada aviso debe llegar a los 4 suscriptores.
        XCTAssertEqual(receivedInLastIteration, eventsPerIteration * subscriberCount)

        cancellables.removeAll()
    }
}
