import XCTest
@testable import PlannerApp

class PomodoroTimerTests: XCTestCase {
    var timer: PomodoroTimer!

    override func setUp() {
        super.setUp()
        self.timer = PomodoroTimer()
    }

    func testInitialState() {
        XCTAssertEqual(self.timer.timeRemaining, 25 * 60)
        XCTAssertFalse(self.timer.isActive)
        XCTAssertEqual(self.timer.mode, .work)
    }

    func testStart() {
        self.timer.start()
        XCTAssertTrue(self.timer.isActive)
    }

    func testStop() {
        self.timer.start()
        self.timer.stop()
        XCTAssertFalse(self.timer.isActive)
    }

    func testReset() {
        self.timer.timeRemaining = 10
        self.timer.reset()
        XCTAssertEqual(self.timer.timeRemaining, 25 * 60)
        XCTAssertFalse(self.timer.isActive)
    }

    func testSetMode() {
        self.timer.setMode(.shortBreak)
        XCTAssertEqual(self.timer.mode, .shortBreak)
        XCTAssertEqual(self.timer.timeRemaining, 5 * 60)
    }
}
