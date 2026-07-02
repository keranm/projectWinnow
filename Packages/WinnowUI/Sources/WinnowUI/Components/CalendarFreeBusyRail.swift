import SwiftUI

public struct FreeBusyRailBlock: Identifiable, Sendable {
    public enum Style: Sendable { case busy, conflict, candidate, suggested }

    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let start: Date
    public let end: Date
    public let style: Style

    public init(title: String, subtitle: String? = nil, start: Date, end: Date, style: Style) {
        self.title = title
        self.subtitle = subtitle
        self.start = start
        self.end = end
        self.style = style
    }
}

/// Vertical hour-ruled timeline showing existing events, a candidate invite, and a
/// suggested free slot — reads "from Apple Calendar · on-device" per the Quiet spec.
public struct CalendarFreeBusyRail: View {
    let dayLabel: String
    let rangeStart: Date
    let rangeEnd: Date
    let blocks: [FreeBusyRailBlock]

    public init(dayLabel: String, rangeStart: Date, rangeEnd: Date, blocks: [FreeBusyRailBlock]) {
        self.dayLabel = dayLabel
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.blocks = blocks
    }

    private var totalSeconds: TimeInterval { max(rangeEnd.timeIntervalSince(rangeStart), 60) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
                AssistDiamond(size: .small)
                Text(dayLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
            }
            Text("from Apple Calendar · on-device")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.winnowTextTertiary)

            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    ForEach(hourMarks, id: \.self) { hour in
                        let y = yPosition(for: hour, height: geo.size.height)
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 1)
                            .offset(y: y)
                        Text(hourLabel(hour))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.winnowTextQuaternary)
                            .background(Color.winnowSurface)
                            .offset(x: 0, y: y - 6)
                    }

                    ForEach(blocks) { block in
                        blockView(block, in: geo.size)
                    }
                }
            }
            .padding(.top, 16)
            .frame(height: 336)
        }
    }

    // MARK: - Layout

    private var hourMarks: [Int] {
        let cal = Calendar.current
        var hours: [Int] = []
        var cursor = rangeStart
        while cursor <= rangeEnd {
            hours.append(cal.component(.hour, from: cursor))
            cursor = cal.date(byAdding: .hour, value: 1, to: cursor) ?? rangeEnd.addingTimeInterval(1)
        }
        return hours
    }

    private func yPosition(for hour: Int, height: CGFloat) -> CGFloat {
        let cal = Calendar.current
        guard let hourDate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: rangeStart) else { return 0 }
        return yPosition(for: hourDate, height: height)
    }

    private func yPosition(for date: Date, height: CGFloat) -> CGFloat {
        CGFloat(date.timeIntervalSince(rangeStart) / totalSeconds) * height
    }

    private func hourLabel(_ hour: Int) -> String {
        let period = hour < 12 ? "a" : "p"
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return "\(h12)\(period)"
    }

    @ViewBuilder
    private func blockView(_ block: FreeBusyRailBlock, in size: CGSize) -> some View {
        let top = yPosition(for: block.start, height: size.height)
        let bottom = yPosition(for: block.end, height: size.height)
        let height = max(bottom - top, 22)
        let halfWidth = size.width * 0.48

        VStack(alignment: .leading, spacing: 1) {
            Text(block.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(textColor(for: block.style))
                .lineLimit(1)
            if let subtitle = block.subtitle {
                Text(subtitle)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(textColor(for: block.style).opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(width: sideAligned(block.style) == nil ? size.width - 34 : halfWidth, height: height, alignment: .topLeading)
        .background(background(for: block.style))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(border(for: block.style))
        .offset(
            x: sideAligned(block.style) == .trailing ? size.width - halfWidth : 34,
            y: top
        )
    }

    private enum Side { case leading, trailing }

    private func sideAligned(_ style: FreeBusyRailBlock.Style) -> Side? {
        switch style {
        case .busy, .conflict: return .leading
        case .candidate: return .trailing
        case .suggested: return nil
        }
    }

    private func background(for style: FreeBusyRailBlock.Style) -> some View {
        Group {
            switch style {
            case .busy, .conflict: Color(hex: "FBE9E6")
            case .candidate: Color(hex: "EEF3FC")
            case .suggested: Color(hex: "EEF7F1")
            }
        }
    }

    private func border(for style: FreeBusyRailBlock.Style) -> some View {
        Group {
            switch style {
            case .busy, .conflict:
                RoundedRectangle(cornerRadius: 5).strokeBorder(Color(hex: "E0533D"), lineWidth: 0).overlay(alignment: .leading) {
                    Rectangle().fill(Color(hex: "E0533D")).frame(width: 3)
                }
            case .candidate:
                RoundedRectangle(cornerRadius: 5).strokeBorder(Color.winnowAccent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            case .suggested:
                RoundedRectangle(cornerRadius: 5).strokeBorder(Color.winnowSuccess.opacity(0.4), lineWidth: 1.5)
            }
        }
    }

    private func textColor(for style: FreeBusyRailBlock.Style) -> Color {
        switch style {
        case .busy, .conflict: Color(hex: "B3402C")
        case .candidate: Color.winnowAccent
        case .suggested: Color.winnowSuccess
        }
    }
}
