import EventKit
import XCTest
@testable import PlannerApp

@MainActor
class MockSyncEventStore: SyncEventStoreProtocol {
    var accessGranted = true
    var savedEvents: [EKEvent] = []
    var removedEvents: [EKEvent] = []
    var storedEvents: [EKEvent] = []
    var mockCalendars: [EKCalendar] = []

    var defaultCalendarForNewEvents: EKCalendar?

    func newEvent() -> EKEvent {
        EKEvent(eventStore: EKEventStore())
    }

    func newCalendar() -> EKCalendar {
        EKCalendar(for: .event, eventStore: EKEventStore())
    }

    func requestAccessToEvents() async -> Bool {
        self.accessGranted
    }

    func requestAccess(to _: EKEntityType, completion: @escaping @Sendable (Bool, Error?) -> Void) {
        completion(self.accessGranted, nil)
    }

    func calendars(for _: EKEntityType) -> [EKCalendar] {
        self.mockCalendars
    }

    func saveCalendar(_ calendar: EKCalendar, commit _: Bool) throws {
        self.mockCalendars.append(calendar)
    }

    func save(_ event: EKEvent, span _: EKSpan) throws {
        self.savedEvents.append(event)
    }

    func remove(_ event: EKEvent, span _: EKSpan) throws {
        self.removedEvents.append(event)
    }

    func event(withIdentifier identifier: String) -> EKEvent? {
        self.storedEvents.first { $0.eventIdentifier == identifier }
    }

    func predicateForEvents(withStart _: Date, end _: Date, calendars _: [EKCalendar]?)
        -> NSPredicate
    {
        NSPredicate(value: true)
    }

    func events(matching _: NSPredicate) -> [EKEvent] {
        self.storedEvents
    }
}

@MainActor
class CalendarSyncManagerTests: XCTestCase {
    var manager: CalendarSyncManager!
    var mockStore: MockSyncEventStore!

    override func setUp() {
        super.setUp()
        self.mockStore = MockSyncEventStore()
        self.manager = CalendarSyncManager(eventStore: self.mockStore)
    }

    func testSetupCalendar_Success() async {
        self.mockStore.accessGranted = true
        let result = await manager.setupCalendar()
        XCTAssertTrue(result)
        XCTAssertEqual(mockStore.mockCalendars.count, 1)
    }

    func testSetupCalendar_Failure() async {
        self.mockStore.accessGranted = false
        let result = await manager.setupCalendar()
        XCTAssertFalse(result)
    }

    func testSyncTaskToCalendar_CreatesEvent() async throws {
        self.mockStore.accessGranted = true
        _ = await manager.setupCalendar()

        var task = PlannerTask(
            title: "Test Task",
            description: "Notes",
            dueDate: Date(),
            estimatedDuration: 3600,
            calendarEventId: nil
        )

        try await manager.syncTaskToCalendar(&task)

        XCTAssertEqual(mockStore.savedEvents.count, 1)
        let savedEvent = try XCTUnwrap(mockStore.savedEvents.first)
        XCTAssertEqual(savedEvent.title, "Test Task")
        XCTAssertEqual(savedEvent.notes, "Notes")
        XCTAssertFalse(savedEvent.isAllDay)
    }
}
