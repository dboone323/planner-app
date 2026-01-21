import Foundation
import SwiftData

/// SwiftData model for PlannerApp goals.
/// Replaces the struct-based `Goal` with a persistent, CloudKit-syncable model.
@Model
final class SDGoal {
    // MARK: - Properties

    /// Unique identifier for the goal.
    @Attribute(.unique) var id: UUID

    /// The title or summary of the goal.
    var title: String

    /// Detailed description of the goal.
    var goalDescription: String

    /// The target date to achieve the goal.
    var targetDate: Date

    /// The date the goal was created.
    var createdAt: Date

    /// The date the goal was last modified.
    var modifiedAt: Date?

    /// Whether the goal is completed.
    var isCompleted: Bool

    /// The priority of the goal ("low", "medium", "high").
    var priority: String

    /// The progress toward the goal (0.0 to 1.0).
    var progress: Double

    // MARK: - Initializer

    /// Creates a new SDGoal.
    init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        targetDate: Date,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil,
        isCompleted: Bool = false,
        priority: String = "medium",
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isCompleted = isCompleted
        self.priority = priority
        self.progress = progress
    }

    // MARK: - Convenience Methods

    /// Priority as a sortable integer.
    var prioritySortOrder: Int {
        switch priority {
        case "high": 3
        case "medium": 2
        case "low": 1
        default: 0
        }
    }

    /// Updates progress and marks completed if 100%.
    func updateProgress(_ newProgress: Double) {
        progress = min(1.0, max(0.0, newProgress))
        modifiedAt = Date()
        if progress >= 1.0 {
            isCompleted = true
        }
    }
}

// MARK: - Legacy Migration Extension

extension SDGoal {
    /// Creates an SDGoal from a legacy Goal struct.
    convenience init(from legacy: Goal) {
        self.init(
            id: legacy.id,
            title: legacy.title,
            goalDescription: legacy.description,
            targetDate: legacy.targetDate,
            createdAt: legacy.createdAt,
            modifiedAt: legacy.modifiedAt,
            isCompleted: legacy.isCompleted,
            priority: legacy.priority.rawValue,
            progress: legacy.progress
        )
    }
}
