//
// FocusModeManager.swift
// PlannerAppCore
//

import Foundation
import os.log

/// Service for managing focus mode state and session history.
@MainActor
public class FocusModeManager: ObservableObject {
    public static let shared = FocusModeManager()
    
    @Published public var isFocusModeEnabled = false
    @Published public var currentSession: FocusSession?
    
    private var sessionHistory: [FocusSession] = []
    private static let logger = Logger(subsystem: "com.planner-app.core", category: "FocusMode")

    private init() {}

    /// Toggles the overall focus mode state.
    public func toggleFocusMode() {
        self.isFocusModeEnabled.toggle()
        let status = self.isFocusModeEnabled ? "ENABLED" : "DISABLED"
        Self.logger.info("Focus Mode \(status)")
    }
    
    /// Starts a new focus session for a given task.
    public func startFocusSession(duration: TimeInterval, taskId: UUID? = nil) {
        let session = FocusSession(startTime: Date(), duration: duration, taskId: taskId)
        self.currentSession = session
        self.isFocusModeEnabled = true
        Self.logger.info("Starting focus session for task ID: \(taskId?.uuidString ?? "none")")
    }
    
    /// Returns the history of all focus sessions.
    public func getSessionHistory() -> [FocusSession] {
        return self.sessionHistory
    }
    
    /// Ends the current focus session.
    public func endCurrentSession(completed: Bool) {
        guard var session = currentSession else { return }
        session.isCompleted = completed
        self.sessionHistory.append(session)
        self.currentSession = nil
        self.isFocusModeEnabled = false
    }
}
