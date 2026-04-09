import Foundation
import SwiftData

/// Represents the priority of a task or goal.
public enum TaskPriority: Int, CaseIterable, Codable, Comparable, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    public var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .critical: "Critical"
        }
    }

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Consolidated SwiftData model for Tasks in PlannerApp.
@Model
public final class PlannerTask: Identifiable, Hashable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var taskDescription: String
    public var isCompleted: Bool
    public var priorityValue: Int
    public var dueDate: Date?
    public var createdAt: Date
    public var modifiedAt: Date?
    public var calendarEventId: String?
    public var estimatedDuration: TimeInterval
    public var sentiment: String
    public var sentimentScore: Double
    
    // Convenience access for the Enum-based priority
    public var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityValue) ?? .medium }
        set { priorityValue = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
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
        self.priorityValue = priority.rawValue
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.calendarEventId = calendarEventId
        self.estimatedDuration = estimatedDuration
        self.sentiment = sentiment
        self.sentimentScore = sentimentScore
    }

    public static func == (lhs: PlannerTask, rhs: PlannerTask) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// Consolidated SwiftData model for Goals in PlannerApp.
@Model
public final class PlannerGoal: Identifiable, Hashable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var goalDescription: String
    public var targetDate: Date
    public var createdAt: Date
    public var modifiedAt: Date?
    public var isCompleted: Bool
    public var priorityValue: Int
    public var progress: Double

    // Convenience access for the Enum-based priority
    public var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityValue) ?? .medium }
        set { priorityValue = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        targetDate: Date,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil,
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isCompleted = isCompleted
        self.priorityValue = priority.rawValue
        self.progress = progress
    }
    
    public func updateProgress(_ newProgress: Double) {
        self.progress = min(1.0, max(0.0, newProgress))
        self.modifiedAt = Date()
        if self.progress >= 1.0 {
            self.isCompleted = true
        }
    }

    public static func == (lhs: PlannerGoal, rhs: PlannerGoal) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// Task Context for prioritization and agent execution.
public struct TaskContext: Codable, Sendable {
    public let dueDate: Date?
    public let dependencies: [UUID]
    public let userPreferences: [String: String]
    public let currentWorkload: Int
    
    public init(
        dueDate: Date? = nil,
        dependencies: [UUID] = [],
        userPreferences: [String: String] = [:],
        currentWorkload: Int = 0
    ) {
        self.dueDate = dueDate
        self.dependencies = dependencies
        self.userPreferences = userPreferences
        self.currentWorkload = currentWorkload
    }
}

/// Status of a project
public enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

/// Consolidated SwiftData model for Projects in PlannerApp.
@Model
public final class PlannerProject: Identifiable, Hashable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var projectDescription: String
    public var statusValue: String
    public var createdAt: Date
    public var modifiedAt: Date?
    public var completedAt: Date?
    
    public var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusValue) ?? .active }
        set { statusValue = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        projectDescription: String = "",
        status: ProjectStatus = .active,
        createdAt: Date = Date(),
        modifiedAt: Date? = Date()
    ) {
        self.id = id
        self.title = title
        self.projectDescription = projectDescription
        self.statusValue = status.rawValue
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    public static func == (lhs: PlannerProject, rhs: PlannerProject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// Consolidated SwiftData model for Journal Entries in PlannerApp.
@Model
public final class PlannerJournalEntry: Identifiable, Hashable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var body: String
    public var date: Date
    public var mood: String
    public var modifiedAt: Date?
    public var sentiment: String
    public var sentimentScore: Double

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date,
        mood: String,
        modifiedAt: Date? = Date(),
        sentiment: String = "neutral",
        sentimentScore: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.mood = mood
        self.modifiedAt = modifiedAt
        self.sentiment = sentiment
        self.sentimentScore = sentimentScore
    }

    public static func == (lhs: PlannerJournalEntry, rhs: PlannerJournalEntry) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// Consolidated SwiftData model for Calendar Events in PlannerApp.
@Model
public final class PlannerCalendarEvent: Identifiable, Hashable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var date: Date
    public var createdAt: Date
    public var modifiedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        createdAt: Date = Date(),
        modifiedAt: Date? = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    public static func == (lhs: PlannerCalendarEvent, rhs: PlannerCalendarEvent) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// Defines how one task relates to another in terms of execution order.
public enum DependencyType: String, Codable, Sendable {
    /// Source task must be completed before target task can start.
    case blocks
    /// Target task is waiting for source task.
    case blockedBy
}

/// A real relationship between two tasks.
public struct TaskDependency: Identifiable, Codable, Sendable {
    public let id: UUID
    public let sourceTaskId: UUID
    public let targetTaskId: UUID
    public let type: DependencyType
    
    public init(id: UUID = UUID(), sourceTaskId: UUID, targetTaskId: UUID, type: DependencyType = .blocks) {
        self.id = id
        self.sourceTaskId = sourceTaskId
        self.targetTaskId = targetTaskId
        self.type = type
    }
}
