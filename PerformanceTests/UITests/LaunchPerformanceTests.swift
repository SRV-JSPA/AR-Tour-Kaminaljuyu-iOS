//
//  LaunchPerformanceTests.swift
//  ArTourKaminaljuyuPerformanceUITests
//
//  Prueba de rendimiento del arranque de la app (UI test + XCTApplicationLaunchMetric).
//

import XCTest

final class LaunchPerformanceTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tiempo de arranque de la app, con 5 repeticiones.
    func testLaunchPerformance() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 5

        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            XCUIApplication().launch()
        }
    }
}
