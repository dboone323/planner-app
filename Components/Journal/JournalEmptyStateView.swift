import SwiftUI

public struct JournalEmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let message: String

    public var body: some View {
        Text(message)
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            .font(
                themeManager.currentTheme.font(
                    forName: themeManager.currentTheme.secondaryFontName, size: 15
                )
            )
            .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical)
    }
}

public struct JournalEmptyStateView_Previews: PreviewProvider {
    public static var previews: some View {
        JournalEmptyStateView(message: "No journal entries yet. Tap '+' to add one.")
            .environmentObject(ThemeManager())
    }
}
