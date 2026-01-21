//
// SDGoalTests.swift
// PlannerAppTests
//
// Unit tests for the SDGoal SwiftData model.
//

@testable import PlannerApp
import SwiftData
import XCTest

final class SDGoalTests: XCTestCase {
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

    func testSDGoalInitialization() throws {
        let targetDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        let goal = SDGoal(
            title: "Test Goal",
            goalDescription: "Test Description",
            targetDate: targetDate,
            isCompleted: false,
            priority: "high",
            progress: 0.5
        )

        XCTAssertEqual(goal.title, "Test Goal")
        XCTAssertEqual(goal.goalDescription, "Test Description")
        XCTAssertEqual(goal.priority, "high")
        XCTAssertEqual(goal.progress, 0.5, accuracy: 0.001)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertNotNil(goal.id)
        XCTAssertNotNil(goal.createdAt)
    }

    func testSDGoalDefaultValues() throws {
        let goal = SDGoal(title: "Minimal Goal", targetDate: Date())

        XCTAssertEqual(goal.title, "Minimal Goal")
        XCTAssertEqual(goal.goalDescription, "")
        XCTAssertEqual(goal.priority, "medium")
        XCTAssertEqual(goal.progress, 0.0, accuracy: 0.001)
        XCTAssertFalse(goal.isCompleted)
    }

    // MARK: - Persistence Tests

    func testSDGoalPersistence() throws {
        let goal = SDGoal(
            title: "Persistent Goal",
            goalDescription: "Long term objective",
            targetDate: Date().addingTimeInterval(86400 * 90),
            priority: "medium",
            progress: 0.25
        )

        context.insert(goal)
        try context.save()

        // Fetch back
        let descriptor = FetchDescriptor<SDGoal>(
            predicate: #Predicate { $0.title == "Persistent Goal" }
        )
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.goalDescription, "Long term objective")
        XCTAssertEqual(fetched.first?.progress ?? 0, 0.25, accuracy: 0.001)
    }

    func testSDGoalUpdate() throws {
        let goal = SDGoal(title: "Original Goal", targetDate: Date())
        context.insert(goal)
        try context.save()

        // Update progress
        goal.progress = 0.75
        goal.title = "Updated Goal"
        try context.save()

        // Verify
        let descriptor = FetchDescriptor<SDGoal>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.first?.title, "Updated Goal")
        XCTAssertEqual(fetched.first?.progress ?? 0, 0.75, accuracy: 0.001)
    }

    func testSDGoalDeletion() throws {
        let goal = SDGoal(title: "To Delete", targetDate: Date())
        context.insert(goal)
        try context.save()

        context.delete(goal)
        try context.save()

        let descriptor = FetchDescriptor<SDGoal>()
        let fetched = try context.fetch(descriptor)

        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Progress Tests

    func testSDGoalUpdateProgress() throws {
        let goal = SDGoal(title: "Progress Test", targetDate: Date())

        goal.updateProgress(0.5)
        XCTAssertEqual(goal.progress, 0.5, accuracy: 0.001)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertNotNil(goal.modifiedAt)
    }

    func testSDGoalAutoCompleteAtFullProgress() throws {
        let goal = SDGoal(title: "Complete Test", targetDate: Date())

        goal.updateProgress(1.0)
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
        XCTAssertTrue(goal.isCompleted)
    }

    func testSDGoalProgressClampedToMax() throws {
        let goal = SDGoal(title: "Clamp Test", targetDate: Date())

        goal.updateProgress(1.5)
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
    }

    func testSDGoalProgressClampedToMin() throws {
        let goal = SDGoal(title: "Clamp Test", targetDate: Date())

        goal.updateProgress(-0.5)
        XCTAssertEqual(goal.progress, 0.0, accuracy: 0.001)
    }

    // MARK: - Priority Tests

    func testSDGoalPrioritySortOrder() throws {
        let low = SDGoal(title: "Low", targetDate: Date(), priority: "low")
        let medium = SDGoal(title: "Medium", targetDate: Date(), priority: "medium")
        let high = SDGoal(title: "High", targetDate: Date(), priority: "high")

        XCTAssertEqual(low.prioritySortOrder, 1)
        XCTAssertEqual(medium.prioritySortOrder, 2)
        XCTAssertEqual(high.prioritySortOrder, 3)
    }

    // MARK: - Completion Tests

    func testSDGoalActiveFiltering() throws {
        let active = SDGoal(title: "In Progress", targetDate: Date(), isCompleted: false, progress: 0.5)
        let done = SDGoal(title: "Completed", targetDate: Date(), isCompleted: true, progress: 1.0)

        context.insert(active)
        context.insert(done)
        try context.save()

        let descriptor = FetchDescriptor<SDGoal>(
            predicate: #Predicate { !$0.isCompleted }
        )
        let activeGoals = try context.fetch(descriptor)

        XCTAssertEqual(activeGoals.count, 1)
        XCTAssertEqual(activeGoals.first?.title, "In Progress")
    }
}
