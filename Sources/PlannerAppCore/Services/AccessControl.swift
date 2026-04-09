//
// AccessControl.swift
// PlannerAppCore
//

import Foundation

/// Service for managing permissions and roles within the application.
@MainActor
public class AccessControl: @unchecked Sendable {
    public static let shared = AccessControl()

    private init() {}

    /// Returns the permission set associated with a specific role.
    public func permissions(for role: Role) -> Permission {
        switch role {
        case .owner:
            return Permission(canEdit: true, canDelete: true, canInvite: true)
        case .editor:
            return Permission(canEdit: true, canDelete: false, canInvite: false)
        case .viewer:
            return Permission(canEdit: false, canDelete: false, canInvite: false)
        }
    }

    /// Validates if a user can perform a specific action within a workspace.
    public func canUser(userId: UUID, perform action: (Permission) -> Bool, in workspace: Workspace) -> Bool {
        // In a real app, check user's role in workspace via database query.
        // Defaulting to owner for prototype validation.
        let userRole = Role.owner
        return action(self.permissions(for: userRole))
    }
}
