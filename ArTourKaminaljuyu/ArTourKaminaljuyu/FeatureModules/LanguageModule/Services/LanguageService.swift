//
//  LanguageService.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 8/06/26.
//

import Foundation
import Combine

final class LanguageService: ObservableObject {
    
    static let shared = LanguageService()
    private init() {}
    
    @Published private(set) var currentLanguage: String = "ES"
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        print("[LanguageModule] idioma cambiado a: \(language)")
        EventBus.shared.publish(.languageChanged(language: language))
    }
    
    func videoPath(for poiId: String) -> String {
        let folder = currentLanguage == "ES" ? "Spanish" : "English"
        let path = "LanguageModule/Resources/\(folder)/\(poiId)"
        print("[LanguageModule] ruta de video para \(poiId): \(path)")
        return path
    }
    
    func string(_ key: String) -> String {
        LocalizedStrings.get(key)
    }
}
