//
// FocusModeManagerTests.swift
// PlannerAppTests
//
// Tests for focus mode state management
//

@testable import PlannerApp
import XCTest

final class FocusModeManagerTests: XCTestCase {
    var manager: FocusModeManager!

    override func setUpWithError() throws {
        manager = FocusModeManager()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsOff() {
        XCTAssertFalse(manager.isFocusModeEnabled)
    }

    // MARK: - Toggle Tests

    func testToggleTurnsOn() {
        // Given: Focus mode is off
        XCTAssertFalse(manager.isFocusModeEnabled)

        // When: Toggle
        manager.toggleFocusMode()

        // Then: Should be on
        XCTAssertTrue(manager.isFocusModeEnabled)
    }

    func testToggleTurnsOff() {
        // Given: Focus mode is on
        manager.toggleFocusMode()
        XCTAssertTrue(manager.isFocusModeEnabled)

        // When: Toggle again
        manager.toggleFocusMode()

        // Then: Should be off
        XCTAssertFalse(manager.isFocusModeEnabled)
    }

    func testDoubleToggleReturnsToOriginal() {
        let original = manager.isFocusModeEnabled
        manager.toggleFocusMode()
        manager.toggleFocusMode()
        XCTAssertEqual(manager.isFocusModeEnabled, original)
    }

    func testMultipleToggles() {
        // Toggle 5 times should end up in on state
        for _ in 0..<5 {
            manager.toggleFocusMode()
        }
        XCTAssertTrue(manager.isFocusModeEnabled)

        // Toggle once more should turn off
        manager.toggleFocusMode()
        XCTAssertFalse(manager.isFocusModeEnabled)
    }
}
