import Foundation

enum NavItem: Hashable, CaseIterable {
    // Primary nav
    case today
    case important
    case other

    // Pulled from mail
    case trips
    case quotes
    case subscriptions
    case calendar

    var title: String {
        switch self {
        case .today:          return "Today"
        case .important:      return "Important"
        case .other:          return "Other"
        case .trips:          return "Trips & deliveries"
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
        case .trips:          return "airplane"
        case .quotes:         return "quote.bubble.fill"
        case .subscriptions:  return "repeat"
        case .calendar:       return "calendar"
        }
    }

    static var primaryItems: [NavItem] { [.today, .important, .other] }
    static var pulledItems: [NavItem]  { [.trips, .quotes, .subscriptions, .calendar] }
}
