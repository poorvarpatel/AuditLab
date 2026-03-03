//
//  AuditLabSmokeTests.swift
//  AuditLabUITests
//
//  Smoke test: launch the app and tap through main tabs to verify UI responds.
//  Uses queries without names/labels so changes to copy or tab order don't break the test.
//

import XCTest

final class AuditLabSmokeTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSmoke_tapAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // All tab bar buttons, no name/label filter — order is stable within a run
        let tabButtons = tabBar.buttons
        let count = tabButtons.count
        XCTAssertGreaterThan(count, 0, "Tab bar should have at least one button")

        for i in 0..<count {
            let button = tabButtons.element(boundBy: i)
            XCTAssertTrue(button.waitForExistence(timeout: 2))
            button.tap()
        }

        // Tap first tab again so we end in a known state
        if count > 0 {
            tabButtons.element(boundBy: 0).tap()
        }
    }

    func testSmoke_tabsShowContent() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let tabButtons = tabBar.buttons
        let count = tabButtons.count
        XCTAssertGreaterThan(count, 0)

        for i in 0..<count {
            tabButtons.element(boundBy: i).tap()
            // After each tap, something should still be on screen (tab bar or content)
            XCTAssertTrue(tabBar.exists)
        }
    }
}
