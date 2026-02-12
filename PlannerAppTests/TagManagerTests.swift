//
// TagManagerTests.swift
// PlannerAppTests
//
// Tests for tag management functionality
//

import SwiftUI
import XCTest
@testable import PlannerApp

final class TagManagerTests: XCTestCase, @unchecked Sendable {
    @MainActor var manager: TagManager!

    override nonisolated func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            self.manager = TagManager.shared
        }
    }

    // MARK: - Initial State Tests

    @MainActor
    func testDefaultTagsExist() {
        let tags = self.manager.getAllTags()
        XCTAssertFalse(tags.isEmpty)
    }

    @MainActor
    func testWorkTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Work" })
    }

    @MainActor
    func testPersonalTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Personal" })
    }

    @MainActor
    func testUrgentTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Urgent" })
    }

    @MainActor
    func testWaitingTagExists() {
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Waiting" })
    }

    // MARK: - Create Tag Tests

    @MainActor
    func testCreateTagReturnsNewTag() {
        let newTag = self.manager.createTag(name: "Testing", color: .purple)
        XCTAssertEqual(newTag.name, "Testing")
        XCTAssertEqual(newTag.color, .purple)
    }

    @MainActor
    func testCreateTagAddsToList() {
        let initialCount = self.manager.getAllTags().count
        _ = self.manager.createTag(name: "NewTag", color: .gray)
        XCTAssertEqual(self.manager.getAllTags().count, initialCount + 1)
    }

    @MainActor
    func testCreatedTagIsRetrievable() {
        _ = self.manager.createTag(name: "Findable", color: .pink)
        let tags = self.manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Findable" })
    }

    // MARK: - Filter Tags Tests

    @MainActor
    func testTagsForNames() {
        let filtered = self.manager.tags(for: ["Work", "Urgent"])
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.name == "Work" || $0.name == "Urgent" })
    }

    @MainActor
    func testTagsForEmptyNames() {
        let filtered = self.manager.tags(for: [])
        XCTAssertTrue(filtered.isEmpty)
    }

    @MainActor
    func testTagsForNonexistentNames() {
        let filtered = self.manager.tags(for: ["Nonexistent"])
        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Tag Struct Tests

    @MainActor
    func testTagHasUniqueId() {
        let tag1 = Tag(name: "Same", color: .blue)
        let tag2 = Tag(name: "Same", color: .blue)
        XCTAssertNotEqual(tag1.id, tag2.id)
    }

    @MainActor
    func testTagIsHashable() {
        let tag = Tag(name: "Test", color: .red)
        var set = Set<Tag>()
        set.insert(tag)
        XCTAssertTrue(set.contains(tag))
    }
}
