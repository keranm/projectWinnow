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
            CommandMenu("Mail") {
                Button("Compose") {}
                    .keyboardShortcut("n", modifiers: .command)
                Divider()
                Button("Archive") {}
                    .keyboardShortcut("e", modifiers: [])
                Button("Reply") {}
                    .keyboardShortcut("r", modifiers: [])
            }
            CommandMenu("Navigate") {
                Button("Next Thread") {}
                    .keyboardShortcut("j", modifiers: [])
                Button("Previous Thread") {}
                    .keyboardShortcut("k", modifiers: [])
                Button("Back to List") {}
                    .keyboardShortcut("u", modifiers: [])
            }
        }
    }
}
