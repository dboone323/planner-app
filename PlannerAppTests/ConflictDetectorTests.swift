import XCTest
@testable import PlannerApp

/// High-fidelity tests for ConflictDetector using the real TimeBlock and PlannerTask models.
@MainActor
class ConflictDetectorTests: XCTestCase {
    var detector: ConflictDetector!

    override func setUp() async throws {
        try await super.setUp()
        self.detector = ConflictDetector()
    }

    func testNoConflicts() {
        let now = Date()
        let block1 = TimeBlock(title: "Block 1", startTime: now, endTime: now.addingTimeInterval(3600), taskId: UUID())
        let block2 = TimeBlock(title: "Block 2", startTime: now.addingTimeInterval(3601), endTime: now.addingTimeInterval(7200), taskId: UUID())

        let conflicts = self.detector.findConflicts(blocks: [block1, block2])
        XCTAssertTrue(conflicts.isEmpty)
    }

    func testSimpleOverlap() {
        let now = Date()
        let block1 = TimeBlock(title: "Block 1", startTime: now, endTime: now.addingTimeInterval(3600), taskId: UUID())
        let block2 = TimeBlock(title: "Block 2", startTime: now.addingTimeInterval(1800), endTime: now.addingTimeInterval(5400), taskId: UUID())

        let conflicts = self.detector.findConflicts(blocks: [block1, block2])
        // We expect at least one conflict to be detected between these two blocks
        XCTAssertFalse(conflicts.isEmpty)
    }

    func testNestedOverlap() {
        let now = Date()
        let block1 = TimeBlock(title: "Outer", startTime: now, endTime: now.addingTimeInterval(7200), taskId: UUID())
        let block2 = TimeBlock(title: "Inner", startTime: now.addingTimeInterval(1800), endTime: now.addingTimeInterval(3600), taskId: UUID())

        let conflicts = self.detector.findConflicts(blocks: [block1, block2])
        XCTAssertFalse(conflicts.isEmpty)
    }

    func testAdjacentBlocks_NoConflict() {
        let now = Date()
        let block1 = TimeBlock(title: "Morning", startTime: now, endTime: now.addingTimeInterval(3600), taskId: UUID())
        let block2 = TimeBlock(title: "Afternoon", startTime: now.addingTimeInterval(3600), endTime: now.addingTimeInterval(7200), taskId: UUID())

        let conflicts = self.detector.findConflicts(blocks: [block1, block2])
        XCTAssertTrue(conflicts.isEmpty, "Adjacent blocks should not conflict.")
    }
}
