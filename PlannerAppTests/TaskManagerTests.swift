@testable import PlannerApp
import XCTest
import SwiftData

final class TaskManagerTests: XCTestCase {
    
    var modelContext: ModelContext!
    var taskManager: TaskManager!
    
    override func setUp() {
        super.setUp()
        
        // In-memory SwiftData
        let schema = Schema([Task.self, Project.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(container)
        
        taskManager = TaskManager(modelContext: modelContext)
    }
    
    override func tearDown() {
        modelContext = nil
        taskManager = nil
        super.tearDown()
    }
    
    // MARK: - CRUD Tests
    
    func testCreateTask() async throws {
        let task = Task(title: "Test Task", dueDate: Date())
        try await taskManager.createTask(task)
        
        let tasks = try taskManager.fetchAllTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Test Task")
    }
    
    func testUpdateTask() async throws {
        let task = Task(title: "Original", dueDate: Date())
        try await taskManager.createTask(task)
        
        task.title = "Updated"
        try await taskManager.updateTask(task)
        
        let tasks = try taskManager.fetchAllTasks()
        XCTAssertEqual(tasks.first?.title, "Updated")
    }
    
    func testDeleteTask() async throws {
        let task = Task(title: "To Delete", dueDate: Date())
        try await taskManager.createTask(task)
        
        try await taskManager.deleteTask(task)
        
        let tasks = try taskManager.fetchAllTasks()
        XCTAssertEqual(tasks.count, 0)
    }
    
    func testFetchAllTasks() async throws {
        let task1 = Task(title: "Task 1", dueDate: Date())
        let task2 = Task(title: "Task 2", dueDate: Date())
        
        try await taskManager.createTask(task1)
        try await taskManager.createTask(task2)
        
        let tasks = try taskManager.fetchAllTasks()
        XCTAssertEqual(tasks.count, 2)
    }
    
    // MARK: - Priority Sorting Tests
    
    func testSortByPriority() async throws {
        let lowTask = Task(title: "Low", dueDate: Date(), priority: .low)
        let highTask = Task(title: "High", dueDate: Date(), priority: .high)
        let mediumTask = Task(title: "Medium", dueDate: Date(), priority: .medium)
        
        try await taskManager.createTask(lowTask)
        try await taskManager.createTask(highTask)
        try await taskManager.createTask(mediumTask)
        
        let sorted = try taskManager.fetchTasksSortedByPriority()
        
        XCTAssertEqual(sorted[0].priority, .high)
        XCTAssertEqual(sorted[1].priority, .medium)
        XCTAssertEqual(sorted[2].priority, .low)
    }
    
    // MARK: - Due Date Handling Tests
    
    func testFetchTasksDueToday() async throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayTask = Task(title: "Today", dueDate: today)
        let tomorrowTask = Task(title: "Tomorrow", dueDate: tomorrow)
        
        try await taskManager.createTask(todayTask)
        try await taskManager.createTask(tomorrowTask)
        
        let todayTasks = try taskManager.fetchTasksDueToday()
        
        XCTAssertEqual(todayTasks.count, 1)
        XCTAssertEqual(todayTasks.first?.title, "Today")
    }
    
    func testFetchOverdueTasks() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let overdueTask = Task(title: "Overdue", dueDate: yesterday, isCompleted: false)
        let futureTask = Task(title: "Future", dueDate: tomorrow)
        
        try await taskManager.createTask(overdueTask)
        try await taskManager.createTask(futureTask)
        
        let overdue = try taskManager.fetchOverdueTasks()
        
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue")
    }
    
    func testFetchTasksThisWeek() async throws {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 8, to: today)!
        
        let thisWeekTask = Task(title: "This Week", dueDate: today)
        let nextWeekTask = Task(title: "Next Week", dueDate: nextWeek)
        
        try await taskManager.createTask(thisWeekTask)
        try await taskManager.createTask(nextWeekTask)
        
        let thisWeek = try taskManager.fetchTasksThisWeek()
        
        XCTAssertEqual(thisWeek.count, 1)
    }
    
    // MARK: - Completion Tests
    
    func testMarkTaskComplete() async throws {
        let task = Task(title: "To Complete", dueDate: Date())
        try await taskManager.createTask(task)
        
        try await taskManager.markComplete(task)
        
        let tasks = try taskManager.fetchAllTasks()
        XCTAssertTrue(tasks.first?.isCompleted == true)
    }
    
    func testFetchCompletedTasks() async throws {
        let completed = Task(title: "Done", dueDate: Date(), isCompleted: true)
        let incomplete = Task(title: "Todo", dueDate: Date(), isCompleted: false)
        
        try await taskManager.createTask(completed)
        try await taskManager.createTask(incomplete)
        
        let completedTasks = try taskManager.fetchCompletedTasks()
        
        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "Done")
    }
    
    // MARK: - Project Association Tests
    
    func testAssignTaskToProject() async throws {
        let project = Project(name: "Test Project")
        try await taskManager.createProject(project)
        
        let task = Task(title: "Task", dueDate: Date())
        task.project = project
        try await taskManager.createTask(task)
        
        let tasks = try taskManager.fetchTasksForProject(project)
        XCTAssertEqual(tasks.count, 1)
    }
}
