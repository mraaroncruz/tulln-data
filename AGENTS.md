This is a web application written using the Phoenix web framework.

For Phoenix 1.8 / LiveView / Elixir / Ecto / HEEx conventions, use the project-local **`phoenix-conventions`** skill at `.claude/skills/phoenix-conventions/SKILL.md`. Invoke it whenever writing or reviewing Elixir, Phoenix, LiveView templates, Ecto schemas, mix tasks, or tests in this repo.

## OpenTulln / tulln_data conventions

### Brand vs code
- Public brand: **OpenTulln**. Wordmark, `<title>`, copy, design tokens.
- OTP app + modules: `tulln_data` / `TullnData` / `TullnDataWeb`. Do **not** rename.
- Reason: brand-only rename. Inter's lowercase `ll` made "Tulln" read as "TuIIn".

### Routes
- `/` — landing, 4 Gemeinde cards
- `/haushalt/:slug` — budget treemap + Quicktest cards + peer compare (`?vs=korneuburg,stockerau`, max 3 peers)
- `/info` — methodology / glossary / attribution
- `/hochwasser/test` — internal gauge demo (NOT public; promotion to `/hochwasser` tracked in ELB-1340)

### Design tokens (`assets/css/app.css` `@theme` block)
- Primary: forest green `#1B4332` (`ot-primary`). Not water-blue — flood lens needs blue later.
- Surfaces: `ot-surface`, `ot-surface-subtle`, `ot-on-surface`, `ot-on-surface-variant`, `ot-outline`.
- A–E grade chips, monochromatic treemap scale.
- Inter font + `tabular-nums` for all numbers.

### Shared components (`TullnDataWeb.UI`)
Use `use TullnDataWeb, :html` (brings routes + icons). NOT bare `use Phoenix.VerifiedRoutes`.
- `<.gemeinde_card>` — landing tile
- `<.treemap_svg>` — squarified treemap (pure Elixir layout in `TullnData.Budgets.Treemap`)
- `<.treemap_thumb>` — 4 decorative variants for landing
- `<.quicktest_card>` — A–E chip + value + sparkline slot + German tooltip
- `<.grade_chip>` — standalone A–E pill
- `<.attribution_strip>` — `offenerhaushalt.at · KDZ · Stadt Tulln` (CC-BY 3.0 AT mandatory)

### Budget ingest
- Task: `mix tulln.ingest.budget <slug> <year>`
- Routing: 2001–2019 → VRV97. 2020+ → VRV2015 (all 3 haushalte: fhh/ehh/vhh).
- 404 / empty body → `[skip] not_published`. NOT failure. Do not raise.
- VRV2015 vhh 2023+ has 23 columns (adds Id-Vhh, Sektor, Land between Vorhabencode + Mvag). Third `row_to_map/1` clause in `lib/tulln_data/budget/vrv2015.ex`.
- Postgres 65535-param cap → `Budgets.replace_line_items!/2` chunks `insert_all` at 1000 rows.
- offenerhaushalt.at VRV2015 needs CSRF + session cookie flow (in `Budget.Client`).
- Known broken: Korneuburg 2020–2022 returns 302 → ELB-1401, not yet fixed.

### KDZ Quicktest — **MATH IS STUBBED**
- `TullnData.Budgets.Quicktest.compute/2` returns hardcoded per-Gemeinde `@demo_values` matching the v1 designer mock (Tulln B / Klosterneuburg A / Korneuburg C / Stockerau B).
- Card shape, grade colors, sparkline slots, thresholds in `@thresholds` are correct. **Only numeric source is fake.**
- Real aggregation = ELB-1400. Needs: leaf-vs-group/total isolation in hierarchical VRV2015, MVAG → operating/capital flow mapping, VRV97 ↔ VRV2015 sign convention reconcile.
- Until real: `/info` must NOT claim grades are authoritative.

### External-data TLS workaround
Pegelonline + NÖ 48h forecast endpoints fail TLS peer verification (`key_usage_mismatch` on Austrian-gov certs). Both clients set:
```elixir
@req_opts [connect_options: [transport_opts: [verify: :verify_none]]]
```
Files: `lib/tulln_data/pegelonline.ex`, `lib/tulln_data/noe_forecast.ex`. Do not copy this to other clients without verifying the cert is actually broken.

### Seeded Gemeinden (`priv/repo/seeds.exs`)
| Slug | GKZ | Name |
|---|---|---|
| `tulln-der-donau` | 32135 | Tulln an der Donau |
| `klosterneuburg` | 32144 | Klosterneuburg (NOT 32125 — that was wrong; fixed in PR #13) |
| `korneuburg` | 31207 | Korneuburg |
| `stockerau` | 31230 | Stockerau |

### Local bootstrap (Docker)
PostGIS image: **`imresamu/postgis:16-3.5-alpine`**. Default `postgis/postgis` image lacks `postgis_version()` extension on Alpine variants we tried.

### Linear
- Workspace: ELB team. Projects: Budget Treemap, Flood Dashboard, Data Platform.
- CLI bug: `linear issue update --status started` maps to custom "Blocked" status in this workspace, not "In Progress". Use GraphQL with explicit status ID `03b427c5-035c-46fb-9fe3-dd1a5a2c0759` for "In Progress".
