//
// PriorityManager.swift
// PlannerApp
//
// Service for managing task prioritization logic
//

import SwiftUI

class PriorityManager {
    static let shared = PriorityManager()
    
    func color(for priority: Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    func icon(for priority: Priority) -> String {
        switch priority {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
    
    func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        // Sort by priority (descending) then due date (ascending)
        return tasks.sorted {
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
