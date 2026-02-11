import XCTest
@testable import PlannerApp

final class TaskManagerTests: XCTestCase {
    var taskManager: TaskDataManager!

    override func setUp() {
        super.setUp()
        // Use a mock UserDefaults if possible, or just clear the shared instance
        self.taskManager = TaskDataManager.shared
        self.taskManager.clearAllTasks()
    }

    override func tearDown() {
        self.taskManager.clearAllTasks()
        self.taskManager = nil
        super.tearDown()
    }

    // MARK: - CRUD Tests

    func testCreateTask() {
        let task = PlannerTask(title: "Test Task", dueDate: Date())
        self.taskManager.add(task)

        let tasks = self.taskManager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Test Task")
    }

    func testUpdateTask() {
        var task = PlannerTask(title: "Original", dueDate: Date())
        self.taskManager.add(task)

        task.title = "Updated"
        self.taskManager.update(task)

        let tasks = self.taskManager.load()
        XCTAssertEqual(tasks.first?.title, "Updated")
    }

    func testDeleteTask() {
        let task = PlannerTask(title: "To Delete", dueDate: Date())
        self.taskManager.add(task)

        self.taskManager.delete(task)

        let tasks = self.taskManager.load()
        XCTAssertEqual(tasks.count, 0)
    }

    func testFetchAllTasks() {
        let task1 = PlannerTask(title: "Task 1", dueDate: Date())
        let task2 = PlannerTask(title: "Task 2", dueDate: Date())

        self.taskManager.add(task1)
        self.taskManager.add(task2)

        let tasks = self.taskManager.load()
        XCTAssertEqual(tasks.count, 2)
    }

    // MARK: - Priority Sorting Tests

    func testSortByPriority() {
        let lowTask = PlannerTask(title: "Low", priority: .low)
        let highTask = PlannerTask(title: "High", priority: .high)
        let mediumTask = PlannerTask(title: "Medium", priority: .medium)

        self.taskManager.add(lowTask)
        self.taskManager.add(highTask)
        self.taskManager.add(mediumTask)

        let sorted = self.taskManager.tasksSortedByPriority()

        XCTAssertEqual(sorted[0].priority, .high)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }

    // MARK: - Due Date Handling Tests

    func testFetchTasksDueToday() throws {
        let today = Date()
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))

        let todayTask = PlannerTask(title: "Today", dueDate: today)
        let tomorrowTask = PlannerTask(title: "Tomorrow", dueDate: tomorrow)

        self.taskManager.add(todayTask)
        self.taskManager.add(tomorrowTask)

        // TaskDataManager.tasksDue(within: 1) might include today and tomorrow depending on implementation
        // Let's check the specific implementation of tasksDue(within:)
        // It uses <= futureDate.
        // We want tasks due "today". The manager has getTaskStatistics()["dueToday"].
        // But let's test tasksDue(within: 0) which should be today?
        // tasksDue(within: 0) adds 0 days to now. So <= now.
        // If due date is exact time, it might be tricky.

        // Let's just test that we can filter manually if needed, or use the stats.
        let stats = self.taskManager.getTaskStatistics()
        // This depends on how getTaskStatistics calculates "dueToday"
        // It uses: dueDate >= todayStart && dueDate < todayEnd

        XCTAssertEqual(stats["dueToday"], 1)
    }

    func testFetchOverdueTasks() throws {
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        let overdueTask = PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday)
        let futureTask = PlannerTask(title: "Future", dueDate: tomorrow)

        self.taskManager.add(overdueTask)
        self.taskManager.add(futureTask)

        let overdue = self.taskManager.overdueTasks()

        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }

    // MARK: - Completion Tests

    func testMarkTaskComplete() {
        var task = PlannerTask(title: "To Complete", dueDate: Date())
        self.taskManager.add(task)

        task.isCompleted = true
        self.taskManager.update(task)

        let tasks = self.taskManager.load()
        XCTAssertTrue(tasks.first?.isCompleted == true)
    }

    func testFetchCompletedTasks() {
        let completed = PlannerTask(title: "Done", isCompleted: true, dueDate: Date())
        let incomplete = PlannerTask(title: "Todo", isCompleted: false, dueDate: Date())

        self.taskManager.add(completed)
        self.taskManager.add(incomplete)

        let completedTasks = self.taskManager.tasks(filteredByCompletion: true)

        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "Done")
    }
}
