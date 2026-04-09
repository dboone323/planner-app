import EventKit
import XCTest
import PlannerAgentCore
@testable import PlannerApp

@MainActor
class CalendarSyncManagerTests: XCTestCase {
    var manager: CalendarSyncManager!
    var realStore: EKEventStore!
    var testDefaults: UserDefaults!
    var defaultsSuiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        
        // In reality, we use EKEventStore directly. 
        // Note: EKEventStore on simulator is isolated. 
        // On real hardware, this would require permissions.
        self.realStore = EKEventStore()
        
        self.defaultsSuiteName = "CalendarSyncManagerTests.\(UUID().uuidString)"
        self.testDefaults = try XCTUnwrap(UserDefaults(suiteName: self.defaultsSuiteName))
        self.testDefaults.removePersistentDomain(forName: self.defaultsSuiteName)
        
        self.manager = CalendarSyncManager(eventStore: self.realStore, userDefaults: self.testDefaults)
    }

    override func tearDown() {
        self.testDefaults?.removePersistentDomain(forName: self.defaultsSuiteName)
        self.manager = nil
        self.realStore = nil
        self.testDefaults = nil
        self.defaultsSuiteName = nil
        super.tearDown()
    }

    func testSetupCalendar_Success() async throws {
        // Reality check: we expect to be able to request access or already have it on simulator
        let access = await realStore.requestAccessToEvents()
        
        // If we can't get access in this environment, skip the test rather than mocking it.
        try XCTSkipIf(!access, "Calendar access not available in this environment")
        
        let result = await manager.setupCalendar()
        XCTAssertTrue(result)
    }

    func testSyncTaskToCalendar_CreatesEvent() async throws {
        let access = await realStore.requestAccessToEvents()
        try XCTSkipIf(!access, "Calendar access not available in this environment")
        
        _ = await manager.setupCalendar()

        let task = PlannerTask(
            title: "Test Task",
            taskDescription: "Notes",
            dueDate: Date(),
            estimatedDuration: 3600,
            calendarEventId: nil
        )

        try await manager.syncTaskToCalendar(task)

        XCTAssertNotNil(task.calendarEventId)
        
        // Verify against real store
        let savedEvent = try XCTUnwrap(realStore.event(withIdentifier: task.calendarEventId!))
        XCTAssertEqual(savedEvent.title, "Test Task")
        // EKEvent notes maps to PlannerTask taskDescription
        XCTAssertEqual(savedEvent.notes, "Notes")
        XCTAssertFalse(savedEvent.isAllDay)
        
        // Cleanup
        try realStore.remove(savedEvent, span: .thisEvent)
    }
}
