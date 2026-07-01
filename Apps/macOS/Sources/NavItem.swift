import Foundation

enum NavItem: Hashable, CaseIterable {
    // Primary nav
    case today
    case important
    case other

    // Pulled from mail (shown only when non-empty)
    case flights
    case deliveries
    case quotes
    case subscriptions
    case calendar

    var title: String {
        switch self {
        case .today:          return "Today"
        case .important:      return "Important"
        case .other:          return "Other"
        case .flights:        return "Trips"
        case .deliveries:     return "Deliveries"
        case .quotes:         return "Quotes"
        case .subscriptions:  return "Subscriptions"
        case .calendar:       return "Calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .today:          return "star.fill"
        case .important:      return "flag.fill"
        case .other:          return "tray.fill"
        case .flights:        return "airplane"
        case .deliveries:     return "shippingbox"
        case .quotes:         return "quote.bubble.fill"
        case .subscriptions:  return "repeat"
        case .calendar:       return "calendar"
        }
    }

    static var primaryItems: [NavItem] { [.today, .important, .other] }
    static var pulledItems: [NavItem]  { [.flights, .deliveries, .quotes, .subscriptions, .calendar] }
}
