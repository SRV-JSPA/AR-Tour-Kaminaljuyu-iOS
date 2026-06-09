//
//  EventBus.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 15/05/26.
//

import Foundation
import Combine

enum AppEvent {
    case poiReached(poiId: String)
    case tourStarted
    case tourCompleted
    case poiChanged(poiId: String?)
    case locationUpdated(latitude: Double, longitude: Double, heading: Double)
    case languageChanged(language: String)
}

final class EventBus {
    
    static let shared = EventBus()
    private init() {}
    
    private let subject = PassthroughSubject<AppEvent, Never>()
    
    var publisher: AnyPublisher<AppEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func publish(_ event: AppEvent) {
        subject.send(event)
    }
}
