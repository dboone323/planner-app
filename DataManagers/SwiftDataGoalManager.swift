import Foundation
import SwiftData

/// SwiftData-based goal manager that replaces the legacy UserDefaults-based GoalDataManager.
@MainActor
final class SwiftDataGoalManager: ObservableObject {
    /// The SwiftData model context for database operations.
    private let modelContext: ModelContext

    /// Creates a new SwiftDataGoalManager.
    /// - Parameter modelContext: The ModelContext to use for operations.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Fetches all goals, sorted by target date.
    func load() -> [SDGoal] {
        let descriptor = FetchDescriptor<SDGoal>(
            sortBy: [SortDescriptor(\.targetDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Adds a new goal.
    func add(_ goal: SDGoal) {
        modelContext.insert(goal)
        saveContext()
    }

    /// Updates an existing goal.
    func update(_ goal: SDGoal) {
        goal.modifiedAt = Date()
        saveContext()
    }

    /// Deletes a goal.
    func delete(_ goal: SDGoal) {
        modelContext.delete(goal)
        saveContext()
    }

    /// Finds a goal by ID.
    func find(by id: UUID) -> SDGoal? {
        let predicate = #Predicate<SDGoal> { $0.id == id }
        var descriptor = FetchDescriptor<SDGoal>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Filtered Queries

    /// Gets goals filtered by completion status.
    func goals(filteredByCompletion completed: Bool) -> [SDGoal] {
        let predicate = #Predicate<SDGoal> { $0.isCompleted == completed }
        let descriptor = FetchDescriptor<SDGoal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.targetDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Gets goals sorted by priority.
    func goalsSortedByPriority() -> [SDGoal] {
        load().sorted { $0.prioritySortOrder > $1.prioritySortOrder }
    }

    /// Gets goals with progress above a threshold.
    func goalsWithProgress(above threshold: Double) -> [SDGoal] {
        let predicate = #Predicate<SDGoal> { $0.progress >= threshold }
        let descriptor = FetchDescriptor<SDGoal>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Clears all goals.
    func clearAllGoals() {
        let goals = load()
        for goal in goals {
            modelContext.delete(goal)
        }
        saveContext()
    }

    // MARK: - Statistics

    /// Gets goal statistics.
    func getGoalStatistics() -> [String: Any] {
        let goals = load()
        let completed = goals.filter(\.isCompleted).count
        let avgProgress = goals.isEmpty ? 0.0 : goals.reduce(0.0) { $0 + $1.progress } / Double(goals.count)

        return [
            "total": goals.count,
            "completed": completed,
            "inProgress": goals.count - completed,
            "averageProgress": avgProgress
        ]
    }

    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("[SwiftDataGoalManager] Save failed: \(error.localizedDescription)")
        }
    }
}
