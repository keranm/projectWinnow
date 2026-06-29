import SwiftUI
import WinnowCore
import WinnowUI

struct ReadingPaneView: View {
    let thread: MailThread
    @State private var replyText: String = ""
    @FocusState private var replyFocused: Bool

    private var lastMessage: MailMessage? { thread.messages.last }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(thread.subject)
                        .font(WinnowTypography.title)
                        .foregroundStyle(Color.winnowText)

                    participantsMeta
                }
                .padding(.horizontal, WinnowSpacing.sectionH)
                .padding(.top, WinnowSpacing.sectionH)
                .padding(.bottom, 16)

                Divider().padding(.horizontal, WinnowSpacing.sectionH).opacity(0.5)

                // Assist summary
                if let summary = thread.summary {
                    AssistSummaryCard(summary: summary)
                        .padding(.horizontal, WinnowSpacing.sectionH)
                        .padding(.top, 18)
                }

                // Message body
                if let message = lastMessage {
                    messageBody(message)
                }

                Spacer(minLength: 24)

                Divider().opacity(0.5)

                // Compose footer
                composeFooter
            }
        }
        .background(Color.winnowSurface)
    }

    private var participantsMeta: some View {
        HStack(spacing: 6) {
            if let from = lastMessage?.from {
                senderAvatar(from)

                VStack(alignment: .leading, spacing: 2) {
                    Text(from.displayName)
                        .font(WinnowTypography.label)
                        .foregroundStyle(Color.winnowText)

                    if let toList = lastMessage?.to, !toList.isEmpty {
                        Text("to \(toList.map(\.displayName).joined(separator: ", "))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.winnowTextTertiary)
                    }
                }
            }

            Spacer()

            if let date = lastMessage?.date {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(WinnowTypography.meta)
                    .foregroundStyle(Color.winnowTextTertiary)
            }
        }
    }

    private func senderAvatar(_ participant: Participant) -> some View {
        Circle()
            .fill(Color.winnowAccentTint)
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(participant.displayName.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowAccent)
            )
    }

    private func messageBody(_ message: MailMessage) -> some View {
        Group {
            switch message.body {
            case .plain(let text):
                Text(text)
                    .font(WinnowTypography.body)
                    .foregroundStyle(Color.winnowText)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            case .html:
                // HTML rendering — use WebView in a later build
                Text("[HTML message — rendering coming soon]")
                    .font(WinnowTypography.body)
                    .foregroundStyle(Color.winnowTextTertiary)
            case nil:
                Text(message.snippet)
                    .font(WinnowTypography.body)
                    .foregroundStyle(Color.winnowTextSecondary)
            }
        }
        .padding(.horizontal, WinnowSpacing.sectionH)
        .padding(.top, 18)
    }

    private var composeFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Suggested reply chips
            if !thread.suggestedReplies.isEmpty {
                HStack(spacing: 8) {
                    AssistDiamond(size: .small)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(thread.suggestedReplies, id: \.self) { reply in
                                Button(action: { replyText = reply; replyFocused = true }) {
                                    Text(reply)
                                        .font(WinnowTypography.label)
                                        .foregroundStyle(Color.winnowAccent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.winnowAccent.opacity(0.4), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Reply field + send
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Reply…", text: $replyText, axis: .vertical)
                    .font(WinnowTypography.body)
                    .focused($replyFocused)
                    .textFieldStyle(.plain)
                    .lineLimit(3...8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.winnowStage.opacity(0.5))
                    .cornerRadius(WinnowRadius.row)

                Button("Send") {}
                    .buttonStyle(WinnowPrimaryButton())
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, WinnowSpacing.sectionH)
        .padding(.vertical, 16)
    }
}

struct WinnowPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WinnowTypography.label)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: WinnowRadius.row)
                    .fill(Color.winnowAccent.opacity(configuration.isPressed ? 0.8 : 1))
            )
    }
}
