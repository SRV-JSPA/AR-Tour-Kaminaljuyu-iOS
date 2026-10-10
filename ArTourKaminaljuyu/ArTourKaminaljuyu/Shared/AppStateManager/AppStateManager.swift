//
//  AppStateManager.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 15/05/26.
//

import Foundation
import Combine

final class AppStateManager: ObservableObject {
    
    static let shared = AppStateManager()
    private init() {}
    
    @Published private(set) var currentState: AppState = .idle
    @Published private(set) var activePOIId: String? = nil
    
    func startTour() {
        currentState = .inTour(activePOIId: nil)
    }
    
    func setActivePOI(_ poiId: String?) {
        activePOIId = poiId
        currentState = .inTour(activePOIId: poiId)
    }
    
    func completeTour() {
        currentState = .completed
        activePOIId = nil
    }
    
    func reset() {
        currentState = .idle
        activePOIId = nil
    }
}
