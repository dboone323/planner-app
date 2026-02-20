//
// TaskTemplateService.swift
// PlannerApp
//
// Service for task templates and quick add presets
//

import Foundation

struct TaskTemplate: Identifiable {
    let id = UUID()
    let name: String
    let defaultTitle: String
    let defaultPriority: Priority
    let defaultTags: [String]
    let checklistItems: [String]
}

enum Priority: Int, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class TaskTemplateService: @unchecked Sendable {
    static let shared = TaskTemplateService()

    func getTemplates() -> [TaskTemplate] {
        [
            TaskTemplate(
                name: "Bug Report",
                defaultTitle: "Fix Bug: ",
                defaultPriority: .high,
                defaultTags: ["bug", "dev"],
                checklistItems: ["Reproduce issue", "Identify root cause", "Fix code", "Verify fix"]
            ),
            TaskTemplate(
                name: "Meeting Prep",
                defaultTitle: "Prep for: ",
                defaultPriority: .medium,
                defaultTags: ["meeting", "work"],
                checklistItems: ["Review agenda", "Prepare slides", "Gather metrics"]
            ),
            TaskTemplate(
                name: "Grocery Run",
                defaultTitle: "Buy Groceries",
                defaultPriority: .low,
                defaultTags: ["personal", "shopping"],
                checklistItems: ["Milk", "Eggs", "Bread"]
            ),
        ]
    }
}
