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
        if self.isFocusModeEnabled {
            // Enable Do Not Disturb logic (mock)
            print("Focus Mode ON: Notifications silenced")
        } else {
            print("Focus Mode OFF")
        }
    }
}
