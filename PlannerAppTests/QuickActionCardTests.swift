//
//  QuickActionCardTests.swift
//  PlannerAppTests
//
//  Tests for QuickActionCard value wiring and action behavior.
//

import SwiftUI
import PlannerAppCore
import XCTest
@testable import PlannerApp

@MainActor
final class QuickActionCardTests: XCTestCase {
    func testInitialization() {
        var tapped = false
        let card = QuickActionCard(
            title: "Add PlannerTask",
            icon: "plus.circle.fill",
            color: .blue
        ) {
            tapped = true
        }

        XCTAssertEqual(card.title, "Add PlannerTask")
        XCTAssertEqual(card.icon, "plus.circle.fill")
        XCTAssertEqual(card.color, .blue)
        XCTAssertFalse(tapped)

        card.action()
        XCTAssertTrue(tapped)
    }

    func testProperties() {
        let card = QuickActionCard(
            title: "Focus Session",
            icon: "timer",
            color: .orange
        ) {}

        XCTAssertEqual(card.title, "Focus Session")
        XCTAssertEqual(card.icon, "timer")
        XCTAssertEqual(card.color, .orange)
    }

    func testPublicMethods() {
        var tapCount = 0
        let card = QuickActionCard(
            title: "Tap",
            icon: "hand.tap",
            color: .green
        ) {
            tapCount += 1
        }

        card.action()
        card.action()
        card.action()

        XCTAssertEqual(tapCount, 3)
    }

    func testEdgeCases() {
        var invoked = false
        let card = QuickActionCard(
            title: "",
            icon: "",
            color: .clear
        ) {
            invoked = true
        }

        XCTAssertEqual(card.title, "")
        XCTAssertEqual(card.icon, "")
        XCTAssertEqual(card.color, .clear)

        card.action()
        XCTAssertTrue(invoked)
    }

    func testErrorHandling() {
        var state = "initial"
        let card = QuickActionCard(
            title: "Recover",
            icon: "arrow.clockwise",
            color: .red
        ) {
            state = "updated"
        }

        card.action()
        XCTAssertEqual(state, "updated")
    }

    func testIntegration() {
        var selectedAction = ""
        let card = QuickActionCard(
            title: "Add Event",
            icon: "calendar.badge.plus",
            color: .purple
        ) {
            selectedAction = "calendar.badge.plus"
        }

        card.action()
        XCTAssertEqual(selectedAction, card.icon)
    }
}
