//
//  AppState.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 15/05/26.
//

import Foundation

enum AppState: Equatable {
    case idle
    case inTour(activePOIId: String?)
    case completed
}
