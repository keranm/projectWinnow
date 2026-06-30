import SwiftUI
import WinnowUI

struct AccountsPanel: View {
    @Environment(WinnowSettings.self) private var settings
    @State private var editingIdentity: WinnowSettings.Identity? = nil
    @State private var isAddingIdentity = false

    var body: some View {
        @Bindable var s = settings
        VStack(alignment: .leading, spacing: 0) {
            // ── Title ──────────────────────────────────────────────────────
            Text("Identities & aliases")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            Text("Each address keeps its own outgoing route and signature. Winnow picks the right one automatically.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color(hex: "8A8A90"))
                .lineSpacing(3)
                .padding(.top, 5)

            // ── Auto-route toggle ──────────────────────────────────────────
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reply from the address a message was sent to")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                    Text("Incoming address → matching identity, every time. Override per message in compose.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8A8A90"))
                }
                Spacer()
                WinnowToggle(isOn: $s.autoRouteReplies) { settings.save() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(hex: "F7F9FC"))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(Color.winnowAccent.opacity(0.14), lineWidth: 1)
            )
            .padding(.top, 18)

            // ── Identity table ─────────────────────────────────────────────
            VStack(spacing: 0) {
                // Table header
                HStack {
                    Text("ADDRESS")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("SENDS VIA")
                        .frame(width: 130, alignment: .leading)
                    Text("SIGNATURE")
                        .frame(width: 150, alignment: .leading)
                    Spacer().frame(width: 60)
                }
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color(hex: "A2A2A8"))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.winnowSidebar)

                Divider().opacity(0.6)

                if settings.identities.isEmpty {
                    Text("No identities yet — add one below.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.winnowTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                } else {
                    ForEach(settings.identities) { identity in
                        IdentityRow(
                            identity: identity,
                            onEdit: { editingIdentity = identity },
                            onSetDefault: { settings.setDefault(id: identity.id) }
                        )
                        if identity.id != settings.identities.last?.id {
                            Divider().opacity(0.5)
                        }
                    }
                }
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
            .padding(.top, 18)

            // ── Footer ────────────────────────────────────────────────────
            HStack(spacing: 8) {
                Button {
                    editingIdentity = WinnowSettings.Identity(
                        email: "", displayName: "", label: "Personal",
                        sendsVia: "Gmail SMTP", signatureName: "", signatureBody: ""
                    )
                } label: {
                    Text("＋ Add identity")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.winnowAccent)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    AssistDiamond(size: .small)
                    Text("Routing stays on this Mac · credentials in the macOS Keychain")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.winnowTextTertiary)
                }
            }
            .padding(.top, 13)
        }
        .sheet(item: $editingIdentity) { identity in
            IdentityEditorSheet(identity: identity) { saved in
                settings.upsertIdentity(saved)
                editingIdentity = nil
            } onDismiss: {
                editingIdentity = nil
            }
            .environment(settings)
        }
    }
}

// MARK: - Identity row

private struct IdentityRow: View {
    let identity: WinnowSettings.Identity
    let onEdit: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        HStack {
            // Address + label
            VStack(alignment: .leading, spacing: 1) {
                Text(identity.email)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                    .lineLimit(1)
                Text(identity.label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "A2A2A8"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sends via
            Text(identity.sendsVia)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Color.winnowTextSecondary)
                .frame(width: 130, alignment: .leading)

            // Signature
            Text(identity.signatureName.isEmpty ? "— none —" : "\"\(identity.signatureName)\"")
                .font(.system(size: 12.5))
                .foregroundStyle(identity.signatureName.isEmpty ? Color.winnowTextTertiary : Color(hex: "8A8A90"))
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)

            // Action
            HStack(spacing: 8) {
                if identity.isDefault {
                    Text("Default")
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(Color.winnowSuccess)
                        .frame(width: 60, alignment: .leading)
                } else {
                    Button("Set default", action: onSetDefault)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.winnowTextTertiary)
                        .buttonStyle(.plain)
                        .frame(width: 60, alignment: .leading)
                }
            }

            Button("Edit", action: onEdit)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.winnowAccent)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Identity editor sheet

struct IdentityEditorSheet: View {
    @State var identity: WinnowSettings.Identity
    let onSave: (WinnowSettings.Identity) -> Void
    let onDismiss: () -> Void

    @FocusState private var focused: Field?
    enum Field { case displayName, email, label, sendsVia, sigName, sigBody }

    var body: some View {
        VStack(spacing: 0) {
            // Chrome
            HStack {
                Button("Cancel", action: onDismiss)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.winnowTextTertiary)
                Spacer()
                Text(identity.email.isEmpty ? "New identity" : "Edit identity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                Spacer()
                Button("Save") { onSave(identity) }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowAccent)
                    .disabled(identity.email.isEmpty || identity.displayName.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Identity details
                    editorSection("Identity") {
                        editorField("Email address", value: $identity.email, field: .email)
                        Divider().opacity(0.4)
                        editorField("Display name", value: $identity.displayName, field: .displayName)
                        Divider().opacity(0.4)
                        editorField("Label", value: $identity.label, field: .label, placeholder: "Personal, Work…")
                        Divider().opacity(0.4)
                        editorField("Sends via", value: $identity.sendsVia, field: .sendsVia, placeholder: "Gmail SMTP")
                    }

                    // Signature
                    editorSection("Signature") {
                        editorField("Signature name", value: $identity.signatureName, field: .sigName, placeholder: "e.g. Alex Morgan")
                        Divider().opacity(0.4)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Signature body")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.4)
                                .foregroundStyle(Color(hex: "9AA6BB"))
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)

                            TextEditor(text: $identity.signatureBody)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Color.winnowText)
                                .focused($focused, equals: .sigBody)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }

                    // Privacy note
                    HStack(spacing: 6) {
                        AssistDiamond(size: .small)
                        Text("Signatures are stored locally — they're never uploaded to any server.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.winnowTextTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
        .background(Color.winnowSurface)
        .frame(width: 520, height: 500)
        .onAppear { focused = identity.email.isEmpty ? .email : .sigBody }
    }

    @ViewBuilder
    private func editorSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
    }

    private func editorField(
        _ label: String,
        value: Binding<String>,
        field: Field,
        placeholder: String = ""
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color(hex: "9AA6BB"))
                .textCase(.uppercase)
                .frame(width: 110, alignment: .trailing)

            TextField(placeholder, text: value)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
                .foregroundStyle(Color.winnowText)
                .focused($focused, equals: field)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}
