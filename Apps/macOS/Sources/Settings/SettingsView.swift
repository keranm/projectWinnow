import SwiftUI
import WinnowUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general        = "General"
    case accounts       = "Accounts"
    case snippets       = "Snippets"
    case rules          = "Rules"
    case calendar       = "Calendar"
    case appearance     = "Appearance"
    case intelligence   = "Intelligence"
    case privacy        = "Privacy & Security"
    case shortcuts      = "Shortcuts"
    case lab            = "Lab"

    var id: String { rawValue }

    var hasAssistDiamond: Bool { self == .intelligence }
}

struct SettingsView: View {
    @Environment(WinnowSettings.self) private var settings
    @State private var selection: SettingsSection = .accounts

    var body: some View {
        HStack(spacing: 0) {
            // ── Sidebar ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 1) {
                ForEach(SettingsSection.allCases) { section in
                    SettingsNavRow(
                        section: section,
                        isSelected: selection == section
                    )
                    .onTapGesture { selection = section }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(width: 202)
            .background(Color.winnowSidebar)

            Divider()

            // ── Content ────────────────────────────────────────────────────
            ScrollView {
                Group {
                    switch selection {
                    case .general:      GeneralPanel()
                    case .accounts:     AccountsPanel()
                    case .snippets:     SnippetsPanel()
                    case .rules:        RulesPanel()
                    case .calendar:     CalendarPanel()
                    case .appearance:   AppearancePanel()
                    case .intelligence: IntelligencePanel()
                    case .privacy:      PrivacyPanel()
                    case .shortcuts:    ShortcutsPanel()
                    case .lab:          LabPanel()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 36)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .background(Color.winnowSurface)
        }
        .frame(width: 820, height: 580)
    }
}

// MARK: - Nav row

private struct SettingsNavRow: View {
    let section: SettingsSection
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            if section.hasAssistDiamond {
                if isSelected {
                    AssistDiamond(size: .small)
                } else {
                    Color.clear.frame(width: 7, height: 7)
                }
            }

            Text(section.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.winnowText : Color.winnowTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.winnowAccentTint : (isHovered ? Color.winnowHover : .clear))
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.winnowAccent)
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Shared settings primitives

struct SettingsSectionHeader: View {
    let title: String
    var diamond: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if diamond { AssistDiamond(size: .small) }
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color(hex: "9AA6BB"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color(hex: "A2A2A8"))
            }
            Spacer()
            WinnowToggle(isOn: $isOn, onChange: onChange)
        }
    }
}

struct WinnowToggle: View {
    @Binding var isOn: Bool
    var onChange: (() -> Void)? = nil
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.winnowAccent : Color(hex: "D8D8DE"))
                .frame(width: 38, height: 22)
                .opacity(isHovered ? 0.82 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isHovered)

            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(isOn ? 0.25 : 0.20), radius: 1, x: 0, y: 1)
                .frame(width: 18, height: 18)
                .padding(2)
        }
        .animation(.spring(duration: 0.2), value: isOn)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
            onChange?()
        }
        .onHover { isHovered = $0 }
    }
}
