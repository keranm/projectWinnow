import SwiftUI
import WinnowUI

struct SnippetsPanel: View {
    @Environment(WinnowSettings.self) private var settings
    @State private var selectedID: UUID? = nil
    @State private var editBuffer: WinnowSettings.Snippet? = nil
    @State private var isNewSnippetHovered = false

    private var selectedSnippet: WinnowSettings.Snippet? {
        guard let id = selectedID else { return nil }
        return settings.snippets.first { $0.id == id }
    }

    var body: some View {
        Text("Snippets")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color(hex: "161618"))
            .padding(.bottom, 14)

        HStack(alignment: .top, spacing: 0) {
            // ── Snippet list ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 1) {
                if settings.snippets.isEmpty {
                    Text("No snippets yet")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.winnowTextTertiary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 12)
                }

                ForEach(settings.snippets) { snippet in
                    SnippetListRow(
                        snippet: snippet,
                        isSelected: selectedID == snippet.id
                    )
                    .onTapGesture {
                        selectedID = snippet.id
                        editBuffer = snippet
                    }
                }

                Divider().opacity(0.4).padding(.top, 4)

                Button {
                    let new = WinnowSettings.Snippet(name: "New snippet", shortcut: ";new", body: "")
                    settings.upsertSnippet(new)
                    selectedID = new.id
                    editBuffer = new
                } label: {
                    Text("＋ New snippet")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.winnowAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(isNewSnippetHovered ? Color.winnowHover : .clear)
                        .animation(.easeInOut(duration: 0.12), value: isNewSnippetHovered)
                }
                .buttonStyle(.plain)
                .onHover { isNewSnippetHovered = $0 }
            }
            .frame(width: 220)
            .background(Color.winnowSidebar)

            Divider()

            // ── Editor ────────────────────────────────────────────────────
            if let snippet = editBuffer {
                SnippetEditor(initial: snippet) { updated in
                    settings.upsertSnippet(updated)
                    editBuffer = updated
                } onDelete: {
                    if let id = selectedID { settings.deleteSnippet(id: id) }
                    selectedID = nil; editBuffer = nil
                }
            } else {
                VStack {
                    Text("Select a snippet to edit")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.winnowTextTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
        .onAppear {
            if selectedID == nil, let first = settings.snippets.first {
                selectedID = first.id
                editBuffer = first
            }
        }
    }
}

// MARK: - List row

private struct SnippetListRow: View {
    let snippet: WinnowSettings.Snippet
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(snippet.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.winnowText : Color.winnowTextSecondary)
                .lineLimit(1)

            Spacer()

            Text(snippet.shortcut)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium).monospaced())
                .foregroundStyle(isSelected ? Color.winnowAccent : Color(hex: "B2B2B8"))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.winnowAccentTint : (isHovered ? Color.winnowHover : .clear))
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
                if isSelected {
                    Rectangle()
                        .fill(Color.winnowAccent)
                        .frame(width: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .padding(.vertical, 4)
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Editor

private struct SnippetEditor: View {
    @State private var snippet: WinnowSettings.Snippet
    let onChange: (WinnowSettings.Snippet) -> Void
    let onDelete: () -> Void

    @FocusState private var focused: Field?

    init(initial: WinnowSettings.Snippet, onChange: @escaping (WinnowSettings.Snippet) -> Void, onDelete: @escaping () -> Void) {
        _snippet = State(initialValue: initial)
        self.onChange = onChange
        self.onDelete = onDelete
    }
    enum Field { case name, shortcut, body }

    @State private var isDeleteHovered = false
    private let placeholders = ["first name", "date", "calendar link"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Name + Shortcut row
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NAME")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color(hex: "A2A2A8"))

                    TextField("Snippet name", text: $snippet.name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "161618"))
                        .focused($focused, equals: .name)
                        .onChange(of: snippet.name) { _, _ in onChange(snippet) }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("SHORTCUT")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color(hex: "A2A2A8"))

                    HStack(spacing: 7) {
                        TextField(";shortcut", text: $snippet.shortcut)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13).monospaced())
                            .foregroundStyle(Color.winnowAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.winnowAccentTint)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .focused($focused, equals: .shortcut)
                            .fixedSize()
                            .onChange(of: snippet.shortcut) { _, _ in onChange(snippet) }

                        Text("type to expand")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.winnowTextTertiary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            // Body header
            HStack(spacing: 8) {
                Text("BODY")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color(hex: "A2A2A8"))

                Spacer()

                Text("Insert:")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.winnowTextTertiary)

                ForEach(placeholders, id: \.self) { ph in
                    PlaceholderChip(label: ph) {
                        snippet.body += " {{\(ph)}}"
                        onChange(snippet)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            // Body editor
            TextEditor(text: $snippet.body)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "34343A"))
                .focused($focused, equals: .body)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.winnowSurface)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 9)
                .onChange(of: snippet.body) { _, _ in onChange(snippet) }

            // Footer
            HStack(spacing: 8) {
                AssistDiamond(size: .small)
                Text("Placeholders fill from the recipient & your calendar as you type — all on this Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.winnowTextTertiary)

                Spacer()

                Button("Delete snippet") { onDelete() }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.winnowAlert)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDeleteHovered ? Color.winnowAlert.opacity(0.08) : .clear)
                            .animation(.easeInOut(duration: 0.12), value: isDeleteHovered)
                    )
                    .buttonStyle(.plain)
                    .onHover { isDeleteHovered = $0 }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Placeholder chip

private struct PlaceholderChip: View {
    let label: String
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 12.5).monospaced())
                .foregroundStyle(Color.winnowAccent)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.winnowAccent.opacity(0.14) : Color.winnowAccentTint)
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
