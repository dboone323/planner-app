//
//  ConflictResolver.swift
//  PlannerApp
//
//  Pure logic for resolving sync conflicts between local and server records.
//  This file contains no CloudKit I/O operations and is fully unit testable.
//

import CloudKit
import Foundation

/// Represents a sync conflict between local and server data
struct SyncConflictInfo: Identifiable, Equatable {
    let id: UUID
    let recordID: CKRecord.ID
    let localRecord: CKRecord
    let serverRecord: CKRecord
    let conflictType: ConflictType
    let detectedAt: Date

    init(
        id: UUID = UUID(),
        recordID: CKRecord.ID,
        localRecord: CKRecord,
        serverRecord: CKRecord,
        conflictType: ConflictType,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.recordID = recordID
        self.localRecord = localRecord
        self.serverRecord = serverRecord
        self.conflictType = conflictType
        self.detectedAt = detectedAt
    }

    static func == (lhs: SyncConflictInfo, rhs: SyncConflictInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// Strategy for resolving conflicts
enum ConflictResolutionStrategy {
    case useLocal           // Always use local version
    case useServer          // Always use server version
    case useNewest          // Use whichever was modified most recently
    case merge              // Attempt to merge changes
    case manual             // Require user decision
}

/// Pure logic for conflict detection and resolution
struct ConflictResolver {

    // MARK: - Conflict Detection

    /// Detect if there's a conflict between local and server records
    /// - Parameters:
    ///   - localRecord: The local version of the record
    ///   - serverRecord: The server version of the record
    ///   - lastSyncDate: The timestamp of the last successful sync
    /// - Returns: A SyncConflictInfo if conflict exists, nil otherwise
    static func detectConflict(
        localRecord: CKRecord,
        serverRecord: CKRecord,
        lastSyncDate: Date?
    ) -> SyncConflictInfo? {
        // No conflict if records are identical
        guard localRecord.recordChangeTag != serverRecord.recordChangeTag else {
            return nil
        }

        let localModified = localRecord.modificationDate ?? Date.distantPast
        let serverModified = serverRecord.modificationDate ?? Date.distantPast
        let syncDate = lastSyncDate ?? Date.distantPast

        // Both modified after last sync = conflict
        if localModified > syncDate && serverModified > syncDate {
            let conflictType = determineConflictType(local: localRecord, server: serverRecord)
            return SyncConflictInfo(
                recordID: localRecord.recordID,
                localRecord: localRecord,
                serverRecord: serverRecord,
                conflictType: conflictType
            )
        }

        return nil
    }

    /// Determine the type of conflict based on record states
    private static func determineConflictType(local: CKRecord, server: CKRecord) -> ConflictType {
        // Check if either record appears to be a deletion marker
        let localIsDeleted = local["isDeleted"] as? Bool ?? false
        let serverIsDeleted = server["isDeleted"] as? Bool ?? false

        if localIsDeleted || serverIsDeleted {
            return .deleted
        }

        // Check if this is a new creation conflict
        let localCreated = local.creationDate
        let serverCreated = server.creationDate

        if localCreated != serverCreated {
            return .created
        }

        return .modified
    }

    // MARK: - Conflict Resolution

    /// Resolve a conflict using the specified strategy
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - strategy: The resolution strategy to apply
    /// - Returns: The record to save as the resolution, or nil if manual resolution needed
    static func resolve(
        conflict: SyncConflictInfo,
        strategy: ConflictResolutionStrategy
    ) -> CKRecord? {
        switch strategy {
        case .useLocal:
            return conflict.localRecord

        case .useServer:
            return conflict.serverRecord

        case .useNewest:
            return resolveByNewest(conflict: conflict)

        case .merge:
            return attemptMerge(conflict: conflict)

        case .manual:
            return nil // Requires user intervention
        }
    }

    /// Resolve conflict by choosing the newest record
    private static func resolveByNewest(conflict: SyncConflictInfo) -> CKRecord {
        let localDate = conflict.localRecord.modificationDate ?? Date.distantPast
        let serverDate = conflict.serverRecord.modificationDate ?? Date.distantPast

        return localDate > serverDate ? conflict.localRecord : conflict.serverRecord
    }

    /// Attempt to merge two conflicting records
    /// Returns merged record if possible, otherwise the newest
    private static func attemptMerge(conflict: SyncConflictInfo) -> CKRecord {
        // Create a new record based on the server record (preserves system fields)
        let merged = conflict.serverRecord

        // Get the field keys that exist in both records
        let localKeys = Set(conflict.localRecord.allKeys())
        let serverKeys = Set(conflict.serverRecord.allKeys())
        let allKeys = localKeys.union(serverKeys)

        for key in allKeys {
            let localValue = conflict.localRecord[key]
            let serverValue = conflict.serverRecord[key]

            // If only one has a value, use that
            if localValue == nil && serverValue != nil {
                // Server value already in merged
                continue
            } else if localValue != nil && serverValue == nil {
                merged[key] = localValue
            } else if let localVal = localValue, let serverVal = serverValue {
                // Both have values - use the more recent one based on modification date
                let localDate = conflict.localRecord.modificationDate ?? Date.distantPast
                let serverDate = conflict.serverRecord.modificationDate ?? Date.distantPast

                if localDate > serverDate {
                    merged[key] = localVal
                }
                // Otherwise keep server value (already in merged)
            }
        }

        return merged
    }

    // MARK: - Batch Resolution

    /// Apply a resolution strategy to multiple conflicts
    /// - Parameters:
    ///   - conflicts: Array of conflicts to resolve
    ///   - strategy: Strategy to apply to all conflicts
    /// - Returns: Array of resolved records (excludes manual resolution items)
    static func resolveAll(
        conflicts: [SyncConflictInfo],
        strategy: ConflictResolutionStrategy
    ) -> [CKRecord] {
        conflicts.compactMap { conflict in
            resolve(conflict: conflict, strategy: strategy)
        }
    }

    // MARK: - Conflict Analysis

    /// Analyze the differences between conflicting records
    /// - Parameter conflict: The conflict to analyze
    /// - Returns: Dictionary of field names to their local and server values
    static func analyzeConflict(_ conflict: SyncConflictInfo) -> [String: (local: Any?, server: Any?)] {
        var differences: [String: (local: Any?, server: Any?)] = [:]

        let localKeys = Set(conflict.localRecord.allKeys())
        let serverKeys = Set(conflict.serverRecord.allKeys())
        let allKeys = localKeys.union(serverKeys)

        for key in allKeys {
            let localValue = conflict.localRecord[key]
            let serverValue = conflict.serverRecord[key]

            // Check if values are different
            if !valuesAreEqual(localValue, serverValue) {
                differences[key] = (local: localValue, server: serverValue)
            }
        }

        return differences
    }

    /// Compare two CKRecordValue instances for equality
    private static func valuesAreEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        if lhs == nil || rhs == nil { return false }

        // Handle common types
        if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        }
        if let lhsInt = lhs as? Int, let rhsInt = rhs as? Int {
            return lhsInt == rhsInt
        }
        if let lhsDouble = lhs as? Double, let rhsDouble = rhs as? Double {
            return lhsDouble == rhsDouble
        }
        if let lhsBool = lhs as? Bool, let rhsBool = rhs as? Bool {
            return lhsBool == rhsBool
        }
        if let lhsDate = lhs as? Date, let rhsDate = rhs as? Date {
            return lhsDate == rhsDate
        }

        // Default to false for complex types
        return false
    }
}
