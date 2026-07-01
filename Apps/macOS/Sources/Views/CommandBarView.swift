import SwiftUI
import WinnowCore
import WinnowUI

struct CommandBarView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

    private var allSections: [CmdSection] { buildSections() }

    private var filteredSections: [CmdSection] {
        guard !query.isEmpty else { return allSections }
        return allSections.compactMap { section in
            let items = section.items.filter { $0.label.localizedCaseInsensitiveContains(query) }
            return items.isEmpty ? nil : CmdSection(header: section.header, isIntelligence: section.isIntelligence, items: items)
        }
    }

    private var flatItems: [CmdItem] { filteredSections.flatMap { $0.items } }

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                searchField
                Divider()
                commandList
            }
            .frame(width: 540)
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.20), radius: 32, y: 10)
        }
        .onAppear { searchFocused = true }
        .onKeyPress(.upArrow)   { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(+1); return .handled }
        .onKeyPress(.return)    { execute(); return .handled }
        .onKeyPress(.escape)    { isPresented = false; return .handled }
        .onChange(of: query)    { selectedIndex = 0 }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.winnowTextTertiary)
            TextField("Search commands…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Color.winnowText)
                .focused($searchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Command list

    private var commandList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(filteredSections) { section in
                    sectionHeader(section)
                    ForEach(section.items) { item in
                        commandRow(item)
                    }
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxHeight: 380)
    }

    @ViewBuilder
    private func sectionHeader(_ section: CmdSection) -> some View {
        HStack(spacing: 6) {
            if section.isIntelligence {
                AssistDiamond(size: .small)
            }
            Text(section.header)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(Color.winnowLabelText)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func commandRow(_ item: CmdItem) -> some View {
        let itemIdx = flatItems.firstIndex(where: { $0.id == item.id }) ?? -1
        let isSelected = itemIdx == selectedIndex

        Button {
            item.action()
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.winnowAccent : Color.winnowTextTertiary)
                    .frame(width: 20)

                Text(item.label)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.winnowText)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(item.shortcut, id: \.self) { key in
                        KbdBadge(key: key)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                ZStack(alignment: .leading) {
                    if isSelected {
                        Color.winnowAccentTint
                        Rectangle()
                            .fill(Color.winnowAccent)
                            .frame(width: 2)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Commands

    private func buildSections() -> [CmdSection] {
        let hasThread = appState.selectedThreadID != nil

        var conversation: [CmdItem] = []
        if hasThread {
            conversation = [
                CmdItem(id: "snooze-reply", icon: "clock",      label: "Snooze until they reply", shortcut: ["Z"]) {
                    if let id = appState.selectedThreadID {
                        appState.snooze(threadID: id, condition: .onReply)
                    }
                },
                CmdItem(id: "archive",       icon: "archivebox", label: "Archive",                 shortcut: ["E"]) {
                    if let id = appState.selectedThreadID { appState.archive(id) }
                },
                CmdItem(id: "mark-done",     icon: "checkmark",  label: "Mark done",               shortcut: ["M"]) {
                    if let id = appState.selectedThreadID {
                        appState.markRead(id); appState.archive(id)
                    }
                },
                CmdItem(id: "add-label",     icon: "tag",        label: "Add label",               shortcut: ["L"]) {},
            ]
        }

        let goTo: [CmdItem] = [
            CmdItem(id: "goto-today", icon: "sun.max",  label: "Today", shortcut: ["G", "T"]) {
                appState.selectedNavItem = .today
            },
            CmdItem(id: "goto-inbox", icon: "tray",     label: "Inbox", shortcut: ["G", "I"]) {
                appState.selectedNavItem = .other
            },
        ]

        let intelligence: [CmdItem] = [
            CmdItem(id: "summarize", icon: "text.bubble", label: "Summarize this thread", shortcut: ["S"]) {},
        ]

        var sections: [CmdSection] = []
        if !conversation.isEmpty {
            sections.append(CmdSection(header: "ON THIS CONVERSATION", isIntelligence: false, items: conversation))
        }
        sections.append(CmdSection(header: "GO TO", isIntelligence: false, items: goTo))
        sections.append(CmdSection(header: "ASK WINNOW  ·  ON-DEVICE", isIntelligence: true, items: intelligence))
        return sections
    }

    // MARK: - Keyboard navigation

    private func moveSelection(_ delta: Int) {
        let count = flatItems.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func execute() {
        guard selectedIndex < flatItems.count else { return }
        flatItems[selectedIndex].action()
        isPresented = false
    }
}

// MARK: - Keyboard badge

private struct KbdBadge: View {
    let key: String

    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.winnowTextSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.winnowSidebar)
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.black.opacity(0.14), lineWidth: 1)
                }
            )
            .shadow(color: .black.opacity(0.10), radius: 0, y: 1)
    }
}

// MARK: - Data models

private struct CmdSection: Identifiable {
    let id = UUID()
    let header: String
    let isIntelligence: Bool
    let items: [CmdItem]
}

private struct CmdItem: Identifiable {
    let id: String
    let icon: String
    let label: String
    let shortcut: [String]
    let action: () -> Void
}
