//
//  DashboardViewModelTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for DashboardViewModel
//

import XCTest
@testable import PlannerApp

final class DashboardViewModelTests: XCTestCase, @unchecked Sendable {
    @MainActor var viewModel: DashboardViewModel!

    // MARK: - Setup & Teardown

    override nonisolated func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            self.viewModel = DashboardViewModel()
            // Clear all data managers
            TaskDataManager.shared.clearAllTasks()
            CalendarDataManager.shared.clearAllEvents()
            GoalDataManager.shared.clearAllGoals()
        }
    }

    override nonisolated func tearDown() async throws {
        await MainActor.run {
            // Cleanup test environment
            TaskDataManager.shared.clearAllTasks()
            CalendarDataManager.shared.clearAllEvents()
            GoalDataManager.shared.clearAllGoals()
            self.viewModel = nil
        }
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func testInitialization() {
        XCTAssertNotNil(self.viewModel, "ViewModel should initialize")
        XCTAssertEqual(self.viewModel.todaysEvents.count, 0, "Should start with no events")
        XCTAssertEqual(self.viewModel.incompleteTasks.count, 0, "Should start with no tasks")
        XCTAssertEqual(self.viewModel.upcomingGoals.count, 0, "Should start with no goals")
        XCTAssertEqual(self.viewModel.totalTodaysEventsCount, 0)
        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 0)
        XCTAssertEqual(self.viewModel.totalUpcomingGoalsCount, 0)
    }

    // MARK: - Property Tests

    @MainActor
    func testPublishedProperties() {
        XCTAssertNotNil(self.viewModel.todaysEvents)
        XCTAssertNotNil(self.viewModel.incompleteTasks)
        XCTAssertNotNil(self.viewModel.upcomingGoals)
        XCTAssertNotNil(self.viewModel.recentActivities)
        XCTAssertNotNil(self.viewModel.upcomingItems)
        XCTAssertNotNil(self.viewModel.allGoals)
        XCTAssertNotNil(self.viewModel.allEvents)
        XCTAssertNotNil(self.viewModel.allJournalEntries)
    }

    @MainActor
    func testQuickStatsProperties() {
        XCTAssertEqual(self.viewModel.totalTasks, 0)
        XCTAssertEqual(self.viewModel.completedTasks, 0)
        XCTAssertEqual(self.viewModel.totalGoals, 0)
        XCTAssertEqual(self.viewModel.completedGoals, 0)
        XCTAssertEqual(self.viewModel.todayEvents, 0)
    }

    // MARK: - fetchDashboardData Tests

    @MainActor
    func testFetchDashboardDataWithNoData() {
        self.viewModel.fetchDashboardData()

        XCTAssertEqual(self.viewModel.todaysEvents.count, 0)
        XCTAssertEqual(self.viewModel.incompleteTasks.count, 0)
        XCTAssertEqual(self.viewModel.upcomingGoals.count, 0)
        XCTAssertEqual(self.viewModel.totalTodaysEventsCount, 0)
        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 0)
        XCTAssertEqual(self.viewModel.totalUpcomingGoalsCount, 0)
    }

    @MainActor
    func testFetchDashboardDataFiltersTodaysEvents() throws {
        // Add events: today, yesterday, tomorrow
        let today = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))

        CalendarDataManager.shared.add(CalendarEvent(title: "Today Event", date: today))
        CalendarDataManager.shared.add(CalendarEvent(title: "Yesterday Event", date: yesterday))
        CalendarDataManager.shared.add(CalendarEvent(title: "Tomorrow Event", date: tomorrow))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalTodaysEventsCount, 1, "Should filter only today's events"
        )
        XCTAssertEqual(self.viewModel.todaysEvents.count, 1)
        XCTAssertEqual(self.viewModel.todaysEvents.first?.title, "Today Event")
    }

    @MainActor
    func testFetchDashboardDataFiltersIncompleteTasks() {
        TaskDataManager.shared.add(PlannerTask(title: "Incomplete Task", isCompleted: false))
        TaskDataManager.shared.add(PlannerTask(title: "Complete Task", isCompleted: true))
        TaskDataManager.shared.add(PlannerTask(title: "Another Incomplete", isCompleted: false))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalIncompleteTasksCount, 2, "Should filter incomplete tasks"
        )
        XCTAssertEqual(self.viewModel.incompleteTasks.count, 2)
    }

    @MainActor
    func testFetchDashboardDataFiltersUpcomingGoals() throws {
        let today = Date()
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 5, to: today))
        let nextMonth = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 30, to: today))

        GoalDataManager.shared.add(
            Goal(title: "This Week", description: "Soon", targetDate: nextWeek)
        )
        GoalDataManager.shared.add(
            Goal(title: "Next Month", description: "Later", targetDate: nextMonth)
        )

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalUpcomingGoalsCount, 1, "Should filter goals within 7 days"
        )
        XCTAssertEqual(self.viewModel.upcomingGoals.count, 1)
        XCTAssertEqual(self.viewModel.upcomingGoals.first?.title, "This Week")
    }

    @MainActor
    func testFetchDashboardDataRespectsLimit() {
        // Add 5 incomplete tasks
        for i in 1...5 {
            TaskDataManager.shared.add(PlannerTask(title: "Task \(i)", isCompleted: false))
        }

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 5, "Should count all tasks")
        XCTAssertEqual(
            self.viewModel.incompleteTasks.count, 3, "Should limit displayed tasks to default of 3"
        )
    }

    @MainActor
    func testFetchDashboardDataSortsEventsByTime() throws {
        let today = Date()
        let morning = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)
        )
        let afternoon = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)
        )
        let evening = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)
        )

        CalendarDataManager.shared.add(CalendarEvent(title: "Evening", date: evening))
        CalendarDataManager.shared.add(CalendarEvent(title: "Morning", date: morning))
        CalendarDataManager.shared.add(CalendarEvent(title: "Afternoon", date: afternoon))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.todaysEvents.first?.title, "Morning", "Events should be sorted by time"
        )
        XCTAssertEqual(self.viewModel.todaysEvents[1].title, "Afternoon")
        XCTAssertEqual(
            self.viewModel.todaysEvents.last?.title, "Evening", "Latest event within limit"
        )
    }

    @MainActor
    func testFetchDashboardDataSortsGoalsByDate() throws {
        let today = Date()
        let day3 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 3, to: today))
        let day5 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 5, to: today))
        let day1 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))

        GoalDataManager.shared.add(Goal(title: "Day 3", description: "", targetDate: day3))
        GoalDataManager.shared.add(Goal(title: "Day 5", description: "", targetDate: day5))
        GoalDataManager.shared.add(Goal(title: "Day 1", description: "", targetDate: day1))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.upcomingGoals.first?.title, "Day 1", "Goals should be sorted by date"
        )
    }

    // MARK: - refreshData Tests

    @MainActor
    func testRefreshDataCallsFetchDashboardData() async {
        TaskDataManager.shared.add(PlannerTask(title: "Test Task", isCompleted: false))

        await self.viewModel.refreshData()

        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 1, "Should update task counts")
        XCTAssertEqual(self.viewModel.totalTasks, 1, "Should update quick stats")
    }

    @MainActor
    func testRefreshDataUpdatesQuickStats() async {
        TaskDataManager.shared.add(PlannerTask(title: "Task 1", isCompleted: false))
        TaskDataManager.shared.add(PlannerTask(title: "Task 2", isCompleted: true))
        GoalDataManager.shared.add(Goal(title: "Goal 1", description: "", targetDate: Date()))

        await self.viewModel.refreshData()

        XCTAssertEqual(self.viewModel.totalTasks, 2)
        XCTAssertEqual(self.viewModel.completedTasks, 1)
        XCTAssertEqual(self.viewModel.totalGoals, 1)
    }

    // MARK: - Edge Case Tests

    @MainActor
    func testHandlesEmptyDataGracefully() {
        self.viewModel.fetchDashboardData()

        XCTAssertNotNil(self.viewModel.todaysEvents)
        XCTAssertNotNil(self.viewModel.incompleteTasks)
        XCTAssertNotNil(self.viewModel.upcomingGoals)
        XCTAssertEqual(self.viewModel.todaysEvents.count, 0)
    }

    @MainActor
    func testHandlesDateBoundaryConditions() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let almostMidnight = midnight.addingTimeInterval(86399) // 23:59:59

        CalendarDataManager.shared.add(CalendarEvent(title: "Start of Day", date: midnight))
        CalendarDataManager.shared.add(CalendarEvent(title: "End of Day", date: almostMidnight))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalTodaysEventsCount, 2, "Should include both boundary events"
        )
    }

    @MainActor
    func testHandlesLargeDatasets() {
        // Add 100 tasks
        for i in 1...100 {
            TaskDataManager.shared.add(PlannerTask(title: "Task \(i)", isCompleted: false))
        }

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 100, "Should count all tasks")
        XCTAssertEqual(self.viewModel.incompleteTasks.count, 3, "Should limit display to 3")
    }

    // MARK: - Integration Tests

    @MainActor
    func testFullDashboardDataFlow() throws {
        // Setup realistic data
        let today = Date()
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 5, to: today))

        TaskDataManager.shared.add(
            PlannerTask(title: "Buy groceries", isCompleted: false, priority: .high)
        )
        TaskDataManager.shared.add(
            PlannerTask(title: "Finish project", isCompleted: false, priority: .medium)
        )
        CalendarDataManager.shared.add(CalendarEvent(title: "Team meeting", date: today))
        GoalDataManager.shared.add(
            Goal(title: "Learn Swift", description: "Complete tutorial", targetDate: nextWeek)
        )

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 2)
        XCTAssertEqual(self.viewModel.totalTodaysEventsCount, 1)
        XCTAssertEqual(self.viewModel.totalUpcomingGoalsCount, 1)
        XCTAssertEqual(self.viewModel.incompleteTasks.count, 2)
        XCTAssertEqual(self.viewModel.todaysEvents.count, 1)
        XCTAssertEqual(self.viewModel.upcomingGoals.count, 1)
    }
}
