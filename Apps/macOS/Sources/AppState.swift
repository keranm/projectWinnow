import SwiftUI
import AppKit
import WinnowCore

@Observable
@MainActor
final class AppState {
    // Navigation
    var selectedNavItem: NavItem = .today
    var selectedThreadID: String?

    // Data
    var threads: [MailThread] = []
    var accounts: [Account] = []

    // Auth / sync state
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var syncError: String?
    var lastSyncDate: Date?

    // Pagination
    var hasMoreThreads: Bool { nextPageToken != nil }
    private var nextPageToken: String?

    // Compose
    var isComposing: Bool = false

    // Snooze
    var snoozedIDs: Set<String> = []

    // Rules
    var ruleFilteredIDs: Set<String> = []

    // Search
    var isSearchActive: Bool = false
    var searchQuery: String = ""
    var searchResults: [MailThread] = []
    var isSearching: Bool = false
    var searchResultCount: Int = 0
    var searchDuration: TimeInterval = 0
    private var searchTask: Task<Void, Never>?

    // Derived
    var selectedThread: MailThread? {
        guard let id = selectedThreadID else { return nil }
        return threads.first { $0.id == id }
    }

    func count(for item: NavItem) -> Int {
        switch item {
        case .today:         return threads.filter { !$0.isRead }.count
        case .important:     return threads.filter { $0.labels.contains("IMPORTANT") }.count
        case .other:         return threads.filter { $0.labels.contains("INBOX") }.count
        case .flights:       return threads.filter { isFlight($0) }.count
        case .deliveries:    return threads.filter { isDelivery($0) }.count
        case .quotes:        return 0
        case .subscriptions: return threads.filter { isBill($0) }.count
        case .calendar:      return 0
        }
    }

    var visibleThreads: [MailThread] {
        if isSearchActive { return searchResults }
        let hidden = snoozedIDs.union(ruleFilteredIDs)
        func visible(_ t: MailThread) -> Bool { !hidden.contains(t.id) }
        switch selectedNavItem {
        case .today, .important:
            return threads.filter { visible($0) && ($0.labels.contains("IMPORTANT") || $0.needsReply) }
        case .flights:
            return threads.filter { visible($0) && isFlight($0) }
        case .deliveries:
            return threads.filter { visible($0) && isDelivery($0) }
        case .subscriptions:
            return threads.filter { visible($0) && isBill($0) }
        default:
            return threads.filter { visible($0) && $0.labels.contains("INBOX") }
        }
    }

    // Internal
    private var gmailClient: GmailAPIClient?
    private let keychain = KeychainStore()
    private let tokenKey = "oauth_tokens_primary"
    private var fullBodyLoadedIDs: Set<String> = []
    private var backgroundSyncTask: Task<Void, Never>?
    var settings: WinnowSettings = WinnowSettings()

    // MARK: - Lifecycle

    func bootstrap() async {
        snoozedIDs = settings.activeSnoozedIDs()
        guard let data = try? keychain.getData(forKey: tokenKey),
              let tokens = try? JSONDecoder().decode(OAuthTokens.self, from: data)
        else { return }
        await connectClient(tokens: tokens)
    }

    // MARK: - Auth

    func signInWithGmail() async {
        isLoading = true
        syncError = nil

        do {
            let service = AuthService(clientID: Secrets.gmailClientID, clientSecret: Secrets.gmailClientSecret)
            let tokens = try await service.authenticate { url in
                Task { @MainActor in NSWorkspace.shared.open(url) }
            }
            try? keychain.setData(JSONEncoder().encode(tokens), forKey: tokenKey)
            await connectClient(tokens: tokens)
        } catch {
            syncError = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        backgroundSyncTask?.cancel()
        backgroundSyncTask = nil
        keychain.delete(forKey: tokenKey)
        gmailClient = nil
        isAuthenticated = false
        threads = []
        accounts = []
        selectedThreadID = nil
        nextPageToken = nil
        fullBodyLoadedIDs = []
        isComposing = false
    }

    // MARK: - Sync

    func syncInbox() async {
        guard let client = gmailClient else { return }
        isLoading = true
        syncError = nil

        do {
            let profile = try await client.getProfile()
            let displayName = profile.emailAddress.components(separatedBy: "@").first?.capitalized ?? profile.emailAddress
            accounts = [Account(
                id: "primary",
                email: profile.emailAddress,
                displayName: displayName,
                provider: .gmail,
                color: .blue
            )]
            settings.seedIdentityIfNeeded(email: profile.emailAddress, displayName: displayName)

            let (raw, token) = try await client.syncInbox()
            let fetched = await ExtractionPipeline.shared.processTier1(raw)
            threads = fetched
            nextPageToken = token
            fullBodyLoadedIDs = []
            lastSyncDate = Date()
            checkSnoozeWakeUps()
            applyRules()
            if selectedThreadID == nil || !threads.contains(where: { $0.id == selectedThreadID }) {
                selectedThreadID = visibleThreads.first?.id
            }

            let updated = await client.currentTokens()
            try? keychain.setData(JSONEncoder().encode(updated), forKey: tokenKey)
        } catch {
            syncError = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard let token = nextPageToken, !isLoadingMore, let client = gmailClient else { return }
        isLoadingMore = true

        do {
            let (raw, newToken) = try await client.loadMoreThreads(pageToken: token)
            let annotated = await ExtractionPipeline.shared.processTier1(raw)
            let existingIDs = Set(threads.map { $0.id })
            threads += annotated.filter { !existingIDs.contains($0.id) }
            nextPageToken = newToken
            applyRules()
        } catch {
            syncError = error.localizedDescription
        }

        isLoadingMore = false
    }

    // MARK: - Thread actions

    func selectThread(_ id: String?) {
        withAnimation(.easeInOut(duration: 0.12)) { selectedThreadID = id }
    }

    func advance() {
        guard let id = selectedThreadID,
              let idx = visibleThreads.firstIndex(where: { $0.id == id }),
              idx + 1 < visibleThreads.count
        else { return }
        selectedThreadID = visibleThreads[idx + 1].id
    }

    func retreat() {
        guard let id = selectedThreadID,
              let idx = visibleThreads.firstIndex(where: { $0.id == id }),
              idx > 0
        else { return }
        selectedThreadID = visibleThreads[idx - 1].id
    }

    func markRead(_ id: String) {
        guard let i = threads.firstIndex(where: { $0.id == id }), !threads[i].isRead else { return }
        threads[i].isRead = true
        Task { try? await gmailClient?.modifyThread(id, removeLabels: ["UNREAD"]) }
    }

    func archive(_ id: String) {
        if selectedThreadID == id { advance() }
        threads.removeAll { $0.id == id }
        Task { try? await gmailClient?.modifyThread(id, removeLabels: ["INBOX"]) }
    }

    func sendReply(threadID: String, body: String) async {
        guard let client = gmailClient,
              let account = accounts.first,
              let thread = threads.first(where: { $0.id == threadID }),
              let lastMsg = thread.messages.last
        else { return }

        do {
            try await client.sendReply(
                threadID: threadID,
                inReplyToMessageID: lastMsg.rfc2822MessageID,
                from: account.email,
                to: [lastMsg.from.email],
                subject: thread.subject,
                plainBody: body
            )
        } catch {
            syncError = error.localizedDescription
        }
    }

    func sendNew(to toLine: String, subject: String, body: String) async {
        guard let client = gmailClient, let account = accounts.first else { return }
        let recipients = toLine
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !recipients.isEmpty else { return }
        do {
            try await client.sendNew(from: account.email, to: recipients, subject: subject, plainBody: body)
        } catch {
            syncError = error.localizedDescription
        }
    }

    // MARK: - Snooze

    func snooze(threadID: String, until wakeDate: Date) {
        settings.snooze(threadID: threadID, until: wakeDate)
        snoozedIDs = settings.activeSnoozedIDs()
        if selectedThreadID == threadID { advance() }
    }

    func snooze(threadID: String, condition: SnoozeCondition) {
        let messageCount = threads.first { $0.id == threadID }?.messages.count ?? 0
        settings.snooze(threadID: threadID, condition: condition, messageCount: messageCount)
        snoozedIDs = settings.activeSnoozedIDs()
        if selectedThreadID == threadID { advance() }
    }

    func unsnooze(threadID: String) {
        settings.unsnooze(threadID: threadID)
        snoozedIDs = settings.activeSnoozedIDs()
    }

    func checkSnoozeWakeUps() {
        settings.clearExpiredSnoozes()
        // Fire condition-based entries
        var triggered: [String] = []
        for entry in settings.snoozeEntries {
            guard entry.condition != nil,
                  let thread = threads.first(where: { $0.id == entry.threadID }),
                  entry.isTriggered(by: thread)
            else { continue }
            triggered.append(entry.threadID)
        }
        triggered.forEach { settings.unsnooze(threadID: $0) }
        snoozedIDs = settings.activeSnoozedIDs()
    }

    // MARK: - Rules

    func applyRules() {
        let enabled = settings.rules.filter { $0.isEnabled }
        guard !enabled.isEmpty else { ruleFilteredIDs = []; return }

        var toFilter: Set<String> = []
        for thread in threads {
            for rule in enabled where rule.matches(thread) {
                for action in rule.actions {
                    switch action {
                    case .skipInbox:
                        toFilter.insert(thread.id)
                    case .markAsRead:
                        if !thread.isRead {
                            if let i = threads.firstIndex(where: { $0.id == thread.id }) {
                                threads[i].isRead = true
                            }
                            Task { try? await gmailClient?.modifyThread(thread.id, removeLabels: ["UNREAD"]) }
                        }
                    case .archive:
                        toFilter.insert(thread.id)
                        Task { try? await gmailClient?.modifyThread(thread.id, removeLabels: ["INBOX"]) }
                    }
                }
                break // first matching rule wins
            }
        }
        ruleFilteredIDs = toFilter
    }

    // MARK: - Search

    func activateSearch() {
        isSearchActive = true
        searchQuery = ""
        searchResults = []
        searchResultCount = 0
        selectedThreadID = nil
    }

    func clearSearch() {
        searchTask?.cancel()
        isSearchActive = false
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    func search(query: String) {
        searchTask?.cancel()
        searchQuery = query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            searchResultCount = 0
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        guard let client = gmailClient else { return }
        isSearching = true
        let start = Date()
        do {
            let (raw, _) = try await client.searchThreads(query: query)
            let processed = await ExtractionPipeline.shared.processTier1(raw)
            guard searchQuery == query else { return }
            searchResults = processed
            searchResultCount = processed.count
            searchDuration = Date().timeIntervalSince(start)
        } catch {
            if searchQuery == query { searchResults = [] }
        }
        if searchQuery == query { isSearching = false }
    }

    /// Fetches the full thread body on demand. Safe to call repeatedly — no-ops if already loaded.
    func loadFullThread(_ id: String) async {
        guard let client = gmailClient, !fullBodyLoadedIDs.contains(id) else { return }
        guard let full = try? await client.getFullThread(id) else { return }
        if let i = threads.firstIndex(where: { $0.id == id }) { threads[i] = full }
        fullBodyLoadedIDs.insert(id)
    }

    // MARK: - Private helpers

    private func connectClient(tokens: OAuthTokens) async {
        let client = GmailAPIClient(
            tokens: tokens,
            clientID: Secrets.gmailClientID,
            clientSecret: Secrets.gmailClientSecret,
            accountID: "primary"
        )
        gmailClient = client
        isAuthenticated = true
        await syncInbox()
        startBackgroundSync()
    }

    private func startBackgroundSync() {
        backgroundSyncTask?.cancel()
        backgroundSyncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300)) // 5 min
                if !Task.isCancelled { await syncInbox() }
            }
        }
    }

    private func isFlight(_ t: MailThread) -> Bool {
        t.intelligenceResults.contains { if case .flightInfo = $0 { return true }; return false }
    }

    private func isDelivery(_ t: MailThread) -> Bool {
        t.intelligenceResults.contains { if case .packageTracking = $0 { return true }; return false }
    }

    private func isBill(_ t: MailThread) -> Bool {
        t.intelligenceResults.contains { if case .bill = $0 { return true }; return false }
    }
}
