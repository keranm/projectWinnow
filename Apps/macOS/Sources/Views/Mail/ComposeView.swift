import SwiftUI
import WinnowCore
import WinnowUI

struct ComposeView: View {
    @Environment(AppState.self) private var appState
    @Environment(WinnowSettings.self) private var settings
    @Binding var isPresented: Bool

    @State private var toLine = ""
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var isSending = false
    @State private var isCancelHovered = false
    @FocusState private var focused: Field?

    enum Field { case to, subject, body }

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
                    let t = toLine; let s = subject; let b = bodyText
                    isSending = true
                    Task {
                        await appState.sendNew(to: t, subject: s, body: b)
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
                    .onSubmit { focused = .body }
                Divider().opacity(0.4)

                TextEditor(text: $bodyText)
                    .font(WinnowTypography.body)
                    .focused($focused, equals: .body)
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
        }
        .background(Color.winnowSurface)
        .frame(width: 560, height: 440)
        .onAppear {
            focused = .to
            if let sig = settings.defaultIdentity?.signatureBody, !sig.isEmpty {
                bodyText = "\n\n\(sig)"
            }
        }
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
