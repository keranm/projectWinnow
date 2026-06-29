# Winnow

A quiet, local-first email client for Gmail. macOS first, iOS companion. No servers. No subscription.

## What it is

Winnow pairs a content-first reading experience with barely-there on-device intelligence — summaries, triage, package/flight/receipt extraction, suggested replies — and strong keyboard control. Everything runs on your device. Your email never leaves.

## Tech stack

| Layer | Technology |
|---|---|
| App | SwiftUI (macOS 14+ / iOS 17+) |
| Shared logic | Swift packages (WinnowCore, WinnowUI) |
| Primary sync | Gmail API (OAuth PKCE, `history.list` polling) |
| Secondary sync | IMAP/SMTP adapter (Fastmail, iCloud, Outlook) |
| Calendar | EventKit (no Google Calendar API) |
| Auth | OAuth 2.0 PKCE + macOS/iOS Keychain |
| Intelligence tier 1 | Deterministic (regex, JSON-LD schema.org, `.ics`) |
| Intelligence tier 2 | Core ML + `NLEmbedding` (triage, sender classification) |
| Intelligence tier 3 | Apple Foundation Models (summaries, replies); MLX power mode |
| Local store | Encrypted on-device, powers instant offline search |

## Repository layout

```
Apps/
  macOS/          — macOS app target (Xcode project lives here)
  iOS/            — iOS app target

Packages/
  WinnowCore/     — provider-agnostic sync engine, models, auth, intelligence
  WinnowUI/       — shared SwiftUI components and design system

design_handoff_winnow/   — design reference files (HTML prototypes, read-only)

docs/
  architecture.md       — how the pieces connect
  design-system.md      — tokens, components, the "Quiet" language
  decisions/            — Architecture Decision Records (ADRs)
```

## Getting started

> Prerequisites: Xcode 16+, macOS 14 Sonoma or later.

1. Clone the repo
2. Open `Apps/macOS/Winnow.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Add a `Config/Secrets.swift` (git-ignored) with your OAuth client ID:
   ```swift
   enum Secrets {
       static let gmailClientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
   }
   ```
5. Build & run (`⌘R`)

## Design references

The `design_handoff_winnow/` folder contains HTML prototypes for every screen. Open them in a browser to inspect exact colours, spacing, and copy. **Winnow Design Spec.dc.html** is the canonical starting point.

See [docs/design-system.md](docs/design-system.md) for the extracted token reference.

## Contributing

See [docs/contributing.md](docs/contributing.md). Issues and PRs are managed on GitHub.

## Privacy promise

Tokens live in the Keychain. Requests go straight from your device to Google. There are no Winnow servers in the path — the privacy guarantee holds at the network layer, not just the UI.

## Licence

TBD.
