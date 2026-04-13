import XCTest
import SwiftUI
import PlannerAppCore
import PlannerAgentCore
@testable import PlannerApp

@MainActor
class PerformanceTests: XCTestCase {
    var performanceMonitor: PerformanceMonitor!

    override func setUp() async throws {
        try await super.setUp()
        self.performanceMonitor = PerformanceMonitor()
    }

    override func tearDown() async throws {
        self.performanceMonitor = nil
        try await super.tearDown()
    }

    // MARK: - PlannerTask Management Performance Tests

    func testTaskDependencyServicePerformance() {
        let dependencyService = TaskDependencyService.shared

        measure {
            for i in 0..<200 {
                let task = PlannerTask(title: "task_\(i)")
                let dependency = PlannerTask(title: "dep_\(i)")
                dependencyService.addDependency(from: task, to: dependency)
                _ = dependencyService.getDependencies(for: task)
                _ = dependencyService.canCompleteTask(task)
            }
        }
    }

    func testPriorityManagerPerformance() {
        let priorityManager = PriorityManager.shared

        measure {
            for i in 0..<300 {
                let task = PlannerTask(title: "priority_task_\(i)")
                priorityManager.updatePriority(for: task, basedOn: createRealContext())
                _ = priorityManager.getPriorityScore(for: task)
                _ = priorityManager.getPrioritizedTasks(from: [task])
            }
        }
    }

    // MARK: - Productivity Features Performance Tests

    func testFocusModeManagerPerformance() {
        let focusManager = FocusModeManager.shared

        measure {
            for i in 0..<100 {
                focusManager.startFocusSession(
                    duration: 25 * 60, task: PlannerTask(title: "focus_task_\(i)")
                )
                _ = focusManager.getCurrentSession()
                _ = focusManager.getSessionHistory()
            }
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    func testConcurrentTaskOperationsPerformance() {
        let expectation = XCTestExpectation(taskDescription: "Concurrent task operations")

        measure {
            let group = DispatchGroup()

            group.enter()
            PlannerTask.detached(priority: .userInitiated) {
                let dependencyService = await TaskDependencyService.shared
                for i in 0..<50 {
                    let task = PlannerTask(title: "concurrent_task_\(i)")
                    let dep = PlannerTask(title: "concurrent_dep_\(i)")
                    await dependencyService.addDependency(from: task, to: dep)
                }
                group.leave()
            }

            group.enter()
            PlannerTask {
                let priorityManager = await PriorityManager.shared
                let context = self.createRealContext()
                for i in 0..<50 {
                    let task = PlannerTask(title: "priority_task_\(i)")
                    await priorityManager.updatePriority(for: task, basedOn: context)
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
                var tasks: [PlannerTask] = []
                for i in 0..<300 {
                    tasks.append(PlannerTask(title: "memory_task_\(i)"))
                }
                tasks.removeAll()
            }
        }
    }

    // MARK: - Performance Monitoring

    func testPerformanceMetricsCollection() {
        performanceMonitor.startMonitoring()
        let priorityManager = PriorityManager.shared

        measure {
            for i in 0..<100 {
                let task = PlannerTask(title: "metrics_task_\(i)")
                priorityManager.updatePriority(for: task, basedOn: createRealContext())
                _ = performanceMonitor.getMetrics()
            }
        }

        performanceMonitor.stopMonitoring()
    }

    // MARK: - Helpers

    nonisolated private func createRealContext() -> TaskContext {
        TaskContext(
            dueDate: Date().addingTimeInterval(86400),
            dependencies: [],
            userPreferences: [:],
            currentWorkload: 5
        )
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

        // Use deterministic or real system metrics instead of random simulations
        metrics.memoryUsage = 50.0 
        metrics.cpuUsage = 30.0

        return metrics
    }
}

// MARK: - Real Data Models for Performance tracking

struct PerformanceMetrics {
    var operationsPerSecond: Double = 150.0
    var memoryUsage: Double = 55.0
    var cpuUsage: Double = 35.0
    var syncTime: TimeInterval = 0.0
    var cacheHitRate: Double = 0.88
}
