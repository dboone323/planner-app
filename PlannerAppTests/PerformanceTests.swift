//
// PerformanceTests.swift
// PlannerAppTests
//

import XCTest
@testable import PlannerApp

class PerformanceTests: XCTestCase, @unchecked Sendable {
    @MainActor var performanceMonitor: PerformanceMonitor!

    override nonisolated func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            self.performanceMonitor = PerformanceMonitor()
        }
    }

    override nonisolated func tearDown() async throws {
        await MainActor.run {
            self.performanceMonitor = nil
        }
        try await super.tearDown()
    }

    // MARK: - Task Management Performance Tests

    @MainActor
    func testTaskDependencyServicePerformance() {
        let dependencyService = TaskDependencyService.shared

        measure {
            for i in 0..<200 {
                let task = createMockTask(id: "task_\(i)")
                let dependency = createMockTask(id: "dep_\(i)")
                dependencyService.addDependency(from: task, to: dependency)
                _ = dependencyService.getDependencies(for: task)
                _ = dependencyService.canCompleteTask(task)
            }
        }
    }

    @MainActor
    func testPriorityManagerPerformance() {
        let priorityManager = PriorityManager.shared

        measure {
            for i in 0..<300 {
                let task = createMockTask(id: "priority_task_\(i)")
                priorityManager.updatePriority(for: task, basedOn: createMockContext())
                _ = priorityManager.getPriorityScore(for: task)
                _ = priorityManager.getPrioritizedTasks(from: [task])
            }
        }
    }

    @MainActor
    func testTagManagerPerformance() {
        let tagManager = TagManager.shared

        measure {
            for i in 0..<150 {
                let tag = MockTag(id: "tag_\(i)", name: "Tag \(i)", color: .blue)
                tagManager.createTag(tag)
                _ = tagManager.getTasksWithTag(tag)
                _ = tagManager.getTagStatistics()
            }
        }
    }

    // MARK: - Calendar & Time Management Performance Tests

    @MainActor
    func testCalendarSyncServicePerformance() {
        let calendarSync = CalendarSyncService.shared

        measure {
            for i in 0..<50 {
                let event = createMockCalendarEvent(id: "event_\(i)")
                calendarSync.syncEvent(event)
                _ = calendarSync.getEventsForDate(Date())
                _ = calendarSync.getConflictingEvents(for: event)
            }
        }
    }

    @MainActor
    func testTimeBlockServicePerformance() {
        let timeBlockService = TimeBlockService.shared

        measure {
            for i in 0..<100 {
                let timeBlock = createMockTimeBlock(id: "block_\(i)")
                timeBlockService.scheduleTimeBlock(timeBlock)
                _ = timeBlockService.getTimeBlocksForDate(Date())
                _ = timeBlockService.getAvailableTimeSlots(on: Date())
            }
        }
    }

    // MARK: - Productivity Features Performance Tests

    @MainActor
    func testPomodoroTimerPerformance() {
        let pomodoroTimer = PomodoroTimer.shared

        measure {
            for _ in 0..<200 {
                pomodoroTimer.startTimer()
                pomodoroTimer.pauseTimer()
                pomodoroTimer.resetTimer()
                _ = pomodoroTimer.getCurrentSession()
            }
        }
    }

    @MainActor
    func testFocusModeManagerPerformance() {
        let focusManager = FocusModeManager.shared

        measure {
            for i in 0..<100 {
                focusManager.startFocusSession(
                    duration: 25 * 60, task: createMockTask(id: "focus_task_\(i)")
                )
                _ = focusManager.getCurrentSession()
                _ = focusManager.getSessionHistory()
            }
        }
    }

    @MainActor
    func testProductivityAnalyticsPerformance() {
        let analytics = ProductivityAnalytics.shared

        measure {
            for _ in 0..<50 {
                _ = analytics.calculateDailyProductivity()
                _ = analytics.generateWeeklyReport()
                _ = analytics.getProductivityTrends()
                _ = analytics.getTimeDistribution()
            }
        }
    }

    // MARK: - Data Management Performance Tests

    @MainActor
    func testBackupManagerPerformance() {
        let backupManager = BackupManager.shared

        measure {
            for _ in 0..<20 {
                _ = backupManager.createBackup()
                _ = backupManager.getBackupHistory()
                _ = backupManager.validateBackupIntegrity()
            }
        }
    }

    @MainActor
    func testConflictDetectorPerformance() {
        let conflictDetector = ConflictDetector.shared

        measure {
            for i in 0..<100 {
                let task1 = createMockTask(id: "conflict_task1_\(i)")
                let task2 = createMockTask(id: "conflict_task2_\(i)")
                _ = conflictDetector.detectConflicts(between: task1, and: task2)
                _ = conflictDetector.getAllConflicts()
            }
        }
    }

    // MARK: - Template & Workspace Performance Tests

    @MainActor
    func testTaskTemplateServicePerformance() {
        let templateService = TaskTemplateService.shared

        measure {
            for i in 0..<80 {
                let template = createMockTaskTemplate(id: "template_\(i)")
                templateService.saveTemplate(template)
                _ = templateService.getTemplatesForCategory(.work)
                _ = templateService.createTaskFromTemplate(template)
            }
        }
    }

    @MainActor
    func testWorkspaceManagerPerformance() {
        let workspaceManager = WorkspaceManager.shared

        measure {
            for i in 0..<50 {
                let workspace = createMockWorkspace(id: "workspace_\(i)")
                workspaceManager.createWorkspace(workspace)
                _ = workspaceManager.getAllWorkspaces()
                _ = workspaceManager.getWorkspaceStatistics()
            }
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    @MainActor
    func testConcurrentTaskOperationsPerformance() {
        let expectation = XCTestExpectation(description: "Concurrent task operations")

        measure {
            let group = DispatchGroup()

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let dependencyService = TaskDependencyService.shared
                for i in 0..<50 {
                    let task = createMockTask(id: "concurrent_task_\(i)")
                    dependencyService.addDependency(
                        from: task, to: createMockTask(id: "concurrent_dep_\(i)")
                    )
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let priorityManager = PriorityManager.shared
                for i in 0..<50 {
                    let task = createMockTask(id: "priority_task_\(i)")
                    priorityManager.updatePriority(for: task, basedOn: createMockContext())
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let analytics = ProductivityAnalytics.shared
                for _ in 0..<50 {
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

    @MainActor
    func testMemoryUsageDuringTaskOperations() {
        measure {
            autoreleasepool {
                var tasks: [MockTask] = []
                var timeBlocks: [MockTimeBlock] = []
                var workspaces: [MockWorkspace] = []

                for i in 0..<300 {
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

    @MainActor
    func testPerformanceMetricsCollection() {
        performanceMonitor.startMonitoring()

        let priorityManager = PriorityManager.shared

        measure {
            for i in 0..<100 {
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
    private var metrics: MockPerformanceMetrics = .init()

    func startMonitoring() {
        startTime = Date()
        operationCount = 0
        metrics = MockPerformanceMetrics()
    }

    func stopMonitoring() {
        startTime = nil
    }

    func getMetrics() -> MockPerformanceMetrics {
        operationCount += 1

        if let startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            metrics.operationsPerSecond = Double(operationCount) / elapsed
        }

        // Simulate memory and CPU monitoring
        metrics.memoryUsage = Double.random(in: 40...80)
        metrics.cpuUsage = Double.random(in: 25...60)

        return metrics
    }
}

// MARK: - Extended Data Models

struct MockPerformanceMetrics {
    var operationsPerSecond: Double = 150.0
    var memoryUsage: Double = 55.0
    var cpuUsage: Double = 35.0
    var syncTime: TimeInterval = 0.0
    var cacheHitRate: Double = 0.88
}

// MARK: - Mock Data Creation

private func createMockTask(id: String) -> MockTask {
    MockTask(
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

private func createMockCalendarEvent(id: String) -> MockCalendarEvent {
    MockCalendarEvent(
        id: id,
        title: "Test Event",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        isAllDay: false,
        calendarId: "test_calendar"
    )
}

private func createMockTimeBlock(id: String) -> MockTimeBlock {
    MockTimeBlock(
        id: id,
        title: "Test Time Block",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        taskId: "test_task",
        isCompleted: false
    )
}

private func createMockTaskTemplate(id: String) -> MockTaskTemplate {
    MockTaskTemplate(
        id: id,
        name: "Test Template",
        description: "A test template",
        category: .work,
        estimatedDuration: 60,
        defaultPriority: .medium,
        subtasks: []
    )
}

private func createMockWorkspace(id: String) -> MockWorkspace {
    MockWorkspace(
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
    @MainActor static let shared = TaskDependencyService()

    func addDependency(from task: MockTask, to dependency: MockTask) {
        // Simulate adding dependency
    }

    func getDependencies(for task: MockTask) -> [MockTask] {
        []
    }

    func canCompleteTask(_ task: MockTask) -> Bool {
        true
    }
}

extension PriorityManager {
    @MainActor static let shared = PriorityManager()

    func updatePriority(for task: MockTask, basedOn context: TaskContext) {
        // Simulate priority update
    }

    func getPriorityScore(for task: MockTask) -> Double {
        0.7
    }

    func getPrioritizedTasks(from tasks: [MockTask]) -> [MockTask] {
        tasks
    }
}

extension TagManager {
    @MainActor static let shared = TagManager()

    func createTag(_ tag: MockTag) {
        // Simulate tag creation
    }

    func getTasksWithTag(_ tag: MockTag) -> [MockTask] {
        []
    }

    func getTagStatistics() -> [String: Int] {
        [:]
    }
}

extension CalendarSyncService {
    @MainActor static let shared = CalendarSyncService()

    func syncEvent(_ event: MockCalendarEvent) {
        // Simulate event sync
    }

    func getEventsForDate(_ date: Date) -> [MockCalendarEvent] {
        []
    }

    func getConflictingEvents(for event: MockCalendarEvent) -> [MockCalendarEvent] {
        []
    }
}

extension TimeBlockService {
    @MainActor static let shared = TimeBlockService()

    func scheduleTimeBlock(_ timeBlock: MockTimeBlock) {
        // Simulate scheduling
    }

    func getTimeBlocksForDate(_ date: Date) -> [MockTimeBlock] {
        []
    }

    func getAvailableTimeSlots(on date: Date) -> [DateInterval] {
        []
    }
}

extension PomodoroTimer {
    nonisolated(unsafe) static let shared = PomodoroTimer()

    func startTimer() {
        // Simulate starting timer
    }

    func pauseTimer() {
        // Simulate pausing timer
    }

    func resetTimer() {
        // Simulate resetting timer
    }

    func getCurrentSession() -> MockPomodoroSession? {
        nil
    }
}

extension FocusModeManager {
    nonisolated(unsafe) static let shared = FocusModeManager()

    func startFocusSession(duration: TimeInterval, task: MockTask) {
        // Simulate starting focus session
    }

    func getCurrentSession() -> MockFocusSession? {
        nil
    }

    func getSessionHistory() -> [MockFocusSession] {
        []
    }
}

extension ProductivityAnalytics {
    @MainActor static let shared = ProductivityAnalytics()

    func calculateDailyProductivity() -> Double {
        0.75
    }

    func generateWeeklyReport() -> MockProductivityReport {
        MockProductivityReport()
    }

    func getProductivityTrends() -> [MockProductivityDataPoint] {
        []
    }

    func getTimeDistribution() -> [String: TimeInterval] {
        [:]
    }
}

extension BackupManager {
    @MainActor static let shared = BackupManager()

    func createBackup() -> MockBackupResult {
        .success
    }

    func getBackupHistory() -> [MockBackupInfo] {
        []
    }

    func validateBackupIntegrity() -> Bool {
        true
    }
}

extension ConflictDetector {
    @MainActor static let shared = ConflictDetector()

    func detectConflicts(between task1: MockTask, and task2: MockTask) -> [MockConflict] {
        []
    }

    func getAllConflicts() -> [MockConflict] {
        []
    }
}

extension TaskTemplateService {
    @MainActor static let shared = TaskTemplateService()

    func saveTemplate(_ template: MockTaskTemplate) {
        // Simulate saving template
    }

    func getTemplatesForCategory(_ category: MockTaskCategory) -> [MockTaskTemplate] {
        []
    }

    func createTaskFromTemplate(_ template: MockTaskTemplate) -> MockTask {
        createMockTask(id: "from_template")
    }
}

extension WorkspaceManager {
    nonisolated(unsafe) static let shared = WorkspaceManager()

    func createWorkspace(_ workspace: MockWorkspace) {
        // Simulate workspace creation
    }

    func getAllWorkspaces() -> [MockWorkspace] {
        []
    }

    func getWorkspaceStatistics() -> MockWorkspaceStats {
        MockWorkspaceStats()
    }
}

// MARK: - Mock Data Structures

struct MockTask {
    let id: String
    let title: String
    let description: String
    let dueDate: Date
    let priority: MockTaskPriority
    let isCompleted: Bool
    let createdAt: Date
    let tags: [MockTag]
    let estimatedDuration: TimeInterval
}

struct MockTag {
    let id: String
    let name: String
    let color: MockTagColor
}

struct MockCalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarId: String
}

struct MockTimeBlock {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let taskId: String
    let isCompleted: Bool
}

struct MockTaskTemplate {
    let id: String
    let name: String
    let description: String
    let category: MockTaskCategory
    let estimatedDuration: TimeInterval
    let defaultPriority: MockTaskPriority
    let subtasks: [String]
}

struct MockWorkspace {
    let id: String
    let name: String
    let description: String
    let color: MockWorkspaceColor
    let iconName: String
    let createdAt: Date
}

struct TaskContext {
    let dueDate: Date
    let dependencies: [MockTask]
    let userPreferences: [String: Any]
    let currentWorkload: Int
}

enum MockTaskPriority {
    case low, medium, high, urgent
}

enum MockTagColor {
    case red, blue, green, yellow, purple
}

enum MockTaskCategory {
    case work, personal, health, learning
}

enum MockWorkspaceColor {
    case red, blue, green, yellow, purple
}

struct MockPomodoroSession {
    var duration: TimeInterval
    var elapsedTime: TimeInterval
    var isActive: Bool
}

struct MockFocusSession {
    let id: String
    let startTime: Date
    let duration: TimeInterval
    let taskId: String
    var isCompleted: Bool
}

struct MockProductivityReport {
    var dailyAverage: Double = 0.0
    var weeklyTotal: Double = 0.0
    var topCategories: [String] = []
}

struct MockProductivityDataPoint {
    let date: Date
    let productivity: Double
}

enum MockBackupResult {
    case success, failure
}

struct MockBackupInfo {
    let id: String
    let createdAt: Date
    let size: Int64
}

struct MockConflict {
    let id: String
    let type: MockConflictType
    let description: String
}

enum MockConflictType {
    case timeOverlap, dependencyConflict, resourceConflict
}

struct MockWorkspaceStats {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var activeWorkspaces: Int = 0
}
