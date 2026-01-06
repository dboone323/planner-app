//
//  TaskDataManagerTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for TaskDataManager
//

@testable import PlannerApp
import XCTest

final class TaskDataManagerTests: XCTestCase {
    var manager: TaskDataManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        manager = TaskDataManager.shared
        manager.clearAllTasks()
    }

    override func tearDown() {
        manager.clearAllTasks()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(TaskDataManager.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = TaskDataManager.shared
        let instance2 = TaskDataManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    // MARK: - Load/Save Tests

    func testLoadReturnsEmptyArrayInitially() {
        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 0, "Should return empty array when no tasks saved")
    }

    func testSaveAndLoadTasks() {
        let task1 = PlannerTask(title: "Task 1")
        let task2 = PlannerTask(title: "Task 2")

        manager.save(tasks: [task1, task2])
        let loadedTasks = manager.load()

        XCTAssertEqual(loadedTasks.count, 2)
        XCTAssertEqual(loadedTasks[0].title, "Task 1")
        XCTAssertEqual(loadedTasks[1].title, "Task 2")
    }

    // MARK: - Add Tests

    func testAddTask() {
        let task = PlannerTask(title: "New Task")
        manager.add(task)

        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "New Task")
        XCTAssertEqual(tasks.first?.id, task.id)
    }

    func testAddMultipleTasks() {
        manager.add(PlannerTask(title: "Task 1"))
        manager.add(PlannerTask(title: "Task 2"))
        manager.add(PlannerTask(title: "Task 3"))

        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 3)
    }

    // MARK: - Update Tests

    func testUpdateTask() {
        var task = PlannerTask(title: "Original Title")
        manager.add(task)

        task.title = "Updated Title"
        task.isCompleted = true
        manager.update(task)

        let loadedTasks = manager.load()
        XCTAssertEqual(loadedTasks.count, 1)
        XCTAssertEqual(loadedTasks.first?.title, "Updated Title")
        XCTAssertTrue(loadedTasks.first?.isCompleted ?? false)
    }

    func testUpdateNonexistentTask() {
        let task = PlannerTask(title: "Nonexistent")
        manager.update(task)

        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 0, "Updating nonexistent task should not add it")
    }

    // MARK: - Delete Tests

    func testDeleteTask() {
        let task = PlannerTask(title: "To Delete")
        manager.add(task)
        XCTAssertEqual(manager.load().count, 1)

        manager.delete(task)
        XCTAssertEqual(manager.load().count, 0)
    }

    func testDeleteOnlySpecifiedTask() {
        let task1 = PlannerTask(title: "Keep")
        let task2 = PlannerTask(title: "Delete")

        manager.add(task1)
        manager.add(task2)
        manager.delete(task2)

        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Keep")
    }

    // MARK: - Find Tests

    func testFindTaskById() {
        let task = PlannerTask(title: "Findable")
        manager.add(task)

        let found = manager.find(by: task.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Findable")
        XCTAssertEqual(found?.id, task.id)
    }

    func testFindNonexistentTask() {
        let found = manager.find(by: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Filtering Tests

    func testFilterByCompletionStatus() {
        manager.add(PlannerTask(title: "Complete", isCompleted: true))
        manager.add(PlannerTask(title: "Incomplete", isCompleted: false))
        manager.add(PlannerTask(title: "Also Complete", isCompleted: true))

        let completed = manager.tasks(filteredByCompletion: true)
        let incomplete = manager.tasks(filteredByCompletion: false)

        XCTAssertEqual(completed.count, 2)
        XCTAssertEqual(incomplete.count, 1)
    }

    func testTasksDueWithin() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 8, to: today)!

        manager.add(PlannerTask(title: "Tomorrow", isCompleted: false, dueDate: tomorrow))
        manager.add(PlannerTask(title: "Next Week", isCompleted: false, dueDate: nextWeek))

        let dueWithin7Days = manager.tasksDue(within: 7)
        XCTAssertEqual(dueWithin7Days.count, 1)
        XCTAssertEqual(dueWithin7Days.first?.title, "Tomorrow")
    }

    func testTasksDueWithinExcludesCompleted() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        manager.add(PlannerTask(title: "Due Tomorrow", isCompleted: true, dueDate: tomorrow))

        let dueSoon = manager.tasksDue(within: 7)
        XCTAssertEqual(dueSoon.count, 0, "Completed tasks should not appear in due tasks")
    }

    func testOverdueTasks() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        manager.add(PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday))
        manager.add(PlannerTask(title: "Future", isCompleted: false, dueDate: tomorrow))
        manager.add(PlannerTask(title: "Overdue but Done", isCompleted: true, dueDate: yesterday))

        let overdue = manager.overdueTasks()
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }

    // MARK: - Sorting Tests

    func testTasksSortedByPriority() {
        manager.add(PlannerTask(title: "Low", priority: .low))
        manager.add(PlannerTask(title: "High", priority: .high))
        manager.add(PlannerTask(title: "Medium", priority: .medium))

        let sorted = manager.tasksSortedByPriority()
        XCTAssertEqual(sorted[0].title, "High")
        XCTAssertEqual(sorted[1].title, "Medium")
        XCTAssertEqual(sorted[2].title, "Low")
    }

    func testTasksSortedByDate() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        manager.add(PlannerTask(title: "Next Week", dueDate: nextWeek))
        manager.add(PlannerTask(title: "Tomorrow", dueDate: tomorrow))
        manager.add(PlannerTask(title: "No Date"))

        let sorted = manager.tasksSortedByDate()
        XCTAssertEqual(sorted[0].title, "Tomorrow", "Soonest task first")
        XCTAssertEqual(sorted[1].title, "Next Week")
        XCTAssertEqual(sorted[2].title, "No Date", "Tasks without dates come last")
    }

    // MARK: - Statistics Tests

    func testGetTaskStatistics() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        // Use end of day to ensure this is always in the future during test day
        let todayEndOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: today)!

        manager.add(PlannerTask(title: "Complete", isCompleted: true))
        manager.add(PlannerTask(title: "Incomplete", isCompleted: false))
        manager.add(PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday))
        manager.add(PlannerTask(title: "Due Today", isCompleted: false, dueDate: todayEndOfDay))

        let stats = manager.getTaskStatistics()

        XCTAssertEqual(stats["total"], 4)
        XCTAssertEqual(stats["completed"], 1)
        XCTAssertEqual(stats["incomplete"], 3)
        XCTAssertEqual(stats["overdue"], 1)
        XCTAssertEqual(stats["dueToday"], 1)
    }

    func testStatisticsWithNoTasks() {
        let stats = manager.getTaskStatistics()

        XCTAssertEqual(stats["total"], 0)
        XCTAssertEqual(stats["completed"], 0)
        XCTAssertEqual(stats["incomplete"], 0)
        XCTAssertEqual(stats["overdue"], 0)
        XCTAssertEqual(stats["dueToday"], 0)
    }

    // MARK: - Clear Tests

    func testClearAllTasks() {
        manager.add(PlannerTask(title: "Task 1"))
        manager.add(PlannerTask(title: "Task 2"))
        XCTAssertEqual(manager.load().count, 2)

        manager.clearAllTasks()
        XCTAssertEqual(manager.load().count, 0)
    }

    // MARK: - Edge Case Tests

    func testPersistenceAcrossInstances() {
        let task = PlannerTask(title: "Persistent")
        manager.add(task)

        // Access shared instance again (simulating app restart)
        let newAccess = TaskDataManager.shared
        let tasks = newAccess.load()

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Persistent")
    }

    func testHandlesTasksWithoutDueDate() {
        manager.add(PlannerTask(title: "No Due Date"))

        let overdue = manager.overdueTasks()
        let dueSoon = manager.tasksDue(within: 7)

        XCTAssertEqual(overdue.count, 0, "Tasks without due date should not be overdue")
        XCTAssertEqual(dueSoon.count, 0, "Tasks without due date should not be in due soon")
    }

    func testHandlesEmptyTitle() {
        let task = PlannerTask(title: "")
        manager.add(task)

        let tasks = manager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "")
    }
}
