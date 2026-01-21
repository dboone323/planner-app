//
// SyncRefreshView.swift
// PlannerApp
//
// Step 28: Pull-to-refresh for CloudKit sync status.
//

import SwiftUI

/// Pull-to-refresh enabled list with sync status indicator.
struct SyncRefreshableView<Content: View>: View {
    @Binding var isSyncing: Bool
    @Binding var lastSyncDate: Date?
    let onRefresh: () async -> Void
    let content: Content

    init(
        isSyncing: Binding<Bool>,
        lastSyncDate: Binding<Date?>,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _isSyncing = isSyncing
        _lastSyncDate = lastSyncDate
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sync status bar
            SyncStatusBar(isSyncing: isSyncing, lastSyncDate: lastSyncDate)

            // Refreshable content
            content
                .refreshable {
                    await onRefresh()
                }
        }
    }
}

/// Status bar showing sync state.
struct SyncStatusBar: View {
    let isSyncing: Bool
    let lastSyncDate: Date?

    var body: some View {
        HStack(spacing: 8) {
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let date = lastSyncDate {
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
                Text("Last synced \(date, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "icloud")
                    .foregroundColor(.gray)
                Text("Not synced")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

/// Manual sync button.
struct ManualSyncButton: View {
    @Binding var isSyncing: Bool
    let action: () async -> Void

    var body: some View {
        Button(action: {
            Task {
                isSyncing = true
                await action()
                isSyncing = false
            }
        }, label: {
            HStack {
                if isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text("Sync Now")
            }
        })
        .disabled(isSyncing)
    }
}

/// Sync error alert modifier.
struct SyncErrorAlert: ViewModifier {
    @Binding var error: Error?
    @Binding var showError: Bool

    func body(content: Content) -> some View {
        content
            .alert("Sync Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
                Button("Retry") {
                    // Trigger retry
                }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error occurred")
            }
    }
}

extension View {
    func syncErrorAlert(error: Binding<Error?>, showError: Binding<Bool>) -> some View {
        modifier(SyncErrorAlert(error: error, showError: showError))
    }
}

/// Preview
#Preview {
    SyncRefreshableView(
        isSyncing: .constant(false),
        lastSyncDate: .constant(Date().addingTimeInterval(-300)),
        onRefresh: {},
        content: {
            List {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }
        }
    )
}
