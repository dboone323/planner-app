import SwiftUI

/// A view that provides pull-to-refresh functionality for iOS
/// Wraps content in a scroll view with pull-to-refresh capability
public struct PullToRefresh<Content: View>: View {
    let coordinateSpaceName: String
    let onRefresh: () async -> Void
    let content: Content

    @State private var isRefreshing = false

    public init(
        coordinateSpaceName: String,
        @ViewBuilder content: () -> Content,
        onRefresh: @escaping () async -> Void
    ) {
        self.coordinateSpaceName = coordinateSpaceName
        self.content = content()
        self.onRefresh = onRefresh
    }

    public var body: some View {
        ScrollView {
            content
                .anchorPreference(key: OffsetPreferenceKey.self, value: .top) {
                    $0.y
                }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(OffsetPreferenceKey.self) { offset in
            if offset > 50 && !isRefreshing {
                Task {
                    isRefreshing = true
                    await onRefresh()
                    isRefreshing = false
                }
            }
        }
        .overlay(
            Group {
                if isRefreshing {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.8))
                }
            }
        )
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public extension View {
    /// Adds pull-to-refresh functionality to a ScrollView
    func pullToRefresh(
        coordinateSpaceName: String,
        onRefresh: @escaping () async -> Void
    ) -> some View {
        PullToRefresh(coordinateSpaceName: coordinateSpaceName, content: { self }, onRefresh: onRefresh)
    }
}
