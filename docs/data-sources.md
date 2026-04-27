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

## Alternative Sources (evaluated, not used)

| Source | Access | Why not primary |
|---|---|---|
| PegelAlarm API (api.pegelalarm.at) | JSON, requires auth (free test account via office@sobos.at) | Auth required, adds operational dependency |
| DanubeHIS (danubehis.org) | WaterML 2.0 / CSV / XLS, requires registration | Registration required, 30-min intervals |
| viadonau DoRIS (doris.bmimi.gv.at) | SPA only, no public API | No programmatic access |
| NÖ Wasserstand (noe.gv.at/wasserstand) | SPA only, no public API | No programmatic access |
