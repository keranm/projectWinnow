# Architecture

## Principle: no servers, ever

Every request goes from the device straight to Gmail's API (or the IMAP/SMTP endpoint). There is no Winnow backend, no relay, no analytics endpoint. This isn't a feature — it's a constraint that shapes everything.

## High-level diagram

```
┌──────────────────────────────────┐
│             Your device           │
│                                  │
│  ┌──────────┐  ┌───────────────┐ │
│  │  Winnow  │  │ Local store   │ │
│  │  (app)   │  │ (encrypted)   │ │
│  └────┬─────┘  └───────────────┘ │
│       │                          │
│  ┌────▼──────────────────────┐   │
│  │     Sync Engine           │   │
│  │  (provider-agnostic)      │   │
│  │                           │   │
│  │  ┌─────────┐ ┌─────────┐  │   │
│  │  │ Gmail   │ │  IMAP/  │  │   │
│  │  │Adapter  │ │  SMTP   │  │   │
│  │  └────┬────┘ └────┬────┘  │   │
│  └───────┼───────────┼───────┘   │
│          │           │           │
│  ┌───────▼───────────▼────────┐  │
│  │     Auth (OAuth PKCE)      │  │
│  │     Keychain storage       │  │
│  └────────────────────────────┘  │
└──────────┬───────────┬───────────┘
           │           │
    Gmail API      IMAP/SMTP
```

## Sync strategy

**Gmail accounts** use the Gmail API exclusively:
- Initial sync: paginated `users.messages.list`, headers first, bodies on open
- Incremental: store `historyId`, poll `users.history.list` on foreground + 30s timer + iOS background refresh
- No Cloud Pub/Sub (`watch`) — that requires a webhook server

**Non-Gmail accounts** (Fastmail, iCloud, Outlook) use an IMAP adapter behind the same `SyncEngine` protocol. The app doesn't know which adapter is active.

## Intelligence tiers

Always route to the cheapest tier that can handle the task.

| Tier | What | When |
|------|------|------|
| 1 | Deterministic (regex, JSON-LD, `.ics`, schema.org) | Packages, flights, hotels, receipts, bills, OTPs |
| 2 | Core ML + `NLEmbedding` | Triage priority, needs-reply, sender classification, project grouping |
| 3 | Apple Foundation Models (default) or MLX (plugged-in Mac) | Summaries, suggested replies, draft assist |

Cloud models are off by default and require the user to supply their own API key. Nothing calls home.

## Calendar integration

Winnow reads free/busy data from EventKit — which already aggregates Google Calendar, iCloud Calendar, and Exchange locally. No Google Calendar API scope is needed. RSVP responses are sent via `messages.send` through the invite's own account.

## Auth

- OAuth 2.0 with PKCE, no client secret needed
- Tokens stored in macOS/iOS Keychain, never on disk in plaintext
- Gmail scopes: `gmail.modify` + `https://mail.google.com/` (requires Google OAuth verification + annual CASA audit for public release)
- Token refresh handled by the `AuthService`, transparent to the rest of the app

## Local store

A single encrypted SQLite database (via GRDB or similar) per account, keyed by a Keychain-stored key. Powers:
- Instant offline search (Gmail `q=` syntax parity)
- Full offline read
- Outbox queue (sends on reconnect)
- Intelligence caches (extraction results, embeddings)

## Packages

### WinnowCore

Pure Swift, no UIKit/AppKit/SwiftUI dependency. Testable in isolation.

- `Models/` — `Thread`, `Message`, `Label`, `Account`, `Identity`, `Attachment`
- `Services/Gmail/` — `GmailAPIClient`, `GmailSyncAdapter`
- `Services/IMAP/` — `IMAPAdapter`, `SMTPSender`
- `Services/Sync/` — `SyncEngine` protocol + `SyncCoordinator`
- `Storage/` — `MailStore`, migrations
- `Auth/` — `AuthService`, `KeychainStore`
- `Intelligence/` — `ExtractionPipeline`, tier dispatch

### WinnowUI

SwiftUI components and the design system. Depends on WinnowCore for types.

- `DesignSystem/` — `WinnowColors`, `WinnowTypography`, `WinnowSpacing`
- `Components/` — `AssistDiamond`, `KeycapView`, `ToggleRow`, `ThreadRow`, `AssistSummaryCard`

## Known constraints

- **Google OAuth verification**: required before the app can be published. CASA audit annually thereafter.
- **Push latency**: polling means ~30s delay vs instant push. Acceptable for a quiet, focused client.
- **MLX on iOS**: not available. iOS uses Apple Foundation Models only.
