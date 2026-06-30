import SwiftUI
import WinnowCore
import WinnowUI

struct ReadingPaneView: View {
    let thread: MailThread
    @Environment(AppState.self) private var appState
    @Environment(WinnowSettings.self) private var settings
    @State private var replyText: String = ""
    @State private var signatureSeeded = false
    @State private var isSendHovered = false
    @FocusState private var replyFocused: Bool

    private var latestMessage: MailMessage? { thread.messages.last }
    private var earlierMessages: [MailMessage] { thread.messages.dropLast().reversed() }

    var body: some View {
        VStack(spacing: 0) {
            threadHeader
            bodyContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            composeFooter
        }
        .background(Color.winnowSurface)
        .task(id: thread.id) {
            replyText = ""
            signatureSeeded = false
            await appState.loadFullThread(thread.id)
            if !thread.isRead {
                try? await Task.sleep(for: .seconds(1.5))
                appState.markRead(thread.id)
            }
        }
    }

    // MARK: - Header

    private var threadHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.subject)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "171719"))
                .tracking(-0.22)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            participantsMeta
        }
        .padding(.horizontal, WinnowSpacing.sectionHWide)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    private var participantsMeta: some View {
        HStack(spacing: 6) {
            let names = participantNames
            Text(names)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.winnowTextTertiary)

            Text("·")
                .foregroundStyle(Color(hex: "D2D2D8"))

            Text("\(thread.messages.count) \(thread.messages.count == 1 ? "message" : "messages")")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.winnowTextQuaternary)
        }
    }

    private var participantNames: String {
        var seen = Set<String>()
        var names: [String] = []
        for msg in thread.messages {
            let key = msg.from.email
            if !seen.contains(key) {
                seen.insert(key)
                names.append(msg.from.displayName)
            }
        }
        return names.joined(separator: ", ")
    }

    // MARK: - Body

    @ViewBuilder
    private var bodyContent: some View {
        if let msg = latestMessage {
            switch msg.body {
            case .html(let html):
                VStack(spacing: 0) {
                    if let summary = thread.summary {
                        AssistSummaryCard(summary: summary)
                            .padding(.horizontal, WinnowSpacing.sectionHWide)
                            .padding(.top, 18)
                            .padding(.bottom, 8)
                    }
                    messageHeader(msg)
                    MessageWebView(html: html)
                }

            case .plain(let text):
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let summary = thread.summary {
                            AssistSummaryCard(summary: summary)
                                .padding(.horizontal, WinnowSpacing.sectionHWide)
                                .padding(.top, 18)
                        }
                        messageHeader(msg)
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "34343A"))
                            .lineSpacing(5)
                            .textSelection(.enabled)
                            .padding(.horizontal, WinnowSpacing.sectionHWide)
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !earlierMessages.isEmpty {
                            collapsedMessages
                        }
                    }
                }

            case nil:
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading…")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.winnowTextTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            Color.winnowSurface
        }
    }

    // MARK: - Message sender header

    private func messageHeader(_ msg: MailMessage) -> some View {
        HStack(alignment: .top, spacing: 13) {
            senderAvatar(msg.from, size: 36)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(msg.from.displayName)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                    Spacer()
                    Text(messageTime(msg.date))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.winnowTextQuaternary)
                }
                .padding(.top, 9)
            }
        }
        .padding(.horizontal, WinnowSpacing.sectionHWide)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private func messageTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let s = date.formatted(date: .omitted, time: .shortened)
            return s.replacingOccurrences(of: " AM", with: " AM")
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - Collapsed earlier messages

    private var collapsedMessages: some View {
        VStack(spacing: 0) {
            Color.black.opacity(0.05).frame(height: 1)
                .padding(.horizontal, WinnowSpacing.sectionHWide)
                .padding(.bottom, 14)

            ForEach(Array(earlierMessages.enumerated()), id: \.element.id) { i, msg in
                HStack(alignment: .center, spacing: 13) {
                    senderAvatar(msg.from, size: 30)

                    HStack(spacing: 0) {
                        Text(msg.from.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.winnowTextSubdued)
                        Text(" — \(msg.snippet ?? "…")")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "A2A2A8"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer()

                    Text(collapsedTime(msg.date))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "C2C2C8"))
                }
                .padding(.horizontal, WinnowSpacing.sectionHWide)
                .padding(.vertical, i == 0 ? 0 : 6)
                .padding(.bottom, i == 0 ? 6 : 0)
            }
        }
    }

    private func collapsedTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let s = date.formatted(date: .omitted, time: .shortened)
            return s.replacingOccurrences(of: " AM", with: "a").replacingOccurrences(of: " PM", with: "p")
        } else if cal.isDateInYesterday(date) { return "Yest" }
        let fmt = DateFormatter(); fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    // MARK: - Avatar

    private func senderAvatar(_ participant: Participant, size: CGFloat) -> some View {
        let palette: [(bg: String, fg: String)] = [
            ("fbe7ea", "c0566c"), ("e8eafb", "5a5fc0"), ("e4f0e8", "4f9168"),
            ("f3ece0", "a07d3a"), ("dbe6f8", "2f6bdb"), ("eef0f4", "6a7184"),
        ]
        let idx = abs(participant.email.hashValue) % palette.count
        let pair = palette[idx]
        let initials = participant.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
            .uppercased()
        return Circle()
            .fill(Color(hex: pair.bg))
            .frame(width: size, height: size)
            .overlay(
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(Color(hex: pair.fg))
            )
    }

    // MARK: - Compose footer

    private var composeFooter: some View {
        VStack(alignment: .leading, spacing: 11) {
            if !thread.suggestedReplies.isEmpty {
                quickReplies
            }
            replyBox
        }
        .padding(.horizontal, WinnowSpacing.sectionHWide)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Color.winnowSurface)
        .overlay(alignment: .top) {
            Color.black.opacity(0.05).frame(height: 1)
        }
    }

    private var quickReplies: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(thread.suggestedReplies, id: \.self) { reply in
                    QuickReplyChip(text: reply) {
                        replyText = reply
                        replyFocused = true
                    }
                }
            }
        }
    }

    private var replyBox: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(replyPlaceholder, text: $replyText, axis: .vertical)
                .onChange(of: replyFocused) { _, focused in
                    guard focused, !signatureSeeded else { return }
                    signatureSeeded = true
                    if let sig = settings.defaultIdentity?.signatureBody, !sig.isEmpty {
                        replyText = "\n\n\(sig)"
                    }
                }
                .font(.system(size: 13.5))
                .foregroundStyle(Color.winnowText)
                .focused($replyFocused)
                .textFieldStyle(.plain)
                .lineLimit(1...8)
                .frame(maxWidth: .infinity)

            Button("Send") {
                let body = replyText
                let tid = thread.id
                replyText = ""
                Task { await appState.sendReply(threadID: tid, body: body) }
            }
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill({
                        let isEmpty = replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        if isEmpty { return Color.winnowAccent.opacity(0.4) }
                        return Color.winnowAccent.opacity(isSendHovered ? 0.88 : 1.0)
                    }())
                    .animation(.easeInOut(duration: 0.12), value: isSendHovered)
            )
            .buttonStyle(.plain)
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
            .onHover { isSendHovered = $0 }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
        )
    }

    private var replyPlaceholder: String {
        if let name = latestMessage?.from.displayName.components(separatedBy: " ").first {
            return "Reply to \(name)…"
        }
        return "Reply…"
    }
}

// MARK: - Quick reply chip

private struct QuickReplyChip: View {
    let text: String
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Color(hex: "5A5A62"))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isHovered ? Color.winnowHover : .clear)
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.black.opacity(isHovered ? 0.14 : 0.10), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Primary button style (used in ComposeView)

struct WinnowPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration)
    }

    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.winnowAccent.opacity(
                            configuration.isPressed ? 0.75 : (isHovered ? 0.88 : 1.0)
                        ))
                        .animation(.easeInOut(duration: 0.12), value: isHovered)
                )
                .onHover { isHovered = $0 }
        }
    }
}
