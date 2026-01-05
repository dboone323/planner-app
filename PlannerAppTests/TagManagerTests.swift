//
// TagManagerTests.swift
// PlannerAppTests
//
// Tests for tag management functionality
//

import XCTest
import SwiftUI
@testable import PlannerApp

final class TagManagerTests: XCTestCase {
    
    var manager: TagManager!
    
    override func setUpWithError() throws {
        manager = TagManager.shared
    }
    
    // MARK: - Initial State Tests
    
    func testDefaultTagsExist() {
        let tags = manager.getAllTags()
        XCTAssertFalse(tags.isEmpty)
    }
    
    func testWorkTagExists() {
        let tags = manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Work" })
    }
    
    func testPersonalTagExists() {
        let tags = manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Personal" })
    }
    
    func testUrgentTagExists() {
        let tags = manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Urgent" })
    }
    
    func testWaitingTagExists() {
        let tags = manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Waiting" })
    }
    
    // MARK: - Create Tag Tests
    
    func testCreateTagReturnsNewTag() {
        let newTag = manager.createTag(name: "Testing", color: .purple)
        XCTAssertEqual(newTag.name, "Testing")
        XCTAssertEqual(newTag.color, .purple)
    }
    
    func testCreateTagAddsToList() {
        let initialCount = manager.getAllTags().count
        _ = manager.createTag(name: "NewTag", color: .gray)
        XCTAssertEqual(manager.getAllTags().count, initialCount + 1)
    }
    
    func testCreatedTagIsRetrievable() {
        _ = manager.createTag(name: "Findable", color: .pink)
        let tags = manager.getAllTags()
        XCTAssertTrue(tags.contains { $0.name == "Findable" })
    }
    
    // MARK: - Filter Tags Tests
    
    func testTagsForNames() {
        let filtered = manager.tags(for: ["Work", "Urgent"])
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.name == "Work" || $0.name == "Urgent" })
    }
    
    func testTagsForEmptyNames() {
        let filtered = manager.tags(for: [])
        XCTAssertTrue(filtered.isEmpty)
    }
    
    func testTagsForNonexistentNames() {
        let filtered = manager.tags(for: ["Nonexistent"])
        XCTAssertTrue(filtered.isEmpty)
    }
    
    // MARK: - Tag Struct Tests
    
    func testTagHasUniqueId() {
        let tag1 = Tag(name: "Same", color: .blue)
        let tag2 = Tag(name: "Same", color: .blue)
        XCTAssertNotEqual(tag1.id, tag2.id)
    }
    
    func testTagIsHashable() {
        let tag = Tag(name: "Test", color: .red)
        var set = Set<Tag>()
        set.insert(tag)
        XCTAssertTrue(set.contains(tag))
    }
}
