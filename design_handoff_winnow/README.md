# Handoff: Winnow — local-first Gmail client (macOS + iOS)

## Overview
Winnow is a quiet, local-first, privacy-respecting email client for Gmail, targeting **macOS (primary)** and **iOS (secondary)**. It runs entirely on-device: no servers, nothing shared, no subscription. It pairs a content-first reading experience with *barely-there* on-device intelligence (summaries, triage, extraction of packages/flights/hotels/quotes, suggested replies) and powerful keyboard control.

This bundle contains the full design surface: the desktop 3-pane app, onboarding, smart landing, the "smarts" extraction views, settings (intelligence, accounts, calendar, notifications, rules, integrations, signatures), command bar + triage, multi-account/search, iOS key screens, dark mode, empty/loading/offline/error states, an architecture one-pager, and a design-spec/tokens page.

## About the Design Files
The files in this bundle are **design references created in HTML** — prototypes showing intended look and behaviour, **not production code to copy directly**. They are authored as "Design Components" (`.dc.html`); treat them as visual+behavioural specs.

The task is to **recreate these designs in the target codebase's environment**. For Winnow that almost certainly means **native Apple platforms — SwiftUI (macOS + iOS), sharing a Swift core** — since the product depends on EventKit (Apple Calendar), Keychain, on-device ML (Core ML / NaturalLanguage), and Apple Foundation Models / MLX. Use the platform's native components and patterns; do not ship the HTML. The HTML's exact colours, type, spacing and copy are authoritative for visual fidelity.

## Fidelity
**High-fidelity.** Final colours, typography, spacing, copy, and interaction intent. Recreate pixel-faithfully using native controls. The one liberty: glyphs in the mocks use Unicode stand-ins (e.g. `◷ ✈ ▣ ⌫ ◆ ⌗`) — replace with SF Symbols (`clock`, `airplane`, `shippingbox`, `archivebox`, `sparkles`/custom diamond, `tag`, etc.).

## Design language — "Quiet"
- Near-monochrome, generous whitespace, **hairline dividers** (`rgba(0,0,0,.05–.08)`), minimal colour, rare/short motion.
- **Type:** `system-ui` everywhere → map to **SF Pro** natively. `ui-monospace` → **SF Mono** for times, amounts, tracking numbers, shortcuts, technical strings. (Note: the HTML deliberately avoids `-apple-system` alone because it renders serif in Chromium — irrelevant natively, but it's why you see `system-ui`.)
- **Accent:** `#2F6BDB` (calm blue), used sparingly — selection, primary action, links, and the assist marker only.
- **Assist diamond:** a small rotated 45° square in accent blue (`.di`) that **always means "produced by on-device intelligence."** It is the product's signature mark — reproduce it consistently (a filled diamond / `sparkles`-equivalent).
- **Selected state:** background `#EEF3FC` + `inset 2px 0 #2F6BDB` (a 2px accent bar on the leading edge).

## Design Tokens
**Colour**
- Text `#1C1C20` · Secondary `#55555C` · Tertiary `#9A9AA0`
- Sidebar `#FAFAFA` · Surface `#FFFFFF` · Stage/behind `#ECECED`
- Accent `#2F6BDB` · Accent tint `#EEF3FC`
- Success `#2F9E6F` · Caution `#C08A4A` · Alert `#D9534F`
- Borders/hairlines `rgba(0,0,0,.05)`–`rgba(0,0,0,.08)`
- **Dark mode:** Surface `#1C1C1E` · Sidebar/chrome `#161617` · App bg `#0E0E10` · Accent `#4F8EF0` · Accent-tint/selection `#20304D` · Text `#F2F2F5` · Secondary `#A0A0A8` · Tertiary `#6A6A72` · hairlines `rgba(255,255,255,.07)`

**Type scale** (size/weight) — Display 30/600 (tracking −.02em) · Title 22/600 · Body 14/400 (line-height ~1.6) · Label 13/500 · Section header 11/600 uppercase tracking .05em colour `#9AA6BB` · Meta 11 mono.

**Radius** — rows/controls 7px · cards 11–13px · sheets/large 16px · pills/chips full (14–20px) · toggles 11–12px.

**Spacing** — 4px rhythm. Row padding 11–14px; card padding 14–18px; window/section padding 26–34px. Gaps via fl/grid `gap`, not margins.

**Toggle** — 40×23 track, 19px knob, on = `#2F6BDB`, off = `#D8D8DE`. **Keycap (`.kbd`)** — mono 11px, white bg, `border:1px solid rgba(0,0,0,.16)` with 2px bottom border, radius 6.

**Shadows** — window `0 24px 70px rgba(20,22,45,.18), 0 2px 6px rgba(0,0,0,.05)`; popover `0 22px 55px rgba(10,12,30,.26)`; command palette `0 30px 80px rgba(10,12,30,.34)`.

## Core layout (desktop 3-pane)
- **Window chrome:** 46px title bar, traffic-light dots left, centered "Winnow" wordmark in `#9A9AA0`.
- **Sidebar** ~212–228px, bg `#FAFAFA`, right hairline. Account chip at top; nav rows (Today, Important, Other); "Pulled from mail" section (Trips & deliveries, Quotes, Subscriptions, Calendar); footer status row with green dot + "On-device · synced 2m ago".
- **List column** ~316–356px, right hairline. Section title; rows = unread dot (accent `#2F6BDB` / transparent) + sender (600/13.5) + time (mono 11, right) + subject (500/13) + preview (400/12.5 `#8A8A90`), truncated; selected row uses the selected-state recipe.
- **Reading pane** flex-1, `#FFFFFF`, padding 26–34px. Title 22/600; participants meta; **assist summary block** (bg `#F7F9FC`, border `rgba(47,107,219,.10)`, radius 9, leading diamond, "SUMMARY" eyebrow); message with avatar; collapsed earlier messages. **Compose footer:** suggested-reply chips (outline) then a reply field with primary Send.

## Screens / Views (file → what it shows)
- **Winnow Mail** — three aesthetic directions explored early: **Quiet** (chosen), **Native** (frosted/dense + ⌘K), **Editorial** (warm/serif). *Build the Quiet direction;* the other two are rejected alternates kept for reference.
- **Winnow Quiet Flow** — Welcome/connect Gmail → Privacy & sync setup (toggles) → Inbox → Compose w/ attachments → Send-later popover.
- **Winnow Today** — smart landing. Greeting + on-device briefing line; **Needs a reply** (hero, with "Draft ready" diamond chip), **Following up**, **Due soon** (bills/renewals, ↑ price-change in caution), **Trips & deliveries**, **Projects** grid, agent-activity strip. Has assistance modes (Suggest / Auto-file / Off) and a showProjects flag.
- **Winnow Smarts** — on-device extraction: package tracking card (stepper), Trip detail (flights+hotel grouped), Detection settings (per-type toggles, each labelled code vs. ML), Project quotes gathered across threads.
- **Winnow Settings** — Settings → Intelligence: engine choice (On-device Apple Foundation Models = active; Mac power model MLX = downloadable; BYO API key = off/"leaves device"), assistance level segmented, "what runs locally" toggles, privacy ledger (0 B sent / trackers blocked / etc.).
- **Winnow Snooze & Projects** — conditional **smart snooze** popover ("when they reply", "I get home", "trip starts" — on-device watchers) + full **Project page** (threads, tags/multi-tag, next-steps checklist, quotes, files).
- **Winnow Aliases & Snippets** — compose From-alias auto-matched to the address mail was sent to; Settings → identities table (sends-via + signature per identity); Snippets manager (`;shortcut` + placeholders); inline `;shortcut` expansion w/ autocomplete in compose.
- **Winnow Calendar** — inline invite RSVP with **Apple Calendar (EventKit) free/busy** timeline + on-device conflict detection + suggested free slot; "Find a time" in compose; Settings → Calendar (EventKit source, calendar visibility w/ colours, working hours, conflict toggles).
- **Winnow Integrations** — directory (Calendly connected, Cal.com, Apple Reminders = on-device, Todoist, Things/Linear soon); OAuth consent sheet stating exactly what's shared ("never sees your email content"); compose inserting a Calendly booking link.
- **Winnow Notifications & Rules** — notification settings (Important-only by default, VIPs, silent for newsletters, honour macOS Focus, quiet hours); sample macOS notification (actionable, rare); **Rules builder** (when/then, optional "also save as Gmail filter"); **Vacation responder** (token-aware).
- **Winnow Accounts & Search** — **Unified inbox** (per-account colour dots), Accounts settings (colours, profiles, working hours, "mute during Focus"), **Search** (instant, Gmail `q=` syntax, grouped People/Messages/Attachments, filter chips), **Person/contact view** (stats, recent threads, shared files/projects).
- **Winnow Command & Triage** — **⌘K command bar** over faded inbox (contextual actions + "Ask Winnow" on-device); **Triage-to-Zero** focused one-at-a-time mode w/ keyboard legend; **Inbox Zero** end state; **Keyboard map** (`?`).
- **Winnow iOS** — iPhone key screens (Today, Inbox w/ glance cards + compose FAB, Thread + reply, Smart-snooze sheet). Uses a device frame in the mock; build natively. Shares the Quiet language and `system-ui`/SF Pro.
- **Winnow Dark** — dark-mode core 3-pane (token reference above).
- **Winnow States** — Empty, Loading (skeleton), Offline (amber banner + readable local mailbox + queued sends), Error (token expired / 401, local copy still shown).
- **Winnow Architecture** — "How Winnow connects" one-pager (Gmail API primary; IMAP/SMTP secondary adapter; poll `history.list`, no Pub/Sub; OAuth PKCE + Keychain).
- **Winnow Design Spec** — the canonical tokens + component inventory + principles page (start here).

## Interactions & Behaviour
- **Selection/nav:** single-select list with the selected-state bar; `J/K` move, `U` back to list, `G T`/`G I` go-to.
- **Triage:** single-key `E` archive, `S` snooze, `R` reply, `Y` done, `L` label, `M` move, `X` select, `→` skip; Triage-to-Zero advances one card at a time with a progress bar and ends on the Zero screen.
- **Command bar:** ⌘K opens a centered palette (scrim `rgba(20,22,40,.26)`), fuzzy input, grouped results (contextual actions, go-to, "Ask Winnow · on-device"); Esc closes.
- **Compose:** alias From auto-matches the incoming address; `;shortcut` triggers snippet autocomplete; placeholders (`first name`, `date`, `calendar link`, booking link) resolve **at send time**; Send / Send & archive (⇧⌘↵) / Undo send (⌘Z); Send-later and Schedule popovers.
- **Snooze:** time presets + **conditional** triggers watched on-device.
- **Calendar:** RSVP Yes/Maybe/No writes back via the invite's own account (no separate Google Calendar scope); conflicts computed locally from EventKit free/busy; "Find a time" proposes slots inside working hours.
- **Motion:** rare and short — favour quick fades/translations; no gratuitous animation.

## State Management (conceptual)
- **Sync:** provider-agnostic layer. Gmail account → Gmail API; stored `historyId` + `users.history.list` for incremental deltas; poll on foreground + timer + iOS background refresh (no Pub/Sub `watch` — would need a server). Non-Gmail → IMAP/SMTP adapter.
- **Local store:** full message/thread/label store on device powering instant search (Gmail `q=` parity) and full offline read/search/compose; replies queue offline and send on reconnect.
- **Intelligence tiers:** (1) deterministic code — packages, flights, hotels, receipts, bills, OTP (regex / templates / `.ics` / schema.org JSON-LD); (2) small on-device ML — triage, needs-reply, sender-type, project grouping (Core ML / `NLEmbedding`); (3) on-device LLM — summaries, suggested replies, draft assist (Apple Foundation Models default; MLX "power mode" on plugged-in Macs; optional BYO cloud key, **off by default**). Always route to the cheapest tier that works.
- **Assistance modes:** Suggest (default) / Auto-file / Off — affects whether drafts/triage are surfaced vs. applied, and the Today agent strip copy.
- **Identities:** per-address send-route + signature; auto-select reply identity from the address mail was sent to.
- **Auth:** OAuth 2.0 (PKCE), tokens in macOS/iOS Keychain, all requests direct from device. Restricted Gmail scopes require Google OAuth verification + annual CASA audit before public release.

## Connectivity (decided architecture)
- **Primary:** Gmail API for the Gmail account (native labels/threads, `q=` search, partial fetch, `messages.send` honouring verified send-as aliases, incremental `history.list`).
- **Secondary:** IMAP/SMTP adapter for non-Gmail accounts (Fastmail/iCloud/Outlook). Sync layer provider-agnostic.
- **Sending:** Gmail API for Gmail identities; SMTP for non-Gmail identities.
- **Push:** poll `history.list` (no Cloud Pub/Sub — keeps the no-servers promise).
- **Calendar:** Apple Calendar via **EventKit** (already aggregates Google/iCloud/Exchange locally) — no Google Calendar API, no extra server.

## Assets
- No raster assets/logos are required; the mocks use Unicode glyphs → replace with **SF Symbols**. The assist **diamond** is a rotated square, reproducible in code (or a custom symbol). Avatar monograms are coloured circles with initials. The signature editor has a user "Drop logo" slot (user-supplied image, persisted).
- Fonts: **SF Pro** (system) + **SF Mono**. (The "Editorial" rejected direction referenced Newsreader serif — not used in the Quiet build.)

## Files (in this bundle)
All 18 `.dc.html` design references are included alongside this README. Open them in a browser to inspect exact styling; **Winnow Design Spec.dc.html** is the canonical token/component reference and the best starting point, followed by **Winnow Mail** (Quiet direction) and **Winnow Today**.

> Note: these are authored as Design Components and load a small runtime (`support.js`) when opened standalone. They render for visual reference; you are recreating them natively, so the runtime is irrelevant to implementation.
