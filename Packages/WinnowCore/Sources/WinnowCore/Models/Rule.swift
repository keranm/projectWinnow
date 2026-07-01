import Foundation

public enum ConditionMatch: String, Codable, Sendable, CaseIterable {
    case all = "all"
    case any = "any"

    public var displayName: String {
        switch self {
        case .all: return "all conditions"
        case .any: return "any condition"
        }
    }
}

public struct RuleCondition: Codable, Sendable {
    public enum ConditionField: String, Codable, Sendable, CaseIterable {
        case from    = "from"
        case subject = "subject"

        public var displayName: String {
            switch self {
            case .from:    return "From"
            case .subject: return "Subject"
            }
        }
    }

    public var field: ConditionField
    public var value: String

    public init(field: ConditionField = .from, value: String = "") {
        self.field = field
        self.value = value
    }

    public func evaluate(_ thread: MailThread) -> Bool {
        guard !value.isEmpty else { return false }
        switch field {
        case .from:
            return thread.messages.contains {
                $0.from.email.localizedCaseInsensitiveContains(value) ||
                $0.from.displayName.localizedCaseInsensitiveContains(value)
            }
        case .subject:
            return thread.subject.localizedCaseInsensitiveContains(value)
        }
    }
}

public enum RuleAction: String, Codable, Hashable, Sendable, CaseIterable {
    case skipInbox  = "skipInbox"
    case markAsRead = "markAsRead"
    case archive    = "archive"

    public var displayName: String {
        switch self {
        case .skipInbox:  return "Skip inbox"
        case .markAsRead: return "Mark as read"
        case .archive:    return "Archive"
        }
    }

    public var systemImage: String {
        switch self {
        case .skipInbox:  return "tray"
        case .markAsRead: return "envelope.open"
        case .archive:    return "archivebox"
        }
    }
}

public struct Rule: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var conditionMatch: ConditionMatch
    public var conditions: [RuleCondition]
    public var actions: [RuleAction]

    public init(
        id: UUID = UUID(),
        name: String = "New Rule",
        isEnabled: Bool = true,
        conditionMatch: ConditionMatch = .all,
        conditions: [RuleCondition] = [],
        actions: [RuleAction] = [.skipInbox]
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.conditionMatch = conditionMatch
        self.conditions = conditions
        self.actions = actions
    }

    public func matches(_ thread: MailThread) -> Bool {
        guard !conditions.isEmpty else { return false }
        let results = conditions.map { $0.evaluate(thread) }
        return conditionMatch == .all ? results.allSatisfy { $0 } : results.contains(true)
    }
}
