import Foundation
import WinnowCore

@Observable
final class WinnowSettings {

    // MARK: - Nested types

    enum Engine: String, CaseIterable, Codable {
        case foundation = "foundation"
        case mlx        = "mlx"
        case cloud      = "cloud"

        var title: String {
            switch self {
            case .foundation: "On-device · Apple Foundation Models"
            case .mlx:        "Mac power model · MLX"
            case .cloud:      "Connect your own API key"
            }
        }
    }

    enum AssistanceLevel: String, CaseIterable, Codable {
        case suggest  = "suggest"
        case autoFile = "autoFile"
        case off      = "off"

        var label: String {
            switch self {
            case .suggest:  "Suggest"
            case .autoFile: "Auto-file"
            case .off:      "Off"
            }
        }

        var description: String {
            switch self {
            case .suggest:
                return "Winnow surfaces drafts and triage suggestions, but never sends or files anything without you."
            case .autoFile:
                return "Winnow sorts newsletters, receipts, and notifications automatically. You can always undo."
            case .off:
                return "No suggestions or automatic actions — Winnow is a plain mail client."
            }
        }
    }

    struct Identity: Identifiable, Codable {
        var id: UUID    = UUID()
        var email: String
        var displayName: String
        var label: String          // "Personal", "Work", etc.
        var sendsVia: String       // "Gmail SMTP", "Gmail alias", "Fastmail SMTP"
        var signatureName: String  // Short display name, e.g. "Alex Morgan"
        var signatureBody: String  // Full text appended to outgoing messages
        var isDefault: Bool        = false

        static func defaultForGmail(email: String, displayName: String) -> Identity {
            Identity(
                email: email,
                displayName: displayName,
                label: "Personal",
                sendsVia: "Gmail SMTP",
                signatureName: displayName,
                signatureBody: "\(displayName)",
                isDefault: true
            )
        }
    }

    struct Snippet: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var shortcut: String   // e.g. ";intro"
        var body: String
    }

    // MARK: - Intelligence

    var engine: Engine            = .foundation
    var assistanceLevel: AssistanceLevel = .suggest
    var cloudAPIEnabled: Bool     = false
    var cloudAPIKey: String       = ""

    var extractPackages: Bool     = true
    var extractFlights: Bool      = true
    var extractHotels: Bool       = true
    var extractQuotes: Bool       = true
    var extractSubscriptions: Bool = true
    var extractNeedsReply: Bool   = true

    // MARK: - Accounts / Identities

    var identities: [Identity]    = []
    var autoRouteReplies: Bool    = true

    // MARK: - Snippets

    var snippets: [Snippet] = []

    // MARK: - Rules

    var rules: [Rule] = []

    // MARK: - Snooze

    var snoozeEntries: [SnoozeEntry] = []

    // MARK: - General

    var showDockBadge: Bool       = true
    var threadDensity: String     = "comfortable"   // "comfortable" | "compact"

    // MARK: - Persistence (UserDefaults backing store)

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var isLoading = false

    // MARK: - Init

    init() {
        isLoading = true
        load()
        isLoading = false
    }

    // MARK: - Seeders (called from AppState after first auth)

    func seedIdentityIfNeeded(email: String, displayName: String) {
        guard !identities.contains(where: { $0.email == email }) else { return }
        identities.append(.defaultForGmail(email: email, displayName: displayName))
        save()
    }

    // MARK: - Derived

    var defaultIdentity: Identity? { identities.first(where: { $0.isDefault }) ?? identities.first }

    func identity(for email: String) -> Identity? {
        identities.first(where: { $0.email.lowercased() == email.lowercased() })
    }

    // MARK: - Snippets helpers

    func deleteSnippet(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    func upsertSnippet(_ snippet: Snippet) {
        if let i = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[i] = snippet
        } else {
            snippets.append(snippet)
        }
        save()
    }

    // MARK: - Rules helpers

    func upsertRule(_ rule: Rule) {
        if let i = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[i] = rule
        } else {
            rules.append(rule)
        }
        save()
    }

    func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    func moveRule(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Snooze helpers

    func snooze(threadID: String, until wakeDate: Date) {
        snoozeEntries.removeAll { $0.threadID == threadID }
        snoozeEntries.append(SnoozeEntry(threadID: threadID, wakeDate: wakeDate))
        save()
    }

    func unsnooze(threadID: String) {
        snoozeEntries.removeAll { $0.threadID == threadID }
        save()
    }

    func activeSnoozedIDs(at now: Date = Date()) -> Set<String> {
        Set(snoozeEntries.filter { $0.wakeDate > now }.map { $0.threadID })
    }

    func clearExpiredSnoozes(at now: Date = Date()) {
        let before = snoozeEntries.count
        snoozeEntries.removeAll { $0.wakeDate <= now }
        if snoozeEntries.count != before { save() }
    }

    // MARK: - Identity helpers

    func upsertIdentity(_ identity: Identity) {
        if let i = identities.firstIndex(where: { $0.id == identity.id }) {
            identities[i] = identity
        } else {
            identities.append(identity)
        }
        save()
    }

    func setDefault(id: UUID) {
        for i in identities.indices { identities[i].isDefault = identities[i].id == id }
        save()
    }

    // MARK: - Load / Save

    func save() {
        guard !isLoading else { return }
        defaults.set(engine.rawValue, forKey: "s.engine")
        defaults.set(assistanceLevel.rawValue, forKey: "s.assistLevel")
        defaults.set(cloudAPIEnabled, forKey: "s.cloudAPI")
        defaults.set(cloudAPIKey, forKey: "s.cloudKey")
        defaults.set(extractPackages, forKey: "s.extractPkg")
        defaults.set(extractFlights, forKey: "s.extractFlt")
        defaults.set(extractHotels, forKey: "s.extractHtl")
        defaults.set(extractQuotes, forKey: "s.extractQte")
        defaults.set(extractSubscriptions, forKey: "s.extractSub")
        defaults.set(extractNeedsReply, forKey: "s.extractNR")
        defaults.set(autoRouteReplies, forKey: "s.autoRoute")
        defaults.set(showDockBadge, forKey: "s.dockBadge")
        defaults.set(threadDensity, forKey: "s.density")

        let enc = JSONEncoder()
        if let data = try? enc.encode(identities)    { defaults.set(data, forKey: "s.identities") }
        if let data = try? enc.encode(snippets)      { defaults.set(data, forKey: "s.snippets") }
        if let data = try? enc.encode(rules)         { defaults.set(data, forKey: "s.rules") }
        if let data = try? enc.encode(snoozeEntries) { defaults.set(data, forKey: "s.snooze") }
    }

    private func load() {
        if let raw = defaults.string(forKey: "s.engine"),
           let v = Engine(rawValue: raw) { engine = v }
        if let raw = defaults.string(forKey: "s.assistLevel"),
           let v = AssistanceLevel(rawValue: raw) { assistanceLevel = v }
        cloudAPIEnabled   = defaults.bool(forKey: "s.cloudAPI")
        cloudAPIKey       = defaults.string(forKey: "s.cloudKey") ?? ""
        if defaults.object(forKey: "s.extractPkg") != nil {
            extractPackages      = defaults.bool(forKey: "s.extractPkg")
            extractFlights       = defaults.bool(forKey: "s.extractFlt")
            extractHotels        = defaults.bool(forKey: "s.extractHtl")
            extractQuotes        = defaults.bool(forKey: "s.extractQte")
            extractSubscriptions = defaults.bool(forKey: "s.extractSub")
            extractNeedsReply    = defaults.bool(forKey: "s.extractNR")
        }
        if defaults.object(forKey: "s.autoRoute") != nil {
            autoRouteReplies = defaults.bool(forKey: "s.autoRoute")
        }
        showDockBadge = defaults.object(forKey: "s.dockBadge") != nil
            ? defaults.bool(forKey: "s.dockBadge") : true
        threadDensity = defaults.string(forKey: "s.density") ?? "comfortable"

        let dec = JSONDecoder()
        if let data = defaults.data(forKey: "s.identities"),
           let v = try? dec.decode([Identity].self, from: data)    { identities = v }
        if let data = defaults.data(forKey: "s.snippets"),
           let v = try? dec.decode([Snippet].self, from: data)     { snippets = v }
        if let data = defaults.data(forKey: "s.rules"),
           let v = try? dec.decode([Rule].self, from: data)        { rules = v }
        if let data = defaults.data(forKey: "s.snooze"),
           let v = try? dec.decode([SnoozeEntry].self, from: data) { snoozeEntries = v }
    }
}
