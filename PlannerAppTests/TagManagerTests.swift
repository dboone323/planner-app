//
// TagManagerTests.swift
// PlannerAppTests
//
// High-fidelity tests for TagManager using the real PlannerTag model.
//

import SwiftUI
import XCTest
@testable import PlannerApp

@MainActor
final class TagManagerTests: XCTestCase {
    var manager: TagManager!

    override func setUp() async throws {
        try await super.setUp()
        self.manager = TagManager.shared
    }

    // MARK: - Initial State Tests

    func testDefaultTagsExist() {
        let tags = self.manager.getAllTags()
        XCTAssertFalse(tags.isEmpty)
    }

    func testWorkTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Work" })
    }

    func testPersonalTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Personal" })
    }

    func testUrgentTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Urgent" })
    }

    func testWaitingTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Waiting" })
    }

    // MARK: - Create Tag Tests

    func testCreateTagReturnsNewTag() {
        let newTag = self.manager.createTag(name: "Testing", color: .purple)
        XCTAssertEqual(newTag.name, "Testing")
        // Note: PlannerTag stores colorName as String, verified in TagManager.swift
        XCTAssertEqual(newTag.colorName, "custom")
    }

    func testCreateTagAddsToList() {
        let initialCount = self.manager.getAllTags().count
        _ = self.manager.createTag(name: "NewTag", color: .gray)
        XCTAssertEqual(self.manager.getAllTags().count, initialCount + 1)
    }

    func testCreatedTagIsRetrievable() {
        _ = self.manager.createTag(name: "Findable", color: .pink)
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Findable" })
    }

    // MARK: - Filter Tags Tests

    func testTagsForNames() {
        let filtered = self.manager.tags(for: ["Work", "Urgent"])
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.name == "Work" || $0.name == "Urgent" })
    }

    func testTagsForEmptyNames() {
        let filtered = self.manager.tags(for: [])
        XCTAssertTrue(filtered.isEmpty)
    }

    func testTagsForNonexistentNames() {
        let filtered = self.manager.tags(for: ["Nonexistent"])
        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - PlannerTag Struct Tests

    func testPlannerTagHasUniqueId() {
        let tag1 = PlannerTag(name: "Same", colorName: "blue")
        let tag2 = PlannerTag(name: "Same", colorName: "blue")
        XCTAssertNotEqual(tag1.id, tag2.id)
    }

    func testPlannerTagIsHashable() {
        let tag = PlannerTag(name: "Test", colorName: "red")
        var set = Set<PlannerTag>()
        set.insert(tag)
        XCTAssertTrue(set.contains(tag))
    }
}
