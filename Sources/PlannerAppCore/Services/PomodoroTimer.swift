//
// PomodoroTimer.swift
// PlannerAppCore
//

import Combine
import Foundation

/// Service for managing Pomodoro work/break sessions.
@MainActor
public class PomodoroTimer: ObservableObject {
    public static let shared = PomodoroTimer()

    @Published public var timeRemaining: Int = 25 * 60
    @Published public var isActive = false
    @Published public var mode: TimerMode = .work

    public enum TimerMode: String, Codable, Sendable {
        case work
        case shortBreak
        case longBreak

        public var duration: Int {
            switch self {
            case .work: 25 * 60
            case .shortBreak: 5 * 60
            case .longBreak: 15 * 60
            }
        }
    }

    private var timer: AnyCancellable?

    private init() {}

    /// Starts the Pomodoro timer.
    public func start() {
        self.isActive = true
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
            }
        }
    }
    
    /// Alias for performance tests and real usage
    public func startTimer() {
        start()
    }
    
    /// Pauses the current timer session.
    public func pauseTimer() {
        self.stop()
    }

    /// Stops the current timer session.
    public func stop() {
        self.isActive = false
        self.timer?.cancel()
    }

    /// Resets the current timer to its mode's duration.
    public func reset() {
        self.stop()
        self.timeRemaining = self.mode.duration
    }
    
    /// Alias for performance tests and real usage
    public func resetTimer() {
        reset()
    }

    /// Updates the timer mode (e.g., from work to break).
    public func setMode(_ newMode: TimerMode) {
        self.mode = newMode
        self.reset()
    }
    
    /// Returns the active session state for analytical purposes.
    public func getCurrentSession() -> [String: Any] {
        return [
            "mode": mode.rawValue,
            "isActive": isActive,
            "timeRemaining": timeRemaining
        ]
    }
}
