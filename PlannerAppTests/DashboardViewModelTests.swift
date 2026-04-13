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
            // Clear AppStorage/UserDefaults settings used by the dashboard
            UserDefaults.standard.removeObject(forKey: AppSettingKeys.dashboardItemLimit)
            UserDefaults.standard.removeObject(forKey: AppSettingKeys.firstDayOfWeek)
            
            self.viewModel = DashboardViewModel()
            // Clear all data managers
            WorkspaceManager.shared.clearAllTasks()
            WorkspaceManager.shared.clearAllEvents()
            WorkspaceManager.shared.clearAllGoals()
        }
    }

    override nonisolated func tearDown() async throws {
        await MainActor.run {
            // Cleanup test environment
            WorkspaceManager.shared.clearAllTasks()
            WorkspaceManager.shared.clearAllEvents()
            WorkspaceManager.shared.clearAllGoals()
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

        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Today Event", date: today))
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Yesterday Event", date: yesterday))
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Tomorrow Event", date: tomorrow))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalTodaysEventsCount, 1, "Should filter only today's events"
        )
        XCTAssertEqual(self.viewModel.todaysEvents.count, 1)
        XCTAssertEqual(self.viewModel.todaysEvents.first?.title, "Today Event")
    }

    @MainActor
    func testFetchDashboardDataFiltersIncompleteTasks() {
        WorkspaceManager.shared.add(PlannerTask(title: "Incomplete PlannerTask", isCompleted: false))
        WorkspaceManager.shared.add(PlannerTask(title: "Complete PlannerTask", isCompleted: true))
        WorkspaceManager.shared.add(PlannerTask(title: "Another Incomplete", isCompleted: false))

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

        WorkspaceManager.shared.add(
            PlannerGoal(title: "This Week", taskDescription: "Soon", targetDate: nextWeek)
        )
        WorkspaceManager.shared.add(
            PlannerGoal(title: "Next Month", taskDescription: "Later", targetDate: nextMonth)
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
            WorkspaceManager.shared.add(PlannerTask(title: "PlannerTask \(i)", isCompleted: false))
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

        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Evening", date: evening))
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Morning", date: morning))
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Afternoon", date: afternoon))

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

        WorkspaceManager.shared.add(PlannerGoal(title: "Day 3", taskDescription: "", targetDate: day3))
        WorkspaceManager.shared.add(PlannerGoal(title: "Day 5", taskDescription: "", targetDate: day5))
        WorkspaceManager.shared.add(PlannerGoal(title: "Day 1", taskDescription: "", targetDate: day1))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.upcomingGoals.first?.title, "Day 1", "Goals should be sorted by date"
        )
    }

    // MARK: - refreshData Tests

    @MainActor
    func testRefreshDataCallsFetchDashboardData() async {
        WorkspaceManager.shared.add(PlannerTask(title: "Test PlannerTask", isCompleted: false))

        await self.viewModel.refreshData()

        XCTAssertEqual(self.viewModel.totalIncompleteTasksCount, 1, "Should update task counts")
        XCTAssertEqual(self.viewModel.totalTasks, 1, "Should update quick stats")
    }

    @MainActor
    func testRefreshDataUpdatesQuickStats() async {
        WorkspaceManager.shared.add(PlannerTask(title: "PlannerTask 1", isCompleted: false))
        WorkspaceManager.shared.add(PlannerTask(title: "PlannerTask 2", isCompleted: true))
        WorkspaceManager.shared.add(PlannerGoal(title: "PlannerGoal 1", taskDescription: "", targetDate: Date()))

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

        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Start of Day", date: midnight))
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "End of Day", date: almostMidnight))

        self.viewModel.fetchDashboardData()

        XCTAssertEqual(
            self.viewModel.totalTodaysEventsCount, 2, "Should include both boundary events"
        )
    }

    @MainActor
    func testHandlesLargeDatasets() {
        // Add 100 tasks
        for i in 1...100 {
            WorkspaceManager.shared.add(PlannerTask(title: "PlannerTask \(i)", isCompleted: false))
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

        WorkspaceManager.shared.add(
            PlannerTask(title: "Buy groceries", isCompleted: false, priority: .high)
        )
        WorkspaceManager.shared.add(
            PlannerTask(title: "Finish project", isCompleted: false, priority: .medium)
        )
        WorkspaceManager.shared.add(PlannerCalendarEvent(title: "Team meeting", date: today))
        WorkspaceManager.shared.add(
            PlannerGoal(title: "Learn Swift", taskDescription: "Complete tutorial", targetDate: nextWeek)
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
