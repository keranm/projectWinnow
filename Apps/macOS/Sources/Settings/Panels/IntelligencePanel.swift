import SwiftUI
import WinnowCore
import WinnowUI

struct IntelligencePanel: View {
    @Environment(WinnowSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings

        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("Intelligence")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "161618"))
                .tracking(-0.2)

            Text("Winnow's assistance runs on this Mac by default. Generation tasks — summaries and replies — use a language model; everything else is local code.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "8A8A90"))
                .lineSpacing(3)
                .frame(maxWidth: 560, alignment: .leading)
                .padding(.top, 5)

            // ── Engine ─────────────────────────────────────────────────────
            SettingsSectionHeader(title: "Engine").padding(.top, 26)
            VStack(spacing: 10) {
                EngineCard(engine: .foundation, selected: s.engine == .foundation) {
                    s.engine = .foundation; settings.save()
                }
                EngineCard(engine: .mlx, selected: s.engine == .mlx) {
                    s.engine = .mlx; settings.save()
                }
                CloudEngineCard(isSelected: s.engine == .cloud, isEnabled: $s.cloudAPIEnabled, apiKey: $s.cloudAPIKey) {
                    s.engine = s.cloudAPIEnabled ? .cloud : .foundation; settings.save()
                }
            }
            .padding(.top, 11)

            if !GenerationEngine.isAvailable {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "C08A4A"))
                        .padding(.top, 1)
                    Text("The on-device model isn't available right now — enable Apple Intelligence in System Settings (requires macOS 26). Until then, summaries fall back to on-device extraction and reply suggestions are off.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "7A6A52"))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: 560, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(hex: "FDF6EE"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(Color(hex: "C08A4A").opacity(0.22), lineWidth: 1)
                        )
                )
                .padding(.top, 10)
            }

            // ── Assistance level ───────────────────────────────────────────
            SettingsSectionHeader(title: "Assistance level").padding(.top, 26)
            HStack(spacing: 14) {
                AssistanceLevelPicker(selection: $s.assistanceLevel) { settings.save() }
                Text(s.assistanceLevel.description)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 11)

            // ── What runs locally ──────────────────────────────────────────
            SettingsSectionHeader(title: "What runs locally", diamond: true).padding(.top, 26)
            localTogglesGrid.padding(.top, 11)

            // ── Privacy ledger ─────────────────────────────────────────────
            SettingsSectionHeader(title: "Privacy ledger").padding(.top, 26)
            PrivacyLedger().padding(.top, 11)
            Text("This week · resets Monday")
                .font(.system(size: 11.5))
                .foregroundStyle(Color(hex: "B2B2B8"))
                .padding(.top, 9)
        }
    }

    // MARK: - Local toggles grid

    private var localTogglesGrid: some View {
        @Bindable var s = settings
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 22), GridItem(.flexible())], spacing: 10) {
            SettingsToggleRow(title: "Packages & deliveries", subtitle: "Code · no model", isOn: $s.extractPackages) { settings.save() }
            SettingsToggleRow(title: "Flights & trips",       subtitle: "Code · no model", isOn: $s.extractFlights)  { settings.save() }
            SettingsToggleRow(title: "Hotels & reservations", subtitle: "Code · no model", isOn: $s.extractHotels)   { settings.save() }
            SettingsToggleRow(title: "Price quotes",          subtitle: "On-device embeddings", isOn: $s.extractQuotes) { settings.save() }
            SettingsToggleRow(title: "Subscriptions",         subtitle: "Code · no model", isOn: $s.extractSubscriptions) { settings.save() }
            SettingsToggleRow(title: "Triage & needs-reply",  subtitle: "On-device classifier", isOn: $s.extractNeedsReply) { settings.save() }
        }
    }
}

// MARK: - Engine card

private struct EngineCard: View {
    let engine: WinnowSettings.Engine
    let selected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false
    @State private var isDownloadHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Radio circle
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Color.winnowAccent : Color(hex: "C2C2C8"),
                                      lineWidth: selected ? 5 : 1.5)
                        .frame(width: 18, height: 18)
                    if selected {
                        Circle().fill(Color.white).frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.winnowText)
                    Text(subtitleText)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "8A8A90"))
                        .lineSpacing(2)
                }

                Spacer()

                if selected {
                    Text("ACTIVE")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(Color.winnowSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "E8F4EE"))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else if engine == .mlx {
                    Button("Download · 4.2 GB") {}
                        .buttonStyle(.plain)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.winnowAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(isDownloadHovered ? Color.winnowAccentTint : .clear)
                                .animation(.easeInOut(duration: 0.12), value: isDownloadHovered)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(Color.winnowAccent.opacity(0.28), lineWidth: 1)
                        )
                        .onHover { isDownloadHovered = $0 }
                }
            }

            if selected && engine == .foundation {
                // Detail footer
                HStack(spacing: 28) {
                    statCell(label: "Model",   value: "Foundation · 3B")
                    statCell(label: "Source",  value: "Built into macOS 26")
                    statCell(label: "Storage", value: "0 MB · ships with OS")
                }
                .padding(.leading, 30)
                .padding(.top, 13)
                .padding(.bottom, 2)
                .overlay(alignment: .top) {
                    Divider().offset(y: 12).padding(.leading, 30).opacity(0.6)
                }
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .background(selected ? Color(hex: "FBFCFE") : Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    selected ? Color.winnowAccent : Color.black.opacity(0.10),
                    lineWidth: selected ? 1.5 : 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(!selected && isHovered ? Color.winnowHover : .clear)
                .animation(.easeInOut(duration: 0.12), value: isHovered)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }

    private var subtitleText: String {
        switch engine {
        case .foundation:
            return "Runs on this Mac and your iPhone. Free, private, always available. Best for summaries and short replies."
        case .mlx:
            return "A larger local model for sharper drafts. Runs on Apple silicon when your Mac is plugged in."
        case .cloud:
            return ""
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color(hex: "A2A2A8"))
            Text(value)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Color(hex: "34343A"))
        }
    }
}

// MARK: - Cloud engine card

private struct CloudEngineCard: View {
    let isSelected: Bool
    @Binding var isEnabled: Bool
    @Binding var apiKey: String
    let onToggle: () -> Void
    @State private var isPasteHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.winnowAccent : Color(hex: "C2C2C8"),
                                      lineWidth: isSelected ? 5 : 1.5)
                        .frame(width: 18, height: 18)
                    if isSelected { Circle().fill(Color.white).frame(width: 8, height: 8) }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Connect your own API key")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.winnowText)

                        Text("LEAVES DEVICE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.4)
                            .foregroundStyle(Color.winnowCaution)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(hex: "F7EFE2"))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }

                    Text("Use a frontier cloud model for drafting. Only the text you ask Winnow to draft is sent — and only when you trigger it.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "8A8A90"))
                        .lineSpacing(2)
                }

                Spacer()
                WinnowToggle(isOn: $isEnabled, onChange: onToggle)
            }

            // API key field
            HStack(spacing: 10) {
                Text(isEnabled ? apiKey : "sk-········································")
                    .font(.system(size: 12.5).monospaced())
                    .foregroundStyle(isEnabled ? Color.winnowText : Color(hex: "A2A2A8"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isEnabled {
                    Button("Paste") {
                        if let s = NSPasteboard.general.string(forType: .string) { apiKey = s }
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Color.winnowAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isPasteHovered ? Color.winnowAccentTint : .clear)
                            .animation(.easeInOut(duration: 0.12), value: isPasteHovered)
                    )
                    .buttonStyle(.plain)
                    .onHover { isPasteHovered = $0 }
                } else {
                    Text("disabled")
                        .font(.system(size: 11).monospaced())
                        .foregroundStyle(Color(hex: "B2B2B8"))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(Color(hex: "F6F6F7"))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.6)
            .padding(.leading, 30)
            .padding(.top, 12)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .background(Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Assistance level picker

private struct AssistanceLevelPicker: View {
    @Binding var selection: WinnowSettings.AssistanceLevel
    let onChange: () -> Void
    @State private var hoveredLevel: WinnowSettings.AssistanceLevel? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WinnowSettings.AssistanceLevel.allCases, id: \.self) { level in
                let isSelected = selection == level
                let isHovered = hoveredLevel == level && !isSelected
                Text(level.label)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.winnowText : Color(hex: "6A6A70"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                            } else if isHovered {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.winnowHover)
                            }
                        }
                    )
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
                    .contentShape(Rectangle())
                    .onTapGesture { selection = level; onChange() }
                    .onHover { hoveredLevel = $0 ? level : nil }
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .animation(.easeInOut(duration: 0.15), value: selection)
    }
}

// MARK: - Privacy ledger

private struct PrivacyLedger: View {
    private let stats: [(value: String, label: String)] = [
        ("0 B", "sent off device"),
        ("0", "trackers blocked"),
        ("0", "newsletters filed"),
        ("0", "summaries made"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                if i > 0 { Divider() }
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.value)
                        .font(.system(size: 22, weight: .semibold).monospaced())
                        .foregroundStyle(Color(hex: "161618"))
                    Text(stat.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "8A8A90"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.winnowSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
    }
}
