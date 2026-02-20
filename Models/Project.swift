// MARK: - Project Model

import CloudKit
import CoreTransferable
import Foundation

/// Represents the status of a project.
public enum ProjectStatus: String, CaseIterable, Codable {
    /// Project is currently active.
    case active
    /// Project is completed.
    case completed
    /// Project is on hold.
    case onHold
    /// Project is cancelled.
    case cancelled

    /// Human-readable display name for the status.
    var displayName: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        case .onHold: "On Hold"
        case .cancelled: "Cancelled"
        }
    }

    /// Color associated with the status.
    var color: String {
        switch self {
        case .active: "blue"
        case .completed: "green"
        case .onHold: "orange"
        case .cancelled: "red"
        }
    }
}

/// Represents a project that can contain multiple tasks.
public struct PlannerProject: Identifiable, Codable, Transferable {
    /// Unique identifier for the project.
    public let id: UUID
    /// The name of the project.
    var name: String
    /// Detailed description of the project.
    var description: String
    /// The current status of the project.
    var status: ProjectStatus
    /// The color theme for the project.
    var color: String
    /// The date the project was created.
    var createdAt: Date
    /// The date the project was last modified.
    var modifiedAt: Date?
    /// Target completion date for the project.
    var targetCompletionDate: Date?
    /// Actual completion date (if completed).
    var completedAt: Date?

    /// Creates a new project.
    /// - Parameters:
    ///   - id: The unique identifier (default: new UUID).
    ///   - name: The project name.
    ///   - description: The project description (default: empty).
    ///   - status: The project status (default: .active).
    ///   - color: The project color theme (default: "blue").
    ///   - targetCompletionDate: Target completion date (optional).
    ///   - createdAt: The creation date (default: now).
    ///   - modifiedAt: The last modified date (default: now).
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        status: ProjectStatus = .active,
        color: String = "blue",
        targetCompletionDate: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date? = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.color = color
        self.targetCompletionDate = targetCompletionDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.completedAt = nil
    }

    /// Marks the project as completed.
    mutating func markCompleted() {
        self.status = .completed
        self.completedAt = Date()
        self.modifiedAt = Date()
    }

    /// Calculates the progress of the project based on associated tasks.
    /// - Parameter tasks: The tasks associated with this project.
    /// - Returns: Progress as a value between 0.0 and 1.0.
    func progress(with tasks: [PlannerTask]) -> Double {
        let projectTasks = tasks.filter { $0.projectId == self.id }
        guard !projectTasks.isEmpty else { return 0.0 }

        let completedTasks = projectTasks.filter(\.isCompleted)
        return Double(completedTasks.count) / Double(projectTasks.count)
    }

    /// Returns the number of tasks in this project.
    /// - Parameter tasks: The tasks to count.
    /// - Returns: The number of tasks associated with this project.
    func taskCount(with tasks: [PlannerTask]) -> Int {
        tasks.count(where: { $0.projectId == self.id })
    }

    /// Returns the number of completed tasks in this project.
    /// - Parameter tasks: The tasks to count.
    /// - Returns: The number of completed tasks associated with this project.
    func completedTaskCount(with tasks: [PlannerTask]) -> Int {
        tasks.count(where: { $0.projectId == self.id && $0.isCompleted })
    }
}
