//
// TagManager.swift
// PlannerApp
//
// Service for managing tags and labels
//

import SwiftUI

struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
}

class TagManager {
    static let shared = TagManager()

    private var tags: [Tag] = [
        Tag(name: "Work", color: .blue),
        Tag(name: "Personal", color: .green),
        Tag(name: "Urgent", color: .red),
        Tag(name: "Waiting", color: .orange)
    ]

    func getAllTags() -> [Tag] {
        return tags
    }

    func createTag(name: String, color: Color) -> Tag {
        let newTag = Tag(name: name, color: color)
        tags.append(newTag)
        return newTag
    }

    func tags(for names: [String]) -> [Tag] {
        return tags.filter { names.contains($0.name) }
    }
}
