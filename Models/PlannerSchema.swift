import Foundation
import SwiftData

/// The versioned schema definitions for PlannerApp.
enum PlannerSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SDTask.self, SDGoal.self]
    }

    @Model
    final class SDTask {
        @Attribute(.unique) var id: UUID
        var title: String
        var taskDescription: String
        var isCompleted: Bool
        var priority: String
        var dueDate: Date?
        var createdAt: Date
        var modifiedAt: Date?
        var calendarEventId: String?
        var estimatedDuration: TimeInterval
        var sentiment: String
        var sentimentScore: Double

        init(
            id: UUID = UUID(),
            title: String,
            taskDescription: String = "",
            isCompleted: Bool = false,
            priority: String = "medium",
            dueDate: Date? = nil,
            createdAt: Date = Date(),
            modifiedAt: Date? = nil,
            calendarEventId: String? = nil,
            estimatedDuration: TimeInterval = 3600,
            sentiment: String = "neutral",
            sentimentScore: Double = 0.0
        ) {
            self.id = id
            self.title = title
            self.taskDescription = taskDescription
            self.isCompleted = isCompleted
            self.priority = priority
            self.dueDate = dueDate
            self.createdAt = createdAt
            self.modifiedAt = modifiedAt
            self.calendarEventId = calendarEventId
            self.estimatedDuration = estimatedDuration
            self.sentiment = sentiment
            self.sentimentScore = sentimentScore
        }

        // MARK: - Logic

        func analyzeSentiment() {
            let lower = self.taskDescription.lowercased()
            let positives = [
                "love", "great", "excellent", "happy", "good", "amazing", "wonderful", "fast",
                "clean",
            ]
            let negatives = [
                "hate", "bad", "terrible", "slow", "bug", "broken", "awful", "poor", "crash",
            ]

            let positiveCount = positives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            let negativeCount = negatives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
            let rawScore = Double(positiveCount - negativeCount)
            let normalizedScore = max(-1.0, min(1.0, rawScore / 5.0))

            self.sentimentScore = normalizedScore
            self.sentiment =
                normalizedScore > 0.2
                ? "positive" : (normalizedScore < -0.2 ? "negative" : "neutral")
            self.modifiedAt = Date()
        }

        var prioritySortOrder: Int {
            switch self.priority {
            case "high": 3
            case "medium": 2
            case "low": 1
            default: 0
            }
        }
    }

    @Model
    final class SDGoal {
        @Attribute(.unique) var id: UUID
        var title: String
        var goalDescription: String
        var targetDate: Date
        var createdAt: Date
        var modifiedAt: Date?
        var isCompleted: Bool
        var priority: String
        var progress: Double

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

        // MARK: - Logic

        var prioritySortOrder: Int {
            switch self.priority {
            case "high": 3
            case "medium": 2
            case "low": 1
            default: 0
            }
        }

        func updateProgress(_ newProgress: Double) {
            self.progress = min(1.0, max(0.0, newProgress))
            self.modifiedAt = Date()
            if self.progress >= 1.0 {
                self.isCompleted = true
            }
        }
    }
}

// MARK: - Migration Plan

enum PlannerMigrationPlan: SchemaMigrationPlan {
    static var stages: [MigrationStage] {
        []  // No migrations yet
    }
    static var schemas: [any VersionedSchema.Type] {
        [PlannerSchemaV1.self]
    }
}

// MARK: - Typealiases

typealias SDTask = PlannerSchemaV1.SDTask
typealias SDGoal = PlannerSchemaV1.SDGoal

// MARK: - Legacy Migration Extensions

extension SDTask {
    convenience init(from legacy: PlannerTask) {
        self.init(
            id: legacy.id,
            title: legacy.title,
            taskDescription: legacy.description,
            isCompleted: legacy.isCompleted,
            priority: legacy.priority.rawValue,
            dueDate: legacy.dueDate,
            createdAt: legacy.createdAt,
            modifiedAt: legacy.modifiedAt,
            calendarEventId: legacy.calendarEventId,
            estimatedDuration: legacy.estimatedDuration,
            sentiment: legacy.sentiment,
            sentimentScore: legacy.sentimentScore
        )
    }
}

extension SDGoal {
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
