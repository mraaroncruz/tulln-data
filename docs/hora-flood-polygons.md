# HORA Flood Inundation Polygons

## Source

HORA (HOchwasserRisikozonierung Austria) publishes flood scenario polygons for three return periods:

| Scenario | Return Period | ZIP Download |
|----------|--------------|--------------|
| HQ30     | 30 years     | `https://inspire.lfrz.gv.at/000801/ds/HWRL_UEFF_HQ30.zip` |
| HQ100    | 100 years    | `https://inspire.lfrz.gv.at/000801/ds/HWRL_UEFF_HQ100.zip` |
| HQ300    | 300 years    | `https://inspire.lfrz.gv.at/000801/ds/HWRL_UEFF_HQ300.zip` |

- **Publisher**: Bundesministerium fur Land- und Forstwirtschaft, Klima- und Umweltschutz (BMLUK), via Umweltbundesamt GmbH
- **License**: CC BY 4.0
- **Format**: INSPIRE GML 3.2.1 (NZ-Core HazardArea schema)
- **Native CRS**: EPSG:3035 (ETRS89 / LAEA Europe)
- **Coverage**: All of Austria (~277 MB ZIP / ~1 GB GML per scenario)
- **Publication date**: 2020-03-20

## INSPIRE Metadata

- HQ30: <https://geometadatensuche.inspire.gv.at/metadatensuche/inspire/api/records/06a75330-49e1-482e-b430-7adf3a8863bc>
- HQ100: <https://geometadatensuche.inspire.gv.at/metadatensuche/inspire/api/records/afda3f35-074b-49d9-8522-7031bc839c33>

## Data Structure

Each GML feature is a `nz-core:HazardArea` with:

- `base:localId` — `{gemeindekennzahl}_{index}` (e.g., `32101_0` = Tulln an der Donau)
- `gml:Surface` geometry as `gml:PolygonPatch` with `gml:posList` (lat/lon pairs)
- `nz-core:returnPeriod` — 30, 100, or 300
- `nz-core:beginLifeSpanVersion` — ISO 8601 datetime

## Filtering

Bezirk Tulln (political district 321) features are identified by `localId` prefix `321`.

## Ingestion

```sh
# Ingest all three scenarios
mix tulln.ingest.hora

# Ingest a specific scenario
mix tulln.ingest.hora hq100
```

The task downloads each ZIP, stream-parses the GML with SAX, filters to Bezirk Tulln features, and upserts into the `flood_scenarios` table. Re-running is safe (upsert on `source_id` + `scenario`).

## Database Schema

```sql
CREATE TABLE flood_scenarios (
  id bigserial PRIMARY KEY,
  source_id varchar NOT NULL,
  scenario varchar NOT NULL,      -- hq30, hq100, hq300
  return_period integer NOT NULL,  -- 30, 100, 300
  geom geometry NOT NULL,          -- SRID 4326
  source_updated_at timestamptz,
  inserted_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  UNIQUE (source_id, scenario)
);

CREATE INDEX flood_scenarios_geom_index ON flood_scenarios USING gist (geom);
```

## Point-in-polygon query

```elixir
point = %Geo.Point{coordinates: {15.89, 48.33}, srid: 4326}
TullnData.Hora.flood_class(point)
# => "hq30" | "hq100" | "hq300" | nil
```

Returns the most severe (lowest return period) flood class that contains the point.
