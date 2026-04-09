//
// TagManager.swift
// PlannerAppCore
//

import SwiftUI
import Foundation

/// Service for managing tags and labels across the application.
@MainActor
public class TagManager: @unchecked Sendable {
    public static let shared = TagManager()

    private var tags: [PlannerTag] = [
        PlannerTag(name: "Work", colorName: "blue"),
        PlannerTag(name: "Personal", colorName: "green"),
        PlannerTag(name: "Urgent", colorName: "red"),
        PlannerTag(name: "Waiting", colorName: "orange"),
    ]

    private init() {}

    /// Returns all registered tags.
    public func getAllTags() -> [PlannerTag] {
        self.tags
    }

    /// Creates and registers a new tag.
    public func createTag(name: String, colorName: String = "custom") -> PlannerTag {
        let newTag = PlannerTag(name: name, colorName: colorName)
        self.tags.append(newTag)
        return newTag
    }
    
    /// Overload for reality tests that might use the real struct
    public func registerTag(_ tag: PlannerTag) {
        self.tags.append(tag)
    }

    /// Finds tags by their names.
    public func tags(for names: [String]) -> [PlannerTag] {
        self.tags.filter { names.contains($0.name) }
    }
    
    /// Returns statistics for all tags (e.g., usage count).
    public func getTagStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        for tag in tags {
            stats[tag.name] = 0 // In reality, count tasks
        }
        return stats
    }
}
