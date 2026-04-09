//
// PriorityManager.swift
// PlannerAppCore
//

import SwiftUI
import Foundation

/// Service for managing task prioritization logic.
@MainActor
public class PriorityManager: @unchecked Sendable {
    public static let shared = PriorityManager()

    private init() {}

    /// Returns the suggested color for a priority level
    public func color(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: .blue
        case .medium: .yellow
        case .high: .orange
        case .critical: .red
        }
    }

    /// Returns the SF Symbol name for a priority level
    public func icon(for priority: TaskPriority) -> String {
        switch priority {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        case .critical: "exclamationmark.triangle.fill"
        }
    }

    /// Sorts an array of PlannerTasks by priority and due date
    public func sortTasks(_ tasks: [PlannerTask]) -> [PlannerTask] {
        tasks.sorted {
            if $0.priority.rawValue != $1.priority.rawValue {
                return $0.priority.rawValue > $1.priority.rawValue
            }
            return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }

    /// Calculates a priority score (0.0 to 1.0) for a task based on its context
    public func getPriorityScore(for task: PlannerTask) -> Double {
        var score = 0.5
        
        switch task.priority {
        case .critical: score += 0.4
        case .high: score += 0.3
        case .medium: score += 0.1
        case .low: score -= 0.1
        }
        
        if let dueDate = task.dueDate {
            let timeToDue = dueDate.timeIntervalSinceNow
            if timeToDue < 0 {
                score += 0.2 // Overdue
            } else if timeToDue < 86400 {
                score += 0.15 // Due within 24 hours
            }
        }
        
        return min(1.0, max(0.0, score))
    }

    /// Update priority for a task based on its context
    public func updatePriority(for task: PlannerTask, basedOn context: TaskContext) {
        let newScore = getPriorityScore(for: task)
        task.sentimentScore = newScore
        task.modifiedAt = Date()
    }
    
    /// Re-prioritizes a collection of tasks
    public func getPrioritizedTasks(from tasks: [PlannerTask]) -> [PlannerTask] {
        return self.sortTasks(tasks)
    }
}
