//
// TaskDependencyService.swift
// PlannerApp
//
// Service for managing task dependencies (blocking/blocked by)
//

import Foundation

enum DependencyType: String, Codable {
    case blocks
    case blockedBy
}

struct TaskDependency: Identifiable, Codable {
    let id: UUID
    let sourceTaskId: UUID
    let targetTaskId: UUID
    let type: DependencyType
}

class TaskDependencyService: @unchecked Sendable {
    static let shared = TaskDependencyService()

    func canComplete(taskId: UUID, dependencies: [TaskDependency], taskStatusProvider: (UUID) -> Bool) -> Bool {
        // Find all tasks that block this task
        let blockers = dependencies.filter { $0.targetTaskId == taskId && $0.type == .blocks }

        // Check if all blockers are complete
        for blocker in blockers where !taskStatusProvider(blocker.sourceTaskId) {
            return false
        }

        return true
    }

    func getBlockedTasks(for taskId: UUID, dependencies: [TaskDependency]) -> [UUID] {
        dependencies
            .filter { $0.sourceTaskId == taskId && $0.type == .blocks }
            .map(\.targetTaskId)
    }
}
