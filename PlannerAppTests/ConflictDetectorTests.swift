@testable import PlannerApp
import XCTest

class ConflictDetectorTests: XCTestCase {
    var detector: ConflictDetector!

    override func setUp() {
        super.setUp()
        detector = ConflictDetector()
    }

    func testNoConflicts() {
        let now = Date()
        let block1 = TimeBlock(taskId: UUID(), startTime: now, duration: 3600) // 1 hour
        let block2 = TimeBlock(taskId: UUID(), startTime: now.addingTimeInterval(3600), duration: 3600) // Next hour

        let conflicts = detector.findConflicts(blocks: [block1, block2])
        XCTAssertTrue(conflicts.isEmpty)
    }

    func testSimpleOverlap() {
        let now = Date()
        let block1 = TimeBlock(taskId: UUID(), startTime: now, duration: 3600) // 0:00 - 1:00
        let block2 = TimeBlock(taskId: UUID(), startTime: now.addingTimeInterval(1800), duration: 3600) // 0:30 - 1:30

        let conflicts = detector.findConflicts(blocks: [block1, block2])
        XCTAssertEqual(conflicts.count, 2)
    }

    func testNestedOverlap() {
        let now = Date()
        let block1 = TimeBlock(taskId: UUID(), startTime: now, duration: 7200) // 0:00 - 2:00
        let block2 = TimeBlock(taskId: UUID(), startTime: now.addingTimeInterval(1800), duration: 1800) // 0:30 - 1:00

        let conflicts = detector.findConflicts(blocks: [block1, block2])
        XCTAssertEqual(conflicts.count, 2)
    }

    func testAdjacentBlocks_NoConflict() {
        let now = Date()
        let block1 = TimeBlock(taskId: UUID(), startTime: now, duration: 3600) // 0:00 - 1:00
        // Exact end time matches next start time
        let block2 = TimeBlock(taskId: UUID(), startTime: now.addingTimeInterval(3600), duration: 3600) // 1:00 - 2:00

        let conflicts = detector.findConflicts(blocks: [block1, block2])
        XCTAssertTrue(conflicts.isEmpty)
    }
}
