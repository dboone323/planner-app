//
// FocusModeManagerTests.swift
// PlannerAppTests
//
// Tests for focus mode state management
//

import XCTest
@testable import PlannerApp

final class FocusModeManagerTests: XCTestCase {
    var manager: FocusModeManager!

    override func setUpWithError() throws {
        self.manager = FocusModeManager()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsOff() {
        XCTAssertFalse(self.manager.isFocusModeEnabled)
    }

    // MARK: - Toggle Tests

    func testToggleTurnsOn() {
        // Given: Focus mode is off
        XCTAssertFalse(self.manager.isFocusModeEnabled)

        // When: Toggle
        self.manager.toggleFocusMode()

        // Then: Should be on
        XCTAssertTrue(self.manager.isFocusModeEnabled)
    }

    func testToggleTurnsOff() {
        // Given: Focus mode is on
        self.manager.toggleFocusMode()
        XCTAssertTrue(self.manager.isFocusModeEnabled)

        // When: Toggle again
        self.manager.toggleFocusMode()

        // Then: Should be off
        XCTAssertFalse(self.manager.isFocusModeEnabled)
    }

    func testDoubleToggleReturnsToOriginal() {
        let original = self.manager.isFocusModeEnabled
        self.manager.toggleFocusMode()
        self.manager.toggleFocusMode()
        XCTAssertEqual(self.manager.isFocusModeEnabled, original)
    }

    func testMultipleToggles() {
        // Toggle 5 times should end up in on state
        for _ in 0 ..< 5 {
            self.manager.toggleFocusMode()
        }
        XCTAssertTrue(self.manager.isFocusModeEnabled)

        // Toggle once more should turn off
        self.manager.toggleFocusMode()
        XCTAssertFalse(self.manager.isFocusModeEnabled)
    }
}
