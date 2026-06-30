import SwiftUI

@main
struct WinnowApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 760)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                Divider()
                Button("Sign Out") { appState.signOut() }
            }

            CommandMenu("Mail") {
                Button("Compose New") { appState.isComposing = true }
                    .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Refresh") { Task { await appState.syncInbox() } }
                    .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Archive") {
                    if let id = appState.selectedThreadID { appState.archive(id) }
                }
                .keyboardShortcut("e", modifiers: [])

                Button("Mark as Read") {
                    if let id = appState.selectedThreadID { appState.markRead(id) }
                }
                .keyboardShortcut("m", modifiers: [])
            }

            CommandMenu("Navigate") {
                Button("Today") { appState.selectedNavItem = .today }
                    .keyboardShortcut("1", modifiers: .command)

                Button("Inbox") { appState.selectedNavItem = .other }
                    .keyboardShortcut("2", modifiers: .command)

                Button("Trips & Deliveries") { appState.selectedNavItem = .trips }
                    .keyboardShortcut("3", modifiers: .command)

                Button("Subscriptions") { appState.selectedNavItem = .subscriptions }
                    .keyboardShortcut("4", modifiers: .command)

                Divider()

                Button("Next Thread") { appState.advance() }
                    .keyboardShortcut("j", modifiers: [])

                Button("Previous Thread") { appState.retreat() }
                    .keyboardShortcut("k", modifiers: [])
            }
        }
    }
}
