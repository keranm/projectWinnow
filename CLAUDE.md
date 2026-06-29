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

## Design language — "Quiet"

Near-monochrome, generous whitespace, hairline dividers, minimal colour, rare motion.

- Accent blue `#2F6BDB` (light) / `#4F8EF0` (dark) — used sparingly
- The **assist diamond** (rotated 45° filled square in accent) = "produced by on-device intelligence." It must appear consistently wherever intelligence surfaces a result
- Selected row: `accentTint` background + 2px accent bar on the leading edge
- SF Pro (system-ui) for all text; SF Mono (ui-monospace) for times, amounts, tracking numbers, shortcuts
- Replace all Unicode glyphs in the mocks with SF Symbols (see `docs/design-system.md` glyph mapping)

## ADRs

Architectural decisions that are settled — don't re-litigate without a new issue:

- [ADR 001](docs/decisions/001-no-server-architecture.md) — no server, ever
- [ADR 002](docs/decisions/002-gmail-api-over-imap.md) — Gmail API primary, IMAP adapter secondary
- [ADR 003](docs/decisions/003-eventkit-over-google-calendar-api.md) — EventKit, no Google Calendar scope

## GitHub workflow

- Issues tracked on GitHub: https://github.com/keranm/projectWinnow/issues
- Branch naming: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `design/`
- PRs: one logical change, one approval before merge

## Common tasks

**Adding a new screen:**
1. Check the corresponding `.dc.html` file in `design_handoff_winnow/`
2. Create the view in `Packages/WinnowUI/Sources/WinnowUI/` or the app target
3. Use design tokens from `WinnowColors`, `WinnowTypography`, `WinnowSpacing`
4. Add the assist diamond wherever intelligence results appear

**Adding a new intelligence extraction:**
1. Determine which tier (deterministic regex → Core ML → Foundation Models)
2. Implement in `Packages/WinnowCore/Sources/WinnowCore/Intelligence/`
3. Register in `ExtractionPipeline`
4. Unit test the deterministic path exhaustively

**Adding a new setting:**
1. Check `Winnow Settings.dc.html` for the UI spec
2. Persist in iCloud Key-Value Store (not UserDefaults) for cross-device sync
3. No server-side storage
