// PlannerApp/Views/Journal/JournalView.swift (Biometrics Removed - v10)
import SwiftUI

// Removed LocalAuthentication import

public struct JournalView: View {
    // Access shared ThemeManager and data/settings
    @EnvironmentObject var themeManager: ThemeManager
    @State private var journalEntries: [JournalEntry] = []
    @State private var showAddEntry = false
    @State private var searchText = ""
    @State private var sentimentFilter: SentimentFilter = .all
    @State private var sortOption: JournalSortOption = .date

    // --- Security State REMOVED ---
    // @AppStorage(AppSettingKeys.journalBiometricsEnabled) private var biometricsEnabled: Bool = false
    // @State private var isUnlocked: Bool = true // Assume always unlocked now
    // @State private var showingAuthenticationError = false
    // @State private var authenticationErrorMsg = ""
    // @State private var isAuthenticating = false

    // Filtered and sorted entries
    private var filteredEntries: [JournalEntry] {
        // Apply text search filter
        let searched = self.searchText.isEmpty
            ? self.journalEntries
            : self.journalEntries.filter {
                $0.title.localizedCaseInsensitiveContains(self.searchText)
                    || $0.body.localizedCaseInsensitiveContains(self.searchText)
                    || $0.mood.contains(self.searchText)
            }

        // Apply sentiment filter
        let sentimentFiltered: [JournalEntry] = switch self.sentimentFilter {
        case .all:
            searched
        case .positive:
            searched.filter { $0.sentiment == "positive" }
        case .neutral:
            searched.filter { $0.sentiment == "neutral" }
        case .negative:
            searched.filter { $0.sentiment == "negative" }
        }

        // Apply sorting
        switch self.sortOption {
        case .date:
            return sentimentFiltered.sorted(by: { $0.date > $1.date })
        case .sentiment:
            return sentimentFiltered.sorted(by: { $0.sentimentScore > $1.sentimentScore })
        }
    }

    // Removed init() related to isUnlocked state

    public var body: some View {
        NavigationStack {
            // Directly show journal content, bypassing lock checks
            VStack(spacing: 0) {
                JournalListView(
                    filteredEntries: self.filteredEntries,
                    searchText: self.searchText,
                    journalEntries: self.journalEntries,
                    onDeleteEntry: self.deleteEntry
                )
                .searchable(text: self.$searchText, prompt: "Search Entries")
            }
            .background(self.themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 12) {
                        // Sentiment Filter Picker
                        Picker("Filter", selection: self.$sentimentFilter) {
                            ForEach(SentimentFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Sentiment Filter")

                        // Sort Option Picker
                        Picker("Sort", selection: self.$sortOption) {
                            ForEach(JournalSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Sort By")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SentimentAnalyticsView(entries: self.journalEntries)
                            .environmentObject(self.themeManager)
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .accessibilityLabel("View Sentiment Analytics")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.showAddEntry.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: self.$showAddEntry) {
                AddJournalEntryView(journalEntries: self.$journalEntries)
                    .environmentObject(self.themeManager) // Pass ThemeManager
                    .onDisappear(perform: self.saveEntries)
            }
            .onAppear {
                print("[JournalView Simplified] onAppear.")
                // Only load entries
                self.loadEntries()
            }
            // Apply theme accent color to toolbar items
            .accentColor(self.themeManager.currentTheme.primaryAccentColor)
            // Removed alert for authentication errors
        } // End NavigationStack
        // Removed .onChange(of: biometricsEnabled)
    }

    // --- View Builder for Locked State (REMOVED) ---

    // --- Authentication Function (REMOVED) ---

    // --- Data Functions ---
    private func deleteEntry(at offsets: IndexSet) {
        print("[JournalView Simplified] deleteEntry called with offsets: \(offsets)")
        let idsToDelete = offsets.map { offset -> UUID in
            return self.filteredEntries[offset].id
        }
        print("[JournalView Simplified] IDs to delete: \(idsToDelete)")
        self.journalEntries.removeAll { entry in
            idsToDelete.contains(entry.id)
        }
        self.saveEntries()
    }

    private func loadEntries() {
        print("[JournalView Simplified] loadEntries called")
        self.journalEntries = JournalDataManager.shared.load()
        print("[JournalView Simplified] Loaded \(self.journalEntries.count) entries.")
    }

    private func saveEntries() {
        print("[JournalView Simplified] saveEntries called")
        JournalDataManager.shared.save(entries: self.journalEntries)
    }
}

// MARK: - Supporting Types

enum SentimentFilter: String, CaseIterable {
    case all = "All"
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
}

enum JournalSortOption: String, CaseIterable {
    case date = "Date"
    case sentiment = "Sentiment"
}

// --- Preview Provider (Unchanged) ---
public struct JournalView_Previews: PreviewProvider {
    public static var previews: some View {
        JournalView()
            .environmentObject(ThemeManager())
    }
}
