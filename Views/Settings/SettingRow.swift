import SwiftUI

public struct SettingRow<Accessory: View>: View {
    public let title: String
    public let subtitle: String?
    public let accessory: (() -> Accessory)?

    public init(title: String, subtitle: String? = nil, @ViewBuilder accessory: (() -> Accessory)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                if let subtitle = self.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let accessory = self.accessory {
                accessory()
            }
        }
    }
}
