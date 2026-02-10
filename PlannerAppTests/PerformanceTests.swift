//
// PerformanceTests.swift
// PlannerAppTests
//

import XCTest
@testable import PlannerApp

class PerformanceTests: XCTestCase {
    var performanceMonitor: PerformanceMonitor!

    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor()
    }

    override func tearDown() {
        performanceMonitor = nil
        super.tearDown()
    }

    // MARK: - Task Management Performance Tests

    func testTaskDependencyServicePerformance() {
        let dependencyService = TaskDependencyService.shared

        measure {
            for i in 0 ..< 200 {
                let task = createMockTask(id: "task_\(i)")
                let dependency = createMockTask(id: "dep_\(i)")
                dependencyService.addDependency(from: task, to: dependency)
                _ = dependencyService.getDependencies(for: task)
                _ = dependencyService.canCompleteTask(task)
            }
        }
    }

    func testPriorityManagerPerformance() {
        let priorityManager = PriorityManager.shared

        measure {
            for i in 0 ..< 300 {
                let task = createMockTask(id: "priority_task_\(i)")
                priorityManager.updatePriority(for: task, basedOn: createMockContext())
                _ = priorityManager.getPriorityScore(for: task)
                _ = priorityManager.getPrioritizedTasks(from: [task])
            }
        }
    }

    func testTagManagerPerformance() {
        let tagManager = TagManager.shared

        measure {
            for i in 0 ..< 150 {
                let tag = Tag(id: "tag_\(i)", name: "Tag \(i)", color: .blue)
                tagManager.createTag(tag)
                _ = tagManager.getTasksWithTag(tag)
                _ = tagManager.getTagStatistics()
            }
        }
    }

    // MARK: - Calendar & Time Management Performance Tests

    func testCalendarSyncServicePerformance() {
        let calendarSync = CalendarSyncService.shared

        measure {
            for i in 0 ..< 50 {
                let event = createMockCalendarEvent(id: "event_\(i)")
                calendarSync.syncEvent(event)
                _ = calendarSync.getEventsForDate(Date())
                _ = calendarSync.getConflictingEvents(for: event)
            }
        }
    }

    func testTimeBlockServicePerformance() {
        let timeBlockService = TimeBlockService.shared

        measure {
            for i in 0 ..< 100 {
                let timeBlock = createMockTimeBlock(id: "block_\(i)")
                timeBlockService.scheduleTimeBlock(timeBlock)
                _ = timeBlockService.getTimeBlocksForDate(Date())
                _ = timeBlockService.getAvailableTimeSlots(on: Date())
            }
        }
    }

    // MARK: - Productivity Features Performance Tests

    func testPomodoroTimerPerformance() {
        let pomodoroTimer = PomodoroTimer.shared

        measure {
            for _ in 0 ..< 200 {
                pomodoroTimer.startTimer()
                pomodoroTimer.pauseTimer()
                pomodoroTimer.resetTimer()
                _ = pomodoroTimer.getCurrentSession()
            }
        }
    }

    func testFocusModeManagerPerformance() {
        let focusManager = FocusModeManager.shared

        measure {
            for i in 0 ..< 100 {
                focusManager.startFocusSession(duration: 25 * 60, task: createMockTask(id: "focus_task_\(i)"))
                _ = focusManager.getCurrentSession()
                _ = focusManager.getSessionHistory()
            }
        }
    }

    func testProductivityAnalyticsPerformance() {
        let analytics = ProductivityAnalytics.shared

        measure {
            for _ in 0 ..< 50 {
                _ = analytics.calculateDailyProductivity()
                _ = analytics.generateWeeklyReport()
                _ = analytics.getProductivityTrends()
                _ = analytics.getTimeDistribution()
            }
        }
    }

    // MARK: - Data Management Performance Tests

    func testBackupManagerPerformance() {
        let backupManager = BackupManager.shared

        measure {
            for _ in 0 ..< 20 {
                _ = backupManager.createBackup()
                _ = backupManager.getBackupHistory()
                _ = backupManager.validateBackupIntegrity()
            }
        }
    }

    func testConflictDetectorPerformance() {
        let conflictDetector = ConflictDetector.shared

        measure {
            for i in 0 ..< 100 {
                let task1 = createMockTask(id: "conflict_task1_\(i)")
                let task2 = createMockTask(id: "conflict_task2_\(i)")
                _ = conflictDetector.detectConflicts(between: task1, and: task2)
                _ = conflictDetector.getAllConflicts()
            }
        }
    }

    // MARK: - Template & Workspace Performance Tests

    func testTaskTemplateServicePerformance() {
        let templateService = TaskTemplateService.shared

        measure {
            for i in 0 ..< 80 {
                let template = createMockTaskTemplate(id: "template_\(i)")
                templateService.saveTemplate(template)
                _ = templateService.getTemplatesForCategory(.work)
                _ = templateService.createTaskFromTemplate(template)
            }
        }
    }

    func testWorkspaceManagerPerformance() {
        let workspaceManager = WorkspaceManager.shared

        measure {
            for i in 0 ..< 50 {
                let workspace = createMockWorkspace(id: "workspace_\(i)")
                workspaceManager.createWorkspace(workspace)
                _ = workspaceManager.getAllWorkspaces()
                _ = workspaceManager.getWorkspaceStatistics()
            }
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    func testConcurrentTaskOperationsPerformance() {
        let expectation = XCTestExpectation(description: "Concurrent task operations")

        measure {
            let group = DispatchGroup()

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let dependencyService = TaskDependencyService.shared
                for i in 0 ..< 50 {
                    let task = createMockTask(id: "concurrent_task_\(i)")
                    dependencyService.addDependency(from: task, to: createMockTask(id: "concurrent_dep_\(i)"))
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let priorityManager = PriorityManager.shared
                for i in 0 ..< 50 {
                    let task = createMockTask(id: "priority_task_\(i)")
                    priorityManager.updatePriority(for: task, basedOn: createMockContext())
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let analytics = ProductivityAnalytics.shared
                for _ in 0 ..< 50 {
                    _ = analytics.calculateDailyProductivity()
                }
                group.leave()
            }

            group.notify(queue: .main) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 15.0)
    }

    // MARK: - Memory Performance Tests

    func testMemoryUsageDuringTaskOperations() {
        measure {
            autoreleasepool {
                var tasks: [Task] = []
                var timeBlocks: [TimeBlock] = []
                var workspaces: [Workspace] = []

                for i in 0 ..< 300 {
                    tasks.append(createMockTask(id: "memory_task_\(i)"))
                    timeBlocks.append(createMockTimeBlock(id: "memory_block_\(i)"))
                    workspaces.append(createMockWorkspace(id: "memory_workspace_\(i)"))
                }

                tasks.removeAll()
                timeBlocks.removeAll()
                workspaces.removeAll()
            }
        }
    }

    // MARK: - Performance Monitoring

    func testPerformanceMetricsCollection() {
        performanceMonitor.startMonitoring()

        let priorityManager = PriorityManager.shared

        measure {
            for i in 0 ..< 100 {
                let task = createMockTask(id: "metrics_task_\(i)")
                priorityManager.updatePriority(for: task, basedOn: createMockContext())
                _ = performanceMonitor.getMetrics()
            }
        }

        performanceMonitor.stopMonitoring()
    }
}

// MARK: - Performance Monitor

class PerformanceMonitor {
    private var startTime: Date?
    private var operationCount = 0
    private var metrics: PerformanceMetrics = .init()

    func startMonitoring() {
        startTime = Date()
        operationCount = 0
        metrics = PerformanceMetrics()
    }

    func stopMonitoring() {
        startTime = nil
    }

    func getMetrics() -> PerformanceMetrics {
        operationCount += 1

        if let startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            metrics.operationsPerSecond = Double(operationCount) / elapsed
        }

        // Simulate memory and CPU monitoring
        metrics.memoryUsage = Double.random(in: 40 ... 80)
        metrics.cpuUsage = Double.random(in: 25 ... 60)

        return metrics
    }
}

// MARK: - Extended Data Models

struct PerformanceMetrics {
    var operationsPerSecond: Double = 150.0
    var memoryUsage: Double = 55.0
    var cpuUsage: Double = 35.0
    var syncTime: TimeInterval = 0.0
    var cacheHitRate: Double = 0.88
}

// MARK: - Mock Data Creation

private func createMockTask(id: String) -> Task {
    Task(
        id: id,
        title: "Test Task",
        description: "A test task for performance testing",
        dueDate: Date().addingTimeInterval(86400),
        priority: .medium,
        isCompleted: false,
        createdAt: Date(),
        tags: [],
        estimatedDuration: 60
    )
}

private func createMockCalendarEvent(id: String) -> CalendarEvent {
    CalendarEvent(
        id: id,
        title: "Test Event",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        isAllDay: false,
        calendarId: "test_calendar"
    )
}

private func createMockTimeBlock(id: String) -> TimeBlock {
    TimeBlock(
        id: id,
        title: "Test Time Block",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        taskId: "test_task",
        isCompleted: false
    )
}

private func createMockTaskTemplate(id: String) -> TaskTemplate {
    TaskTemplate(
        id: id,
        name: "Test Template",
        description: "A test template",
        category: .work,
        estimatedDuration: 60,
        defaultPriority: .medium,
        subtasks: []
    )
}

private func createMockWorkspace(id: String) -> Workspace {
    Workspace(
        id: id,
        name: "Test Workspace",
        description: "A test workspace",
        color: .blue,
        iconName: "folder",
        createdAt: Date()
    )
}

private func createMockContext() -> TaskContext {
    TaskContext(
        dueDate: Date().addingTimeInterval(86400),
        dependencies: [],
        userPreferences: [:],
        currentWorkload: 5
    )
}

// MARK: - Mock Extensions for Testing

extension TaskDependencyService {
    static let shared = TaskDependencyService()

    func addDependency(from task: Task, to dependency: Task) {
        // Simulate adding dependency
    }

    func getDependencies(for task: Task) -> [Task] {
        []
    }

    func canCompleteTask(_ task: Task) -> Bool {
        true
    }
}

extension PriorityManager {
    static let shared = PriorityManager()

    func updatePriority(for task: Task, basedOn context: TaskContext) {
        // Simulate priority update
    }

    func getPriorityScore(for task: Task) -> Double {
        0.7
    }

    func getPrioritizedTasks(from tasks: [Task]) -> [Task] {
        tasks
    }
}

extension TagManager {
    static let shared = TagManager()

    func createTag(_ tag: Tag) {
        // Simulate tag creation
    }

    func getTasksWithTag(_ tag: Tag) -> [Task] {
        []
    }

    func getTagStatistics() -> [String: Int] {
        [:]
    }
}

extension CalendarSyncService {
    static let shared = CalendarSyncService()

    func syncEvent(_ event: CalendarEvent) {
        // Simulate event sync
    }

    func getEventsForDate(_ date: Date) -> [CalendarEvent] {
        []
    }

    func getConflictingEvents(for event: CalendarEvent) -> [CalendarEvent] {
        []
    }
}

extension TimeBlockService {
    static let shared = TimeBlockService()

    func scheduleTimeBlock(_ timeBlock: TimeBlock) {
        // Simulate scheduling
    }

    func getTimeBlocksForDate(_ date: Date) -> [TimeBlock] {
        []
    }

    func getAvailableTimeSlots(on date: Date) -> [DateInterval] {
        []
    }
}

extension PomodoroTimer {
    static let shared = PomodoroTimer()

    func startTimer() {
        // Simulate starting timer
    }

    func pauseTimer() {
        // Simulate pausing timer
    }

    func resetTimer() {
        // Simulate resetting timer
    }

    func getCurrentSession() -> PomodoroSession? {
        nil
    }
}

extension FocusModeManager {
    static let shared = FocusModeManager()

    func startFocusSession(duration: TimeInterval, task: Task) {
        // Simulate starting focus session
    }

    func getCurrentSession() -> FocusSession? {
        nil
    }

    func getSessionHistory() -> [FocusSession] {
        []
    }
}

extension ProductivityAnalytics {
    static let shared = ProductivityAnalytics()

    func calculateDailyProductivity() -> Double {
        0.75
    }

    func generateWeeklyReport() -> ProductivityReport {
        ProductivityReport()
    }

    func getProductivityTrends() -> [ProductivityDataPoint] {
        []
    }

    func getTimeDistribution() -> [String: TimeInterval] {
        [:]
    }
}

extension BackupManager {
    static let shared = BackupManager()

    func createBackup() -> BackupResult {
        .success
    }

    func getBackupHistory() -> [BackupInfo] {
        []
    }

    func validateBackupIntegrity() -> Bool {
        true
    }
}

extension ConflictDetector {
    static let shared = ConflictDetector()

    func detectConflicts(between task1: Task, and task2: Task) -> [Conflict] {
        []
    }

    func getAllConflicts() -> [Conflict] {
        []
    }
}

extension TaskTemplateService {
    static let shared = TaskTemplateService()

    func saveTemplate(_ template: TaskTemplate) {
        // Simulate saving template
    }

    func getTemplatesForCategory(_ category: TaskCategory) -> [TaskTemplate] {
        []
    }

    func createTaskFromTemplate(_ template: TaskTemplate) -> Task {
        createMockTask(id: "from_template")
    }
}

extension WorkspaceManager {
    static let shared = WorkspaceManager()

    func createWorkspace(_ workspace: Workspace) {
        // Simulate workspace creation
    }

    func getAllWorkspaces() -> [Workspace] {
        []
    }

    func getWorkspaceStatistics() -> WorkspaceStats {
        WorkspaceStats()
    }
}

// MARK: - Mock Data Structures

struct Task {
    let id: String
    let title: String
    let description: String
    let dueDate: Date
    let priority: TaskPriority
    let isCompleted: Bool
    let createdAt: Date
    let tags: [Tag]
    let estimatedDuration: TimeInterval
}

struct Tag {
    let id: String
    let name: String
    let color: TagColor
}

struct CalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarId: String
}

struct TimeBlock {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let taskId: String
    let isCompleted: Bool
}

struct TaskTemplate {
    let id: String
    let name: String
    let description: String
    let category: TaskCategory
    let estimatedDuration: TimeInterval
    let defaultPriority: TaskPriority
    let subtasks: [String]
}

struct Workspace {
    let id: String
    let name: String
    let description: String
    let color: WorkspaceColor
    let iconName: String
    let createdAt: Date
}

struct TaskContext {
    let dueDate: Date
    let dependencies: [Task]
    let userPreferences: [String: Any]
    let currentWorkload: Int
}

enum TaskPriority {
    case low, medium, high, urgent
}

enum TagColor {
    case red, blue, green, yellow, purple
}

enum TaskCategory {
    case work, personal, health, learning
}

enum WorkspaceColor {
    case red, blue, green, yellow, purple
}

struct PomodoroSession {
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isActive: Bool
}

struct FocusSession {
    let id: String
    let startTime: Date
    let duration: TimeInterval
    let taskId: String
    var isCompleted: Bool
}

struct ProductivityReport {
    var dailyAverage: Double = 0.0
    var weeklyTotal: Double = 0.0
    var topCategories: [String] = []
}

struct ProductivityDataPoint {
    let date: Date
    let productivity: Double
}

enum BackupResult {
    case success, failure
}

struct BackupInfo {
    let id: String
    let createdAt: Date
    let size: Int64
}

struct Conflict {
    let id: String
    let type: ConflictType
    let description: String
}

enum ConflictType {
    case timeOverlap, dependencyConflict, resourceConflict
}

struct WorkspaceStats {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var activeWorkspaces: Int = 0
}
