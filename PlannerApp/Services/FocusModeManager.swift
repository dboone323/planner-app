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
        isFocusModeEnabled.toggle()
        if isFocusModeEnabled {
            // Enable Do Not Disturb logic (mock)
            print("Focus Mode ON: Notifications silenced")
        } else {
            print("Focus Mode OFF")
        }
    }
}
