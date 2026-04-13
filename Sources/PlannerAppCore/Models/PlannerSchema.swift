import Foundation
import SwiftData

/// The versioned schema definitions for PlannerApp.
public enum PlannerSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [SDTask.self, SDGoal.self]
    }

    @Model
    public final class SDTask {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var taskDescription: String
        public var isCompleted: Bool
        public var priority: String
        public var dueDate: Date?
        public var createdAt: Date
        public var modifiedAt: Date?
        public var calendarEventId: String?
        public var estimatedDuration: TimeInterval
        public var sentiment: String
        public var sentimentScore: Double

        public init(
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

        public func analyzeSentiment() {
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
                    ? "positive"
                    : (normalizedScore < -0.2 ? "negative" : "neutral")
            self.modifiedAt = Date()
        }

        public var prioritySortOrder: Int {
            switch self.priority {
            case "high": 3
            case "medium": 2
            case "low": 1
            default: 0
            }
        }
    }

    @Model
    public final class SDGoal {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var goalDescription: String
        public var targetDate: Date
        public var createdAt: Date
        public var modifiedAt: Date?
        public var isCompleted: Bool
        public var priority: String
        public var progress: Double

        public init(
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

        public var prioritySortOrder: Int {
            switch self.priority {
            case "high": 3
            case "medium": 2
            case "low": 1
            default: 0
            }
        }

        public func updateProgress(_ newProgress: Double) {
            self.progress = min(1.0, max(0.0, newProgress))
            self.modifiedAt = Date()
            if self.progress >= 1.0 {
                self.isCompleted = true
            }
        }
    }
}

// MARK: - Migration Plan

public enum PlannerMigrationPlan: SchemaMigrationPlan {
    public static var stages: [MigrationStage] {
        [] // No migrations yet
    }

    public static var schemas: [any VersionedSchema.Type] {
        [PlannerSchemaV1.self]
    }
}

// MARK: - Typealiases

public typealias SDTask = PlannerSchemaV1.SDTask
public typealias SDGoal = PlannerSchemaV1.SDGoal

// MARK: - Legacy Migration Extensions

extension SDTask {
    public convenience init(from legacy: PlannerTask) {
        self.init(
            id: legacy.id,
            title: legacy.title,
            taskDescription: legacy.taskDescription ?? "",
            isCompleted: legacy.isCompleted,
            priority: legacy.priority.rawValue.description,
            dueDate: legacy.dueDate,
            createdAt: legacy.createdAt,
            modifiedAt: legacy.modifiedAt,
            calendarEventId: nil,
            estimatedDuration: legacy.estimatedDuration,
            sentiment: "neutral",
            sentimentScore: legacy.sentimentScore
        )
    }
}

extension SDGoal {
    public convenience init(from legacy: PlannerGoal) {
        self.init(
            id: legacy.id,
            title: legacy.title,
            goalDescription: legacy.goalDescription,
            targetDate: legacy.targetDate,
            createdAt: legacy.createdAt,
            modifiedAt: legacy.modifiedAt,
            isCompleted: legacy.isCompleted,
            priority: legacy.priority.rawValue.description,
            progress: legacy.progress
        )
    }
}
