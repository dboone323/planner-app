//
// FocusModeManager.swift
// PlannerApp
//
// Service for managing focus mode state
//

import Foundation

class FocusModeManager: ObservableObject {
    @Published var isFocusModeEnabled = false

    func toggleFocusMode() {
        self.isFocusModeEnabled.toggle()
        let status = self.isFocusModeEnabled ? "ENABLED" : "DISABLED"

        // In a production environment, this would integrate with System Focus APIs
        // or trigger a centralized EventBus notification.
        NSLog("[FocusModeManager] Focus Mode \(status)")
    }
}
