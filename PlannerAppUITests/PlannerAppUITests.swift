//
//  PlannerAppUITests.swift
//  PlannerAppUITests
//
//  Created by Daniel Stevens on 4/28/25.
//

import XCTest

final class PlannerAppUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests
        // before they run.
        // The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        dismissSystemPermissionAlertsIfPresent(in: app)

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testScreenshot() {
        let app = XCUIApplication()
        app.launch()
        dismissSystemPermissionAlertsIfPresent(in: app)

        // Take a screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertNotNil(screenshot)
    }

    @MainActor
    func testLaunchPerformance() {
        let primingApp = XCUIApplication()
        primingApp.launch()
        dismissSystemPermissionAlertsIfPresent(in: primingApp)
        primingApp.terminate()

        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
        }
    }
}

extension XCTestCase {
    @MainActor
    func dismissSystemPermissionAlertsIfPresent(
        in app: XCUIApplication,
        timeout: TimeInterval = 3
    ) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let preferredButtons = [
            "Allow",
            "Allow While Using App",
            "Allow While Using the App",
            "Allow Once",
            "Allow Notifications",
            "Always Allow",
            "OK",
            "Continue",
        ]

        let interruptionToken = addUIInterruptionMonitor(withDescription: "System Permission Alert") { alert in
            Self.tapPreferredButton(in: alert, preferredButtons: preferredButtons)
        }
        defer {
            removeUIInterruptionMonitor(interruptionToken)
        }

        let deadline = Date().addingTimeInterval(timeout)
        var consecutiveNoAlertChecks = 0
        while Date() < deadline {
            if Self.handleAlert(in: app.alerts.firstMatch, preferredButtons: preferredButtons) {
                consecutiveNoAlertChecks = 0
                continue
            }

            if Self.handleAlert(in: springboard.alerts.firstMatch, preferredButtons: preferredButtons) {
                consecutiveNoAlertChecks = 0
                continue
            }

            app.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))

            if Self.handleAlert(in: springboard.alerts.firstMatch, preferredButtons: preferredButtons) {
                consecutiveNoAlertChecks = 0
                continue
            }

            consecutiveNoAlertChecks += 1
            if consecutiveNoAlertChecks >= 3 {
                break
            }
        }
    }

    @MainActor
    private static func handleAlert(
        in alert: XCUIElement,
        preferredButtons: [String]
    ) -> Bool {
        guard alert.exists else {
            return false
        }

        if tapPreferredButton(in: alert, preferredButtons: preferredButtons) {
            return true
        }

        let buttons = alert.buttons.allElementsBoundByIndex
        if buttons.count > 1 {
            buttons[1].tap()
            return true
        }

        if let first = buttons.first, first.exists {
            first.tap()
            return true
        }

        return false
    }

    @MainActor
    private static func tapPreferredButton(
        in alert: XCUIElement,
        preferredButtons: [String]
    ) -> Bool {
        for title in preferredButtons {
            let button = alert.buttons[title]
            if button.exists {
                button.tap()
                return true
            }
        }

        let allowMatch = alert.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Allow'")).firstMatch
        if allowMatch.exists {
            allowMatch.tap()
            return true
        }

        let approveMatch = alert.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'OK' OR label CONTAINS[c] 'Continue'")
        ).firstMatch
        if approveMatch.exists {
            approveMatch.tap()
            return true
        }

        return false
    }
}
