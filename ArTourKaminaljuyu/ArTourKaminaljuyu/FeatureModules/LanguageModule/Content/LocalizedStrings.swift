//
//  LocalizedStrings.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 28/06/26.
//

import Foundation

struct LocalizedStrings {
    
    static func get(_ key: String) -> String {
        let lang = LanguageService.shared.currentLanguage
        return strings[lang]?[key] ?? strings["ES"]?[key] ?? key
    }
    
    private static let strings: [String: [String: String]] = [
        "ES": [
            // MainMenuView
            "welcome_line1": "Bienvenidos al\nParque Arqueológico",
            "app_title": "Kaminaljuyú",
            "welcome_line3": "",
            "guided_tour": "Tour Guiado",
            "free_tour": "Tour Libre",
            "instructions": "Instrucciones\nde Uso",
            "terms": "Términos y\nCondiciones",
            
            // InstructionsView
            "instructions_title": "Instrucciones de Uso",
            "instruction_1": "Selecciona 'Tour Guiado' o 'Tour Libre' desde el menú principal.",
            "instruction_2": "Si eliges 'Tour Guiado', sigue la ruta recomendada para una mejor experiencia.",
            "instruction_3": "Apunta tu dispositivo hacia los puntos de interés para activar las escenas de realidad aumentada.",
            "instruction_4": "Utiliza el botón de información para conocer detalles históricos de cada estructura.",
            "instruction_5": "En cualquier momento, puedes consultar las 'Instrucciones de Uso' o los 'Términos y Condiciones' desde el menú principal.",
            "instructions_footer": "¡Disfruta tu recorrido por Kaminaljuyú!",
            
            // TourControlsView
            "tour_controls_title": "Controles del Tour AR",
            "tour_controls_subtitle": "Toca cualquier lugar para continuar",
            "control_back": "Regresar al menú principal",
            "control_info": "Ver información del POI cercano",
            "control_start": "Iniciar recorrido guiado automático",
            "control_next": "Avanzar al siguiente punto de interés",
            "control_finish": "Finalizar el recorrido guiado",
            
            // TermsView
            "terms_title": "Términos y Condiciones",
            "terms_intro": "Bienvenido a la aplicación de recorrido virtual del Parque Arqueológico Kaminaljuyú. Al utilizar esta aplicación, usted acepta los siguientes términos:",
            "term_1": "Esta aplicación tiene como propósito ofrecer una experiencia educativa e interactiva basada en información histórica, arqueológica y cultural disponible hasta la fecha de su desarrollo.",
            "term_2": "El contenido visual y textual ha sido elaborado a partir de investigaciones académicas, registros históricos y reconstrucciones interpretativas.",
            "term_3": "Debido a limitaciones inherentes a la investigación arqueológica, algunas representaciones de estructuras, objetos y paisajes pueden no reflejar con total exactitud las condiciones originales del sitio en la antigüedad.",
            "term_4": "Parte de la información presentada puede estar sujeta a cambios a medida que se desarrollen nuevas investigaciones arqueológicas o actualizaciones académicas.",
            "term_5": "Esta aplicación no sustituye una visita física ni la asesoría de profesionales en arqueología o historia.",
            "terms_disclaimer_title": "Descargo de responsabilidad:",
            "terms_disclaimer_body": "Aunque se ha procurado la mayor precisión posible, la representación de ciertas estructuras, escenarios y detalles visuales puede contener elementos hipotéticos o interpretativos debido a la falta de evidencia completa o alteraciones ocurridas a lo largo del tiempo.",
            "terms_footer": "Al utilizar esta aplicación, usted reconoce y acepta estas condiciones.",
        ],
        "EN": [
            // MainMenuView
            "welcome_line1": "Welcome to",
            "app_title": "Kaminaljuyú",
            "welcome_line3": "Archaeological Park",
            "guided_tour": "Guided Tour",
            "free_tour": "Free Tour",
            "instructions": "Instructions\nfor Use",
            "terms": "Terms &\nConditions",
            
            // InstructionsView
            "instructions_title": "Instructions for Use",
            "instruction_1": "Select 'Guided Tour' or 'Free Tour' from the main menu.",
            "instruction_2": "If you choose 'Guided Tour', follow the recommended route for a better experience.",
            "instruction_3": "Point your device toward points of interest to activate augmented reality scenes.",
            "instruction_4": "Use the information button to learn historical details about each structure.",
            "instruction_5": "At any time, you can check 'Instructions for Use' or 'Terms and Conditions' from the main menu.",
            "instructions_footer": "Enjoy your tour of Kaminaljuyú!",
            
            // TourControlsView
            "tour_controls_title": "AR Tour Controls",
            "tour_controls_subtitle": "Tap anywhere to continue",
            "control_back": "Return to main menu",
            "control_info": "View nearby POI information",
            "control_start": "Start automatic guided tour",
            "control_next": "Advance to next point of interest",
            "control_finish": "Finish the guided tour",
            
            // TermsView
            "terms_title": "Terms and Conditions",
            "terms_intro": "Welcome to the virtual tour application of the Kaminaljuyú Archaeological Park. By using this application, you agree to the following terms:",
            "term_1": "This application aims to provide an educational and interactive experience based on historical, archaeological, and cultural information available at the time of its development.",
            "term_2": "The visual and textual content has been developed from academic research, historical records, and interpretive reconstructions.",
            "term_3": "Due to inherent limitations in archaeological research, some representations of structures, objects, and landscapes may not fully reflect the original conditions of the site in antiquity.",
            "term_4": "Some of the information presented may be subject to change as new archaeological research or academic updates are developed.",
            "term_5": "This application does not replace a physical visit or the advice of professionals in archaeology or history.",
            "terms_disclaimer_title": "Disclaimer:",
            "terms_disclaimer_body": "Although the greatest possible accuracy has been sought, the representation of certain structures, scenarios, and visual details may contain hypothetical or interpretive elements due to lack of complete evidence or alterations that have occurred over time.",
            "terms_footer": "By using this application, you acknowledge and accept these conditions.",
        ]
    ]
}
