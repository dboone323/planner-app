//
//  CalendarDataManagerTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for CalendarDataManager
//

import XCTest
@testable import PlannerApp

final class CalendarDataManagerTests: XCTestCase, @unchecked Sendable {
    @MainActor var manager: CalendarDataManager!

    // MARK: - Setup & Teardown

    override nonisolated func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            self.manager = WorkspaceManager.shared
            self.manager.clearAllEvents()
        }
    }

    override nonisolated func tearDown() async throws {
        await MainActor.run {
            self.manager.clearAllEvents()
            self.manager = nil
        }
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func testSharedInstanceExists() {
        XCTAssertNotNil(WorkspaceManager.shared)
    }

    @MainActor
    func testSharedInstanceIsSingleton() {
        let instance1 = WorkspaceManager.shared
        let instance2 = WorkspaceManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    // MARK: - Load/Save Tests

    @MainActor
    func testLoadReturnsEmptyArrayInitially() {
        let events = self.manager.load()
        XCTAssertEqual(events.count, 0)
    }

    @MainActor
    func testSaveAndLoadEvents() {
        let event1 = PlannerCalendarEvent(title: "Meeting", date: Date())
        let event2 = PlannerCalendarEvent(title: "Lunch", date: Date())

        self.manager.save(events: [event1, event2])
        let loadedEvents = self.manager.load()

        XCTAssertEqual(loadedEvents.count, 2)
        XCTAssertEqual(loadedEvents[0].title, "Meeting")
        XCTAssertEqual(loadedEvents[1].title, "Lunch")
    }

    // MARK: - Add Tests

    @MainActor
    func testAddEvent() {
        let event = PlannerCalendarEvent(title: "Conference", date: Date())
        self.manager.add(event)

        let events = self.manager.load()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Conference")
        XCTAssertEqual(events.first?.id, event.id)
    }

    @MainActor
    func testAddMultipleEvents() {
        self.manager.add(PlannerCalendarEvent(title: "Event 1", date: Date()))
        self.manager.add(PlannerCalendarEvent(title: "Event 2", date: Date()))
        self.manager.add(PlannerCalendarEvent(title: "Event 3", date: Date()))

        XCTAssertEqual(self.manager.load().count, 3)
    }

    // MARK: - Update Tests

    @MainActor
    func testUpdateEvent() {
        var event = PlannerCalendarEvent(title: "Original", date: Date())
        self.manager.add(event)

        let newDate = Date().addingTimeInterval(3600)
        event.title = "Updated"
        event.date = newDate
        self.manager.update(event)

        let loadedEvents = self.manager.load()
        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.title, "Updated")
        XCTAssertEqual(loadedEvents.first?.date, newDate)
    }

    @MainActor
    func testUpdateNonexistentEvent() {
        let event = PlannerCalendarEvent(title: "Nonexistent", date: Date())
        self.manager.update(event)

        XCTAssertEqual(self.manager.load().count, 0)
    }

    // MARK: - Delete Tests

    @MainActor
    func testDeleteEvent() {
        let event = PlannerCalendarEvent(title: "To Delete", date: Date())
        self.manager.add(event)
        XCTAssertEqual(self.manager.load().count, 1)

        self.manager.delete(event)
        XCTAssertEqual(self.manager.load().count, 0)
    }

    @MainActor
    func testDeleteOnlySpecifiedEvent() {
        let event1 = PlannerCalendarEvent(title: "Keep", date: Date())
        let event2 = PlannerCalendarEvent(title: "Delete", date: Date())

        self.manager.add(event1)
        self.manager.add(event2)
        self.manager.delete(event2)

        let events = self.manager.load()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Keep")
    }

    // MARK: - Find Tests

    @MainActor
    func testFindEventById() {
        let event = PlannerCalendarEvent(title: "Findable", date: Date())
        self.manager.add(event)

        let found = self.manager.find(by: event.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Findable")
        XCTAssertEqual(found?.id, event.id)
    }

    @MainActor
    func testFindNonexistentEvent() {
        let found = self.manager.find(by: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Events For Date Tests

    @MainActor
    func testEventsForSpecificDate() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))
        let todayMorning = try XCTUnwrap(calendar.date(byAdding: .hour, value: 9, to: today))
        let todayNoon = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: today))

        self.manager.add(PlannerCalendarEvent(title: "Today 1", date: todayMorning))
        self.manager.add(PlannerCalendarEvent(title: "Today 2", date: todayNoon))
        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))

        let todayEvents = self.manager.events(for: today)
        XCTAssertEqual(todayEvents.count, 2)
        XCTAssertEqual(todayEvents[0].title, "Today 1")
    }

    @MainActor
    func testEventsForDateReturnsSortedByTime() throws {
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

        self.manager.add(PlannerCalendarEvent(title: "Evening", date: evening))
        self.manager.add(PlannerCalendarEvent(title: "Morning", date: morning))
        self.manager.add(PlannerCalendarEvent(title: "Afternoon", date: afternoon))

        let events = self.manager.events(for: today)
        XCTAssertEqual(events[0].title, "Morning")
        XCTAssertEqual(events[1].title, "Afternoon")
        XCTAssertEqual(events[2].title, "Evening")
    }

    // MARK: - Events Between Dates Tests

    @MainActor
    func testEventsBetweenDates() throws {
        let today = Date()
        let twoDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -2, to: today))
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))

        self.manager.add(PlannerCalendarEvent(title: "Two Days Ago", date: twoDaysAgo))
        self.manager.add(PlannerCalendarEvent(title: "Yesterday", date: yesterday))
        self.manager.add(PlannerCalendarEvent(title: "Today", date: today))
        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))

        let eventsInRange = self.manager.events(between: yesterday, and: today)
        XCTAssertEqual(eventsInRange.count, 2)
        XCTAssertEqual(eventsInRange[0].title, "Yesterday")
        XCTAssertEqual(eventsInRange[1].title, "Today")
    }

    @MainActor
    func testEventsBetweenDatesSorted() throws {
        let start = Date()
        let end = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 3, to: start))
        let day1 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: start))
        let day2 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 2, to: start))

        self.manager.add(PlannerCalendarEvent(title: "Day 2", date: day2))
        self.manager.add(PlannerCalendarEvent(title: "Day 1", date: day1))

        let events = self.manager.events(between: start, and: end)
        XCTAssertEqual(events[0].title, "Day 1")
        XCTAssertEqual(events[1].title, "Day 2")
    }

    // MARK: - Upcoming Events Tests

    @MainActor
    func testUpcomingEventsWithinDays() throws {
        let now = Date()
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 8, to: now))

        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))
        self.manager.add(PlannerCalendarEvent(title: "Next Week", date: nextWeek))

        let upcomingThisWeek = self.manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcomingThisWeek.count, 1)
        XCTAssertEqual(upcomingThisWeek.first?.title, "Tomorrow")
    }

    @MainActor
    func testUpcomingEventsExcludesPast() throws {
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        self.manager.add(PlannerCalendarEvent(title: "Yesterday", date: yesterday))
        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))

        let upcoming = self.manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcoming.count, 1)
        XCTAssertEqual(upcoming.first?.title, "Tomorrow")
    }

    @MainActor
    func testUpcomingEventsSorted() throws {
        let now = Date()
        let day3 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 3, to: now))
        let day1 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let day5 = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 5, to: now))

        self.manager.add(PlannerCalendarEvent(title: "Day 3", date: day3))
        self.manager.add(PlannerCalendarEvent(title: "Day 1", date: day1))
        self.manager.add(PlannerCalendarEvent(title: "Day 5", date: day5))

        let upcoming = self.manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcoming[0].title, "Day 1")
        XCTAssertEqual(upcoming[1].title, "Day 3")
        XCTAssertEqual(upcoming[2].title, "Day 5")
    }

    // MARK: - Sorting Tests

    @MainActor
    func testEventsSortedByDate() throws {
        let today = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))

        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))
        self.manager.add(PlannerCalendarEvent(title: "Yesterday", date: yesterday))
        self.manager.add(PlannerCalendarEvent(title: "Today", date: today))

        let sorted = self.manager.eventsSortedByDate()
        XCTAssertEqual(sorted[0].title, "Yesterday")
        XCTAssertEqual(sorted[1].title, "Today")
        XCTAssertEqual(sorted[2].title, "Tomorrow")
    }

    // MARK: - Statistics Tests

    @MainActor
    func testGetEventStatistics() throws {
        let today = Date()
        let todayMorning = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)
        )
        let todayEvening = try XCTUnwrap(
            Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)
        )
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        let nextWeek = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 10, to: today))

        self.manager.add(PlannerCalendarEvent(title: "Today Morning", date: todayMorning))
        self.manager.add(PlannerCalendarEvent(title: "Today Evening", date: todayEvening))
        self.manager.add(PlannerCalendarEvent(title: "Tomorrow", date: tomorrow))
        self.manager.add(PlannerCalendarEvent(title: "Next Week", date: nextWeek))

        let stats = self.manager.getEventStatistics()

        XCTAssertEqual(stats["total"], 4, "Should count all events")
        XCTAssertEqual(stats["today"], 2, "Should count today's events")
        XCTAssertEqual(stats["thisWeek"], 1, "Tomorrow is the only upcoming event within 7 days")
    }

    @MainActor
    func testStatisticsWithNoEvents() {
        let stats = self.manager.getEventStatistics()

        XCTAssertEqual(stats["total"], 0)
        XCTAssertEqual(stats["today"], 0)
        XCTAssertEqual(stats["thisWeek"], 0)
    }

    // MARK: - Clear Tests

    @MainActor
    func testClearAllEvents() {
        self.manager.add(PlannerCalendarEvent(title: "Event 1", date: Date()))
        self.manager.add(PlannerCalendarEvent(title: "Event 2", date: Date()))
        XCTAssertEqual(self.manager.load().count, 2)

        self.manager.clearAllEvents()
        XCTAssertEqual(self.manager.load().count, 0)
    }

    // MARK: - Edge Cases

    @MainActor
    func testHandlesMidnightBoundary() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let justBeforeMidnight = midnight.addingTimeInterval(-1)
        let justAfterMidnight = midnight.addingTimeInterval(1)

        self.manager.add(PlannerCalendarEvent(title: "Before Midnight", date: justBeforeMidnight))
        self.manager.add(PlannerCalendarEvent(title: "At Midnight", date: midnight))
        self.manager.add(PlannerCalendarEvent(title: "After Midnight", date: justAfterMidnight))

        let todayEvents = self.manager.events(for: Date())
        XCTAssertTrue(todayEvents.contains(where: { $0.title == "At Midnight" }))
        XCTAssertTrue(todayEvents.contains(where: { $0.title == "After Midnight" }))
        XCTAssertFalse(todayEvents.contains(where: { $0.title == "Before Midnight" }))
    }

    @MainActor
    func testPersistenceAcrossInstances() {
        let event = PlannerCalendarEvent(title: "Persistent", date: Date())
        self.manager.add(event)

        let newAccess = WorkspaceManager.shared
        let events = newAccess.load()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Persistent")
    }
}
