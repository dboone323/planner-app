//
// PomodoroTimer.swift
// PlannerApp
//
// Service for Pomodoro technique timer
//

import Combine
import SwiftUI

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
            case .work: 25 * 60
            case .shortBreak: 5 * 60
            case .longBreak: 15 * 60
            }
        }
    }

    private var timer: AnyCancellable?

    func start() {
        self.isActive = true
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                // Notify user
            }
        }
    }

    func stop() {
        self.isActive = false
        self.timer?.cancel()
    }

    func reset() {
        self.stop()
        self.timeRemaining = self.mode.duration
    }

    func setMode(_ newMode: TimerMode) {
        self.mode = newMode
        self.reset()
    }
}
