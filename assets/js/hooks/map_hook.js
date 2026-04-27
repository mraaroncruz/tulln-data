import maplibregl from "maplibre-gl"

const MapHook = {
  mounted() {
    this.map = new maplibregl.Map({
      container: this.el,
      style: {
        version: 8,
        sources: {
          "basemap-at": {
            type: "raster",
            tiles: [
              "https://maps.wien.gv.at/basemap/geolandbasemap/normal/google3857/{z}/{y}/{x}.png"
            ],
            tileSize: 256,
            attribution: '&copy; <a href="https://basemap.at">basemap.at</a>'
          }
        },
        layers: [
          {
            id: "basemap",
            type: "raster",
            source: "basemap-at",
            minzoom: 0,
            maxzoom: 19
          }
        ]
      },
      center: [15.882, 48.332],
      zoom: 14
    })

    this.map.addControl(new maplibregl.NavigationControl())

    this.map.on("load", () => {
      this.map.addSource("parcels", {
        type: "geojson",
        data: { type: "FeatureCollection", features: [] }
      })

      this.map.addLayer({
        id: "parcels-fill",
        type: "fill",
        source: "parcels",
        paint: {
          "fill-color": "#3b82f6",
          "fill-opacity": 0.4
        }
      })

      this.map.addLayer({
        id: "parcels-outline",
        type: "line",
        source: "parcels",
        paint: {
          "line-color": "#1d4ed8",
          "line-width": 2
        }
      })

      this.map.on("click", "parcels-fill", (e) => {
        const feature = e.features[0]
        new maplibregl.Popup()
          .setLngLat(e.lngLat)
          .setHTML(`<strong>${feature.properties.name}</strong>`)
          .addTo(this.map)
      })
    })

    this.map.on("moveend", () => {
      const bounds = this.map.getBounds()
      this.pushEvent("viewport_changed", {
        sw: [bounds.getSouthWest().lng, bounds.getSouthWest().lat],
        ne: [bounds.getNorthEast().lng, bounds.getNorthEast().lat],
        zoom: this.map.getZoom()
      })
    })

    this.handleEvent("update_parcels", ({ geojson }) => {
      const source = this.map.getSource("parcels")
      if (source) {
        source.setData(geojson)
      }
    })
  },

  destroyed() {
    if (this.map) {
      this.map.remove()
    }
  }
}

export default MapHook
