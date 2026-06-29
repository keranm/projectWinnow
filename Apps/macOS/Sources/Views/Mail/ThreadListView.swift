import SwiftUI

struct ThreadListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if appState.visibleThreads.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.visibleThreads) { thread in
                            ThreadRowView(thread: thread,
                                          isSelected: thread.id == appState.selectedThreadID)
                            .onTapGesture {
                                appState.selectThread(thread.id)
                                appState.markRead(thread.id)
                            }
                            Divider().padding(.leading, 36).opacity(0.5)
                        }
                    }
                }
            }
        }
        .background(Color.winnowSurface)
        .focusable()
        .onKeyPress("j") { appState.advance(); return .handled }
        .onKeyPress("k") { appState.retreat(); return .handled }
        .onKeyPress("e") {
            if let id = appState.selectedThreadID { appState.archive(id) }
            return .handled
        }
    }

    private var header: some View {
        HStack {
            Text(appState.selectedNavItem.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.winnowText)
            Spacer()
            if appState.visibleThreads.contains(where: { !$0.isRead }) {
                Text("\(appState.visibleThreads.filter { !$0.isRead }.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.winnowAccent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.winnowTextTertiary)
            Text("All clear")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.winnowTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
