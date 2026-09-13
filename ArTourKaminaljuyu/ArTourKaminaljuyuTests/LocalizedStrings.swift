//
//  LocalizedStrings.swift
//  ArTourKaminaljuyu
//
//  Sistema de localización para español (ES) e inglés (EN).
//  Usado por LanguageService para proveer strings traducidos.
//

import Foundation

struct LocalizedStrings {
    
    // MARK: - Spanish Strings (ES)
    
    static let spanish: [String: String] = [
        // Main Menu
        "welcome_line1": "Bienvenidos a",
        "app_title": "Kaminaljuyú",
        "welcome_line3": "Parque Arqueológico",
        "guided_tour": "Tour Guiado",
        "free_tour": "Tour Libre",
        "instructions": "Instrucciones",
        "terms": "Términos",
        
        // Coming Soon
        "coming_soon_title": "Próximamente",
        "coming_soon_message": "Esta función estará disponible pronto.",
        
        // Instructions
        "instructions_title": "Instrucciones",
        "instruction_1": "Enciende tu GPS y permite el acceso a la ubicación.",
        "instruction_2": "Camina hacia los puntos de interés marcados en el mapa.",
        "instruction_3": "Cuando llegues cerca de un montículo, verás el modelo AR.",
        "instruction_4": "Escucha la narración de la guía virtual maya.",
        "instruction_5": "Completa el recorrido visitando todos los puntos.",
        "instructions_footer": "¡Disfruta tu visita a Kaminaljuyú!",
        
        // Terms
        "terms_title": "Términos y Condiciones",
        "terms_intro": "Al usar esta aplicación, aceptas los siguientes términos:",
        "term_1": "Esta app es solo para uso educativo y turístico.",
        "term_2": "Los modelos AR son representaciones artísticas, no réplicas exactas.",
        "term_3": "Se requiere conexión GPS activa para el funcionamiento completo.",
        "term_4": "No nos hacemos responsables por accidentes durante el uso de la app.",
        "term_5": "Respeta las normas del parque arqueológico en todo momento.",
        "terms_disclaimer_title": "Descargo de Responsabilidad",
        "terms_disclaimer_body": "La información proporcionada es de carácter informativo. Consulta fuentes oficiales para datos históricos verificados.",
        "terms_footer": "Gracias por visitar Kaminaljuyú.",
        
        // Tour Controls
        "tour_controls_title": "Controles del Tour",
        "tour_controls_subtitle": "Aprende a usar los controles durante el recorrido",
        "control_back": "Regresar: Vuelve al menú principal",
        "control_info": "Información: Muestra detalles del punto actual",
        "control_start": "Iniciar: Comienza el tour guiado",
        "control_next": "Siguiente: Avanza al próximo punto de interés",
        "control_finish": "Finalizar: Completa el recorrido",
        "control_toggle": "Alternar: Cambia entre video y mapa con un toque",
        
        // Tour Controls - Start Point Banner (NUEVAS CLAVES)
        "ready_to_start": "Listo para iniciar",
        "walk_to_start_point": "Camina al punto de partida",
        "tap_anywhere_to_start": "Toca cualquier lugar para arrancar el tour",
        "distance_to_start": "Estás a %@m del punto de partida",
        "waiting_for_gps": "Esperando ubicación GPS…",
        
        // Video Toggle
        "hint_toggle_view": "Toca para alternar entre video y mapa",
        "toggle_to_map": "Mapa",
        "toggle_to_video": "Video",
        
        // Skip Intros (NUEVA CLAVE)
        "skip_intros": "Saltar intros",
        
        // Map Overlay - Status Messages (NUEVAS CLAVES)
        "distance_to_poi": "Estás a unos %@ metros de %@",
        "status_idle": "Acércate a un montículo para ver el modelo AR",
        "status_navigating_to_start": "Camina hacia el inicio del recorrido",
        "status_returning": "🔙 Regresando al inicio...",
        "status_completed": "🏁 ¡Recorrido completado!",
    ]
    
    // MARK: - English Strings (EN)
    
    static let english: [String: String] = [
        // Main Menu
        "welcome_line1": "Welcome to",
        "app_title": "Kaminaljuyú",
        "welcome_line3": "Archaeological Park",
        "guided_tour": "Guided Tour",
        "free_tour": "Free Tour",
        "instructions": "Instructions",
        "terms": "Terms",
        
        // Coming Soon
        "coming_soon_title": "Coming Soon",
        "coming_soon_message": "This feature will be available soon.",
        
        // Instructions
        "instructions_title": "Instructions",
        "instruction_1": "Turn on your GPS and allow location access.",
        "instruction_2": "Walk towards the points of interest marked on the map.",
        "instruction_3": "When you get close to a mound, you'll see the AR model.",
        "instruction_4": "Listen to the narration from the Mayan virtual guide.",
        "instruction_5": "Complete the tour by visiting all the points.",
        "instructions_footer": "Enjoy your visit to Kaminaljuyú!",
        
        // Terms
        "terms_title": "Terms and Conditions",
        "terms_intro": "By using this application, you accept the following terms:",
        "term_1": "This app is for educational and tourism purposes only.",
        "term_2": "AR models are artistic representations, not exact replicas.",
        "term_3": "An active GPS connection is required for full functionality.",
        "term_4": "We are not responsible for accidents during app usage.",
        "term_5": "Respect the archaeological park rules at all times.",
        "terms_disclaimer_title": "Disclaimer",
        "terms_disclaimer_body": "The information provided is for informational purposes. Consult official sources for verified historical data.",
        "terms_footer": "Thank you for visiting Kaminaljuyú.",
        
        // Tour Controls
        "tour_controls_title": "Tour Controls",
        "tour_controls_subtitle": "Learn how to use the controls during the tour",
        "control_back": "Back: Return to main menu",
        "control_info": "Info: Show details of current point",
        "control_start": "Start: Begin the guided tour",
        "control_next": "Next: Advance to the next point of interest",
        "control_finish": "Finish: Complete the tour",
        "control_toggle": "Toggle: Switch between video and map with a tap",
        
        // Tour Controls - Start Point Banner (NEW KEYS)
        "ready_to_start": "Ready to start",
        "walk_to_start_point": "Walk to the starting point",
        "tap_anywhere_to_start": "Tap anywhere to start the tour",
        "distance_to_start": "You are %@m from the starting point",
        "waiting_for_gps": "Waiting for GPS location…",
        
        // Video Toggle
        "hint_toggle_view": "Tap to toggle between video and map",
        "toggle_to_map": "Map",
        "toggle_to_video": "Video",
        
        // Skip Intros (NEW KEY)
        "skip_intros": "Skip intros",
        
        // Map Overlay - Status Messages (NEW KEYS)
        "distance_to_poi": "You are about %@ meters from %@",
        "status_idle": "Get close to a mound to see the AR model",
        "status_navigating_to_start": "Walk towards the tour start",
        "status_returning": "🔙 Returning to start...",
        "status_completed": "🏁 Tour completed!",
    ]
    
    // MARK: - Helper Method
    
    /// Obtiene un string localizado para el idioma especificado.
    /// - Parameters:
    ///   - key: La clave del string.
    ///   - language: El código del idioma ("ES" o "EN").
    ///   - arguments: Argumentos opcionales para formatear el string (usando %@).
    /// - Returns: El string localizado, o la clave misma si no se encuentra.
    static func get(_ key: String, language: String, arguments: [String] = []) -> String {
        let dict = language == "EN" ? english : spanish
        guard let template = dict[key] else {
            print("⚠️ [LocalizedStrings] Key not found: '\(key)' for language '\(language)'")
            return key
        }
        
        // Si no hay argumentos, devolver el template directo
        guard !arguments.isEmpty else { return template }
        
        // Reemplazar %@ con los argumentos en orden
        var result = template
        for arg in arguments {
            if let range = result.range(of: "%@") {
                result.replaceSubrange(range, with: arg)
            }
        }
        
        return result
    }
}
