import SwiftUI

struct ThreadListView: View {
    @Environment(AppState.self) private var appState
    @State private var isRefreshHovered = false
    @State private var isLoadMoreHovered = false
    @State private var isSearchHovered = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Color.black.opacity(0.05).frame(height: 1)

            if appState.visibleThreads.isEmpty && !appState.isLoading && !appState.isSearching {
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
                            Color.black.opacity(0.04).frame(height: 1)
                        }

                        if !appState.isSearchActive && appState.hasMoreThreads {
                            loadMoreRow
                        }
                    }
                }
            }
        }
        .background(Color.winnowSurface)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress("j") {
            guard !appState.isSearchActive else { return .ignored }
            appState.advance(); return .handled
        }
        .onKeyPress("k") {
            guard !appState.isSearchActive else { return .ignored }
            appState.retreat(); return .handled
        }
        .onKeyPress("e") {
            guard !appState.isSearchActive else { return .ignored }
            if let id = appState.selectedThreadID { appState.archive(id) }
            return .handled
        }
        .onChange(of: appState.isSearchActive) { _, active in
            if active {
                DispatchQueue.main.async { searchFocused = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Group {
            if appState.isSearchActive {
                searchHeader
            } else {
                normalHeader
            }
        }
    }

    private var normalHeader: some View {
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

            Button {
                appState.activateSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSearchHovered ? Color.winnowHover : .clear)
                            .animation(.easeInOut(duration: 0.12), value: isSearchHovered)
                    )
            }
            .buttonStyle(.plain)
            .help("Search (⌘F)")
            .onHover { isSearchHovered = $0 }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.winnowTextTertiary)

                TextField("Search mail…", text: Binding(
                    get: { appState.searchQuery },
                    set: { appState.search(query: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Color.winnowText)
                .focused($searchFocused)
                .onKeyPress(.escape) {
                    appState.clearSearch()
                    return .handled
                }

                if appState.isSearching {
                    ProgressView()
                        .scaleEffect(0.55)
                        .frame(width: 14, height: 14)
                } else if !appState.searchQuery.isEmpty {
                    Button {
                        appState.search(query: "")
                        searchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.winnowTextQuaternary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Cancel") { appState.clearSearch() }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.winnowAccent)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.winnowHover)
            )

            if !appState.searchQuery.isEmpty && !appState.isSearching {
                Text("\(appState.searchResultCount) result\(appState.searchResultCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.winnowTextQuaternary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
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
