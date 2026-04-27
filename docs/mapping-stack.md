# Mapping Stack Decision

**Decision: MapLibre GL JS**

Date: 2026-04-27
Status: Accepted
Issue: ELB-1330

## Context

Every TullnData dashboard renders a slippy map. The mapping library choice
affects vector-tile capability, WMS support for Austrian government layers,
rendering performance with thousands of parcels, bundle size, LiveView
interoperability, and long-term licensing.

## Candidates

### MapLibre GL JS

Open-source fork of Mapbox GL JS (BSD-3-Clause). WebGL-based, native vector
tile rendering, no API key required.

| Criterion | Rating |
|---|---|
| Vector tiles | Native (MVT via WebGL) |
| WMS support | Via `raster` source type — sufficient |
| Performance (thousands of polygons) | Excellent (GPU-accelerated) |
| Bundle size | ~200 KB gzipped |
| LiveView hook complexity | Moderate |
| License | BSD-3-Clause, no API key |
| basemap.at support | Native WMTS vector tiles |

### Leaflet

Mature, lightweight raster-tile library with a large plugin ecosystem.

| Criterion | Rating |
|---|---|
| Vector tiles | Plugin required (leaflet.vectorGrid or maplibre-gl-leaflet) |
| WMS support | Built-in `L.tileLayer.wms()` |
| Performance (thousands of polygons) | Adequate with Canvas renderer, degrades at scale |
| Bundle size | ~40 KB gzipped |
| LiveView hook complexity | Simple |
| License | BSD-2-Clause |
| basemap.at support | Raster WMTS only |

### OpenLayers

Full-featured GIS library with first-class OGC protocol support.

| Criterion | Rating |
|---|---|
| Vector tiles | Supported |
| WMS support | Best-in-class (WMS, WFS, GML parsing) |
| Performance (thousands of polygons) | Good (Canvas/WebGL hybrid) |
| Bundle size | ~150 KB gzipped (tree-shakeable) |
| LiveView hook complexity | Complex API surface |
| License | BSD-2-Clause |
| basemap.at support | Full (all WMTS formats) |

## Decision Rationale

**MapLibre GL JS** is the best fit for TullnData. The decisive factors:

1. **basemap.at vector tiles.** Austria's official basemap service provides
   WMTS vector tiles (MVT format). MapLibre consumes these natively with
   style-based rendering — no rasterization overhead, resolution-independent
   labels, and smooth zoom transitions.

2. **Parcel rendering performance.** Dashboards must display ~thousands of
   INVEKOS agricultural parcels simultaneously. MapLibre's WebGL pipeline
   renders these as GPU-accelerated fills/strokes without DOM overhead.
   Leaflet's SVG/Canvas renderer struggles at this scale; OpenLayers can
   handle it but requires more configuration.

3. **WMS for NÖ Atlas layers.** HORA flood zones, Solarkataster, and
   Flächenwidmung are served as WMS from `sdi.noe.gv.at`. MapLibre loads
   these as `raster` sources — not as elegant as OpenLayers' native WMS
   support, but fully functional. We query and process WFS data server-side
   in PostGIS, so client-side WFS parsing (OpenLayers' main advantage) is
   unnecessary.

4. **LiveView interop pattern.** The hook lifecycle is straightforward:

   ```javascript
   // Mount: create map once, outside LiveView's DOM management
   mounted() {
     this.map = new maplibregl.Map({ container: this.el, ... });
   }

   // Receive server-pushed GeoJSON updates
   this.handleEvent("update_parcels", ({ geojson }) => {
     this.map.getSource("parcels").setData(geojson);
   });

   // Push viewport changes back to server
   this.map.on("moveend", () => {
     this.pushEvent("viewport_changed", this.map.getBounds());
   });
   ```

   The map DOM is fully managed by JavaScript — LiveView patches never touch
   it. Data flows via `pushEvent` / `handleEvent`.

5. **No vendor lock-in.** BSD-3-Clause license, no API key, no usage metering.
   Backed by the MapLibre organization (AWS, Meta, Microsoft contributors).

## Tradeoffs Accepted

- **WMS is second-class.** Adding a WMS layer requires a `raster` source with
  manual tile URL templating. OpenLayers would be simpler here. Acceptable
  because we only need a handful of WMS overlays, and the pattern is
  copy-paste once established.

- **Larger bundle than Leaflet.** ~200 KB vs ~40 KB gzipped. Acceptable for a
  dashboard app where the map is the primary UI. The WebGL renderer pays for
  itself at our data volumes.

- **Steeper initial learning curve than Leaflet.** MapLibre uses a
  style-specification-driven approach (layers, sources, expressions) rather
  than imperative method calls. This is actually an advantage at scale — styles
  are declarative and composable — but the ramp-up is longer.

## Base Map

**basemap.at** (https://basemap.at) — free Austrian government basemap with
excellent local detail (street names, building footprints, contours). Available
as both raster and vector WMTS. We'll use the vector tile endpoint for
MapLibre and fall back to the raster endpoint for WMS overlay compositing.

Alternative: OpenStreetMap Austria style via tile servers. Kept as fallback.

## NPM Package

```
maplibre-gl  (latest 5.x)
```

Installed via the Phoenix asset pipeline (`assets/package.json` or import map).
