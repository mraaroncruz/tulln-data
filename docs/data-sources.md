# Data Sources

## Real-Time Water Levels: PEGELONLINE REST API v2

**Provider:** Generaldirektion Wasserstraßen und Schifffahrt (GDWS), Germany
**Operator of Austrian data:** viadonau (Austrian Federal Waterway operator)
**Base URL:** `https://www.pegelonline.wsv.de/webservices/rest-api/v2`
**Format:** JSON (application/json)
**Authentication:** None required
**License:** DL-DE->Zero-2.0 (unrestricted use, no attribution required)
**Data quality:** Unvalidated raw values ("ungeprüfte Rohwerte") -- may contain outliers

### Stations

| Station | HZB Nr | PEGELONLINE Nr | River km | Gauge Zero (m ü.A.) | Catchment (km²) |
|---|---|---|---|---|---|
| Kienstock | 207357 | 42011 | 2015.2 | 194.00 | 95,970 |
| Korneuburg | 207241 | 42013 | 1941.5 | 159.87 | 101,537 |

Both stations are operated by viadonau and measure water level (W) via pressure probes
with remote transmission (DFÜ).

### Endpoints

**Current reading (single station):**
```
GET /stations/{SHORTNAME}.json?includeTimeseries=true&includeCurrentMeasurement=true
```
Example: `/stations/KIENSTOCK.json?includeTimeseries=true&includeCurrentMeasurement=true`

Response:
```json
{
  "uuid": "56178f74-b3ef-4192-aad5-4f82d4a91a59",
  "number": "42011",
  "shortname": "KIENSTOCK",
  "longname": "KIENSTOCK",
  "km": 2015.2,
  "agency": "VIA DONAU",
  "water": { "shortname": "DONAU", "longname": "DONAU" },
  "timeseries": [{
    "shortname": "W",
    "longname": "WASSERSTAND ROHDATEN",
    "unit": "cm",
    "equidistance": 15,
    "currentMeasurement": {
      "timestamp": "2026-04-27T15:15:00+02:00",
      "value": 174.0,
      "stateMnwMhw": "unknown",
      "stateNswHsw": "normal"
    },
    "gaugeZero": {
      "unit": "m ü. A.",
      "value": 194.0,
      "validFrom": "2006-10-01"
    }
  }]
}
```

**Time series (last N duration, ISO 8601):**
```
GET /stations/{SHORTNAME}/W/measurements.json?start={DURATION}
```
Example: `/stations/KIENSTOCK/W/measurements.json?start=P1D` (last 24h)

Response: array of `{ "timestamp": "...", "value": 174.0 }`

**Characteristic values (RNW, HSW):**
```
GET /stations/{SHORTNAME}/W.json?includeCharacteristicValues=true
```

| Characteristic | Kienstock (cm) | Korneuburg (cm) | Meaning |
|---|---|---|---|
| RNW | 164 | 191 | Regulierungs-Niedrigwasserstand (regulated low water) |
| HSW | 618 | 549 | Höchster Schifffahrtswasserstand (highest navigable water) |

### Polling cadence

Data updates every **15 minutes** (`equidistance: 15`). Poll at 15-minute intervals
aligned to the quarter-hour.

### Rate limits

No documented rate limits. Be a good citizen -- poll no more often than every 15 minutes.

---

## Historical Water Levels: eHYD (Hydrographisches Zentralbüro)

**Provider:** Austrian Federal Ministry (BML) via Hydrographischer Dienst
**URL:** `https://ehyd.gv.at`
**Format:** CSV (semicolon-delimited, ISO-8859-1 encoding)
**Authentication:** None required
**License:** Open Government Data (OGD) Austria -- CC BY 4.0
**Data range:** 1976 -- Dec 2023 (updated annually)

### Download endpoints

```
GET /services/MessstellenExtraData/owf?id={HZB_NR}&file={FILE_NR}
```

| file | Content | Unit |
|---|---|---|
| 1 | Stammdaten (station metadata) | -- |
| 2 | W-Tagesmittel (daily mean water level) | cm |
| 3 | W-Monatsminima (monthly minimum W) | cm |
| 4 | W-Monatsmaxima (monthly maximum W) | cm |
| 5 | Q-Tagesmittel (daily mean discharge) | m³/s |
| 6 | Q-Monatsminima (monthly minimum Q) | m³/s |
| 7 | Q-Monatsmaxima (monthly maximum Q) | m³/s |

### CSV format

```
Messstelle:                ;Kienstock
HZB-Nummer:                ;207357
...
Einheit:                   ;[cm]
Werte:
01.01.1976 00:00:00;   177
02.01.1976 00:00:00;   191
```

Header block with metadata, then timestamped values. Delimiter: `;`. Decimal separator: `,` (German locale). Gap marker: `Lücke`.

---

## 48h Forecast: NÖ Wasserstand (Land Niederösterreich)

**Provider:** Hydrographischer Dienst Niederösterreich
**Base URL:** `https://www.noe.gv.at/wasserstand/`
**Format:** CSV (semicolon-delimited, UTF-8)
**Authentication:** None required
**License:** Assumed OGD Austria (no explicit license on endpoint)
**CORS:** Not available — server-side proxy required

### Endpoints

**Station list (with current values):**
```
GET kidata/maplist/MapList.json
```

Returns JSON array of all stations with parameters, current value, classification,
coordinates, and display hints. Key fields per entry:
```json
{
  "Parameter": "WasserstandPrognose",
  "Stationnumber": "207357",
  "Stationname": "Kienstock",
  "Timestamp": "2026-04-27T15:15:00+01:00",
  "Value": "178",
  "Unit": "cm",
  "Lat": "48.382",
  "Long": "15.463",
  "Linkparameter": "WasserstandPrognose",
  "Grafik": "48Stunden",
  "Rivername": "Donau"
}
```

**48h forecast time series:**
```
GET kidata/stationdata/{stationNumber}_{parameter}_{timeframe}.csv
```

Parameters for forecast:
- `WasserstandPrognose` — water level (cm)
- `DurchflussPrognose` — discharge (m³/s)

Timeframe: `48Stunden`

Examples:
```bash
curl "https://www.noe.gv.at/wasserstand/kidata/stationdata/207357_WasserstandPrognose_48Stunden.csv"
curl "https://www.noe.gv.at/wasserstand/kidata/stationdata/207357_DurchflussPrognose_48Stunden.csv"
curl "https://www.noe.gv.at/wasserstand/kidata/stationdata/207241_WasserstandPrognose_48Stunden.csv"
```

### CSV Response Schema

```
Datenqualität;!ungeprüfte Rohdaten!;;
Stationsname;Kienstock;;
Stationsnummer;207357;;
Parameter;WasserstandPrognose;;
Zeitreihenname;Wahrscheinlichste Prognose;Vertrauensbreich;Vertrauensbreich
von;2026-04-27 12:00:00;;
bis;2026-04-27 19:00:00;;
Einheit;cm;;
;;;
Datum;Mittel;Min;Max
2026-04-27 12:00:00;186;186;186
2026-04-27 12:15:00;185;185;185
...
2026-04-29 12:00:00;170;150;190
```

**Header (9 rows):**
| Row | Field | Description |
|-----|-------|-------------|
| 1 | Datenqualität | Always "!ungeprüfte Rohdaten!" (unvalidated raw data) |
| 2 | Stationsname | Station name |
| 3 | Stationsnummer | HZB station number |
| 4 | Parameter | `WasserstandPrognose` or `DurchflussPrognose` |
| 5 | Zeitreihenname | Column headers: "Wahrscheinlichste Prognose;Vertrauensbreich;Vertrauensbreich" |
| 6 | von | Start timestamp (local time, no TZ) |
| 7 | bis | End of observed/hindcast window |
| 8 | Einheit | Unit (cm or m³/s) |
| 9 | (empty) | Separator row |

**Data columns:**
| Column | Description |
|--------|-------------|
| Datum | Timestamp `YYYY-MM-DD HH:MM:SS` (local time, CET/CEST) |
| Mittel | Most probable forecast value |
| Min | Lower confidence bound |
| Max | Upper confidence bound |

**Data characteristics:**
- 15-minute intervals (~193 rows per file covering 48h)
- Confidence band: Min=Max=Mittel for near-term (observed/hindcast), widens for forecast horizon
- The `bis` header field marks the transition from observed → forecast (~5-7h from start)

### Donau Forecast Stations (relevant for Tulln)

| Station | Number | Lat | Lon | Position relative to Tulln |
|---------|--------|-----|-----|---------------------------|
| Kienstock | 207357 | 48.382 | 15.463 | ~60km upstream |
| Korneuburg | 207241 | 48.327 | 16.334 | ~25km downstream |

Kienstock is the primary early-warning gauge — rising water there arrives at Tulln
several hours later.

### Update Frequency & Caching

- `Cache-Control: max-age=300` (5-minute browser/CDN cache)
- `Last-Modified` updates sub-hourly (forecast model re-runs)
- Recommended poll interval: **15 minutes** (matches measurement cadence)

### CORS & Proxy Requirement

No `Access-Control-Allow-Origin` header is returned. Browser-side fetch from
`localhost:4000` or any external origin will be blocked by CORS policy.

**Requirement:** Server-side proxy via Phoenix endpoint or Oban background job.

---

## Alternative Sources (evaluated, not used)

| Source | Access | Why not primary |
|---|---|---|
| PegelAlarm API (api.pegelalarm.at) | JSON, requires auth (free test account via office@sobos.at) | Auth required, adds operational dependency |
| DanubeHIS (danubehis.org) | WaterML 2.0 / CSV / XLS, requires registration | Registration required, 30-min intervals |
| viadonau DoRIS (doris.bmimi.gv.at) | SPA only, no public API | No programmatic access |
