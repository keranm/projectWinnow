import SwiftUI

/// The blue-tinted on-device AI summary card that appears in the reading pane.
/// Background #F7F9FC, accent border at 10% opacity, radius 9.
public struct AssistSummaryCard: View {
    let summary: String

    public init(summary: String) {
        self.summary = summary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                AssistDiamond(size: .small)
                Text("SUMMARY")
                    .winnowSectionHeader()
            }

            Text(summary)
                .font(WinnowTypography.body)
                .foregroundStyle(Color.winnowTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(hex: "F7F9FC"))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(Color.winnowAccent.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
