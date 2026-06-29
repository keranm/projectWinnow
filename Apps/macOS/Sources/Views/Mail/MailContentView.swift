import SwiftUI

struct MailContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            ThreadListView()
                .frame(minWidth: 316, maxWidth: 356)

            Divider()

            Group {
                if let thread = appState.selectedThread {
                    ReadingPaneView(thread: thread)
                } else {
                    EmptySelectionView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.winnowSurface)
    }
}
