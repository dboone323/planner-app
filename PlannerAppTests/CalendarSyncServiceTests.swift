import EventKit
import XCTest
@testable import PlannerApp

/// High-fidelity tests for CalendarSyncService using the real EventKit framework.
@MainActor
class CalendarSyncServiceTests: XCTestCase {
    var service: CalendarSyncService!
    let eventStore = EKEventStore()

    override func setUp() {
        super.setUp()
        // Use the shared singleton or a fresh instance with the real store
        self.service = CalendarSyncService.shared
    }

    func testRequestAccess() async {
        // Since we can't reliably automate the TCC (Transparency, Consent, and Control) 
        // prompt in CI without specialized tools, we skip if the environment is strictly non-interactive.
        // On a developer machine, this should be run manually.
        
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            print("Skipping testRequestAccess: requires user interaction for TCC prompt.")
            return
        }
        
        // This validates that the service correctly interacts with the real store
        service.requestAccess()
        
        // Short delay to allow published property to update
        try? await PlannerTask.sleep(nanoseconds: 100_000_000)
        
        let expectedAuthorized = status == .authorized || status == .fullAccess
        XCTAssertEqual(service.isAuthorized, expectedAuthorized)
    }

    func testFetchEvents_AuthorizedReality() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        try XCTSkipIf(status != .authorized && status != .fullAccess, "Test requires full access to EventKit which is not granted in this environment.")
        
        // Fetch real events for today
        let events = self.service.fetchEvents(for: Date())
        
        // We don't assert count > 0 because a clean calendar is valid, 
        // but we verify the service doesn't crash and returns a valid array.
        XCTAssertNotNil(events)
    }

    func testFetchEvents_NotAuthorizedReality() throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        try XCTSkipIf(status == .authorized || status == .fullAccess, "Test requires EventKit access to be restricted.")
        
        let events = self.service.fetchEvents(for: Date())
        XCTAssertTrue(events.isEmpty, "Service should return empty array when not authorized.")
    }
}
