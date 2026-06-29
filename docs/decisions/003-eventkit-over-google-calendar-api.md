# ADR 003 — EventKit over Google Calendar API

**Status:** Accepted  
**Date:** 2026-06-30

## Context

Winnow needs free/busy data and conflict detection for calendar invite handling ("Find a time", RSVP conflict warnings). Options:

1. **Google Calendar API** — requires an additional OAuth scope, additional API calls, possible server involvement for non-Gmail calendar types
2. **EventKit** — Apple's on-device calendar framework, already aggregates Google Calendar, iCloud Calendar, and Exchange locally on any iPhone/Mac where the user has their accounts configured

## Decision

Use EventKit exclusively. We request no Google Calendar API scope.

## Consequences

- Free/busy queries and conflict detection are instant and offline — EventKit data is local
- Works for all calendar providers the user has configured on their device, not just Gmail
- RSVP responses (Yes/Maybe/No) are sent via `messages.send` through the email account that received the invite — no calendar write scope needed
- Users must have their Google account added to the system Calendar app for Winnow to see Google events. This is a reasonable assumption for the target user but worth surfacing in onboarding
- We cannot create Google Calendar events directly (would need `calendar.events` scope). Out of scope for v1
