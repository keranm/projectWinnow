# Contributing

## Workflow

1. Check the [GitHub issues](https://github.com/keranm/projectWinnow/issues) — pick one up or open a new one
2. Branch from `main` with a descriptive name: `feat/compose-snippets`, `fix/gmail-auth-refresh`, `chore/update-gitignore`
3. Keep PRs focused — one logical change per PR
4. Open a draft PR early if you want feedback on direction before finishing
5. Get one approval before merging

## Branch naming

| Prefix | When to use |
|--------|-------------|
| `feat/` | New feature or screen |
| `fix/` | Bug fix |
| `chore/` | Tooling, deps, config |
| `refactor/` | Code change with no user-visible effect |
| `docs/` | Documentation only |
| `design/` | Design system or token updates |

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(compose): add snippet autocomplete with ; trigger
fix(auth): handle token refresh race on app foreground
chore: update .gitignore for Xcode 16
```

## Code style

- Swift 6 strict concurrency where possible — `Sendable`, `@MainActor`, structured concurrency over callbacks
- No `AnyView` wrapping unless unavoidable
- Prefer value types; reach for classes only when you need reference semantics (e.g. `ObservableObject` actors)
- All intelligence work goes through the `ExtractionPipeline` tier-dispatch — don't call Foundation Models directly from a view
- Keep `WinnowCore` free of UIKit/AppKit/SwiftUI imports

## Testing

- Unit tests in `Packages/WinnowCore/Tests/` — run with `⌘U` or `swift test`
- Test deterministic extractors exhaustively (regex paths are cheap to cover)
- UI behaviour tests in `WinnowUITests/`
- Don't mock the sync engine in integration tests — use the IMAP test adapter against a local Greenmail instance

## Design fidelity

When implementing a screen, open the corresponding `design_handoff_winnow/*.dc.html` file in a browser and compare pixel-by-pixel. Key things to check:
- Colour tokens match (use `WinnowColors` — never hardcode hex)
- Typography uses the right style from `WinnowTypography`
- Spacing follows the 4pt rhythm
- Assist diamond appears everywhere on-device intelligence surfaces a result
- SF Symbols replace all Unicode stand-ins

## Issue templates

Use the GitHub issue templates:
- **Bug report** — something broken
- **Feature request** — new behaviour
- **Design deviation** — implementation diverges from spec and needs a decision

## Questions

Open a GitHub Discussion or tag in an issue. Don't DM.
