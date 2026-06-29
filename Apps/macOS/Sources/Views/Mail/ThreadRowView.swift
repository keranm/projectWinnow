import SwiftUI
import WinnowCore
import WinnowUI

struct ThreadRowView: View {
    let thread: MailThread
    let isSelected: Bool

    private var sender: String {
        thread.messages.last?.from.displayName ?? "Unknown"
    }

    private var time: String {
        let cal = Calendar.current
        if cal.isDateInToday(thread.lastMessageDate) {
            return thread.lastMessageDate.formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInYesterday(thread.lastMessageDate) {
            return "Yesterday"
        } else {
            return thread.lastMessageDate.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            UnreadDot(isUnread: !thread.isRead)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(sender)
                        .font(WinnowTypography.senderName)
                        .foregroundStyle(Color.winnowText)
                        .lineLimit(1)

                    Spacer()

                    Text(time)
                        .font(WinnowTypography.meta)
                        .foregroundStyle(Color.winnowTextTertiary)
                }

                Text(thread.subject)
                    .font(WinnowTypography.messageSubject)
                    .foregroundStyle(Color.winnowText)
                    .lineLimit(1)

                Text(thread.snippet)
                    .font(WinnowTypography.messagePreview)
                    .foregroundStyle(Color.winnowTextTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(isSelected ? Color.winnowAccentTint : Color.clear)
                if isSelected {
                    Rectangle()
                        .fill(Color.winnowAccent)
                        .frame(width: 2)
                }
            }
        )
        .contentShape(Rectangle())
    }
}
