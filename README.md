# OpenTulln

Open civic-data dashboards for **Bezirk Tulln** (Niederösterreich). One Phoenix app, multiple lenses on the same place: budget transparency, flood risk, and more to come.

> Public brand: **OpenTulln**. OTP app + modules stay `tulln_data` / `TullnData`.

## What's live

| Route | Lens | Status |
|---|---|---|
| `/` | Landing — 4 Gemeinde cards | ✅ shipped |
| `/haushalt/:slug` | Budget treemap + KDZ Quicktest + peer compare | ✅ MVP (Quicktest math stubbed — see below) |
| `/info` | Methodology, glossary, attribution | ✅ shipped |
| `/hochwasser/test` | Live Donau gauge widget (W/Q + 48h forecast) | 🟡 internal demo only |
| `/hochwasser` | Public flood page | 🚧 ELB-1340 |

Seeded Gemeinden: Tulln an der Donau, Klosterneuburg, Korneuburg, Stockerau.

## Data sources

- **Municipal budgets** — [offenerhaushalt.at](https://www.offenerhaushalt.at) CSV (VRV97 + VRV2015)
- **Fiscal-health grades** — [KDZ Quicktest](https://www.kdz.eu) methodology
- **Flood polygons** — HORA HQ30 / HQ100 / HQ300 inundation zones (PostGIS)
- **Live gauges** — Pegelonline (BMLRT) + NÖ 48h Wasserstand forecast
- **Map tiles** — NÖ Atlas WMS via local proxy

Full details: [`docs/data-sources.md`](docs/data-sources.md).

## Stack

Phoenix 1.8 LiveView · Elixir 1.15+ · PostgreSQL 16 + PostGIS 3.5 · Tailwind v4 (`@theme`) · MapLibre GL JS · pure-Elixir squarified treemap.

## Local setup

```bash
# 1. PostGIS (default postgis/postgis image is broken on Alpine — use imresamu's)
docker run -d --name opentulln-db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  imresamu/postgis:16-3.5-alpine

# 2. Deps + DB + seeds (4 Gemeinden)
mix setup

# 3. Ingest a budget year (idempotent)
mix tulln.ingest.budget tulln-der-donau 2024
mix tulln.ingest.budget klosterneuburg 2024
# 2001–2019 → VRV97. 2020+ → VRV2015 (all 3 haushalte).
# 404 / empty body → [skip] not_published. Not an error.

# 4. Start server
mix phx.server   # http://localhost:4000
```

## Project layout

```
lib/tulln_data/
  budget/            # offenerhaushalt.at client + VRV97/VRV2015 CSV parsers
  budgets/           # Ecto context + Quicktest + Treemap (squarified)
  pegelonline.ex     # Donau gauge client (TLS verify disabled — gov cert quirk)
  noe_forecast.ex    # NÖ 48h forecast client
  hora.ex            # HORA flood polygon ingest + lookup
lib/tulln_data_web/
  live/haushalt_live.ex
  components/
    ui.ex            # <.gemeinde_card>, <.treemap_svg>, <.quicktest_card>, …
    layouts.ex       # OpenTulln shell (header, footer, attribution)
```

## Caveats

- **KDZ Quicktest math is stubbed.** `TullnData.Budgets.Quicktest.compute/2` returns hardcoded per-Gemeinde demo values matching the v1 designer mock. Card layout, grade colors, thresholds are real — numbers aren't. Real aggregation tracked as ELB-1400. Until then, `/info` does not claim the grades are authoritative.
- **Korneuburg 2020–2022 won't ingest** — offenerhaushalt.at returns 302. Tracked as ELB-1401.
- **`/hochwasser/test`** is an internal demo, not a public lens. Promotion → ELB-1340.

## Contributing / agent conventions

See [`AGENTS.md`](AGENTS.md) — has the brand/code split, design tokens, ingest quirks, TLS workaround, component library, and Linear workspace notes.

## License + attribution

- Code: see `LICENSE`
- Data: CC-BY 3.0 AT (offenerhaushalt.at, NÖ Atlas) — attribution mandatory on public pages, handled by `<.attribution_strip>`
