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

---

## Municipal Budget: offenerhaushalt.at (KDZ)

**Provider:** KDZ - Zentrum fur Verwaltungsforschung (www.kdz.or.at)
**URL:** `https://www.offenerhaushalt.at/gemeinde/tulln-der-donau`
**Format:** CSV (semicolon-delimited)
**Authentication:** Session-based (VRV2015), none (VRV97)
**License:** CC BY 4.0 -- attribute KDZ
**Data range:** 2001-present
**GKZ (Gemeindekennziffer):** 32135

Two accounting standards coexist:

| Standard | Years        | Site                     | Encoding    |
|----------|--------------|--------------------------|-------------|
| VRV 1997 | 2001-2019   | vrv97.offenerhaushalt.at | ISO-8859-1  |
| VRV 2015 | 2020-present | www.offenerhaushalt.at   | UTF-8       |

**Boundary year for Tulln: 2019 is the last VRV97 year; 2020 is the first VRV2015 year.**

### Download Mechanics: VRV97 (2001-2019)

Simple GET, no authentication:

```
GET https://vrv97.offenerhaushalt.at/download/{type}/top/tulln-der-donau/{year}
```

Types: `finanzdaten`, `voranschlag`, `rechnungsabschluss`, `schulden`, `haftungen`

Returns CSV directly. Empty response for years without data.

### Download Mechanics: VRV2015 (2020+)

Three-step session-based download (anti-scraping protection):

1. **GET** the download page to get session cookie + CSRF token:
   ```
   GET https://www.offenerhaushalt.at/gemeinde/tulln-der-donau/download
   ```
   Extract `_token` from `<input type="hidden" name="_token" value="...">`.

2. **POST** to token endpoint (same cookie jar) to get the real download URL:
   ```
   POST https://www.offenerhaushalt.at/downloads/get-token
   Body: foo=bar&_token={csrf_token}
   ```
   Returns: `{"action":"https://www.offenerhaushalt.at/downloads/ghdByParams","method":"POST"}`

3. **POST** to the download endpoint (same cookie jar):
   ```
   POST https://www.offenerhaushalt.at/downloads/ghdByParams
   Body: haushalt={type}&rechnungsabschluss={ra|va}&year={year}&origin={origin}&gkz=32135&_token={csrf_token}
   ```

Parameters:
- `haushalt`: `fhh` (Finanzierungshaushalt), `ehh` (Ergebnishaushalt), `vhh` (Vermogenshaushalt)
- `rechnungsabschluss`: `ra` (Rechnungsabschluss/actuals), `va` (Voranschlag/budget)
- `year`: 2001-2026
- `origin`: `gemeinde` (municipality-submitted) or `statistik_at` (Statistik Austria)
- `gkz`: 32135 (Tulln an der Donau)

### VRV97 CSV Schema (9 columns)

| Column                         | Description                               | Example               |
|--------------------------------|-------------------------------------------|-----------------------|
| `gkz`                         | Municipality ID                           | `32135`               |
| `jahr`                        | Fiscal year                               | `2018`                |
| `haushaltskonto-hinweis`      | Budget type (1-4)                         | `1`                   |
| `haushaltskonto-hinweis-name` | Budget type name                          | `ordentliche Ausgaben`|
| `haushaltskonto-ansatz`       | Functional account code (3-digit)         | `010`                 |
| `ansatzbezeichnung`           | Functional account description            | `Zentralamt`          |
| `haushaltskonto-post`         | Economic account code (3-digit)           | `510`                 |
| `kontenbezeichnung`           | Economic account description              | `Geldbezuge der...`   |
| `soll-rj`                     | Amount in EUR                             | `232923,04`           |

`haushaltskonto-hinweis` values: 1=ordinary expenditures, 2=ordinary revenues,
3=extraordinary expenditures, 4=extraordinary revenues.

### VRV2015 CSV Schema: fhh/ehh (16 columns)

| Column                            | Description                            | Example                 |
|-----------------------------------|----------------------------------------|-------------------------|
| `Jahr`                            | Fiscal year                            | `2024`                  |
| `Bundesland`                      | Federal state                          | `Niederosterreich`      |
| `Voranschlag/Rechnungsabschluss`  | Budget or actuals                      | `Rechnungsabschluss`    |
| `Datenquelle`                     | Data source                            | `Gemeinde`              |
| `Gemeindekennziffer`              | Municipality ID                        | `32135`                 |
| `Gemeindename`                    | Municipality name                      | `Tulln an der Donau`    |
| `Haushalt`                        | Budget component                       | `Finanzierungshaushalt` |
| `Ansatz-Uab`                      | Functional classification              | `999`                   |
| `Ansatz-Ugl`                      | Functional sub-classification          | `000`                   |
| `Konto-Grp`                       | Account group                          | `270`                   |
| `Konto-Ugl`                       | Account sub-group                      | `000`                   |
| `Vorhabencode`                    | Project code                           | `0000000`               |
| `Mvag`                            | MVAG code (cash flow classification)   | `4110`                  |
| `Ansatz-Text`                     | Functional classification description  | `Nicht voranschlags...` |
| `Konto-Text`                      | Account description                    | `Vorsteuer - Evidenz`   |
| `Wert`                            | Amount in EUR                          | `2825319,23`            |

VRV2015 vhh (Vermogenshaushalt) uses balance-sheet columns (`Endstand-Vj`, `Zugang`,
`Abgang`, `Aenderung`, `Endstand-Rj`) instead of a single `Wert`.

Key MVAG code ranges: 31xx=operative receipts, 32xx=operative payments,
33xx=investment receipts, 34xx=investment payments, 35xx=financing receipts,
36xx=financing payments, 41xx/42xx=off-budget items.

### Update Frequency

- **Rechnungsabschluss** (actuals): annually, typically Q1 of following year
- **Voranschlag** (budget): after municipal council approval, typically late prior year
- **Statistik Austria** mirror: updated annually in October

### Attribution

Required: `Datenquelle: offenerhaushalt.at, KDZ - Zentrum fur Verwaltungsforschung, CC BY 4.0`
Notify KDZ of applications using the data: offenerhaushalt@kdz.or.at

### KDZ Quicktest

Financial health ratios at:
`https://www.offenerhaushalt.at/gemeinde/tulln-der-donau/quicktest`

Five ratios: offentliche Sparquote, Eigenfinanzierungsquote, Verschuldungsdauer,
Schuldendienstquote, Investitionsquote. HTML only (no CSV download). May need scraping.

### ETL Implications

1. **Two parsers needed:** VRV97 (ISO-8859-1, 9 cols) and VRV2015 (UTF-8, 16 cols)
2. **VRV2015 download is session-based:** 3-step token exchange required
3. **Three VRV2015 components per year:** fhh, ehh, vhh (each a separate download)
4. **German decimal format:** comma separator (parse `"2825319,23"` as `2825319.23`)
5. **VRV97-to-VRV2015 mapping:** account codes differ; crosswalk table needed for trends

### Sample Files

- `priv/samples/vrv97_tulln_2018_finanzdaten.csv` -- VRV97, 2018 Tulln finanzdaten
- `priv/samples/vrv2015_tulln_2024_fhh_ra.csv` -- VRV2015, 2024 Finanzierungshaushalt RA
