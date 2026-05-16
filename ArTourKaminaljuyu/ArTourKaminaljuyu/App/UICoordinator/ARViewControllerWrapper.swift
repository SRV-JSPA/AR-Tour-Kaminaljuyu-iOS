//
//  ARViewControllerWrapper.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 16/05/26.
//

import SwiftUI
import ARKit

struct ARViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController()
    }
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}
