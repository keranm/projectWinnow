import Foundation

/// On-device Important/Other triage — replaces Gmail's IMPORTANT label.
///
/// Important means one of:
///   1. it needs a reply (`NeedsReplySignal`),
///   2. it's from a person you actually correspond with (and isn't automated),
///   3. it's time-critical awareness: a package arriving about now, a flight
///      departing within a day, an event starting within a couple of hours.
///
/// Generic notifications — "your shipment is on the way", ToS updates, product
/// news — are nice to know, not important. They stay in Other (and the packages
/// still get their Deliveries card).
public enum InboxTriage {

    public static func isImportant(
        _ thread: MailThread,
        selfEmail: String?,
        correspondents: Set<String> = [],
        now: Date = Date()
    ) -> Bool {
        if NeedsReplySignal.needsReply(thread, selfEmail: selfEmail) { return true }
        if isTimeCritical(thread, now: now) { return true }

        guard let last = thread.messages.last else { return false }
        let sender = last.from.email.lowercased()
        guard sender != selfEmail?.lowercased() else { return false }
        return correspondents.contains(sender) && !thread.isLikelyAutomated
    }

    /// People you've written to, and people who wrote in threads you took part in —
    /// derived from the loaded window (a SENT-history sweep can widen this later).
    public static func correspondents(in threads: [MailThread], selfEmail: String?) -> Set<String> {
        guard let se = selfEmail?.lowercased() else { return [] }
        var people = Set<String>()
        for thread in threads {
            guard thread.messages.contains(where: { $0.from.email.lowercased() == se }) else { continue }
            for message in thread.messages {
                if message.from.email.lowercased() == se {
                    for p in message.to + message.cc { people.insert(p.email.lowercased()) }
                } else {
                    people.insert(message.from.email.lowercased())
                }
            }
        }
        people.remove(se)
        return people
    }

    /// "I need to be aware of this now" — imminent deliveries, departures, events.
    static func isTimeCritical(_ thread: MailThread, now: Date) -> Bool {
        for result in thread.intelligenceResults {
            switch result {
            case .packageTracking(let p):
                if case .outForDelivery = p.status { return true }
                if let eta = p.estimatedDelivery, eta > now, eta.timeIntervalSince(now) <= 3 * 3600 { return true }
            case .flightInfo(let f):
                if f.departureDate > now, f.departureDate.timeIntervalSince(now) <= 24 * 3600 { return true }
            case .calendarEvent(let e):
                if !e.isCancelled, e.startDate > now, e.startDate.timeIntervalSince(now) <= 2 * 3600 { return true }
            default:
                break
            }
        }
        return false
    }
}
