import SwiftUI
import WinnowCore
import WinnowUI

struct ComposeView: View {
    @Environment(AppState.self) private var appState
    @Environment(WinnowSettings.self) private var settings
    @Binding var isPresented: Bool

    @State private var toLine = ""
    @State private var subject = ""
    @State private var bodyText = NSAttributedString()
    @State private var bodyFocused = false
    @State private var isSending = false
    @State private var isCancelHovered = false
    @State private var isFindingTime = false
    @FocusState private var focused: Field?

    enum Field { case to, subject }

    private var canSend: Bool {
        !toLine.trimmingCharacters(in: .whitespaces).isEmpty && !isSending
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Chrome ─────────────────────────────────────────────────────────
            HStack {
                Button("Cancel") { isPresented = false }
                    .foregroundStyle(Color.winnowTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isCancelHovered ? Color.winnowHover : .clear)
                            .animation(.easeInOut(duration: 0.12), value: isCancelHovered)
                    )
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .onHover { isCancelHovered = $0 }

                Spacer()

                Text("New Message")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)

                Spacer()

                Button {
                    guard canSend else { return }
                    let t = toLine; let s = subject
                    let b = bodyText.string
                    let html = MailBodyRenderer.htmlBody(from: bodyText)
                    isSending = true
                    Task {
                        await appState.sendNew(to: t, subject: s, body: b, html: html)
                        isSending = false
                        isPresented = false
                    }
                } label: {
                    if isSending {
                        ProgressView().scaleEffect(0.7).frame(width: 40)
                    } else {
                        Text("Send")
                    }
                }
                .buttonStyle(WinnowPrimaryButton())
                .disabled(!canSend)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // ── Fields ─────────────────────────────────────────────────────────
            VStack(spacing: 0) {
                fieldRow("To", text: $toLine, field: .to)
                    .onSubmit { focused = .subject }
                Divider().opacity(0.4)

                fieldRow("Subject", text: $subject, field: .subject)
                    .onSubmit { focused = nil; bodyFocused = true }
                Divider().opacity(0.4)

                FormattedTextEditor(
                    text: $bodyText,
                    placeholder: "Write something…",
                    isFocused: $bodyFocused,
                    fontSize: 14
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Divider().opacity(0.4)
                HStack {
                    findATimeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .background(Color.winnowSurface)
        .frame(width: 560, height: 440)
        .onAppear {
            focused = .to
            if let sig = settings.defaultIdentity?.signatureBody, !sig.isEmpty {
                bodyText = .editorText("\n\n\(sig)", fontSize: 14)
            }
        }
    }

    private var findATimeButton: some View {
        Button {
            isFindingTime = true
            let calIDs = settings.calendarCalendarsSeeded ? settings.calendarSelectedIDs : nil
            let hours = settings.workingHours
            Task {
                if let text = await FindATime.suggestionText(calendarIDs: calIDs, workingHours: hours) {
                    bodyText = bodyText.isBlank
                        ? .editorText(text, fontSize: 14)
                        : bodyText.appendingEditorText("\n\n\(text)", fontSize: 14)
                }
                isFindingTime = false
            }
        } label: {
            HStack(spacing: 6) {
                AssistDiamond(size: .small)
                Text(isFindingTime ? "Finding…" : "Find a time")
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(Color.winnowAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.winnowAccent.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isFindingTime)
        .help("Suggest times you're free, from Apple Calendar")
    }

    private func fieldRow(_ label: String, text: Binding<String>, field: Field) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(WinnowTypography.label)
                .foregroundStyle(Color.winnowTextTertiary)
                .frame(width: 56, alignment: .trailing)

            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(WinnowTypography.body)
                .focused($focused, equals: field)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }
}
