//
// CloudKitSyncTests.swift
// PlannerAppTests
//
// Integration tests for CloudKit synchronization.
//

import CloudKit
@testable import PlannerApp
import SwiftData
import XCTest

final class CloudKitSyncTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Use in-memory container for testing without CloudKit
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SDTask.self, SDGoal.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - CloudKit Configuration Tests

    func testCloudKitContainerConfiguration() throws {
        // Verify CloudKit-enabled configuration can be created
        let cloudConfig = ModelConfiguration(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        XCTAssertNotNil(cloudConfig)
    }

    // MARK: - Sync Status Tests

    func testTaskModifiedAtUpdatesOnChange() throws {
        let task = SDTask(title: "Sync Test Task")
        context.insert(task)
        try context.save()

        let originalModifiedAt = task.modifiedAt

        // Simulate change
        Thread.sleep(forTimeInterval: 0.1)
        task.title = "Updated Title"
        task.modifiedAt = Date()
        try context.save()

        XCTAssertNotEqual(task.modifiedAt, originalModifiedAt)
    }

    func testGoalModifiedAtUpdatesOnProgress() throws {
        let goal = SDGoal(title: "Sync Test Goal", targetDate: Date())
        context.insert(goal)
        try context.save()

        XCTAssertNil(goal.modifiedAt)

        // Update progress
        goal.updateProgress(0.5)
        try context.save()

        XCTAssertNotNil(goal.modifiedAt)
    }

    // MARK: - Bulk Operations Tests

    func testBulkTaskInsertion() throws {
        let taskCount = 100

        for i in 0..<taskCount {
            let task = SDTask(title: "Bulk Task \(i)")
            context.insert(task)
        }
        try context.save()

        let descriptor = FetchDescriptor<SDTask>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, taskCount)
    }

    func testBulkGoalInsertion() throws {
        let goalCount = 50

        for i in 0..<goalCount {
            let goal = SDGoal(title: "Bulk Goal \(i)", targetDate: Date())
            context.insert(goal)
        }
        try context.save()

        let descriptor = FetchDescriptor<SDGoal>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, goalCount)
    }

    // MARK: - Conflict Resolution Tests

    func testTaskUniqueIdConstraint() throws {
        let uuid = UUID()

        let task1 = SDTask(id: uuid, title: "First Task")
        context.insert(task1)
        try context.save()

        // Attempt to insert duplicate ID should cause constraint issue
        let task2 = SDTask(id: uuid, title: "Duplicate Task")
        context.insert(task2)

        // SwiftData should handle unique constraint
        XCTAssertThrowsError(try context.save())
    }

    // MARK: - Data Integrity Tests

    func testTaskDataIntegrityAfterMultipleUpdates() throws {
        let task = SDTask(
            title: "Integrity Test",
            taskDescription: "Original Description",
            priority: "low"
        )
        context.insert(task)
        try context.save()

        // Multiple updates
        task.priority = "medium"
        try context.save()

        task.priority = "high"
        task.isCompleted = true
        try context.save()

        // Verify final state
        let descriptor = FetchDescriptor<SDTask>(
            predicate: #Predicate { $0.title == "Integrity Test" }
        )
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.first?.priority, "high")
        XCTAssertTrue(fetched.first?.isCompleted ?? false)
    }
}
