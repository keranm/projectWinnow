import SwiftUI
import WinnowCore

@Observable
@MainActor
final class AppState {
    var threads: [MailThread] = []
    var accounts: [Account] = []
    var selectedNavItem: NavItem = .today
    var selectedThreadID: String? = nil
    var syncStatus: SyncStatus = .synced

    var selectedThread: MailThread? {
        guard let id = selectedThreadID else { return nil }
        return threads.first { $0.id == id }
    }

    var visibleThreads: [MailThread] {
        switch selectedNavItem {
        case .today, .important:
            return threads.filter { $0.labels.contains("IMPORTANT") }
        case .trips:
            return threads.filter { thread in
                thread.intelligenceResults.contains { if case .flightInfo = $0 { return true } else if case .packageTracking = $0 { return true }; return false }
            }
        case .subscriptions:
            return threads.filter { thread in
                thread.intelligenceResults.contains { if case .bill = $0 { return true }; return false }
            }
        default:
            return threads.filter { $0.labels.contains("INBOX") }
        }
    }

    enum SyncStatus {
        case syncing, synced, offline, error(String)
    }

    init() {
        #if DEBUG
        threads = MockData.threads
        accounts = MockData.accounts
        selectedThreadID = MockData.threads.first?.id
        #endif
    }

    func selectThread(_ id: String?) {
        withAnimation(.easeInOut(duration: 0.12)) {
            selectedThreadID = id
        }
    }

    func advance() {
        guard let currentID = selectedThreadID,
              let idx = visibleThreads.firstIndex(where: { $0.id == currentID }),
              idx + 1 < visibleThreads.count
        else { return }
        selectedThreadID = visibleThreads[idx + 1].id
    }

    func retreat() {
        guard let currentID = selectedThreadID,
              let idx = visibleThreads.firstIndex(where: { $0.id == currentID }),
              idx > 0
        else { return }
        selectedThreadID = visibleThreads[idx - 1].id
    }

    func markRead(_ id: String) {
        if let idx = threads.firstIndex(where: { $0.id == id }) {
            threads[idx].isRead = true
        }
    }

    func archive(_ id: String) {
        threads.removeAll { $0.id == id }
        // TODO: send gmail.modify patch via GmailAPIClient
    }
}
