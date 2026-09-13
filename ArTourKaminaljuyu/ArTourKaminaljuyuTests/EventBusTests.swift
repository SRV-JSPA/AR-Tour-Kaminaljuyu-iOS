//
//  EventBusTests.swift
//  ArTourKaminaljuyuTests
//

import Testing
import Combine
@testable import ArTourKaminaljuyu

@Suite("EventBus", .serialized)
struct EventBusTests {

    @Test("publish envía languageChanged a los suscriptores")
    func publishLanguageChanged() async {
        var received: String?
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = EventBus.shared.publisher.sink { event in
                if case .languageChanged(let lang) = event {
                    received = lang
                    continuation.resume()
                }
            }
            EventBus.shared.publish(.languageChanged(language: "EN"))
        }

        cancellable?.cancel()
        #expect(received == "EN")
    }

    @Test("publish envía nextPOIRequested a los suscriptores")
    func publishNextPOIRequested() async {
        var received = false
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = EventBus.shared.publisher.sink { event in
                if case .nextPOIRequested = event {
                    received = true
                    continuation.resume()
                }
            }
            EventBus.shared.publish(.nextPOIRequested)
        }

        cancellable?.cancel()
        #expect(received)
    }

    @Test("Suscriptores múltiples reciben el mismo evento")
    func multipleSubscribersReceiveEvent() async {
        var countA = 0
        var countB = 0
        var cA: AnyCancellable?
        var cB: AnyCancellable?

        await withCheckedContinuation { continuation in
            var reachedA = false
            var reachedB = false

            let checkDone = {
                if reachedA && reachedB { continuation.resume() }
            }

            cA = EventBus.shared.publisher.sink { event in
                if case .tourEndRequested = event {
                    countA += 1
                    reachedA = true
                    checkDone()
                }
            }
            cB = EventBus.shared.publisher.sink { event in
                if case .tourEndRequested = event {
                    countB += 1
                    reachedB = true
                    checkDone()
                }
            }

            EventBus.shared.publish(.tourEndRequested)
        }

        cA?.cancel()
        cB?.cancel()
        #expect(countA == 1)
        #expect(countB == 1)
    }
}
