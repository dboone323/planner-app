//
//  CalendarDataManagerTests.swift
//  PlannerAppTests
//
//  Comprehensive test suite for CalendarDataManager
//

@testable import PlannerApp
import XCTest

final class CalendarDataManagerTests: XCTestCase {
    var manager: CalendarDataManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        manager = CalendarDataManager.shared
        manager.clearAllEvents()
    }

    override func tearDown() {
        manager.clearAllEvents()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(CalendarDataManager.shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = CalendarDataManager.shared
        let instance2 = CalendarDataManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }

    // MARK: - Load/Save Tests

    func testLoadReturnsEmptyArrayInitially() {
        let events = manager.load()
        XCTAssertEqual(events.count, 0)
    }

    func testSaveAndLoadEvents() {
        let event1 = CalendarEvent(title: "Meeting", date: Date())
        let event2 = CalendarEvent(title: "Lunch", date: Date())

        manager.save(events: [event1, event2])
        let loadedEvents = manager.load()

        XCTAssertEqual(loadedEvents.count, 2)
        XCTAssertEqual(loadedEvents[0].title, "Meeting")
        XCTAssertEqual(loadedEvents[1].title, "Lunch")
    }

    // MARK: - Add Tests

    func testAddEvent() {
        let event = CalendarEvent(title: "Conference", date: Date())
        manager.add(event)

        let events = manager.load()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Conference")
        XCTAssertEqual(events.first?.id, event.id)
    }

    func testAddMultipleEvents() {
        manager.add(CalendarEvent(title: "Event 1", date: Date()))
        manager.add(CalendarEvent(title: "Event 2", date: Date()))
        manager.add(CalendarEvent(title: "Event 3", date: Date()))

        XCTAssertEqual(manager.load().count, 3)
    }

    // MARK: - Update Tests

    func testUpdateEvent() {
        var event = CalendarEvent(title: "Original", date: Date())
        manager.add(event)

        let newDate = Date().addingTimeInterval(3600)
        event.title = "Updated"
        event.date = newDate
        manager.update(event)

        let loadedEvents = manager.load()
        XCTAssertEqual(loadedEvents.count, 1)
        XCTAssertEqual(loadedEvents.first?.title, "Updated")
        XCTAssertEqual(loadedEvents.first?.date, newDate)
    }

    func testUpdateNonexistentEvent() {
        let event = CalendarEvent(title: "Nonexistent", date: Date())
        manager.update(event)

        XCTAssertEqual(manager.load().count, 0)
    }

    // MARK: - Delete Tests

    func testDeleteEvent() {
        let event = CalendarEvent(title: "To Delete", date: Date())
        manager.add(event)
        XCTAssertEqual(manager.load().count, 1)

        manager.delete(event)
        XCTAssertEqual(manager.load().count, 0)
    }

    func testDeleteOnlySpecifiedEvent() {
        let event1 = CalendarEvent(title: "Keep", date: Date())
        let event2 = CalendarEvent(title: "Delete", date: Date())

        manager.add(event1)
        manager.add(event2)
        manager.delete(event2)

        let events = manager.load()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Keep")
    }

    // MARK: - Find Tests

    func testFindEventById() {
        let event = CalendarEvent(title: "Findable", date: Date())
        manager.add(event)

        let found = manager.find(by: event.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.title, "Findable")
        XCTAssertEqual(found?.id, event.id)
    }

    func testFindNonexistentEvent() {
        let found = manager.find(by: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Events For Date Tests

    func testEventsForSpecificDate() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        manager.add(CalendarEvent(title: "Today 1", date: today))
        manager.add(CalendarEvent(title: "Today 2", date: today.addingTimeInterval(3600)))
        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))

        let todayEvents = manager.events(for: today)
        XCTAssertEqual(todayEvents.count, 2)
        XCTAssertEqual(todayEvents[0].title, "Today 1")
    }

    func testEventsForDateReturnsSortedByTime() {
        let today = Date()
        let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
        let afternoon = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
        let evening = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!

        manager.add(CalendarEvent(title: "Evening", date: evening))
        manager.add(CalendarEvent(title: "Morning", date: morning))
        manager.add(CalendarEvent(title: "Afternoon", date: afternoon))

        let events = manager.events(for: today)
        XCTAssertEqual(events[0].title, "Morning")
        XCTAssertEqual(events[1].title, "Afternoon")
        XCTAssertEqual(events[2].title, "Evening")
    }

    // MARK: - Events Between Dates Tests

    func testEventsBetweenDates() {
        let today = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        manager.add(CalendarEvent(title: "Two Days Ago", date: twoDaysAgo))
        manager.add(CalendarEvent(title: "Yesterday", date: yesterday))
        manager.add(CalendarEvent(title: "Today", date: today))
        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))

        let eventsInRange = manager.events(between: yesterday, and: today)
        XCTAssertEqual(eventsInRange.count, 2)
        XCTAssertEqual(eventsInRange[0].title, "Yesterday")
        XCTAssertEqual(eventsInRange[1].title, "Today")
    }

    func testEventsBetweenDatesSorted() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        let day1 = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let day2 = Calendar.current.date(byAdding: .day, value: 2, to: start)!

        manager.add(CalendarEvent(title: "Day 2", date: day2))
        manager.add(CalendarEvent(title: "Day 1", date: day1))

        let events = manager.events(between: start, and: end)
        XCTAssertEqual(events[0].title, "Day 1")
        XCTAssertEqual(events[1].title, "Day 2")
    }

    // MARK: - Upcoming Events Tests

    func testUpcomingEventsWithinDays() {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 8, to: now)!

        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))
        manager.add(CalendarEvent(title: "Next Week", date: nextWeek))

        let upcomingThisWeek = manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcomingThisWeek.count, 1)
        XCTAssertEqual(upcomingThisWeek.first?.title, "Tomorrow")
    }

    func testUpcomingEventsExcludesPast() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        manager.add(CalendarEvent(title: "Yesterday", date: yesterday))
        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))

        let upcoming = manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcoming.count, 1)
        XCTAssertEqual(upcoming.first?.title, "Tomorrow")
    }

    func testUpcomingEventsSorted() {
        let now = Date()
        let day3 = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        let day1 = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let day5 = Calendar.current.date(byAdding: .day, value: 5, to: now)!

        manager.add(CalendarEvent(title: "Day 3", date: day3))
        manager.add(CalendarEvent(title: "Day 1", date: day1))
        manager.add(CalendarEvent(title: "Day 5", date: day5))

        let upcoming = manager.upcomingEvents(within: 7)
        XCTAssertEqual(upcoming[0].title, "Day 1")
        XCTAssertEqual(upcoming[1].title, "Day 3")
        XCTAssertEqual(upcoming[2].title, "Day 5")
    }

    // MARK: - Sorting Tests

    func testEventsSortedByDate() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))
        manager.add(CalendarEvent(title: "Yesterday", date: yesterday))
        manager.add(CalendarEvent(title: "Today", date: today))

        let sorted = manager.eventsSortedByDate()
        XCTAssertEqual(sorted[0].title, "Yesterday")
        XCTAssertEqual(sorted[1].title, "Today")
        XCTAssertEqual(sorted[2].title, "Tomorrow")
    }

    // MARK: - Statistics Tests

    func testGetEventStatistics() {
        let today = Date()
        let todayMorning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
        let todayEvening = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 10, to: today)!

        manager.add(CalendarEvent(title: "Today Morning", date: todayMorning))
        manager.add(CalendarEvent(title: "Today Evening", date: todayEvening))
        manager.add(CalendarEvent(title: "Tomorrow", date: tomorrow))
        manager.add(CalendarEvent(title: "Next Week", date: nextWeek))

        let stats = manager.getEventStatistics()

        XCTAssertEqual(stats["total"], 4, "Should count all events")
        XCTAssertEqual(stats["today"], 2, "Should count today's events")
        XCTAssertEqual(stats["thisWeek"], 1, "Tomorrow is the only upcoming event within 7 days")
    }

    func testStatisticsWithNoEvents() {
        let stats = manager.getEventStatistics()

        XCTAssertEqual(stats["total"], 0)
        XCTAssertEqual(stats["today"], 0)
        XCTAssertEqual(stats["thisWeek"], 0)
    }

    // MARK: - Clear Tests

    func testClearAllEvents() {
        manager.add(CalendarEvent(title: "Event 1", date: Date()))
        manager.add(CalendarEvent(title: "Event 2", date: Date()))
        XCTAssertEqual(manager.load().count, 2)

        manager.clearAllEvents()
        XCTAssertEqual(manager.load().count, 0)
    }

    // MARK: - Edge Cases

    func testHandlesMidnightBoundary() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let justBeforeMidnight = midnight.addingTimeInterval(-1)
        let justAfterMidnight = midnight.addingTimeInterval(1)

        manager.add(CalendarEvent(title: "Before Midnight", date: justBeforeMidnight))
        manager.add(CalendarEvent(title: "At Midnight", date: midnight))
        manager.add(CalendarEvent(title: "After Midnight", date: justAfterMidnight))

        let todayEvents = manager.events(for: Date())
        XCTAssertTrue(todayEvents.contains(where: { $0.title == "At Midnight" }))
        XCTAssertTrue(todayEvents.contains(where: { $0.title == "After Midnight" }))
        XCTAssertFalse(todayEvents.contains(where: { $0.title == "Before Midnight" }))
    }

    func testPersistenceAcrossInstances() {
        let event = CalendarEvent(title: "Persistent", date: Date())
        manager.add(event)

        let newAccess = CalendarDataManager.shared
        let events = newAccess.load()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Persistent")
    }
}
