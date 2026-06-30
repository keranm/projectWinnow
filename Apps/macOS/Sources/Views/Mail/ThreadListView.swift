import SwiftUI

struct ThreadListView: View {
    @Environment(AppState.self) private var appState
    @State private var isRefreshHovered = false
    @State private var isLoadMoreHovered = false

    var body: some View {
        VStack(spacing: 0) {
            header

            // Very subtle 1px separator matching design rgba(0,0,0,.05)
            Color.black.opacity(0.05).frame(height: 1)

            if appState.visibleThreads.isEmpty && !appState.isLoading {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.visibleThreads) { thread in
                            ThreadRowView(
                                thread: thread,
                                isSelected: thread.id == appState.selectedThreadID
                            )
                            .onTapGesture {
                                appState.selectThread(thread.id)
                                appState.markRead(thread.id)
                            }
                            // Hairline divider rgba(0,0,0,.04)
                            Color.black.opacity(0.04).frame(height: 1)
                        }

                        if appState.hasMoreThreads {
                            loadMoreRow
                        }
                    }
                }
            }
        }
        .background(Color.winnowSurface)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress("j") { appState.advance(); return .handled }
        .onKeyPress("k") { appState.retreat(); return .handled }
        .onKeyPress("e") {
            if let id = appState.selectedThreadID { appState.archive(id) }
            return .handled
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(appState.selectedNavItem.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.winnowText)

            Spacer()

            Text(headerDateLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.winnowTextQuaternary)

            Button {
                Task { await appState.syncInbox() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .rotationEffect(appState.isLoading ? .degrees(360) : .zero)
                    .animation(
                        appState.isLoading
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: appState.isLoading
                    )
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isRefreshHovered ? Color.winnowHover : .clear)
                            .animation(.easeInOut(duration: 0.12), value: isRefreshHovered)
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh (⌘R)")
            .padding(.leading, 2)
            .onHover { isRefreshHovered = $0 }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var headerDateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(Date()) {
            return "Today"
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        return fmt.string(from: Date())
    }

    // MARK: - Load more

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
            .background(
                isLoadMoreHovered ? Color.winnowHover : .clear
            )
            .animation(.easeInOut(duration: 0.12), value: isLoadMoreHovered)
        }
        .buttonStyle(.plain)
        .disabled(appState.isLoadingMore)
        .onHover { isLoadMoreHovered = $0 }
    }

    // MARK: - Empty state

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
