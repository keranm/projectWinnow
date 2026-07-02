import SwiftUI

struct MailContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            ThreadListView()
                .frame(minWidth: 316, maxWidth: 356)

            Divider()

            Group {
                if appState.multiSelectedIDs.count > 1 {
                    MultiSelectionView(count: appState.multiSelectedIDs.count)
                } else if let thread = appState.selectedThread {
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

/// Shown in the reading pane while several threads are selected — the bulk actions
/// mirror the row context menu.
private struct MultiSelectionView: View {
    @Environment(AppState.self) private var appState
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            Text("\(count)")
                .font(.system(size: 34, weight: .semibold).monospaced())
                .foregroundStyle(Color.winnowText)

            Text("conversations selected")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.winnowTextTertiary)
                .padding(.top, 4)

            HStack(spacing: 10) {
                Button("Archive All") {
                    appState.archiveAll(appState.multiSelectedIDs)
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.winnowAccent))
                .buttonStyle(.plain)

                Button("Mark as Read") {
                    appState.markReadAll(appState.multiSelectedIDs)
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.winnowTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                )
                .buttonStyle(.plain)
            }
            .padding(.top, 22)

            Text("Esc to deselect")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.winnowTextQuaternary)
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.winnowSurface)
    }
}
