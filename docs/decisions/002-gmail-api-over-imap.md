# ADR 002 — Gmail API as primary transport for Gmail accounts

**Status:** Accepted  
**Date:** 2026-06-30

## Context

Gmail accounts can be accessed via two transports:

1. **Gmail API** (`gmail.googleapis.com`) — REST/JSON, native labels/threads, `q=` search, partial fetch, `history.list` incremental sync
2. **IMAP/SMTP** — standard protocol, works with any client, but loses Gmail-native features (labels, threads, search operators)

## Decision

Gmail accounts use the Gmail API. Non-Gmail accounts (Fastmail, iCloud, Outlook) use an IMAP/SMTP adapter behind a provider-agnostic `SyncEngine` protocol.

## Consequences

- Gmail's native threading, labels, and `q=` search syntax work without translation layers
- `messages.send` through the API honours verified send-as aliases and threading correctly
- Non-Gmail accounts are second-class in feature terms (no label sync, no `q=` parity) — acceptable since the product targets Gmail users
- The sync engine protocol must be designed carefully so the IMAP adapter is a genuine peer, not an afterthought
