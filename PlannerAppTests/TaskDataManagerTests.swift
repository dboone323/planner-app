//
//  TaskDataManagerTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for TaskDataManager
//

import XCTest
@testable import PlannerApp

final class TaskDataManagerTests: XCTestCase, @unchecked Sendable {
    @MainActor var manager: TaskDataManager!

    // MARK: - Setup & Teardown

    override nonisolated func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            self.manager = TaskDataManager.shared
            self.manager.clearAllTasks()
        }
    }

    override nonisolated func tearDown() async throws {
        await MainActor.run {
            self.manager.clearAllTasks()
        }
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func testSharedInstanceExists() {
        XCTAssertNotNil(TaskDataManager.shared)
    }

    @MainActor
    func testSharedInstanceIsSingleton() {
        let instance1 = TaskDataManager.shared
        let instance2 = TaskDataManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    // MARK: - Load/Save Tests

    @MainActor
    func testLoadReturnsEmptyArrayInitially() {
        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 0, "Should return empty array when no tasks saved")
    }

    @MainActor
    func testSaveAndLoadTasks() {
        let task1 = PlannerTask(title: "Task 1")
        let task2 = PlannerTask(title: "Task 2")

        self.manager.save(tasks: [task1, task2])
        let loadedTasks = self.manager.load()

        XCTAssertEqual(loadedTasks.count, 2)
        XCTAssertEqual(loadedTasks[0].title, "Task 1")
        XCTAssertEqual(loadedTasks[1].title, "Task 2")
    }

    // MARK: - Add Tests

    @MainActor
    func testAddTask() {
        let task = PlannerTask(title: "New Task")
        self.manager.add(task)

        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "New Task")
        XCTAssertEqual(tasks.first?.id, task.id)
    }

    @MainActor
    func testAddMultipleTasks() {
        self.manager.add(PlannerTask(title: "Task 1"))
        self.manager.add(PlannerTask(title: "Task 2"))
        self.manager.add(PlannerTask(title: "Task 3"))

        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 3)
    }

    // MARK: - Update Tests

    @MainActor
    func testUpdateTask() {
        var task = PlannerTask(title: "Original Title")
        self.manager.add(task)

        task.title = "Updated Title"
        task.isCompleted = true
        self.manager.update(task)

        let loadedTasks = self.manager.load()
        XCTAssertEqual(loadedTasks.count, 1)
        XCTAssertEqual(loadedTasks.first?.title, "Updated Title")
        XCTAssertTrue(loadedTasks.first?.isCompleted ?? false)
    }

    @MainActor
    func testUpdateNonexistentTask() {
        let task = PlannerTask(title: "Nonexistent")
        self.manager.update(task)

        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 0, "Updating nonexistent task should not add it")
    }

    // MARK: - Delete Tests

    @MainActor
    func testDeleteTask() {
        let task = PlannerTask(title: "To Delete")
        self.manager.add(task)
        XCTAssertEqual(self.manager.load().count, 1)

        self.manager.delete(task)
        XCTAssertEqual(self.manager.load().count, 0)
    }

    @MainActor
    func testDeleteOnlySpecifiedTask() {
        let task1 = PlannerTask(title: "Keep")
        let task2 = PlannerTask(title: "Delete")

        self.manager.add(task1)
        self.manager.add(task2)
        self.manager.delete(task2)

        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Keep")
    }

    // MARK: - Find Tests

    @MainActor
    func testFindTaskById() {
        let task = PlannerTask(title: "Findable")
        self.manager.add(task)

        let found = self.manager.find(by: task.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Findable")
        XCTAssertEqual(found?.id, task.id)
    }

    @MainActor
    func testFindNonexistentTask() {
        let found = self.manager.find(by: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Filtering Tests

    @MainActor
    func testFilterByCompletionStatus() {
        self.manager.add(PlannerTask(title: "Complete", isCompleted: true))
        self.manager.add(PlannerTask(title: "Incomplete", isCompleted: false))
        self.manager.add(PlannerTask(title: "Also Complete", isCompleted: true))

        let completed = self.manager.tasks(filteredByCompletion: true)
        let incomplete = self.manager.tasks(filteredByCompletion: false)

        XCTAssertEqual(completed.count, 2)
        XCTAssertEqual(incomplete.count, 1)
    }

    @MainActor
    func testTasksDueWithin() throws {
        let today = Date()
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 8, to: today))

        self.manager.add(PlannerTask(title: "Tomorrow", isCompleted: false, dueDate: tomorrow))
        self.manager.add(PlannerTask(title: "Next Week", isCompleted: false, dueDate: nextWeek))

        let dueWithin7Days = self.manager.tasksDue(within: 7)
        XCTAssertEqual(dueWithin7Days.count, 1)
        XCTAssertEqual(dueWithin7Days.first?.title, "Tomorrow")
    }

    @MainActor
    func testTasksDueWithinExcludesCompleted() throws {
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        self.manager.add(PlannerTask(title: "Due Tomorrow", isCompleted: true, dueDate: tomorrow))

        let dueSoon = self.manager.tasksDue(within: 7)
        XCTAssertEqual(dueSoon.count, 0, "Completed tasks should not appear in due tasks")
    }

    @MainActor
    func testOverdueTasks() throws {
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        self.manager.add(PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday))
        self.manager.add(PlannerTask(title: "Future", isCompleted: false, dueDate: tomorrow))
        self.manager.add(
            PlannerTask(title: "Overdue but Done", isCompleted: true, dueDate: yesterday)
        )

        let overdue = self.manager.overdueTasks()
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }

    // MARK: - Sorting Tests

    @MainActor
    func testTasksSortedByPriority() {
        self.manager.add(PlannerTask(title: "Low", priority: .low))
        self.manager.add(PlannerTask(title: "High", priority: .high))
        self.manager.add(PlannerTask(title: "Medium", priority: .medium))

        let sorted = self.manager.tasksSortedByPriority()
        XCTAssertEqual(sorted[0].title, "High")
        XCTAssertEqual(sorted[1].title, "Medium")
        XCTAssertEqual(sorted[2].title, "Low")
    }

    @MainActor
    func testTasksSortedByDate() throws {
        let today = Date()
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 7, to: today))

        self.manager.add(PlannerTask(title: "Next Week", dueDate: nextWeek))
        self.manager.add(PlannerTask(title: "Tomorrow", dueDate: tomorrow))
        self.manager.add(PlannerTask(title: "No Date"))

        let sorted = self.manager.tasksSortedByDate()
        XCTAssertEqual(sorted[0].title, "Tomorrow", "Soonest task first")
        XCTAssertEqual(sorted[1].title, "Next Week")
        XCTAssertEqual(sorted[2].title, "No Date", "Tasks without dates come last")
    }

    // MARK: - Statistics Tests

    @MainActor
    func testGetTaskStatistics() throws {
        let today = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        // Use end of day to ensure this is always in the future during test day
        let todayEndOfDay = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: today)
        )

        self.manager.add(PlannerTask(title: "Complete", isCompleted: true))
        self.manager.add(PlannerTask(title: "Incomplete", isCompleted: false))
        self.manager.add(PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday))
        self.manager.add(
            PlannerTask(title: "Due Today", isCompleted: false, dueDate: todayEndOfDay)
        )

        let stats = self.manager.getTaskStatistics()

        XCTAssertEqual(stats["total"], 4)
        XCTAssertEqual(stats["completed"], 1)
        XCTAssertEqual(stats["incomplete"], 3)
        XCTAssertEqual(stats["overdue"], 1)
        XCTAssertEqual(stats["dueToday"], 1)
    }

    @MainActor
    func testStatisticsWithNoTasks() {
        let stats = self.manager.getTaskStatistics()

        XCTAssertEqual(stats["total"], 0)
        XCTAssertEqual(stats["completed"], 0)
        XCTAssertEqual(stats["incomplete"], 0)
        XCTAssertEqual(stats["overdue"], 0)
        XCTAssertEqual(stats["dueToday"], 0)
    }

    // MARK: - Clear Tests

    @MainActor
    func testClearAllTasks() {
        self.manager.add(PlannerTask(title: "Task 1"))
        self.manager.add(PlannerTask(title: "Task 2"))
        XCTAssertEqual(self.manager.load().count, 2)

        self.manager.clearAllTasks()
        XCTAssertEqual(self.manager.load().count, 0)
    }

    // MARK: - Edge Case Tests

    @MainActor
    func testPersistenceAcrossInstances() {
        let task = PlannerTask(title: "Persistent")
        self.manager.add(task)

        // Access shared instance again (simulating app restart)
        let newAccess = TaskDataManager.shared
        let tasks = newAccess.load()

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Persistent")
    }

    @MainActor
    func testHandlesTasksWithoutDueDate() {
        self.manager.add(PlannerTask(title: "No Due Date"))

        let overdue = self.manager.overdueTasks()
        let dueSoon = self.manager.tasksDue(within: 7)

        XCTAssertEqual(overdue.count, 0, "Tasks without due date should not be overdue")
        XCTAssertEqual(dueSoon.count, 0, "Tasks without due date should not be in due soon")
    }

    @MainActor
    func testHandlesEmptyTitle() {
        let task = PlannerTask(title: "")
        self.manager.add(task)

        let tasks = self.manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "")
    }
}
