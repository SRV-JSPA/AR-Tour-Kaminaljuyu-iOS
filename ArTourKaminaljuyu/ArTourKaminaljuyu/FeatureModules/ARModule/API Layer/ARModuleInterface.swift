//
//  ARModuleInterface.swift
//  ArTourKaminaljuyu
//
//  Puerta pública única del ARModule. Consumidores externos NO deben
//  instanciar ARViewController ni ningún service interno del módulo;
//  deben usar `ARModuleView` para embeber la escena AR en SwiftUI, o
//  `ARModuleInterface.shared` cuando necesiten comandos / estado publicado.
//

import SwiftUI
import ARKit
import Combine

// MARK: - ARModuleInterface

/// Puerta pública única del ARModule.
///
/// Placeholder actual: en Fase 3 aquí van a vivir el estado publicado
/// del tour (currentPOIIndex, hasPlacedModel) y los comandos que hoy
/// están dispersos dentro de ARViewController.
final class ARModuleInterface: ObservableObject {

    static let shared = ARModuleInterface()
    private init() {}

    // Futuro (Fase 3, cuando se conecte AppStateManager):
    // @Published private(set) var currentPOIIndex: Int = 0
    // @Published private(set) var hasPlacedModel: Bool = false
    // func stopSession()
}

// MARK: - ARModuleView

/// Adaptador SwiftUI del ARModule. Único punto de entrada para embeber
/// la escena AR en una jerarquía SwiftUI.
struct ARModuleView: UIViewControllerRepresentable {

    init() {}

    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController()
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}
