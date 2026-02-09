import EventKit
import XCTest
@testable import PlannerApp

class MockEventStore: EventStoreProtocol {
    var shouldGrantAccess = true
    var eventsToReturn: [EKEvent] = []

    func requestFullAccessToEvents(completion: @escaping (Bool, Error?) -> Void) {
        completion(self.shouldGrantAccess, nil)
    }

    func predicateForEvents(withStart _: Date, end _: Date, calendars _: [EKCalendar]?) -> NSPredicate {
        NSPredicate(value: true)
    }

    func events(matching _: NSPredicate) -> [EKEvent] {
        self.eventsToReturn
    }
}

class CalendarSyncServiceTests: XCTestCase {
    var service: CalendarSyncService!
    var mockStore: MockEventStore!

    override func setUp() {
        super.setUp()
        self.mockStore = MockEventStore()
        self.service = CalendarSyncService(eventStore: self.mockStore)
    }

    func testRequestAccess_Granted() {
        let expectation = XCTestExpectation(description: "Access granted")
        self.mockStore.shouldGrantAccess = true

        let cancellable = self.service.$isAuthorized.sink { authorized in
            if authorized {
                expectation.fulfill()
            }
        }

        self.service.requestAccess()

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testFetchEvents_Authorized() {
        self.mockStore.shouldGrantAccess = true
        // Set Authorized manually or via requestAccess
        // Since isAuthorized is published, we can cheat for unit test or call request access
        // But requestAccess is async. We can modify service to have internal setter or just trust flow.
        // Or better, since we can't set Published property easily from outside if private, we'll trigger it.

        let expectation = XCTestExpectation(description: "Authorized")
        let cancellable = self.service.$isAuthorized.sink { authorized in
            if authorized {
                expectation.fulfill()
            }
        }
        self.service.requestAccess()
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        // Mock events
        let event = EKEvent(eventStore: EKEventStore()) // Real store needed for init but unused
        event.title = "Test Event"
        self.mockStore.eventsToReturn = [event]

        let events = self.service.fetchEvents(for: Date())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Test Event")
    }

    func testFetchEvents_NotAuthorized() {
        // Default is false
        let events = self.service.fetchEvents(for: Date())
        XCTAssertTrue(events.isEmpty)
    }
}
