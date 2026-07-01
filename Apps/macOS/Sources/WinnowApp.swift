import SwiftUI
import AppKit

@main
struct WinnowApp: App {
    @NSApplicationDelegateAdaptor(WinnowAppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appState.settings)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 880)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                Divider()
                Button("Sign Out") { appState.signOut() }
            }

            CommandMenu("View") {
                Button("Command Bar") { appState.showCommandBar.toggle() }
                    .keyboardShortcut("/", modifiers: .command)
            }

            CommandMenu("Mail") {
                Button("Compose New") { appState.isComposing = true }
                    .keyboardShortcut("n", modifiers: .command)

                Button("Search") { appState.activateSearch() }
                    .keyboardShortcut("f", modifiers: .command)

                Divider()

                Button("Refresh") { Task { await appState.syncInbox() } }
                    .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Archive") {
                    if let id = appState.selectedThreadID { appState.archive(id) }
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Mark as Read") {
                    if let id = appState.selectedThreadID { appState.markRead(id) }
                }
                .keyboardShortcut("m", modifiers: .command)
            }

            CommandMenu("Navigate") {
                Button("Today")         { appState.selectedNavItem = .today }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Inbox")         { appState.selectedNavItem = .other }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Trips")         { appState.selectedNavItem = .flights }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Deliveries")    { appState.selectedNavItem = .deliveries }
                    .keyboardShortcut("4", modifiers: .command)
                Button("Subscriptions") { appState.selectedNavItem = .subscriptions }
                    .keyboardShortcut("5", modifiers: .command)

                Divider()

                Button("Next Thread")     { appState.advance() }
                    .keyboardShortcut("j", modifiers: .command)
                Button("Previous Thread") { appState.retreat() }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }

        // ── Settings window (⌘,) ───────────────────────────────────────────
        Settings {
            SettingsView()
                .environment(appState.settings)
                .environment(appState)
        }
    }
}

// MARK: - App delegate
//
// willOrderOnScreenNotification fires before the window is drawn — the only reliable hook
// that guarantees fullSizeContentView is set before SwiftUI commits its initial layout pass.
// Filtering by width ≥ 1000 skips the Settings window.

final class WinnowAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowBecameKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        // Configure any windows already open at launch
        NSApplication.shared.windows.forEach(configureIfMain(_:))
    }

    @objc private func windowBecameKey(_ note: Notification) {
        guard let window = note.object as? NSWindow else { return }
        configureIfMain(window)
    }

    private func configureIfMain(_ window: NSWindow) {
        guard window.styleMask.contains(.titled),
              !window.styleMask.contains(.fullSizeContentView),
              window.frame.width >= 900 else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.toolbar = nil
    }
}
