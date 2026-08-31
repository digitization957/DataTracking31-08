# Design — DataTracking

A locked design system for this app. Every page redesign reads this file before
emitting code. Do not regenerate per page — extend or amend this file when the
system needs to grow.

## Genre
modern-minimal — internal enterprise document-tracking tool, not a marketing site.

## Scope
Four functional screens share this system: Login, Dashboard, Upload, Repository.
About/Contact/Default are unused ASP.NET template stubs — out of scope, untouched.

## Macrostructure family
None of Hallmark's 21 marketing macrostructures fit an app UI (no hero, no pricing,
no FAQ). Structure is bespoke per screen, built from first principles, sharing one
token system:

- **Login** — centred auth card. No nav.
- **Dashboard** — instrument panel: greeting + KPI stat strip + quick actions.
- **Upload** — two-pane form workbench: classification/subject/remark left,
  files/tags right. Asymmetric split, not stacked-centred.
- **Repository** — filter-rail data browser: sticky filter panel + result list.

## Theme — Cobalt
Cool engineered near-white paper, one electric-cobalt signal accent, ruler-drawn
hairlines, tight 6px radii, bordered controls. The instrument-panel register.

- `--color-paper`      oklch(98% 0.006 250)
- `--color-paper-2`    oklch(95.5% 0.008 250)
- `--color-ink`        oklch(19% 0.014 254)
- `--color-ink-2`      oklch(30% 0.013 254)
- `--color-rule`       oklch(87% 0.012 250)
- `--color-accent`     oklch(52% 0.19 258)
- `--color-focus`      oklch(60% 0.20 258)

Dark mode mirrors these with lightness/chroma inverted per `color.md`'s dark
recipe — same hue, never switched. See `Content/tokens.css`.

## Typography
- Display: Space Grotesk, weight 600–700, normal style
- Body: Inter, weight 400/500
- Mono: JetBrains Mono, weight 400/500 — ids, dates, counts, tabular data
- Display tracking: -0.02em
- Type scale anchor: `--text-2xl` = 2.25rem (app UI stays restrained — no
  marketing-scale display type)

## Spacing
4-point named scale in `Content/tokens.css`. Pages use named tokens
(`var(--space-md)`), never raw values.

## Motion
- Easings: `--ease-out` / `--ease-in` / `--ease-in-out` per `motion.md`
- No page-load reveal stagger — this is a tool used dozens of times a day;
  scroll theatre would become an annoyance, not a delight
- Button press, focus, dropdown-open, modal-open get short/micro durations
- Reduced-motion fallback: opacity-only, ≤150ms

## Microinteractions stance
- Silent success — no "Saved!" toast when the row visibly appears
- Toasts reserved for errors and validation
- Hover delay 800ms / focus delay 0ms on any tooltip
- Optimistic UI where safe (tag/file removal), no confirm dialogs on reversible actions

## CTA voice
- Primary: filled cobalt, 6px radius, weight 600, one action per screen
- Secondary: outlined, ink border, transparent fill
- Destructive/remove: text-only, danger colour, no button chrome

## Nav
Persistent bordered top-bar (wordmark + 3 tab links + user chip + logout).
Not a hidden ⌘K palette — daily-use tool needs constant wayfinding, unlike a
marketing site's landing nav. Active tab marked with accent underline.

## Footer
None. Internal tool — no marketing footer needed.

## What screens MUST share
- Topbar shape, wordmark, accent placement, CTA voice, type pairing, spacing scale.
- Existing element IDs and JS-created class names (`tag-chip`, `rec-row`,
  `file-pill`, `suggest-box`, `suggest-list`, `preview-overlay`, etc.) — the
  AJAX/WebMethod contract is untouched; only the visual layer changed.

## What screens MAY differ on
- Internal layout shape (auth card vs. instrument panel vs. two-pane vs. filter-rail).

## Exports

### tokens.css
See `Content/tokens.css` at the project root — full token set (color, type,
space, motion, radius, z-index).
