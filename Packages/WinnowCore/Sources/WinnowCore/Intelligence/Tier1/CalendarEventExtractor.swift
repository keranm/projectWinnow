import Foundation

/// Detects Google Calendar invitation emails (sent via calendar-notification@google.com,
/// or with the standard "Invitation:" / "Updated invitation:" / "Canceled event:" subject
/// prefixes) and pulls out title + date/time from the subject line and organiser from the
/// sender header. Both are available at Tier 1 (metadata-only sync); location, guests, and
/// meeting link require the full message body — see `enrich(_:withBody:)`, called once
/// `AppState.loadFullThread` has fetched it.
enum CalendarEventExtractor {
    private static let subjectPrefixes: [(prefix: String, cancelled: Bool)] = [
        ("Invitation: ", false),
        ("Updated invitation: ", false),
        ("Invite: ", false),
        ("Canceled event: ", true),
        ("Cancelled event: ", true),
    ]

    private static let inviteSenderDomains = ["calendar.google.com", "calendar-notification@google.com"]

    static func extract(from thread: MailThread) -> IntelligenceResult.CalendarEventInfo? {
        guard let latest = thread.messages.last else { return nil }
        let subject = thread.subject

        let matchedPrefix = subjectPrefixes.first { subject.hasPrefix($0.prefix) }
        let looksLikeInviteSender = inviteSenderDomains.contains { latest.from.email.lowercased().contains($0) }
        guard matchedPrefix != nil || looksLikeInviteSender else { return nil }

        var title = subject
        if let prefix = matchedPrefix?.prefix, subject.hasPrefix(prefix) {
            title = String(subject.dropFirst(prefix.count))
        }

        // Subject format is "<title> @ <when>" — split on the last " @ " so titles containing "@" survive.
        var whenText: String?
        if let range = title.range(of: " @ ", options: .backwards) {
            whenText = String(title[range.upperBound...])
            title = String(title[..<range.lowerBound])
        }

        let (start, end) = parseDates(from: whenText ?? subject, fallback: latest.date)
        guard let start else { return nil }

        return IntelligenceResult.CalendarEventInfo(
            title: title.trimmingCharacters(in: .whitespaces),
            startDate: start,
            endDate: end,
            organiser: latest.from.name,
            organiserEmail: latest.from.email,
            isCancelled: matchedPrefix?.cancelled ?? false
        )
    }

    /// Re-parses the full message body (once loaded) for fields not present in metadata-only sync.
    static func enrich(_ info: IntelligenceResult.CalendarEventInfo, withBody body: MessageBody) -> IntelligenceResult.CalendarEventInfo {
        let text: String
        switch body {
        case .plain(let t): text = t
        case .html(let html): text = stripHTML(html)
        }

        let location = firstMatch(in: text, after: ["Where:", "Location:"])
        let guestsLine = firstMatch(in: text, after: ["Guests:", "Who:"])
        let guests = guestsLine.map {
            $0.components(separatedBy: CharacterSet(charactersIn: ",·")).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } ?? info.guests

        var meetingLink: String? = info.meetingLink
        if let range = text.range(of: #"https?://meet\.google\.com/\S+"#, options: .regularExpression) {
            meetingLink = String(text[range])
        } else if let range = text.range(of: #"https?://\S*zoom\.us/\S+"#, options: .regularExpression) {
            meetingLink = String(text[range])
        }

        return IntelligenceResult.CalendarEventInfo(
            title: info.title,
            startDate: info.startDate,
            endDate: info.endDate,
            location: location ?? info.location,
            organiser: info.organiser,
            organiserEmail: info.organiserEmail,
            guests: guests,
            meetingLink: meetingLink,
            isCancelled: info.isCancelled
        )
    }

    // MARK: - Private

    private static func parseDates(from text: String, fallback: Date) -> (Date?, Date?) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return (fallback, nil)
        }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard let first = matches.first, let start = first.date else { return (fallback, nil) }
        if first.duration > 0 {
            return (start, start.addingTimeInterval(first.duration))
        }
        return (start, nil)
    }

    private static func firstMatch(in text: String, after labels: [String]) -> String? {
        for label in labels {
            guard let labelRange = text.range(of: label) else { continue }
            let rest = text[labelRange.upperBound...]
            if let lineEnd = rest.firstIndex(where: { $0.isNewline }) {
                let value = rest[rest.startIndex..<lineEnd].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { return value }
            } else {
                let value = rest.trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { return String(value.prefix(120)) }
            }
        }
        return nil
    }

    private static func stripHTML(_ html: String) -> String {
        // Inline tags vanish (so "<b>Where:</b> Google Meet" stays one line); block tags break lines.
        var s = html.replacingOccurrences(
            of: #"</?(?:b|i|u|em|strong|span|a|font|small|abbr|time|code)\b[^>]*>"#,
            with: "", options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&middot;", with: "·")
            .replacingOccurrences(of: "&amp;", with: "&")
        return s
    }
}
