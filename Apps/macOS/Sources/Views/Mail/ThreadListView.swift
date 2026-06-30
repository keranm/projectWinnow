import SwiftUI

struct ThreadListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if appState.visibleThreads.isEmpty && !appState.isLoading {
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

                        // Load more footer
                        if appState.hasMoreThreads {
                            loadMoreRow
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

            let unread = appState.visibleThreads.filter { !$0.isRead }.count
            if unread > 0 {
                Text("\(unread)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.winnowAccent)
            }

            Button {
                Task { await appState.syncInbox() }
            } label: {
                Image(systemName: appState.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .rotationEffect(appState.isLoading ? .degrees(360) : .zero)
                    .animation(appState.isLoading
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default, value: appState.isLoading)
            }
            .buttonStyle(.plain)
            .help("Refresh (⌘R)")
            .padding(.leading, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var loadMoreRow: some View {
        Button {
            Task { await appState.loadMore() }
        } label: {
            HStack(spacing: 8) {
                if appState.isLoadingMore {
                    ProgressView().scaleEffect(0.65)
                }
                Text(appState.isLoadingMore ? "Loading…" : "Load more")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.winnowTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .disabled(appState.isLoadingMore)
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
