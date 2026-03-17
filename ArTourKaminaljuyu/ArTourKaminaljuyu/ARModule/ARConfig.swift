//
//  ARConfig.swift
//  ArTourKaminaljuyu
//
//  Módulo AR — Constantes de configuración
//  Equivalente iOS de: HelloGeoConfig.kt
//

import Foundation

enum ARConfig {

    // MARK: - Escala del modelo
    // Equivalente Android: MIN_SCALE / MAX_SCALE
    static let minScale: Float = 0.2
    static let maxScale: Float = 5.0

    // MARK: - Altura de los ojos del usuario sobre el suelo (metros)
    // Se usa para calcular la altitud del ancla cerca del nivel del terreno.
    // Equivalente Android: CAMERA_EYE_HEIGHT_METERS
    static let cameraEyeHeightMeters: Double = 1.6

    // MARK: - Iluminación
    // Equivalente Android: LIGHT_AMBIENT / LIGHT_DIFFUSE
    static let lightAmbient: Float = 0.9
    static let lightDiffuse: Float = 0.7

    // MARK: - Distancia al frente de la cámara para el fallback (sin ARGeoTracking)
    static let modelPlacementDistanceMeters: Float = 3.0
}