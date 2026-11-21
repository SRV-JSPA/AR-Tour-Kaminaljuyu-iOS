//
//  LanguagePerformanceTests.swift
//  ArTourKaminaljuyuTests
//
//  Pruebas de rendimiento del módulo de lenguaje (XCTest + measure).
//
//  Nota: la carpeta ArTourKaminaljuyuTests contiene copias de LanguageService y
//  LocalizedStrings con otra API. Para medir el código real de la app, los tipos
//  se califican con el módulo (`ArTourKaminaljuyu.`).
//

import XCTest
@testable import ArTourKaminaljuyu

final class LanguagePerformanceTests: XCTestCase {

    /// Las 52 claves de texto definidas en LocalizedStrings (mismo conjunto en ES y EN).
    private let allKeys: [String] = [
        "welcome_line1", "app_title", "welcome_line3", "guided_tour", "free_tour",
        "instructions", "terms", "instructions_title", "instruction_1", "instruction_2",
        "instruction_3", "instruction_4", "instruction_5", "instructions_footer",
        "tour_controls_title", "tour_controls_subtitle", "control_back", "control_info",
        "control_start", "control_next", "control_finish", "control_toggle",
        "ready_to_start", "walk_to_start_point", "tap_anywhere_to_start",
        "distance_to_start", "waiting_for_gps", "hint_toggle_view", "toggle_to_map",
        "toggle_to_video", "skip_intros", "distance_to_poi", "status_idle",
        "status_navigating_to_start", "status_returning", "status_completed",
        "back_confirm_title", "back_confirm_message", "coming_soon_title",
        "coming_soon_message", "terms_title", "terms_intro", "term_1", "term_2",
        "term_3", "term_4", "term_5", "terms_disclaimer_title", "terms_disclaimer_body",
        "terms_footer", "poi_monticulo_6_title", "poi_acropolis_title"
    ]

    /// Cambios ES → EN → ES por iteración de `measure`.
    private let roundTripsPerIteration = 100

    /// Lecturas completas de las 52 claves por iteración de `measure`.
    private let fullReadsPerIteration = 100

    private var measureOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }

    override func setUp() {
        super.setUp()
        ArTourKaminaljuyu.LanguageService.shared.setLanguage("ES")
    }

    override func tearDown() {
        ArTourKaminaljuyu.LanguageService.shared.setLanguage("ES")
        super.tearDown()
    }

    // MARK: - Cambio de idioma

    /// Tiempo y memoria de cambiar de español a inglés y de regreso.
    func testLanguageSwitchRoundTrip() {
        let language = ArTourKaminaljuyu.LanguageService.shared
        let roundTrips = roundTripsPerIteration

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            for _ in 0..<roundTrips {
                language.setLanguage("EN")
                language.setLanguage("ES")
            }
        }

        XCTAssertEqual(language.currentLanguage, "ES")
    }

    // MARK: - Obtención de textos

    /// Tiempo y memoria de obtener las 52 claves en español.
    func testAllStringsInSpanish() {
        measureAllStrings(language: "ES")
    }

    /// Tiempo y memoria de obtener las 52 claves en inglés.
    func testAllStringsInEnglish() {
        measureAllStrings(language: "EN")
    }

    private func measureAllStrings(language code: String) {
        ArTourKaminaljuyu.LanguageService.shared.setLanguage(code)
        XCTAssertEqual(ArTourKaminaljuyu.LanguageService.shared.currentLanguage, code)

        let keys = allKeys
        let fullReads = fullReadsPerIteration
        var resolvedInLastIteration = 0

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            var resolved = 0
            for _ in 0..<fullReads {
                for key in keys where ArTourKaminaljuyu.LocalizedStrings.get(key) != key {
                    resolved += 1
                }
            }
            resolvedInLastIteration = resolved
        }

        // Todas las claves deben resolverse a un texto (ninguna devuelve su identificador).
        XCTAssertEqual(resolvedInLastIteration, keys.count * fullReads)
    }
}
