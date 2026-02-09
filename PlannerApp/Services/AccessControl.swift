//
// AccessControl.swift
// PlannerApp
//
// Service for managing permissions and roles
//

import Foundation

enum Role: String, Codable {
    case owner
    case editor
    case viewer
}

struct Permission {
    let canEdit: Bool
    let canDelete: Bool
    let canInvite: Bool
}

class AccessControl {
    static let shared = AccessControl()

    func permissions(for role: Role) -> Permission {
        switch role {
        case .owner:
            Permission(canEdit: true, canDelete: true, canInvite: true)
        case .editor:
            Permission(canEdit: true, canDelete: false, canInvite: false)
        case .viewer:
            Permission(canEdit: false, canDelete: false, canInvite: false)
        }
    }

    func canUser(userId _: UUID, perform action: (Permission) -> Bool, in _: Workspace) -> Bool {
        // In a real app, check user's role in workspace
        // For prototype, assume owner
        let userRole = Role.owner
        return action(self.permissions(for: userRole))
    }
}
