import SwiftUI
import WinnowCore
import WinnowUI

struct ThreadRowView: View {
    let thread: MailThread
    let isSelected: Bool
    @State private var isHovered = false

    private var sender: String {
        thread.messages.last?.from.displayName ?? "Unknown"
    }

    private var time: String {
        let cal = Calendar.current
        let date = thread.lastMessageDate
        if cal.isDateInToday(date) {
            let fmt = date.formatted(date: .omitted, time: .shortened)
            // Compact: "9:24a" instead of "9:24 AM"
            return fmt
                .replacingOccurrences(of: " AM", with: "a")
                .replacingOccurrences(of: " PM", with: "p")
        } else if cal.isDateInYesterday(date) {
            return "Yest"
        } else {
            // Mon / Tue / Wed etc
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            // Unread dot — fixed 7pt circle, always takes its slot
            Circle()
                .fill(thread.isRead ? Color.clear : Color.winnowAccent)
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(sender)
                        .font(.system(size: 13.5, weight: thread.isRead ? .medium : .semibold))
                        .foregroundStyle(thread.isRead ? Color.winnowTextSubdued : Color.winnowText)
                        .lineLimit(1)

                    Spacer()

                    Text(time)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(thread.isRead ? Color.winnowTextQuaternary : Color.winnowTextTertiary)
                }

                Text(thread.subject)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(thread.isRead ? Color.winnowTextSecondary : Color.winnowText)
                    .lineLimit(1)

                Text(thread.snippet)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(isSelected ? Color.winnowAccentTint : (isHovered ? Color.winnowHover : .clear))
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
                if isSelected {
                    Rectangle()
                        .fill(Color.winnowAccent)
                        .frame(width: 2)
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
