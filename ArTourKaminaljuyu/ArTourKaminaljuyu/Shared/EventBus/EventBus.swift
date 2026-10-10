//
//  EventBus.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 15/05/26.
//

import Foundation
import Combine

enum AppEvent {
    case languageChanged(language: String)
    case nextPOIRequested
    case tourEndRequested
    case tourEndCompleted
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
