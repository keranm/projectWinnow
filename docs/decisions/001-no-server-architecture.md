# ADR 001 — No server architecture

**Status:** Accepted  
**Date:** 2026-06-30

## Context

Winnow's core promise is privacy: your email never leaves your device. The two main paths for a Gmail client are:

1. **Server-assisted**: a backend holds OAuth tokens and proxies API calls, enables Pub/Sub push, simplifies multi-device sync
2. **Local-first**: the app holds tokens in the Keychain, calls Gmail directly, no backend in the path

## Decision

Local-first, no servers. All Gmail API requests originate from the user's device. Tokens live in the macOS/iOS Keychain.

## Consequences

- **Push latency**: Gmail's instant push (Cloud Pub/Sub `watch`) requires a webhook. We poll `history.list` instead — foreground + 30s timer + iOS background refresh. Delay is ~30s in the worst case, acceptable for a focused "quiet" client.
- **No cross-device sync outside Gmail**: devices stay in sync via Gmail itself (threads, labels, read state). There's no Winnow-managed sync layer for settings — those live in iCloud Key-Value Store.
- **Google OAuth review**: restricted scopes still require Google's verification process and an annual CASA audit. The no-server decision doesn't exempt us from this; it just means we don't need a server to pass it.
- **Simpler security model**: there's no Winnow backend to compromise. The attack surface is the device and the Gmail API.
