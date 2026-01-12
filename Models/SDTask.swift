import Foundation
import SwiftData

/// SwiftData model for PlannerApp tasks.
/// Replaces the struct-based `PlannerTask` with a persistent, CloudKit-syncable model.
@Model
final class SDTask {
    // MARK: - Properties
    
    /// Unique identifier for the task.
    @Attribute(.unique) var id: UUID
    
    /// The title or summary of the task.
    var title: String
    
    /// Detailed description of the task.
    var taskDescription: String
    
    /// Whether the task is completed.
    var isCompleted: Bool
    
    /// The priority of the task ("low", "medium", "high").
    var priority: String
    
    /// The due date for the task (optional).
    var dueDate: Date?
    
    /// The date the task was created.
    var createdAt: Date
    
    /// The date the task was last modified.
    var modifiedAt: Date?
    
    /// Calendar event identifier for sync.
    var calendarEventId: String?
    
    /// Estimated duration in seconds.
    var estimatedDuration: TimeInterval
    
    /// Sentiment of task description ("positive", "negative", or "neutral").
    var sentiment: String
    
    /// Sentiment score from -1.0 (negative) to 1.0 (positive).
    var sentimentScore: Double
    
    // MARK: - Initializer
    
    /// Creates a new SDTask.
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
    
    // MARK: - Convenience Methods
    
    /// Updates sentiment based on description content.
    func analyzeSentiment() {
        let lower = taskDescription.lowercased()
        let positives = ["love", "great", "excellent", "happy", "good", "amazing", "wonderful", "fast", "clean"]
        let negatives = ["hate", "bad", "terrible", "slow", "bug", "broken", "awful", "poor", "crash"]
        
        let positiveCount = positives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let negativeCount = negatives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let rawScore = Double(positiveCount - negativeCount)
        let normalizedScore = max(-1.0, min(1.0, rawScore / 5.0))
        
        self.sentimentScore = normalizedScore
        self.sentiment = normalizedScore > 0.2 ? "positive" : (normalizedScore < -0.2 ? "negative" : "neutral")
        self.modifiedAt = Date()
    }
    
    /// Priority as a sortable integer.
    var prioritySortOrder: Int {
        switch priority {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }
}

// MARK: - Legacy Migration Extension

extension SDTask {
    /// Creates an SDTask from a legacy PlannerTask struct.
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
