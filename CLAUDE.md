# Winnow — Claude context

## What this project is

Winnow is a local-first, privacy-respecting email client for Gmail. macOS primary, iOS companion. No servers, no subscription. Everything runs on device.

Core promise: **tokens in the Keychain, requests straight from the device, no Winnow servers in the path — ever.**

## Design handoff

All screens have been designed. The source of truth lives in `design_handoff_winnow/*.dc.html` — open these in a browser to inspect exact styling. Start with:

1. `Winnow Design Spec.dc.html` — canonical tokens and component inventory
2. `Winnow Mail.dc.html` — core 3-pane layout (use the **Quiet** direction only; Native and Editorial are rejected)
3. `Winnow Today.dc.html` — smart landing screen

The extracted design tokens are in `docs/design-system.md`. Never hardcode hex values — always use `WinnowColors`.

## Architecture

See `docs/architecture.md` for the full picture. Key rules:

- **No new server calls.** All network traffic goes device → Gmail API (or IMAP/SMTP). If something seems to require a server, raise it as a design deviation issue before building.
- `WinnowCore` must stay free of UIKit/AppKit/SwiftUI imports — it's a pure Swift package.
- Intelligence always routes through `ExtractionPipeline` tier-dispatch, never called directly from a view.
- Calendar = EventKit. We have no Google Calendar API scope.

## Tech stack at a glance

- Swift 6, SwiftUI (macOS 14+ / iOS 17+)
- Packages: `WinnowCore` (logic), `WinnowUI` (components + design system)
- Gmail API via URLSession, OAuth PKCE, tokens in Keychain
- IMAP/SMTP adapter for non-Gmail
- Core ML + NLEmbedding (tier 2 intelligence)
- Apple Foundation Models / MLX (tier 3, off by default)
- EventKit for calendar free/busy

## Current implementation status (as of 2026-07-02)

**Working end-to-end:**
- Gmail OAuth PKCE → Keychain → live inbox sync every 5 min
- Local thread store (`ThreadCache`, WinnowCore/Storage): launch paints from disk instantly, sync refreshes behind it; debounced saves on every thread mutation; cleared on sign-out
- 3-pane mail layout: sidebar nav, thread list, reading pane with HTML rendering
- Reply (with threading) and compose new (⌘N) — NSTextView-backed rich editor (`RichTextEditor.swift`): native newlines/undo/paste, ⌘B/I/U + ⌘K link while focused, floating formatting bar on selection; formatted mail goes out as multipart/alternative (plain + HTML)
- Archive (`e`), mark-read (`m`), pagination, keyboard navigation (j/k)
- Today screen: greeting, needs-reply, due-soon, trips/deliveries cards
- Intelligence Tier 1: `PackageExtractor`, `FlightExtractor`, `BillExtractor`, `SummaryExtractor`, `CalendarEventExtractor` (regex-based, on-device, all routed through `ExtractionPipeline`; unit tests in `WinnowCoreTests`)
- Intelligence Tier 2: `ToneClassifier` (WinnowCore/Intelligence/CoreML) — NLEmbedding zero-shot tone scoring (personal/transactional/marketing) via `ExtractionPipeline.processTier2`, gated by the "Triage & needs-reply" toggle. Promoter-only in `InboxTriage`. Correspondent list seeded by a weekly SENT-mail metadata sweep (`listSentCorrespondents`), persisted in settings.
- Intelligence Tier 3: `GenerationEngine` (WinnowCore/Intelligence/Foundation) on Apple Foundation Models — generative ⌘/ summaries, suggested-reply chips on thread open, background "Draft ready" drafts for needs-reply threads. Requires macOS 26 + Apple Intelligence enabled; falls back to Tier 1 silently when unavailable. Gated by `settings.assistanceLevel != .off`.
- Calendar free/busy — EventKit only (ADR 003): invite detail view w/ free/busy rail, conflict card, inline RSVP; "Find a time" in reply + compose; Settings → Calendar
- Search — Gmail-backed, debounced, keyboard nav
- Snooze + Rules — on-device triage, popover + action bar
- Dark mode — token wash across the app
- ⌘/ command bar (⌘K reserved for prev-thread nav), incl. "Summarize this thread"
- Settings window (⌘,): Accounts/Identities, Signatures, Snippets, Rules, Calendar, Intelligence, General, Shortcuts, Lab
- Signatures: auto-appended in compose and on first reply-field focus
- Signing config locked in `project.yml` — no provisioning-profile errors after xcodegen

**Not yet built (priority order):**
1. Tier 2 extensions — project grouping via embeddings; hotels/quotes/subscriptions extractors (Intelligence settings already shows their toggles)
2. iOS companion target
3. Push notifications
4. iCloud KV Store for settings (currently UserDefaults — CLAUDE.md says KV Store)

## Design language — "Quiet"

Near-monochrome, generous whitespace, hairline dividers, minimal colour, rare motion.

- Accent blue `#2F6BDB` (light) / `#4F8EF0` (dark) — used sparingly
- The **assist diamond** (rotated 45° filled square in accent) = "produced by on-device intelligence." It must appear consistently wherever intelligence surfaces a result
- Selected row: `accentTint` background + 2px accent bar on the leading edge
- SF Pro (system-ui) for all text; SF Mono (ui-monospace) for times, amounts, tracking numbers, shortcuts
- Replace all Unicode glyphs in the mocks with SF Symbols (see `docs/design-system.md` glyph mapping)
- **Text colour hierarchy (4 levels):** `winnowText` → `winnowTextSubdued` → `winnowTextSecondary` → `winnowTextTertiary` → `winnowTextQuaternary`

## ADRs

Architectural decisions that are settled — don't re-litigate without a new issue:

- [ADR 001](docs/decisions/001-no-server-architecture.md) — no server, ever
- [ADR 002](docs/decisions/002-gmail-api-over-imap.md) — Gmail API primary, IMAP adapter secondary
- [ADR 003](docs/decisions/003-eventkit-over-google-calendar-api.md) — EventKit, no Google Calendar scope

## GitHub workflow

- Issues tracked on GitHub: https://github.com/keranm/projectWinnow/issues
- Branch naming: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `design/`
- PRs: one logical change, one approval before merge
- **Push directly to `main`** — Keran has granted blanket permission for this project

## Common tasks

**After any new Swift file is added / directory structure changes:**
```
cd /Users/keran/Development/projectWinnow/Apps/macOS
xcodegen generate
```
This regenerates `Winnow.xcodeproj`. The `project.yml` already has signing locked in (`CODE_SIGN_STYLE: Automatic`, `DEVELOPMENT_TEAM: AUEPCDGA5G`) so the provisioning error won't reappear.

**Adding a new screen:**
1. Check the corresponding `.dc.html` file in `design_handoff_winnow/`
2. Create the view in `Packages/WinnowUI/Sources/WinnowUI/` or the app target under `Apps/macOS/Sources/Views/`
3. Use design tokens from `WinnowColors`, `WinnowTypography`, `WinnowSpacing`
4. Add the assist diamond wherever intelligence results appear
5. Run `xcodegen generate` then build

**Avatar colours (sender initials):**
Hash-based palette used consistently across Today, sidebar, and reading pane:
```swift
let palette: [(bg: String, fg: String)] = [
    ("fbe7ea","c0566c"), ("e8eafb","5a5fc0"), ("e4f0e8","4f9168"),
    ("f3ece0","a07d3a"), ("dbe6f8","2f6bdb"), ("eef0f4","6a7184"),
]
let idx = abs(identifier.hashValue) % palette.count
```
Use the sender's email as the hash key for consistency across sessions.

**Adding a new setting:**
1. Check `Winnow Settings.dc.html` for the UI spec
2. Add the property to `WinnowSettings` (`Apps/macOS/Sources/Settings/WinnowSettings.swift`)
3. Add `save()` / `load()` entries for the new property
4. Note: currently persists to UserDefaults — the intent (CLAUDE.md + ADR) is iCloud KV Store; migrate when implementing cross-device sync
5. `WinnowSettings` is a singleton injected via `.environment(appState.settings)` — do NOT create a second instance

**Adding a new intelligence extraction:**
1. Determine which tier (deterministic regex → Core ML → Foundation Models)
2. Implement in `Packages/WinnowCore/Sources/WinnowCore/Intelligence/`
3. Register in `ExtractionPipeline`
4. Unit test the deterministic path exhaustively

**SourceKit "No such module" errors:**
These are pre-build LSP false alarms — the packages aren't resolved until Xcode builds. Run the build; it succeeds. Ignore SourceKit squiggles on `import WinnowCore` / `import WinnowUI`.
