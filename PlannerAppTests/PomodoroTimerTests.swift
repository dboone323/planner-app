@testable import PlannerApp
import XCTest

class PomodoroTimerTests: XCTestCase {
    var timer: PomodoroTimer!

    override func setUp() {
        super.setUp()
        timer = PomodoroTimer()
    }

    func testInitialState() {
        XCTAssertEqual(timer.timeRemaining, 25 * 60)
        XCTAssertFalse(timer.isActive)
        XCTAssertEqual(timer.mode, .work)
    }

    func testStart() {
        timer.start()
        XCTAssertTrue(timer.isActive)
    }

    func testStop() {
        timer.start()
        timer.stop()
        XCTAssertFalse(timer.isActive)
    }

    func testReset() {
        timer.timeRemaining = 10
        timer.reset()
        XCTAssertEqual(timer.timeRemaining, 25 * 60)
        XCTAssertFalse(timer.isActive)
    }

    func testSetMode() {
        timer.setMode(.shortBreak)
        XCTAssertEqual(timer.mode, .shortBreak)
        XCTAssertEqual(timer.timeRemaining, 5 * 60)
    }
}
