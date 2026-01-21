//
//  DashboardViewModelTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for DashboardViewModel
//

@testable import PlannerApp
import XCTest

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        viewModel = DashboardViewModel()
        // Clear all data managers
        TaskDataManager.shared.clearAllTasks()
        CalendarDataManager.shared.clearAllEvents()
        GoalDataManager.shared.clearAllGoals()
    }

    override func tearDown() {
        // Cleanup test environment
        TaskDataManager.shared.clearAllTasks()
        CalendarDataManager.shared.clearAllEvents()
        GoalDataManager.shared.clearAllGoals()
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel, "ViewModel should initialize")
        XCTAssertEqual(viewModel.todaysEvents.count, 0, "Should start with no events")
        XCTAssertEqual(viewModel.incompleteTasks.count, 0, "Should start with no tasks")
        XCTAssertEqual(viewModel.upcomingGoals.count, 0, "Should start with no goals")
        XCTAssertEqual(viewModel.totalTodaysEventsCount, 0)
        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 0)
        XCTAssertEqual(viewModel.totalUpcomingGoalsCount, 0)
    }

    // MARK: - Property Tests

    func testPublishedProperties() {
        XCTAssertNotNil(viewModel.todaysEvents)
        XCTAssertNotNil(viewModel.incompleteTasks)
        XCTAssertNotNil(viewModel.upcomingGoals)
        XCTAssertNotNil(viewModel.recentActivities)
        XCTAssertNotNil(viewModel.upcomingItems)
        XCTAssertNotNil(viewModel.allGoals)
        XCTAssertNotNil(viewModel.allEvents)
        XCTAssertNotNil(viewModel.allJournalEntries)
    }

    func testQuickStatsProperties() {
        XCTAssertEqual(viewModel.totalTasks, 0)
        XCTAssertEqual(viewModel.completedTasks, 0)
        XCTAssertEqual(viewModel.totalGoals, 0)
        XCTAssertEqual(viewModel.completedGoals, 0)
        XCTAssertEqual(viewModel.todayEvents, 0)
    }

    // MARK: - fetchDashboardData Tests

    func testFetchDashboardDataWithNoData() {
        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.todaysEvents.count, 0)
        XCTAssertEqual(viewModel.incompleteTasks.count, 0)
        XCTAssertEqual(viewModel.upcomingGoals.count, 0)
        XCTAssertEqual(viewModel.totalTodaysEventsCount, 0)
        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 0)
        XCTAssertEqual(viewModel.totalUpcomingGoalsCount, 0)
    }

    func testFetchDashboardDataFiltersTodaysEvents() {
        // Add events: today, yesterday, tomorrow
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        CalendarDataManager.shared.add(CalendarEvent(title: "Today Event", date: today))
        CalendarDataManager.shared.add(CalendarEvent(title: "Yesterday Event", date: yesterday))
        CalendarDataManager.shared.add(CalendarEvent(title: "Tomorrow Event", date: tomorrow))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalTodaysEventsCount, 1, "Should filter only today's events")
        XCTAssertEqual(viewModel.todaysEvents.count, 1)
        XCTAssertEqual(viewModel.todaysEvents.first?.title, "Today Event")
    }

    func testFetchDashboardDataFiltersIncompleteTasks() {
        TaskDataManager.shared.add(PlannerTask(title: "Incomplete Task", isCompleted: false))
        TaskDataManager.shared.add(PlannerTask(title: "Complete Task", isCompleted: true))
        TaskDataManager.shared.add(PlannerTask(title: "Another Incomplete", isCompleted: false))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 2, "Should filter incomplete tasks")
        XCTAssertEqual(viewModel.incompleteTasks.count, 2)
    }

    func testFetchDashboardDataFiltersUpcomingGoals() {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: today)!
        let nextMonth = Calendar.current.date(byAdding: .day, value: 30, to: today)!

        GoalDataManager.shared.add(Goal(title: "This Week", description: "Soon", targetDate: nextWeek))
        GoalDataManager.shared.add(Goal(title: "Next Month", description: "Later", targetDate: nextMonth))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalUpcomingGoalsCount, 1, "Should filter goals within 7 days")
        XCTAssertEqual(viewModel.upcomingGoals.count, 1)
        XCTAssertEqual(viewModel.upcomingGoals.first?.title, "This Week")
    }

    func testFetchDashboardDataRespectsLimit() {
        // Add 5 incomplete tasks
        for i in 1...5 {
            TaskDataManager.shared.add(PlannerTask(title: "Task \(i)", isCompleted: false))
        }

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 5, "Should count all tasks")
        XCTAssertEqual(viewModel.incompleteTasks.count, 3, "Should limit displayed tasks to default of 3")
    }

    func testFetchDashboardDataSortsEventsByTime() {
        let today = Date()
        let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
        let afternoon = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
        let evening = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!

        CalendarDataManager.shared.add(CalendarEvent(title: "Evening", date: evening))
        CalendarDataManager.shared.add(CalendarEvent(title: "Morning", date: morning))
        CalendarDataManager.shared.add(CalendarEvent(title: "Afternoon", date: afternoon))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.todaysEvents.first?.title, "Morning", "Events should be sorted by time")
        XCTAssertEqual(viewModel.todaysEvents[1].title, "Afternoon")
        XCTAssertEqual(viewModel.todaysEvents.last?.title, "Evening", "Latest event within limit")
    }

    func testFetchDashboardDataSortsGoalsByDate() {
        let today = Date()
        let day3 = Calendar.current.date(byAdding: .day, value: 3, to: today)!
        let day5 = Calendar.current.date(byAdding: .day, value: 5, to: today)!
        let day1 = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        GoalDataManager.shared.add(Goal(title: "Day 3", description: "", targetDate: day3))
        GoalDataManager.shared.add(Goal(title: "Day 5", description: "", targetDate: day5))
        GoalDataManager.shared.add(Goal(title: "Day 1", description: "", targetDate: day1))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.upcomingGoals.first?.title, "Day 1", "Goals should be sorted by date")
    }

    // MARK: - refreshData Tests

    func testRefreshDataCallsFetchDashboardData() async {
        TaskDataManager.shared.add(PlannerTask(title: "Test Task", isCompleted: false))

        await viewModel.refreshData()

        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 1, "Should update task counts")
        XCTAssertEqual(viewModel.totalTasks, 1, "Should update quick stats")
    }

    func testRefreshDataUpdatesQuickStats() async {
        TaskDataManager.shared.add(PlannerTask(title: "Task 1", isCompleted: false))
        TaskDataManager.shared.add(PlannerTask(title: "Task 2", isCompleted: true))
        GoalDataManager.shared.add(Goal(title: "Goal 1", description: "", targetDate: Date()))

        await viewModel.refreshData()

        XCTAssertEqual(viewModel.totalTasks, 2)
        XCTAssertEqual(viewModel.completedTasks, 1)
        XCTAssertEqual(viewModel.totalGoals, 1)
    }

    // MARK: - Edge Case Tests

    func testHandlesEmptyDataGracefully() {
        viewModel.fetchDashboardData()

        XCTAssertNotNil(viewModel.todaysEvents)
        XCTAssertNotNil(viewModel.incompleteTasks)
        XCTAssertNotNil(viewModel.upcomingGoals)
        XCTAssertEqual(viewModel.todaysEvents.count, 0)
    }

    func testHandlesDateBoundaryConditions() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let almostMidnight = midnight.addingTimeInterval(86399) // 23:59:59

        CalendarDataManager.shared.add(CalendarEvent(title: "Start of Day", date: midnight))
        CalendarDataManager.shared.add(CalendarEvent(title: "End of Day", date: almostMidnight))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalTodaysEventsCount, 2, "Should include both boundary events")
    }

    func testHandlesLargeDatasets() {
        // Add 100 tasks
        for i in 1...100 {
            TaskDataManager.shared.add(PlannerTask(title: "Task \(i)", isCompleted: false))
        }

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 100, "Should count all tasks")
        XCTAssertEqual(viewModel.incompleteTasks.count, 3, "Should limit display to 3")
    }

    // MARK: - Integration Tests

    func testFullDashboardDataFlow() {
        // Setup realistic data
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: today)!

        TaskDataManager.shared.add(PlannerTask(title: "Buy groceries", isCompleted: false, priority: .high))
        TaskDataManager.shared.add(PlannerTask(title: "Finish project", isCompleted: false, priority: .medium))
        CalendarDataManager.shared.add(CalendarEvent(title: "Team meeting", date: today))
        GoalDataManager.shared.add(Goal(title: "Learn Swift", description: "Complete tutorial", targetDate: nextWeek))

        viewModel.fetchDashboardData()

        XCTAssertEqual(viewModel.totalIncompleteTasksCount, 2)
        XCTAssertEqual(viewModel.totalTodaysEventsCount, 1)
        XCTAssertEqual(viewModel.totalUpcomingGoalsCount, 1)
        XCTAssertEqual(viewModel.incompleteTasks.count, 2)
        XCTAssertEqual(viewModel.todaysEvents.count, 1)
        XCTAssertEqual(viewModel.upcomingGoals.count, 1)
    }
}
