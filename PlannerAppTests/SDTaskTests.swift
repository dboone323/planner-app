//
// SDTaskTests.swift
// PlannerAppTests
//
// Unit tests for the SDTask SwiftData model.
//

@testable import PlannerApp
import SwiftData
import XCTest

final class SDTaskTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SDTask.self, SDGoal.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Initialization Tests

    func testSDTaskInitialization() throws {
        let task = SDTask(
            title: "Test Task",
            taskDescription: "Test Description",
            isCompleted: false,
            priority: "high",
            dueDate: Date()
        )

        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.taskDescription, "Test Description")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.priority, "high")
        XCTAssertNotNil(task.dueDate)
        XCTAssertNotNil(task.id)
        XCTAssertNotNil(task.createdAt)
    }

    func testSDTaskDefaultValues() throws {
        let task = SDTask(title: "Minimal Task")

        XCTAssertEqual(task.title, "Minimal Task")
        XCTAssertEqual(task.taskDescription, "")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.priority, "medium")
        XCTAssertNil(task.dueDate)
    }

    // MARK: - Persistence Tests

    func testSDTaskPersistence() throws {
        let task = SDTask(
            title: "Persistent Task",
            taskDescription: "Should be saved",
            isCompleted: true,
            priority: "high"
        )

        context.insert(task)
        try context.save()

        // Fetch back
        let descriptor = FetchDescriptor<SDTask>(
            predicate: #Predicate { $0.title == "Persistent Task" }
        )
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Persistent Task")
        XCTAssertEqual(fetched.first?.taskDescription, "Should be saved")
        XCTAssertTrue(fetched.first?.isCompleted ?? false)
        XCTAssertEqual(fetched.first?.priority, "high")
    }

    func testSDTaskUpdate() throws {
        let task = SDTask(title: "Original Title")
        context.insert(task)
        try context.save()

        // Update
        task.title = "Updated Title"
        task.isCompleted = true
        try context.save()

        // Verify
        let descriptor = FetchDescriptor<SDTask>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.first?.title, "Updated Title")
        XCTAssertTrue(fetched.first?.isCompleted ?? false)
    }

    func testSDTaskDeletion() throws {
        let task = SDTask(title: "To Delete")
        context.insert(task)
        try context.save()

        // Delete
        context.delete(task)
        try context.save()

        // Verify
        let descriptor = FetchDescriptor<SDTask>()
        let fetched = try context.fetch(descriptor)

        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Priority Tests

    func testSDTaskPrioritySortOrder() throws {
        let lowPriority = SDTask(title: "Low", priority: "low")
        let mediumPriority = SDTask(title: "Medium", priority: "medium")
        let highPriority = SDTask(title: "High", priority: "high")

        XCTAssertEqual(lowPriority.prioritySortOrder, 1)
        XCTAssertEqual(mediumPriority.prioritySortOrder, 2)
        XCTAssertEqual(highPriority.prioritySortOrder, 3)
    }

    // MARK: - Completion Tests

    func testSDTaskCompletionFiltering() throws {
        let completed = SDTask(title: "Done", isCompleted: true)
        let pending = SDTask(title: "Pending", isCompleted: false)

        context.insert(completed)
        context.insert(pending)
        try context.save()

        // Fetch only completed
        let descriptor = FetchDescriptor<SDTask>(
            predicate: #Predicate { $0.isCompleted }
        )
        let completedTasks = try context.fetch(descriptor)

        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "Done")
    }

    // MARK: - Sentiment Tests

    func testSDTaskSentimentAnalysis() throws {
        let task = SDTask(title: "Test", taskDescription: "This is a great and amazing feature")
        task.analyzeSentiment()

        XCTAssertEqual(task.sentiment, "positive")
        XCTAssertGreaterThan(task.sentimentScore, 0)
    }

    func testSDTaskNegativeSentiment() throws {
        let task = SDTask(title: "Test", taskDescription: "This is terrible and has a bug")
        task.analyzeSentiment()

        XCTAssertEqual(task.sentiment, "negative")
        XCTAssertLessThan(task.sentimentScore, 0)
    }
}
