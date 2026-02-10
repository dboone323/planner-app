//
// PriorityManager.swift
// PlannerApp
//
// Service for managing task prioritization logic
//

import SwiftUI

class PriorityManager: @unchecked Sendable {
    static let shared = PriorityManager()

    func color(for priority: Priority) -> Color {
        switch priority {
        case .low: .blue
        case .medium: .yellow
        case .high: .orange
        case .critical: .red
        }
    }

    func icon(for priority: Priority) -> String {
        switch priority {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        case .critical: "exclamationmark.triangle.fill"
        }
    }

    func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        // Sort by priority (descending) then due date (ascending)
        tasks.sorted {
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }
}

// Placeholder TaskItem struct
struct TaskItem: Identifiable {
    let id = UUID()
    let title: String
    let priority: Priority
    let dueDate: Date?
    var isCompleted: Bool
}
