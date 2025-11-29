@testable import PlannerApp
import XCTest

final class TaskManagerTests: XCTestCase {
    
    var taskManager: TaskDataManager!
    
    override func setUp() {
        super.setUp()
        // Use a mock UserDefaults if possible, or just clear the shared instance
        taskManager = TaskDataManager.shared
        taskManager.clearAllTasks()
    }
    
    override func tearDown() {
        taskManager.clearAllTasks()
        taskManager = nil
        super.tearDown()
    }
    
    // MARK: - CRUD Tests
    
    func testCreateTask() {
        let task = PlannerTask(title: "Test Task", dueDate: Date())
        taskManager.add(task)
        
        let tasks = taskManager.load()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Test Task")
    }
    
    func testUpdateTask() {
        var task = PlannerTask(title: "Original", dueDate: Date())
        taskManager.add(task)
        
        task.title = "Updated"
        taskManager.update(task)
        
        let tasks = taskManager.load()
        XCTAssertEqual(tasks.first?.title, "Updated")
    }
    
    func testDeleteTask() {
        let task = PlannerTask(title: "To Delete", dueDate: Date())
        taskManager.add(task)
        
        taskManager.delete(task)
        
        let tasks = taskManager.load()
        XCTAssertEqual(tasks.count, 0)
    }
    
    func testFetchAllTasks() {
        let task1 = PlannerTask(title: "Task 1", dueDate: Date())
        let task2 = PlannerTask(title: "Task 2", dueDate: Date())
        
        taskManager.add(task1)
        taskManager.add(task2)
        
        let tasks = taskManager.load()
        XCTAssertEqual(tasks.count, 2)
    }
    
    // MARK: - Priority Sorting Tests
    
    func testSortByPriority() {
        let lowTask = PlannerTask(title: "Low", priority: .low)
        let highTask = PlannerTask(title: "High", priority: .high)
        let mediumTask = PlannerTask(title: "Medium", priority: .medium)
        
        taskManager.add(lowTask)
        taskManager.add(highTask)
        taskManager.add(mediumTask)
        
        let sorted = taskManager.tasksSortedByPriority()
        
        XCTAssertEqual(sorted[0].priority, .high)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }
    
    // MARK: - Due Date Handling Tests
    
    func testFetchTasksDueToday() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayTask = PlannerTask(title: "Today", dueDate: today)
        let tomorrowTask = PlannerTask(title: "Tomorrow", dueDate: tomorrow)
        
        taskManager.add(todayTask)
        taskManager.add(tomorrowTask)
        
        // TaskDataManager.tasksDue(within: 1) might include today and tomorrow depending on implementation
        // Let's check the specific implementation of tasksDue(within:)
        // It uses <= futureDate. 
        // We want tasks due "today". The manager has getTaskStatistics()["dueToday"].
        // But let's test tasksDue(within: 0) which should be today?
        // tasksDue(within: 0) adds 0 days to now. So <= now.
        // If due date is exact time, it might be tricky.
        
        // Let's just test that we can filter manually if needed, or use the stats.
        let stats = taskManager.getTaskStatistics()
        // This depends on how getTaskStatistics calculates "dueToday"
        // It uses: dueDate >= todayStart && dueDate < todayEnd
        
        XCTAssertEqual(stats["dueToday"], 1)
    }
    
    func testFetchOverdueTasks() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let overdueTask = PlannerTask(title: "Overdue", isCompleted: false, dueDate: yesterday)
        let futureTask = PlannerTask(title: "Future", dueDate: tomorrow)
        
        taskManager.add(overdueTask)
        taskManager.add(futureTask)
        
        let overdue = taskManager.overdueTasks()
        
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }
    
    // MARK: - Completion Tests
    
    func testMarkTaskComplete() {
        var task = PlannerTask(title: "To Complete", dueDate: Date())
        taskManager.add(task)
        
        task.isCompleted = true
        taskManager.update(task)
        
        let tasks = taskManager.load()
        XCTAssertTrue(tasks.first?.isCompleted == true)
    }
    
    func testFetchCompletedTasks() {
        let completed = PlannerTask(title: "Done", isCompleted: true, dueDate: Date())
        let incomplete = PlannerTask(title: "Todo", isCompleted: false, dueDate: Date())
        
        taskManager.add(completed)
        taskManager.add(incomplete)
        
        let completedTasks = taskManager.tasks(filteredByCompletion: true)
        
        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "Done")
    }
}
