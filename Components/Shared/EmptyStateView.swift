import SwiftUI

public struct EmptyStateView: View {
    public let imageSystemName: String
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?

    @EnvironmentObject var themeManager: ThemeManager

    public init(imageSystemName: String, title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: self.imageSystemName)
                .font(.system(size: 40))
                .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)

            Text(self.title)
                .font(.subheadline)
                .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
            }
        }
    }
}

// Preview
#Preview {
    EmptyStateView(imageSystemName: "calendar", title: "No items for this date", subtitle: "Tap + to add an event")
        .environmentObject(ThemeManager())
}
