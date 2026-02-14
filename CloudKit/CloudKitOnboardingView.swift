// PlannerApp/CloudKit/CloudKitOnboardingView.swift
import CloudKit
import Foundation
import SwiftUI

public struct CloudKitOnboardingView: View {
    @StateObject private var cloudKit = EnhancedCloudKitManager.shared // Changed to EnhancedCloudKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRequestingPermission = false
    @State private var showingMergeOptions = false

    @AppStorage("hasCompletedCloudKitOnboarding") private var hasCompletedOnboarding = false

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header image
                Image(systemName: "icloud")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.7), .blue], startPoint: .top, endPoint: .bottom
                        )
                    )
                    .padding(.top, 30)

                Text(NSLocalizedString("sync_with_icloud", comment: "iCloud sync title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Benefits explanation
                VStack(alignment: .leading, spacing: 16) {
                    self.benefitRow(
                        icon: "iphone.and.arrow.forward", title: NSLocalizedString("sync_across_devices", comment: "Sync across devices benefit"),
                        description: NSLocalizedString("sync_across_devices_desc", comment: "Sync across devices description")
                    )

                    self.benefitRow(
                        icon: "lock.shield", title: NSLocalizedString("private_secure", comment: "Private and secure benefit"),
                        description: NSLocalizedString("private_secure_desc", comment: "Private and secure description")
                    )

                    self.benefitRow(
                        icon: "arrow.clockwise.icloud", title: NSLocalizedString("automatic_backup", comment: "Automatic backup benefit"),
                        description: NSLocalizedString("automatic_backup_desc", comment: "Automatic backup description")
                    )

                    self.benefitRow(
                        icon: "person.crop.circle", title: NSLocalizedString("just_for_you", comment: "Just for you benefit"),
                        description: NSLocalizedString("just_for_you_desc", comment: "Just for you description")
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        self.requestiCloudAccess()
                    } label: {
                        Text(NSLocalizedString("enable_icloud_sync", comment: "Enable iCloud sync button"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(self.isRequestingPermission)
                    .overlay {
                        if self.isRequestingPermission {
                            ProgressView()
                                .tint(.white)
                        }
                    }

                    Button {
                        self.skipOnboarding()
                    } label: {
                        Text(NSLocalizedString("maybe_later", comment: "Maybe later button"))
                            .padding()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert(NSLocalizedString("new_device_alert", comment: "New device alert title"), isPresented: self.$showingMergeOptions) {
                Button(NSLocalizedString("merge_from_icloud", comment: "Merge from iCloud button"), action: {
                    self.mergeFromiCloud()
                })
                .accessibilityLabel("Button")

                Button(NSLocalizedString("start_fresh", comment: "Start fresh button"), action: {
                    self.startFresh()
                })
                .accessibilityLabel("Button")
            } message: {
                Text(NSLocalizedString("icloud_merge_prompt", comment: "iCloud merge prompt"))
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func requestiCloudAccess() {
        self.isRequestingPermission = true

        _Concurrency.Task {
            await self.cloudKit.requestiCloudAccess()
            await self.cloudKit.checkAccountStatus()

            DispatchQueue.main.async {
                self.isRequestingPermission = false

                if self.cloudKit.isSignedInToiCloud {
                    self.showingMergeOptions = true
                }
            }
        }
    }

    private func mergeFromiCloud() {
        _Concurrency.Task {
            await self.cloudKit.handleNewDeviceLogin()
            self.completeOnboarding()
        }
    }

    private func startFresh() {
        UserDefaults.standard.set(true, forKey: "HasCompletedInitialSync")
        self.completeOnboarding()
    }

    private func skipOnboarding() {
        self.completeOnboarding()
    }

    private func completeOnboarding() {
        self.hasCompletedOnboarding = true
        self.dismiss()
    }
}

#Preview {
    CloudKitOnboardingView()
}
