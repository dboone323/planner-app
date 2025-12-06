//
// PomodoroTimer.swift
// PlannerApp
//
// Service for Pomodoro technique timer
//

import SwiftUI
import Combine

class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: Int = 25 * 60
    @Published var isActive = false
    @Published var mode: TimerMode = .work

    enum TimerMode {
        case work
        case shortBreak
        case longBreak

        var duration: Int {
            switch self {
            case .work: return 25 * 60
            case .shortBreak: return 5 * 60
            case .longBreak: return 15 * 60
            }
        }
    }

    private var timer: AnyCancellable?

    func start() {
        isActive = true
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                // Notify user
            }
        }
    }

    func stop() {
        isActive = false
        timer?.cancel()
    }

    func reset() {
        stop()
        timeRemaining = mode.duration
    }

    func setMode(_ newMode: TimerMode) {
        mode = newMode
        reset()
    }
}
