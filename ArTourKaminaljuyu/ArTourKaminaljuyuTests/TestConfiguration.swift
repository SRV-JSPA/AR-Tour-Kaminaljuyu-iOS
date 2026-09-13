//
//  TestConfiguration.swift
//  ArTourKaminaljuyuTests
//
//  Configuración global para serializar tests que usan singletons compartidos.
//

import Testing

// Tag personalizado para tests que usan singletons
extension Tag {
    @Tag static var usesSharedState: Self
}

