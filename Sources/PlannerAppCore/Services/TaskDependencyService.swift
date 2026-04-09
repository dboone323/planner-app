//
// TaskDependencyService.swift
// PlannerAppCore
//

import Foundation

/// Service for managing and validating task dependencies.
@MainActor
public class TaskDependencyService: @unchecked Sendable {
    public static let shared = TaskDependencyService()
    
    private var activeDependencies: [TaskDependency] = []

    private init() {}

    /// Checks if a task can be completed based on its blocking dependencies.
    public func canComplete(taskId: UUID, taskStatusProvider: (UUID) -> Bool) -> Bool {
        // Find all tasks that block this task
        let blockers = activeDependencies.filter { $0.targetTaskId == taskId && $0.type == .blocks }

        // Check if all blockers are complete
        for blocker in blockers where !taskStatusProvider(blocker.sourceTaskId) {
            return false
        }

        return true
    }
    
    /// Convenience method for performance tests and real usage
    public func canCompleteTask(_ task: PlannerTask) -> Bool {
        return canComplete(taskId: task.id) { _ in
            return true 
        }
    }

    /// Adds a dependency relationship.
    public func addDependency(from source: PlannerTask, to target: PlannerTask) {
        let dependency = TaskDependency(sourceTaskId: source.id, targetTaskId: target.id, type: .blocks)
        self.activeDependencies.append(dependency)
    }

    /// Retrieves all tasks blocked by the specified task.
    public func getBlockedTasks(for taskId: UUID) -> [UUID] {
        activeDependencies
            .filter { $0.sourceTaskId == taskId && $0.type == .blocks }
            .map(\.targetTaskId)
    }
    
    /// Returns the list of dependencies for a task.
    public func getDependencies(for task: PlannerTask) -> [TaskDependency] {
        return activeDependencies.filter { $0.targetTaskId == task.id }
    }
}
