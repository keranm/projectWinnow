# Design System — "Quiet"

The Winnow design language is called **Quiet**: near-monochrome, generous whitespace, hairline dividers, minimal colour, rare and short motion. It maps cleanly to native Apple platform conventions.

## Colour tokens

### Light mode

| Token | Value | Use |
|-------|-------|-----|
| `text` | `#1C1C20` | Primary text |
| `textSecondary` | `#55555C` | Metadata, labels |
| `textTertiary` | `#9A9AA0` | Hints, placeholders, eyebrows |
| `sidebar` | `#FAFAFA` | Sidebar background |
| `surface` | `#FFFFFF` | Reading pane, cards |
| `stage` | `#ECECED` | App background behind windows |
| `accent` | `#2F6BDB` | Selection, links, unread dots, primary action |
| `accentTint` | `#EEF3FC` | Selected row background, assist card background |
| `success` | `#2F9E6F` | Positive indicators |
| `caution` | `#C08A4A` | Price-change alerts, warnings |
| `alert` | `#D9534F` | Errors, destructive actions |
| `hairline` | `rgba(0,0,0,0.05–0.08)` | Dividers, borders |

### Dark mode

| Token | Value |
|-------|-------|
| `surface` | `#1C1C1E` |
| `sidebar` | `#161617` |
| `stage` | `#0E0E10` |
| `accent` | `#4F8EF0` |
| `accentTint` | `#20304D` |
| `text` | `#F2F2F5` |
| `textSecondary` | `#A0A0A8` |
| `textTertiary` | `#6A6A72` |
| `hairline` | `rgba(255,255,255,0.07)` |

## Typography

Map `system-ui` → **SF Pro**, `ui-monospace` → **SF Mono**.

| Style | Size | Weight | Notes |
|-------|------|--------|-------|
| Display | 30px | 600 | Tracking −0.02em |
| Title | 22px | 600 | Thread subjects, screen titles |
| Body | 14px | 400 | Message body, line-height ~1.6 |
| Label | 13px | 500 | Sender names, row labels |
| Section header | 11px | 600 | Uppercase, tracking 0.05em, `textTertiary` |
| Meta | 11px | 400 | Monospace — times, amounts, tracking numbers, shortcuts |

## Spacing

4px base rhythm.

| Context | Value |
|---------|-------|
| Row padding | 11–14px |
| Card padding | 14–18px |
| Window / section padding | 26–34px |
| Component gap | via `gap`, not margins |

## Radius

| Context | Value |
|---------|-------|
| Rows, controls | 7px |
| Cards | 11–13px |
| Sheets, large surfaces | 16px |
| Pills, chips | full (14–20px) |
| Toggles | 11–12px |

## Shadows

```swift
// Window
shadow(color: Color(hex: "14162D").opacity(0.18), radius: 35, x: 0, y: 24)
shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

// Popover
shadow(color: Color(hex: "0A0C1E").opacity(0.26), radius: 27.5, x: 0, y: 22)

// Command palette
shadow(color: Color(hex: "0A0C1E").opacity(0.34), radius: 40, x: 0, y: 30)
```

## Key components

### Assist diamond (`.di`)

The product's signature mark. A filled 45°-rotated square in `accent` blue. **Always means "produced by on-device intelligence."** Reproduce as:

```swift
Rectangle()
    .fill(Color.winnowAccent)
    .frame(width: size, height: size)
    .rotationEffect(.degrees(45))
    .cornerRadius(1.5)
```

Or use a custom SF Symbol. Never use `sparkles` — it implies cloud/external AI.

### Selected row state

```swift
background(Color.winnowAccentTint)
overlay(alignment: .leading) {
    Rectangle()
        .fill(Color.winnowAccent)
        .frame(width: 2)
}
```

### Toggle

40×23pt track, 19pt knob. On = `accent`, off = `#D8D8DE`.

### Keycap (`.kbd`)

SF Mono 11pt, white background, `border: 1px solid rgba(0,0,0,0.16)` with heavier bottom edge (2px), radius 6pt.

### Unread dot

6pt circle, `accent` when unread, transparent when read.

## Window chrome

46pt title bar height. Traffic-light dots on the left. Centered "Winnow" wordmark in `textTertiary`.

## Sidebar layout

~212–228pt wide. Components from top to bottom:
1. Account chip
2. Nav rows (Today, Important, Other)
3. "Pulled from mail" section (Trips & deliveries, Quotes, Subscriptions, Calendar)
4. Footer status row: green dot + "On-device · synced 2m ago"

## List column

~316–356pt wide. Row anatomy: unread dot + sender (Label weight) + time (Meta, right-aligned) + subject (500 weight) + preview (Body, `textTertiary`, truncated).

## Motion

Rare and short. Favour quick fades and translations. No gratuitous animation.

## Glyph mapping

The design files use Unicode stand-ins. Replace with SF Symbols:

| Unicode | SF Symbol |
|---------|-----------|
| `◷` | `clock` |
| `✈` | `airplane` |
| `▣` | `shippingbox` |
| `⌫` | `archivebox` |
| `◆` | Custom diamond (see above) |
| `⌗` | `tag` |
