import Foundation
import CoreTransferable

// MARK: - PlannerTask Model

/// A label that can be applied to tasks or goals.
public struct PlannerTag: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let colorName: String
    
    public init(id: UUID = UUID(), name: String, colorName: String) {
        self.id = id
        self.name = name
        self.colorName = colorName
    }
}

/// Priority levels for tasks.
public enum TaskPriority: Int, Codable, Sendable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

/// Contextual data for task prioritization.
public struct TaskContext: Codable, Sendable {
    public let userCurrentFocus: String?
    public let availableTimeBlocks: Int
    public let energyLevel: Int
    
    public init(userCurrentFocus: String? = nil, availableTimeBlocks: Int = 0, energyLevel: Int = 5) {
        self.userCurrentFocus = userCurrentFocus
        self.availableTimeBlocks = availableTimeBlocks
        self.energyLevel = energyLevel
    }
}

/// A foundational task model for the Planner ecosystem.
public final class PlannerTask: Identifiable, Hashable, Codable, @unchecked Sendable, Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
    }
    public let id: UUID
    public var title: String
    public var taskDescription: String?
    public var isCompleted: Bool
    public var tagIds: [UUID]
    public var priority: TaskPriority
    public var dueDate: Date?
    public var estimatedDuration: TimeInterval
    public var sentimentScore: Double
    public var calendarEventId: String?
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        isCompleted: Bool = false,
        tagIds: [UUID] = [],
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval = 1800,
        sentimentScore: Double = 0.5,
        calendarEventId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.tagIds = tagIds
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.sentimentScore = sentimentScore
        self.calendarEventId = calendarEventId
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    public static func == (lhs: PlannerTask, rhs: PlannerTask) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A goal model representing long-term objectives.
public final class PlannerGoal: Identifiable, Hashable, Codable, @unchecked Sendable {
    public let id: UUID
    public var title: String
    public var goalDescription: String
    public var targetDate: Date
    public var isCompleted: Bool
    public var priority: TaskPriority
    public var progress: Double
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        targetDate: Date,
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.progress = progress
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    public static func == (lhs: PlannerGoal, rhs: PlannerGoal) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A high-level organizational structure for grouping projects and tasks.
public final class PlannerProject: Identifiable, Hashable, Codable, @unchecked Sendable {
    public let id: UUID
    public var title: String
    public var projectDescription: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var tasks: [PlannerTask]
    
    public init(id: UUID = UUID(), title: String, projectDescription: String = "", tasks: [PlannerTask] = []) {
        self.id = id
        self.title = title
        self.projectDescription = projectDescription
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
        self.tasks = tasks
    }

    public static func == (lhs: PlannerProject, rhs: PlannerProject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A high-level organizational structure for grouping projects and tasks.
public struct PlannerWorkspace: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public let colorName: String
    public let ownerId: UUID
    public var projects: [PlannerProject]
    
    public init(id: UUID = UUID(), name: String, colorName: String = "blue", ownerId: UUID = UUID(), projects: [PlannerProject] = []) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.ownerId = ownerId
        self.projects = projects
    }
}

/// Access roles within a ecosystem.
public enum Role: String, Codable, Sendable {
    case owner
    case editor
    case viewer
}

/// A set of distinct permissions granted to a role.
public struct Permission: Sendable {
    public let canEdit: Bool
    public let canDelete: Bool
    public let canInvite: Bool
    
    public init(canEdit: Bool, canDelete: Bool, canInvite: Bool) {
        self.canEdit = canEdit
        self.canDelete = canDelete
        self.canInvite = canInvite
    }
}

/// A journal entry for reflecting on productivity.
public final class PlannerJournalEntry: Identifiable, Hashable, Codable, @unchecked Sendable {
    public let id: UUID
    public var title: String
    public var body: String
    public var date: Date
    public var mood: String
    public var sentiment: String
    public var sentimentScore: Double
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date,
        mood: String,
        sentiment: String = "neutral",
        sentimentScore: Double = 0.5
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.mood = mood
        self.sentiment = sentiment
        self.sentimentScore = sentimentScore
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    public static func == (lhs: PlannerJournalEntry, rhs: PlannerJournalEntry) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents an event synchronized with the system calendar.
public struct PlannerCalendarEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var location: String?
    
    public init(id: UUID = UUID(), title: String, date: Date, location: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
    }
}

/// Represents a discrete period of focused work.
public struct FocusSession: Identifiable, Codable, Sendable {
    public let id: UUID
    public let startTime: Date
    public let duration: TimeInterval
    public let taskId: UUID?
    public var isCompleted: Bool
    
    public init(id: UUID = UUID(), startTime: Date, duration: TimeInterval, taskId: UUID? = nil, isCompleted: Bool = false) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.taskId = taskId
        self.isCompleted = isCompleted
    }
}

/// Represents a scheduled block of time dedicated to a specific task.
public struct TimeBlock: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let sourceTaskId: UUID?
    public let startTime: Date
    public let endTime: Date
    public var isCompleted: Bool

    public var duration: TimeInterval {
        self.endTime.timeIntervalSince(self.startTime)
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        taskId: UUID? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.sourceTaskId = taskId
        self.isCompleted = isCompleted
    }
}

/// Represents a data point for productivity trends.
public struct ProductivityDataPoint: Codable, Sendable {
    public let date: Date
    public let score: Double
    
    public init(date: Date, score: Double) {
        self.date = date
        self.score = score
    }
}

/// A comprehensive report summarizing productivity over a period.
public struct ProductivityReport: Codable, Sendable {
    public var dailyAverage: Double = 0.0
    public var weeklyTotal: Double = 0.0
    public var topCategories: [String] = []
    
    public init() {}
}

/// Metadata regarding a specific backup instance.
public struct BackupInfo: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let sizeBytes: Int64
    public let deviceName: String
    
    public init(id: UUID = UUID(), date: Date, sizeBytes: Int64, deviceName: String) {
        self.id = id
        self.date = date
        self.sizeBytes = sizeBytes
        self.deviceName = deviceName
    }
}

/// Defines how one task relates to another.
public enum DependencyType: String, Codable, Sendable {
    case blocks
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

/// Defines categories for task templates.
public enum TemplateCategory: String, Codable, Sendable {
    case work
    case personal
    case urgent
    case meeting
}

/// A blueprint for creating new tasks quickly.
public struct TaskTemplate: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let category: TemplateCategory
    public let defaultTitle: String
    public let defaultPriority: TaskPriority
    public let defaultTags: [String]
    public let checklistItems: [String]
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: TemplateCategory = .work,
        defaultTitle: String = "",
        defaultPriority: TaskPriority = .medium,
        defaultTags: [String] = [],
        checklistItems: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultTitle = defaultTitle
        self.defaultPriority = defaultPriority
        self.defaultTags = defaultTags
        self.checklistItems = checklistItems
    }
}
