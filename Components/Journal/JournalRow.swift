import SwiftUI

public struct JournalRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entry: JournalEntry

    private var rowDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.title)
                    .font(
                        themeManager.currentTheme.font(
                            forName: themeManager.currentTheme.primaryFontName, size: 17,
                            weight: .medium
                        )
                    )
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .lineLimit(1)
                Text(entry.date, formatter: rowDateFormatter)
                    .font(
                        themeManager.currentTheme.font(
                            forName: themeManager.currentTheme.secondaryFontName, size: 14
                        )
                    )
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Text(entry.body)
                    .font(
                        themeManager.currentTheme.font(
                            forName: themeManager.currentTheme.secondaryFontName, size: 13
                        )
                    )
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.8))

                SentimentBadge(sentiment: entry.sentiment, score: entry.sentimentScore)
                    .padding(.top, 4)
                    .lineLimit(1)
            }
            Spacer()
            Text(entry.mood)
                .font(.system(size: 30))
        }
        .padding(.vertical, 5)
    }
}

public struct JournalRow_Previews: PreviewProvider {
    public static var previews: some View {
        JournalRow(entry: JournalEntry(title: "Sample Entry", body: "This is a test entry", date: Date(), mood: "😊"))
            .environmentObject(ThemeManager())
    }
}
