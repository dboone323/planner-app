// MARK: - Task Model

import CloudKit
import CoreTransferable
import Foundation

/// Represents the priority of a task (low, medium, high).
public enum TaskPriority: String, CaseIterable, Codable {
    /// Low priority task.
    case low
    /// Medium priority task.
    case medium
    /// High priority task.
    case high

    /// Human-readable display name for the priority.
    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    /// Sort order for priority (higher number = higher priority).
    var sortOrder: Int {
        switch self {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }
}

/// Represents a user task or to-do item in the PlannerApp.
public struct PlannerTask: Identifiable, Codable, Transferable {
    /// Unique identifier for the task.
    public let id: UUID
    /// The title or summary of the task.
    var title: String
    /// Detailed description of the task.
    var description: String
    /// Whether the task is completed.
    var isCompleted: Bool
    /// The priority of the task.
    var priority: TaskPriority
    /// The due date for the task (optional).
    var dueDate: Date?
    /// The date the task was created.
    var createdAt: Date
    /// The date the task was last modified (optional).
    /// The date the task was last modified (optional).
    var modifiedAt: Date? // Added for CloudKit sync/merge

    // Project association
    /// ID of the project this task belongs to (optional).
    var projectId: UUID?

    // Sync properties
    /// Calendar event identifier for sync
    var calendarEventId: String?
    /// Estimated duration in seconds
    var estimatedDuration: TimeInterval

    // Sentiment analysis properties
    /// Sentiment of task description ("positive", "negative", or "neutral")
    var sentiment: String
    /// Sentiment score from -1.0 (negative) to 1.0 (positive)
    var sentimentScore: Double

    /// Creates a new task.
    /// - Parameters:
    ///   - id: The unique identifier (default: new UUID).
    ///   - title: The task title.
    ///   - description: The task description (default: empty).
    ///   - isCompleted: Whether the task is completed (default: false).
    ///   - priority: The task priority (default: .medium).
    ///   - dueDate: The due date (optional).
    ///   - projectId: ID of the project this task belongs to (optional).
    ///   - estimatedDuration: Estimated duration in seconds (default: 3600).
    ///   - calendarEventId: ID of synced calendar event (optional).
    ///   - createdAt: The creation date (default: now).
    ///   - modifiedAt: The last modified date (default: now).
    ///   - sentiment: The sentiment label (default: "neutral").
    ///   - sentimentScore: The sentiment score (default: 0.0).
    init(
        id: UUID = UUID(), title: String, description: String = "", isCompleted: Bool = false,
        priority: TaskPriority = .medium, dueDate: Date? = nil, projectId: UUID? = nil,
        estimatedDuration: TimeInterval = 3600,
        calendarEventId: String? = nil, createdAt: Date = Date(),
        modifiedAt: Date? = Date(), sentiment: String = "neutral", sentimentScore: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.projectId = projectId
        self.estimatedDuration = estimatedDuration
        self.calendarEventId = calendarEventId
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.sentiment = sentiment
        self.sentimentScore = sentimentScore
    }

    // MARK: - Sentiment Analysis

    /// Update task description and trigger sentiment analysis
    mutating func updateDescription(_ newDescription: String) {
        self.description = newDescription
        self.modifiedAt = Date()

        // Analyze sentiment synchronously
        self.analyzeSentiment()
    }

    /// Analyze sentiment of task description using keyword-based scoring
    mutating func analyzeSentiment() {
        // Inline keyword-based sentiment analysis
        let lower = self.description.lowercased()
        let positives = [
            "love", "great", "excellent", "happy", "good", "amazing", "wonderful", "fast", "clean",
        ]
        let negatives = [
            "hate", "bad", "terrible", "slow", "bug", "broken", "awful", "poor", "crash",
        ]
        let positiveCount = positives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let negativeCount = negatives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let rawScore = Double(positiveCount - negativeCount)
        let normalizedScore = max(-1.0, min(1.0, rawScore / 5.0))

        self.sentimentScore = normalizedScore
        self.sentiment = normalizedScore > 0.2 ? "positive" : (normalizedScore < -0.2 ? "negative" : "neutral")
    }

    // MARK: - CloudKit Conversion

    /// Converts this task to a CloudKit record for syncing.
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Task", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["title"] = self.title
        record["description"] = self.description
        record["isCompleted"] = self.isCompleted
        record["priority"] = self.priority.rawValue
        record["dueDate"] = self.dueDate
        record["projectId"] = self.projectId?.uuidString
        record["estimatedDuration"] = self.estimatedDuration
        record["calendarEventId"] = self.calendarEventId
        record["createdAt"] = self.createdAt
        record["modifiedAt"] = self.modifiedAt
        record["sentiment"] = self.sentiment
        record["sentimentScore"] = self.sentimentScore
        return record
    }

    /// Creates a Task from a CloudKit record.
    /// - Parameter ckRecord: The CloudKit record to convert.
    /// - Throws: An error if conversion fails.
    /// - Returns: A Task instance.
    static func from(ckRecord: CKRecord) throws -> PlannerTask {
        guard
            let title = ckRecord["title"] as? String,
            let createdAt = ckRecord["createdAt"] as? Date,
            let idString = ckRecord.recordID.recordName.components(separatedBy: "/").last,
            let id = UUID(uuidString: idString)
        else {
            throw NSError(
                domain: "TaskConversionError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert CloudKit record to Task"]
            )
        }

        return PlannerTask(
            id: id,
            title: title,
            description: ckRecord["description"] as? String ?? "",
            isCompleted: ckRecord["isCompleted"] as? Bool ?? false,
            priority: TaskPriority(rawValue: ckRecord["priority"] as? String ?? "medium")
                ?? .medium,
            dueDate: ckRecord["dueDate"] as? Date,
            projectId: (ckRecord["projectId"] as? String).flatMap { UUID(uuidString: $0) },
            estimatedDuration: ckRecord["estimatedDuration"] as? TimeInterval ?? 3600,
            calendarEventId: ckRecord["calendarEventId"] as? String,
            createdAt: createdAt,
            modifiedAt: ckRecord["modifiedAt"] as? Date,
            sentiment: ckRecord["sentiment"] as? String ?? "neutral",
            sentimentScore: ckRecord["sentimentScore"] as? Double ?? 0.0
        )
    }

    // MARK: - Transferable Implementation

    /// Transferable conformance for drag-and-drop and sharing.
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
