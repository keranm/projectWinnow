import SwiftUI

struct SnoozePickerView: View {
    let onSnooze: (Date) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            snoozeRow(label: "Later today", detail: "6:00 PM", date: laterToday,   icon: "clock")
            snoozeRow(label: "Tomorrow",    detail: "8:00 AM", date: tomorrow,     icon: "sunrise")
            snoozeRow(label: "This weekend", detail: saturdayLabel, date: weekend, icon: "calendar")
            snoozeRow(label: "Next week",   detail: mondayLabel,  date: nextWeek,  icon: "calendar.badge.plus")
        }
        .padding(8)
        .frame(width: 240)
    }

    private func snoozeRow(label: String, detail: String, date: Date, icon: String) -> some View {
        Button {
            onSnooze(date)
            onDismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.winnowTextSecondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.winnowText)
                    Text(detail)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.winnowTextQuaternary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnoozeRowStyle())
    }

    // MARK: - Date helpers

    private var laterToday: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 18; comps.minute = 0; comps.second = 0
        let candidate = Calendar.current.date(from: comps) ?? Date()
        // If it's already past 6 PM, fall back to +2h
        return candidate > Date() ? candidate : Date().addingTimeInterval(7200)
    }

    private var tomorrow: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.day! += 1
        comps.hour = 8; comps.minute = 0; comps.second = 0
        return Calendar.current.date(from: comps) ?? Date().addingTimeInterval(86400)
    }

    private var weekend: Date {
        let cal = Calendar.current
        let today = cal.component(.weekday, from: Date())
        let daysUntilSat = (7 - today + 7) % 7 == 0 ? 7 : (7 - today + 7) % 7
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.day! += daysUntilSat
        comps.hour = 8; comps.minute = 0; comps.second = 0
        return cal.date(from: comps) ?? Date().addingTimeInterval(86400 * Double(daysUntilSat))
    }

    private var nextWeek: Date {
        let cal = Calendar.current
        let today = cal.component(.weekday, from: Date())
        let daysUntilMon = (9 - today) % 7 == 0 ? 7 : (9 - today + 7) % 7
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.day! += daysUntilMon
        comps.hour = 8; comps.minute = 0; comps.second = 0
        return cal.date(from: comps) ?? Date().addingTimeInterval(86400 * Double(daysUntilMon))
    }

    private var saturdayLabel: String { dayLabel(for: weekend) }
    private var mondayLabel:   String { dayLabel(for: nextWeek) }

    private func dayLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        return fmt.string(from: date) + ", 8:00 AM"
    }
}

// MARK: - Row button style

private struct SnoozeRowStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed || isHovered ? Color.winnowHover : Color.clear)
            )
            .onHover { isHovered = $0 }
    }
}
