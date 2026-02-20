import Foundation
import SwiftData

/// SwiftData-based task manager that replaces the legacy UserDefaults-based TaskDataManager.
/// Conforms to the existing TaskDataManaging protocol for minimal disruption.
@MainActor
final class SwiftDataTaskManager: ObservableObject {
    /// The SwiftData model context for database operations.
    private let modelContext: ModelContext

    /// Creates a new SwiftDataTaskManager.
    /// - Parameter modelContext: The ModelContext to use for operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Fetches all tasks, sorted by creation date.
    func load() -> [SDTask] {
        let descriptor = FetchDescriptor<SDTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? self.modelContext.fetch(descriptor)) ?? []
    }

    /// Adds a new task.
    func add(_ task: SDTask) {
        self.modelContext.insert(task)
        self.saveContext()
    }

    /// Updates an existing task (SwiftData handles this automatically via observation).
    func update(_ task: SDTask) {
        task.modifiedAt = Date()
        self.saveContext()
    }

    /// Deletes a task.
    func delete(_ task: SDTask) {
        self.modelContext.delete(task)
        self.saveContext()
    }

    /// Finds a task by ID.
    func find(by id: UUID) -> SDTask? {
        let predicate = #Predicate<SDTask> { $0.id == id }
        var descriptor = FetchDescriptor<SDTask>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? self.modelContext.fetch(descriptor).first
    }

    // MARK: - Filtered Queries

    /// Gets tasks filtered by completion status.
    func tasks(filteredByCompletion completed: Bool) -> [SDTask] {
        let predicate = #Predicate<SDTask> { $0.isCompleted == completed }
        let descriptor = FetchDescriptor<SDTask>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? self.modelContext.fetch(descriptor)) ?? []
    }

    /// Gets incomplete tasks due within a specified number of days.
    func tasksDue(within days: Int) -> [SDTask] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let predicate = #Predicate<SDTask> { task in
            task.dueDate != nil && task.dueDate! <= futureDate && !task.isCompleted
        }
        let descriptor = FetchDescriptor<SDTask>(predicate: predicate)
        return (try? self.modelContext.fetch(descriptor)) ?? []
    }

    /// Gets overdue incomplete tasks.
    func overdueTasks() -> [SDTask] {
        let now = Date()
        let predicate = #Predicate<SDTask> { task in
            task.dueDate != nil && task.dueDate! < now && !task.isCompleted
        }
        let descriptor = FetchDescriptor<SDTask>(predicate: predicate)
        return (try? self.modelContext.fetch(descriptor)) ?? []
    }

    /// Gets tasks sorted by priority (high to low).
    func tasksSortedByPriority() -> [SDTask] {
        // Note: SwiftData doesn't support computed property sorts directly,
        // so we fetch all and sort in-memory.
        self.load().sorted { $0.prioritySortOrder > $1.prioritySortOrder }
    }

    /// Clears all tasks.
    func clearAllTasks() {
        let tasks = self.load()
        for task in tasks {
            self.modelContext.delete(task)
        }
        self.saveContext()
    }

    // MARK: - Statistics

    /// Gets task statistics.
    func getTaskStatistics() -> [String: Int] {
        let tasks = self.load()
        let completed = tasks.filter(\.isCompleted).count
        let overdue = self.overdueTasks().count

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        let dueToday = tasks.count(where: { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate >= todayStart && dueDate < todayEnd
        })

        return [
            "total": tasks.count,
            "completed": completed,
            "incomplete": tasks.count - completed,
            "overdue": overdue,
            "dueToday": dueToday,
        ]
    }

    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try self.modelContext.save()
        } catch {
            print("[SwiftDataTaskManager] Save failed: \(error.localizedDescription)")
        }
    }
}
