# OpenTulln — Design Spec (MVP)

A one-pager for the designer. Everything here is for the **first public release**: a budget-transparency dashboard for four Lower-Austrian Donau-corridor municipalities. Flood, solar, and the other lenses come later — design for budget, but pick a system that scales.

> **Naming note.** Earlier drafts used the working name *TullnData*. We switched to **OpenTulln** because (a) the double-`l` in *Tulln* reads ambiguously in Inter (its lowercase `l` is shaped identically to its capital `I`, so the eye parses *TullnData* as *TuIInData*), and (b) the *Open*-prefix lineage (OpenStreetMap, OpenAddresses, OpenBudgets) communicates "open-data civic project" without explanation.

---

## What the product is

**OpenTulln** is a civic open-data product for Bezirk Tulln. The first lens makes municipal budgets readable: *where does this town's money actually go, and how healthy are its books?* Future lenses will answer "what's the flood risk at my address?", "what's my roof's solar potential?", and so on. They all live in the same shell.

This MVP covers **four Gemeinden**: Tulln an der Donau, Klosterneuburg, Korneuburg, Stockerau. Same regional axis, comparable size (13k–28k inhabitants), same Wien-Pendler economy. The peer set is part of the value proposition: you can see how your town's spending compares to neighbors of the same kind.

## Who it's for

**Engaged citizens, local journalists, council members in NÖ.** German-speaking, comfortable with numbers but not budget analysts. They've heard a number ("Tulln spent X on Y") and want to verify, contextualize, or compare. They will *not* read 200 words of methodology before they see the treemap; they *will* drill in once it's on screen.

Secondary, much later: Tulln residents on phones (flood lens), farmers (solar/crops lens). Don't design for them now, but don't make the shell hostile to them.

## The first moment

A user lands on the home page. They see **four large Gemeinde cards** — name, population, a tiny treemap thumbnail, an overall fiscal-health grade (A–E). No search input. No marketing copy above the fold. The page is *the* answer: "we cover these four towns; pick one."

They tap *Tulln*. **Inside <500 ms** they're on the result page:

- A treemap captioned *"1.000 € Steuergeld aus Tulln gehen an:"* — top-level functional areas (Soziales, Bildung, Verwaltung, Bau & Wohnen, Schulden, …), each rectangle sized to its share. Numbers shown in euros-per-1.000 so they stay legible across town sizes.
- Below it, **five Quicktest cards** — the canonical KDZ Quicktest ratios (Öffentliche Sparquote, Eigenfinanzierungsquote, Verschuldungsdauer, Schuldendienstquote, Investitionsquote) as letter-grade chips A–E, each with the raw value, a 5-year sparkline, and a one-line German tooltip explaining what the ratio means. Grading thresholds come verbatim from KDZ's published methodology (cited on the `/info` page); we do not invent our own.
- A **"Vergleich"** button that opens a chip picker for up to four peers — treemaps render side-by-side (desktop) or stacked (mobile), normalized to €/Einwohner.

That's the 10-second pitch. The user can drill into the treemap (tap a rectangle → it expands and becomes the new root, breadcrumbs above), switch the year (one tap, last year is always visible), or switch the Gemeinde via a small dropdown in the page header.

## Voice & tone

- **German UI throughout.** Plain language, not bureaucratic. "Wie viel Spielraum hat die Stadt nach Pflichtausgaben?" — not "Anteil der öffentlichen Sparquote am Gesamthaushalt."
- **Honest, not promotional.** This is civic data, not a SaaS product. No "Boost your insights!" copy. No emoji. No exclamation marks.
- **Confident with numbers.** Use tabular figures. Don't hedge with "approximately" when the data is exact. *Do* show the source and license at the bottom of every card.
- **Calm.** No urgency, no FOMO, no animated CTAs. The data is interesting on its own.

## Visual language

**Type**
- One sans family. Inter or a comparable open sans. One display weight for headlines, regular and medium for body.
- Tabular figures (variant `tnum`) for every euro amount, ratio value, and sparkline label. Numbers must align in columns.

**Color**
- Calm civic palette: slate/stone neutrals as the ground, **one brand color** for accent and brand moments — propose **navy or forest green** (deliberately *not* "water blue", because the flood lens lands in that color space later).
- **Grade chips A–E in five honest hues** — A is a confident green, E is a serious red, B/C/D step through. No neon. No traffic-light cliché. Borrow from civic-data references (KDZ, Statistik Austria) for tone, not from finance dashboards.
- Treemap rectangles share a single hue family (the brand color), differentiated by **value (lightness)** rather than hue. Color separates Income / Expense / Investment toggles, not categories.

**Layout & spacing**
- 16 px base spacing unit. Generous whitespace.
- Cards: 12 px radius, soft shadows, 2–3 px gaps between treemap rectangles so children remain legible.
- Mobile-first. The 2×2 Gemeinde grid stacks to 1×4. The result page is single-column on mobile, two-column on desktop only at the peer-comparison stage.

**Motion**
- 200–250 ms ease. Treemap drill-in/out animates rectangle bounds. Sparklines draw on mount. Grade chips fade up.
- No looping animations, no parallax, no marketing-style hero reveals.

**Iconography**
- Heroicons (already vendored in the codebase). Outline weight by default. Don't introduce a second icon set.

## Screens to design

| Screen | Purpose | Notes |
|---|---|---|
| **Landing (`/`)** | Pick a Gemeinde | 4 cards in a 2×2 grid (1×4 on mobile). Each card: name, population, brand-colored treemap thumbnail, overall KDZ grade chip. Single attribution strip at the bottom. |
| **Budget result (`/haushalt/:slug`)** | Where the money goes + how healthy the books are | Page header with Gemeinde switcher (dropdown) + year switcher (dropdown). Then the treemap (hero). Then five Quicktest cards in a row (wrapping to grid on mobile). Then "Vergleich" CTA. Footer attribution. |
| **Peer comparison state** of the budget page | Compare 2–4 Gemeinden side by side | Same shell, treemap area becomes a grid of small-multiples treemaps, all normalized to €/Einwohner. Each has the same drill-down behavior. |
| **Info (`/info`)** | Glossary + methodology + attribution | Static, German prose. Defines every term used in the dashboard (Sparquote, HQ100 — for the next lens, etc.). License-text section. |

## Components needed (system-level)

1. **App shell** — header (wordmark + ~2 nav links), main content, footer (attribution + licenses).
2. **Gemeinde card** (landing tile) — large tappable, thumbnail treemap visible.
3. **Gemeinde switcher** (in-page header) — dropdown, current selection + caret.
4. **Year switcher** — dropdown, defaults to the most recent published fiscal year.
5. **Treemap** — full hero version (drillable, animated, with breadcrumbs and toggles for €1.000 / absolute € / €-pro-Einwohner) and thumbnail version (static, for the landing cards).
6. **Quicktest card** — letter-grade chip, value, 5y sparkline, one-line tooltip on hover/tap.
7. **Compare picker** — chip multi-select, up to 4, with a clear "Vergleich starten" CTA.
8. **Attribution strip** — small text at the foot of any page using data: source name, license, link.

## Hard constraints

- **German UI only** at MVP. (Translations are out of scope; bake the strings, don't i18n yet.)
- **WCAG AA.** Color contrast, keyboard navigation, screen-reader semantics on the treemap (provide an accessible table fallback).
- **Mobile-first.** Design for 360 px viewport up. Treemap must remain legible at that width — if it can't, fall back to a sorted bar chart on small screens.
- **Performance budget.** First contentful paint <2 s, largest contentful paint <2.5 s on throttled 3G. No web fonts >100 KB, no hero images >200 KB.
- **Attribution is mandatory.** offenerhaushalt.at is CC-BY 3.0 AT; KDZ data has separate attribution. Every page that uses them must show the credit.
- **No DaisyUI, no design-system kits.** Hand-rolled Tailwind components only — per the project's `AGENTS.md`, the brief calls for distinctive design.

## References worth a look (mood, not direct copying)

- **offenerhaushalt.at** itself — for the baseline of municipal budget visualization. We want to be better than this, but it sets the genre.
- **Where Does My Money Go?** (UK gov spending viz, archived) — the "1.000 €" framing comes from this lineage.
- **Statistik Austria StatCube** — for German-language data-product tone (calm, factual).
- **The Pudding** — for civic-data storytelling presentation (mainly type and pacing).

Avoid: generic SaaS dashboards (Datadog, Looker), fintech apps, anything with neon gradients or playful illustrations. This is civic infrastructure.

## Deliverables (suggestion to discuss)

1. Mobile + desktop frames for the four screens above. Light mode only at MVP; dark mode is post-launch.
2. A small component library file (Figma or equivalent) with the 8 components above, their states (default / hover / active / disabled / focus-visible), and their responsive variants.
3. A color + type token sheet (Tailwind-friendly: name, value, usage note).
4. One short motion-spec page describing the treemap drill animation, sparkline draw, and grade-chip fade.

## What's *out* of scope for this design pass

- The flood lens (`/hochwasser`, `/adresse/:hash`, address result page) — comes next, share the shell.
- Solar, heat, crops, housing, commute, cycling, weather lenses — same shell, much later.
- Authentication, profiles, saved comparisons.
- Email/RSS alert subscriptions ("notify me when the 2025 fiscal year is published").
- A logo lockup beyond a wordmark — defer until the product is real.
- More than four Gemeinden — Bezirk-Tulln-wide and NÖ-wide coverage is post-MVP.

---

**Resolved decisions (carried over from the v1 designer mocks in `priv/design/`):**

- **Brand color is forest green** (`#1B4332` primary, `#012d1d` dark). Treemap rectangles use a monochromatic green scale (`#1B4332` → `#40916C` → `#95D5B2`). Grade chips A–E in `#2D6A4F` / `#74C365` / `#E9C46A` / `#F4A261` / `#BC4749`. Tokens documented in `priv/design/civic_transparency_framework/DESIGN.md`.
- **Result page header uses two separate dropdowns**: Gemeinde ▾ and Jahr ▾.
- **Five Quicktest cards use the canonical KDZ set** (see ratio table in the plan file). Grading thresholds taken verbatim from KDZ's published methodology.

**Still open:**

1. Are the landing-page treemap thumbnails static (faster, decorative) or live LiveView-rendered miniatures of real data (slower but always accurate when a new fiscal year publishes)?
2. Should the landing-page card include a one-line "headline number" beneath the grade chip — e.g. "Verschuldungsdauer: 6,2 Jahre" — or stay clean with just the thumbnail + overall grade?
3. The Quicktest cards in v1 mocks show absolute-€ sub-lines (e.g. "Nettoergebnis: +2,1 Mio €") under the ratio. Keep, drop, or make optional?
