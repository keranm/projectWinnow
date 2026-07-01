import SwiftUI
import WinnowCore
import WinnowUI

struct SnoozePickerView: View {
    let thread: MailThread
    let currentEntry: SnoozeEntry?
    let onSnoozeDate: (Date) -> Void
    let onSnoozeCondition: (SnoozeCondition) -> Void
    let onUnsnooze: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── SNOOZE UNTIL ───────────────────────────────────────────────
            Text("SNOOZE UNTIL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(Color.winnowLabelText)
                .padding(.horizontal, 15)
                .padding(.top, 13)
                .padding(.bottom, 7)

            timeRow("Later today",  detail: "6:00 PM", date: laterToday)
            Color.black.opacity(0.04).frame(height: 1)
            timeRow("Tomorrow",     detail: "8:00 AM", date: tomorrow)
            Color.black.opacity(0.04).frame(height: 1)
            timeRow("This weekend", detail: "Sat",     date: weekend)

            // ── WHEN… · ON-DEVICE ──────────────────────────────────────────
            Color.black.opacity(0.06).frame(height: 1)
            HStack(spacing: 7) {
                AssistDiamond(size: .small)
                Text("WHEN…  ·  ON-DEVICE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.55)
                    .foregroundStyle(Color.winnowLabelText)
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.winnowSurfaceElevated)

            conditionRow("They reply",         detail: "watches this thread", monoDetail: false, condition: .onReply, enabled: true)
            Color.black.opacity(0.04).frame(height: 1)
            conditionRow("I get home",         detail: "location",            monoDetail: false, condition: nil,      enabled: false)
            Color.black.opacity(0.04).frame(height: 1)
            conditionRow("I reach the office", detail: "location",            monoDetail: false, condition: nil,      enabled: false)
            Color.black.opacity(0.04).frame(height: 1)
            conditionRow("My trip starts",     detail: tripLabel,             monoDetail: true,  condition: nil,      enabled: false)

            // ── + Pick a condition ──────────────────────────────────────────
            Color.black.opacity(0.04).frame(height: 1)
            HStack(spacing: 9) {
                Text("+")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.winnowTextTertiary)
                Text("Pick a condition…")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.winnowTextSubdued)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .opacity(0.5)

            // ── Footer ─────────────────────────────────────────────────────
            Color.black.opacity(0.06).frame(height: 1)
            HStack(alignment: .top, spacing: 8) {
                AssistDiamond(size: .small).padding(.top, 3)
                Text("Conditions are watched on your Mac — no rules sent to a server.")
                    .font(.system(size: 11.5))
                    .lineSpacing(2)
                    .foregroundStyle(Color.winnowTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(Color.winnowSidebar)
        }
        .frame(width: 360)
        .background(Color.winnowSurface)
    }

    // MARK: - Time row

    @ViewBuilder
    private func timeRow(_ label: String, detail: String, date: Date) -> some View {
        Button {
            onSnoozeDate(date)
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.winnowTextSubdued)
                Spacer()
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.winnowTextTertiary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
        }
        .buttonStyle(SnoozeRowButtonStyle())
    }

    // MARK: - Condition row

    @ViewBuilder
    private func conditionRow(_ label: String, detail: String, monoDetail: Bool, condition: SnoozeCondition?, enabled: Bool) -> some View {
        let isActive = condition != nil && currentEntry?.condition == condition

        Button {
            guard enabled, let condition else { return }
            if isActive { onUnsnooze() } else { onSnoozeCondition(condition) }
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 13.5, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? Color.winnowText : (enabled ? Color.winnowTextSubdued : Color.winnowTextQuaternary))
                Spacer()
                Text(detail)
                    .font(monoDetail
                          ? .system(size: 12, weight: .medium, design: .monospaced)
                          : .system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? Color.winnowTextSecondary : Color.winnowTextTertiary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(
                ZStack(alignment: .leading) {
                    if isActive {
                        Color.winnowAccentTint
                        Rectangle()
                            .fill(Color.winnowAccent)
                            .frame(width: 2)
                    }
                }
            )
        }
        .buttonStyle(SnoozeRowButtonStyle(active: isActive))
        .disabled(!enabled)
    }

    // MARK: - Date helpers

    private var laterToday: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 18; c.minute = 0; c.second = 0
        let t = Calendar.current.date(from: c) ?? Date()
        return t > Date() ? t : Date().addingTimeInterval(7200)
    }

    private var tomorrow: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.day! += 1; c.hour = 8; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c) ?? Date().addingTimeInterval(86400)
    }

    private var weekend: Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date()) // 1=Sun … 7=Sat
        let days = ((7 - weekday) + 7) % 7
        let d = days == 0 ? 7 : days
        var c = cal.dateComponents([.year, .month, .day], from: Date())
        c.day! += d; c.hour = 8; c.minute = 0; c.second = 0
        return cal.date(from: c) ?? Date().addingTimeInterval(86400 * Double(d))
    }

    private var tripLabel: String {
        let date = thread.intelligenceResults.compactMap { r -> Date? in
            if case .flightInfo(let f) = r { return f.departureDate }
            return nil
        }.min()
        guard let date else { return "—" }
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }
}

// MARK: - Row button style

private struct SnoozeRowButtonStyle: ButtonStyle {
    var active: Bool = false
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(active ? Color.clear : (hovered ? Color.winnowHover : Color.clear))
            .contentShape(Rectangle())
            .onHover { hovered = $0 }
    }
}
