import Foundation

public struct Account: Identifiable, Sendable, Hashable {
    public let id: String
    public var email: String
    public var displayName: String?
    public var provider: Provider
    public var color: AccountColor
    public var isActive: Bool

    public enum Provider: Sendable, Hashable {
        case gmail
        case imap(host: String)
    }

    public enum AccountColor: String, Sendable, Hashable, CaseIterable {
        case blue, green, purple, orange, red, teal

        public var hex: String {
            switch self {
            case .blue:   return "2F6BDB"
            case .green:  return "2F9E6F"
            case .purple: return "7B5EA7"
            case .orange: return "C08A4A"
            case .red:    return "D9534F"
            case .teal:   return "2B8A8A"
            }
        }
    }

    public var initials: String {
        let name = displayName ?? email
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    public init(
        id: String,
        email: String,
        displayName: String? = nil,
        provider: Provider = .gmail,
        color: AccountColor = .blue,
        isActive: Bool = true
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.provider = provider
        self.color = color
        self.isActive = isActive
    }
}
