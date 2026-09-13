//
//  LanguageService.swift
//  ArTourKaminaljuyu
//
//  Servicio de localización que gestiona el idioma actual de la aplicación.
//  Usado por todos los módulos para obtener strings traducidos.
//

import Foundation
import Combine

final class LanguageService: ObservableObject {
    
    static let shared = LanguageService()
    
    @Published private(set) var currentLanguage: String = "ES"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Cambia el idioma de la aplicación.
    /// - Parameter language: Código del idioma ("ES" o "EN").
    func setLanguage(_ language: String) {
        guard language == "ES" || language == "EN" else {
            print("⚠️ [LanguageService] Idioma no soportado: \(language)")
            return
        }
        
        currentLanguage = language
        
        // Publicar evento de cambio de idioma
        EventBus.shared.publish(.languageChanged(language))
        
        print("✓ [LanguageService] Idioma cambiado a: \(language)")
    }
    
    /// Obtiene un string localizado para el idioma actual.
    /// - Parameters:
    ///   - key: La clave del string.
    ///   - arguments: Argumentos opcionales para formatear el string (usando %@).
    /// - Returns: El string localizado en el idioma actual.
    func string(_ key: String, arguments: [String] = []) -> String {
        return LocalizedStrings.get(key, language: currentLanguage, arguments: arguments)
    }
    
    /// Devuelve la ruta del video para un POI en el idioma actual.
    /// - Parameter poiId: ID del punto de interés (ej: "MCII3").
    /// - Returns: Ruta del video en el bundle.
    func videoPath(for poiId: String) -> String {
        let folder = currentLanguage == "EN" ? "English" : "Spanish"
        return "Videos/\(folder)/\(poiId)"
    }
}
