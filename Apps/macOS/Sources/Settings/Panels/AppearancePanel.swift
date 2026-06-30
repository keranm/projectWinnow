import SwiftUI
import WinnowUI

struct AppearancePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Appearance")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            stubBanner("Appearance settings coming soon — colour scheme, font size, and accent customisation.")
        }
    }
}

struct PrivacyPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Privacy & Security")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            stubBanner("Winnow keeps everything on this device. OAuth tokens live in the macOS Keychain. No Winnow servers are ever in the path.")
        }
    }
}

struct ShortcutsPanel: View {
    private let shortcuts: [(String, String)] = [
        ("j / k",    "Next / previous thread"),
        ("e",        "Archive"),
        ("m",        "Mark as read"),
        ("⌘N",       "Compose new message"),
        ("⌘R",       "Refresh inbox"),
        ("⌘↩",       "Send reply"),
        ("⌘1",       "Go to Today"),
        ("⌘2",       "Go to Inbox"),
        ("⌘3",       "Go to Trips & deliveries"),
        ("⌘4",       "Go to Subscriptions"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Shortcuts")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            VStack(spacing: 0) {
                ForEach(Array(shortcuts.enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().opacity(0.4) }
                    HStack {
                        Text(row.0)
                            .font(.system(size: 13, weight: .semibold).monospaced())
                            .foregroundStyle(Color.winnowAccent)
                            .frame(width: 80, alignment: .leading)
                        Text(row.1)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.winnowText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.07), lineWidth: 1))
            .padding(.top, 20)
        }
    }
}

struct LabPanel: View {
    @State private var mlxEnabled = false
    @State private var projectsEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lab")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            Text("Experimental features. They work, but the details may change.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "8A8A90"))
                .lineSpacing(3)
                .padding(.top, 5)

            VStack(spacing: 0) {
                labRow("Projects view", subtitle: "Groups related threads into project cards on Today", isOn: $projectsEnabled)
                Divider().opacity(0.4)
                labRow("MLX drafting", subtitle: "Use the larger MLX model when plugged in (requires download)", isOn: $mlxEnabled)
            }
            .background(Color.winnowSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.07), lineWidth: 1))
            .padding(.top, 20)
        }
    }

    private func labRow(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.winnowText)
                Text(subtitle).font(.system(size: 11.5)).foregroundStyle(Color(hex: "A2A2A8"))
            }
            Spacer()
            WinnowToggle(isOn: isOn)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private func stubBanner(_ text: String) -> some View {
    HStack(spacing: 10) {
        AssistDiamond(size: .small)
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.winnowTextSecondary)
            .lineSpacing(3)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "F7F9FC"))
    .clipShape(RoundedRectangle(cornerRadius: 11))
    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Color.winnowAccent.opacity(0.10), lineWidth: 1))
    .padding(.top, 20)
}
