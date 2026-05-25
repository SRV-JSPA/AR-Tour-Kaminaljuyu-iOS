//
//  AppRouter.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI
import Combine

enum AppRoute {
    case menu
    case tourControls
    case guidedTour
}

final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    private init() {}
    
    @Published var currentRoute: AppRoute = .menu
    
    func navigateTo(_ route: AppRoute) {
        currentRoute = route
    }
}
