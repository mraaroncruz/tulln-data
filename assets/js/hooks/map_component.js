import maplibregl from "maplibre-gl"

const MapComponent = {
  mounted() {
    const config = {
      center: JSON.parse(this.el.dataset.center),
      zoom: parseInt(this.el.dataset.zoom, 10),
      baseLayer: JSON.parse(this.el.dataset.baseLayer),
      overlays: JSON.parse(this.el.dataset.overlays),
      vectorFeatures: JSON.parse(this.el.dataset.vectorFeatures),
      onFeatureClick: this.el.dataset.onFeatureClick || null,
    }

    this._overlayIds = []

    this.map = new maplibregl.Map({
      container: this.el,
      style: buildStyle(config.baseLayer),
      center: config.center,
      zoom: config.zoom,
    })

    this.map.addControl(new maplibregl.NavigationControl())

    this.map.on("load", () => {
      this._addVectorSource(config.vectorFeatures)
      this._addOverlays(config.overlays)

      if (config.onFeatureClick) {
        this._setupClickHandler(config.onFeatureClick)
      }
    })

    this.handleEvent(`map:${this.el.id}:update_features`, ({ geojson }) => {
      const source = this.map.getSource("vector-features")
      if (source) source.setData(geojson)
    })

    this.handleEvent(`map:${this.el.id}:update_overlays`, ({ overlays }) => {
      this._removeOverlays()
      this._addOverlays(overlays)
    })
  },

  _addVectorSource(geojson) {
    this.map.addSource("vector-features", {
      type: "geojson",
      data: geojson,
    })

    this.map.addLayer({
      id: "vector-features-fill",
      type: "fill",
      source: "vector-features",
      paint: {
        "fill-color": "#3b82f6",
        "fill-opacity": 0.4,
      },
    })

    this.map.addLayer({
      id: "vector-features-outline",
      type: "line",
      source: "vector-features",
      paint: {
        "line-color": "#1d4ed8",
        "line-width": 2,
      },
    })

    this.map.addLayer({
      id: "vector-features-circle",
      type: "circle",
      source: "vector-features",
      filter: ["==", "$type", "Point"],
      paint: {
        "circle-radius": 6,
        "circle-color": "#3b82f6",
        "circle-stroke-width": 2,
        "circle-stroke-color": "#1d4ed8",
      },
    })
  },

  _addOverlays(overlays) {
    for (const overlay of overlays) {
      if (overlay.type === "wms") {
        const sourceId = `overlay-${overlay.id}`
        this.map.addSource(sourceId, {
          type: "raster",
          tiles: [buildWmsUrl(overlay)],
          tileSize: overlay.tile_size || 256,
        })
        this.map.addLayer({
          id: sourceId,
          type: "raster",
          source: sourceId,
          paint: { "raster-opacity": overlay.opacity || 0.7 },
        })
        this._overlayIds.push(sourceId)
      }
    }
  },

  _removeOverlays() {
    for (const id of this._overlayIds) {
      if (this.map.getLayer(id)) this.map.removeLayer(id)
      if (this.map.getSource(id)) this.map.removeSource(id)
    }
    this._overlayIds = []
  },

  _setupClickHandler(eventName) {
    const clickableLayers = ["vector-features-fill", "vector-features-circle"]

    for (const layerId of clickableLayers) {
      this.map.on("click", layerId, (e) => {
        if (e.features && e.features.length > 0) {
          const feature = e.features[0]
          this.pushEvent(eventName, {
            properties: feature.properties,
            geometry: feature.geometry,
            lng_lat: [e.lngLat.lng, e.lngLat.lat],
          })
        }
      })

      this.map.on("mouseenter", layerId, () => {
        this.map.getCanvas().style.cursor = "pointer"
      })
      this.map.on("mouseleave", layerId, () => {
        this.map.getCanvas().style.cursor = ""
      })
    }
  },

  destroyed() {
    if (this.map) this.map.remove()
  },
}

function buildStyle(baseLayer) {
  return {
    version: 8,
    sources: {
      "base-layer": {
        type: "raster",
        tiles: [baseLayer.url],
        tileSize: baseLayer.tile_size || 256,
        attribution: baseLayer.attribution || "",
      },
    },
    layers: [
      {
        id: "base-layer",
        type: "raster",
        source: "base-layer",
        minzoom: 0,
        maxzoom: 19,
      },
    ],
  }
}

function buildWmsUrl(overlay) {
  const params = new URLSearchParams({
    service: "WMS",
    request: "GetMap",
    layers: overlay.layers,
    styles: overlay.styles || "",
    format: overlay.format || "image/png",
    transparent: "true",
    version: overlay.version || "1.3.0",
    width: "256",
    height: "256",
    crs: "EPSG:3857",
  })
  return `${overlay.url}?${params.toString()}&bbox={bbox-epsg-3857}`
}

export default MapComponent
