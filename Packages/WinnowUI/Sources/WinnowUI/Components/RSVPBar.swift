import SwiftUI

public enum RSVPResponse: String, Sendable {
    case yes, maybe, no

    public var label: String {
        switch self {
        case .yes: "Yes"
        case .maybe: "Maybe"
        case .no: "No"
        }
    }
}

/// The "Going? Yes / Maybe / No" segmented row on a calendar invite.
public struct RSVPBar: View {
    let selected: RSVPResponse?
    let onSelect: (RSVPResponse) -> Void

    public init(selected: RSVPResponse?, onSelect: @escaping (RSVPResponse) -> Void) {
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("GOING?")
                .winnowSectionHeader()

            HStack(spacing: 8) {
                ForEach([RSVPResponse.yes, .maybe, .no], id: \.self) { option in
                    RSVPPill(option: option, isSelected: selected == option) { onSelect(option) }
                }
            }
        }
    }
}

private struct RSVPPill: View {
    let option: RSVPResponse
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Text(option.label)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(RoundedRectangle(cornerRadius: 9).fill(background))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(border, lineWidth: 1))
        .onHover { isHovered = $0 }
    }

    private var isYesSelected: Bool { isSelected && option == .yes }

    private var foreground: Color {
        if isYesSelected { return Color.winnowSuccess }
        if isSelected { return Color.winnowAccent }
        return isHovered ? Color.winnowText : Color.winnowTextSecondary
    }

    private var background: Color {
        if isYesSelected { return Color(hex: "EEF7F1") }
        if isSelected { return Color.winnowAccentTint }
        return isHovered ? Color.winnowHover : .clear
    }

    private var border: Color {
        if isYesSelected { return Color.winnowSuccess.opacity(0.4) }
        if isSelected { return Color.winnowAccent.opacity(0.4) }
        return Color.black.opacity(0.12)
    }
}
