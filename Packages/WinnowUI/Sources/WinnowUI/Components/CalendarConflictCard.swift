import SwiftUI

/// On-device conflict warning shown on a calendar invite — "This overlaps your X" — with an
/// optional one-tap "propose the free slot instead" action alongside "keep as is".
public struct CalendarConflictCard: View {
    let conflictSummary: String
    let suggestedTimeLabel: String?
    let onPropose: (() -> Void)?
    let onKeep: () -> Void

    public init(
        conflictSummary: String,
        suggestedTimeLabel: String?,
        onPropose: (() -> Void)?,
        onKeep: @escaping () -> Void
    ) {
        self.conflictSummary = conflictSummary
        self.suggestedTimeLabel = suggestedTimeLabel
        self.onPropose = onPropose
        self.onKeep = onKeep
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Color.winnowCaution)
                .frame(width: 8, height: 8)
                .rotationEffect(.degrees(45))
                .cornerRadius(1.5)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(conflictSummary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)

                if let suggestedTimeLabel {
                    Text("You and the organizer are both free at \(suggestedTimeLabel). Reply with a new time?")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color(hex: "7A6A52"))
                        .lineSpacing(3)
                }

                HStack(spacing: 8) {
                    if let onPropose, let suggestedTimeLabel {
                        Button("Propose \(suggestedTimeLabel)", action: onPropose)
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.winnowAccent))
                    }

                    Button("Keep as is", action: onKeep)
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "5A5A62"))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color(hex: "FDF6EE"))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Color.winnowCaution.opacity(0.22), lineWidth: 1))
    }
}
