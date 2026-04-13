import Foundation
import PlannerAppCore
import SwiftData
import PlannerAppCore

/// PlannerTask Context for prioritization and agent execution.
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
