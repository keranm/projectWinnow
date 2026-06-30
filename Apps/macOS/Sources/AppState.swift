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
    var syncError: String?
    var lastSyncDate: Date?

    // Derived
    var selectedThread: MailThread? {
        guard let id = selectedThreadID else { return nil }
        return threads.first { $0.id == id }
    }

    var visibleThreads: [MailThread] {
        switch selectedNavItem {
        case .today, .important:
            return threads.filter { $0.labels.contains("IMPORTANT") || $0.needsReply }
        case .trips:
            return threads.filter { $0.intelligenceResults.contains { if case .flightInfo = $0 { return true }; if case .packageTracking = $0 { return true }; return false } }
        case .subscriptions:
            return threads.filter { $0.intelligenceResults.contains { if case .bill = $0 { return true }; return false } }
        default:
            return threads.filter { $0.labels.contains("INBOX") }
        }
    }

    // Internal
    private var gmailClient: GmailAPIClient?
    private let keychain = KeychainStore()
    private let tokenKey = "oauth_tokens_primary"
    private var fullBodyLoadedIDs: Set<String> = []

    // MARK: - Lifecycle

    func bootstrap() async {
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
        keychain.delete(forKey: tokenKey)
        gmailClient = nil
        isAuthenticated = false
        threads = []
        accounts = []
        selectedThreadID = nil
    }

    // MARK: - Sync

    func syncInbox() async {
        guard let client = gmailClient else { return }
        isLoading = true
        syncError = nil

        do {
            let profile = try await client.getProfile()
            accounts = [Account(
                id: "primary",
                email: profile.emailAddress,
                displayName: profile.emailAddress.components(separatedBy: "@").first?.capitalized,
                provider: .gmail,
                color: .blue
            )]

            let fetched = try await client.syncInbox()
            threads = fetched
            lastSyncDate = Date()
            if selectedThreadID == nil { selectedThreadID = threads.first?.id }

            // Persist refreshed tokens back to Keychain
            let updated = await client.currentTokens()
            try? keychain.setData(JSONEncoder().encode(updated), forKey: tokenKey)
        } catch {
            syncError = error.localizedDescription
        }

        isLoading = false
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
        if let i = threads.firstIndex(where: { $0.id == id }) { threads[i].isRead = true }
    }

    func archive(_ id: String) {
        threads.removeAll { $0.id == id }
    }

    /// Fetches the full thread body on demand. Safe to call repeatedly — no-ops if already loaded.
    func loadFullThread(_ id: String) async {
        guard let client = gmailClient, !fullBodyLoadedIDs.contains(id) else { return }
        guard let full = try? await client.getFullThread(id) else { return }
        if let i = threads.firstIndex(where: { $0.id == id }) {
            threads[i] = full
        }
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
    }

    private func loadMockData() {
        #if DEBUG
        threads = MockData.threads
        accounts = MockData.accounts
        selectedThreadID = MockData.threads.first?.id
        #endif
    }
}
