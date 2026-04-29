defmodule TullnDataWeb.MapDemoLive do
  use TullnDataWeb, :live_view

  @tulln_hauptplatz %{
    "type" => "Feature",
    "properties" => %{"name" => "Tulln Hauptplatz"},
    "geometry" => %{
      "type" => "Polygon",
      "coordinates" => [
        [
          [15.8820, 48.3310],
          [15.8835, 48.3310],
          [15.8835, 48.3320],
          [15.8820, 48.3320],
          [15.8820, 48.3310]
        ]
      ]
    }
  }

  @donaupark %{
    "type" => "Feature",
    "properties" => %{"name" => "Donaupark"},
    "geometry" => %{
      "type" => "Polygon",
      "coordinates" => [
        [
          [15.8780, 48.3335],
          [15.8810, 48.3335],
          [15.8810, 48.3355],
          [15.8780, 48.3355],
          [15.8780, 48.3335]
        ]
      ]
    }
  }

  @noe_atlas_overlay %{
    id: "noe-atlas",
    type: "wms",
    url: "https://gis.noe.gv.at/arcgis/services/PUBLIC/atlas_noe/MapServer/WMSServer",
    layers: "0",
    opacity: 0.5
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Map Demo",
       features_label: "(none)",
       wms_active: false,
       clicked_feature: nil
     )}
  end

  @impl true
  def handle_event("load_polygon", _params, socket) do
    {:noreply,
     socket
     |> assign(features_label: "Hauptplatz")
     |> push_vector_features("map", [@tulln_hauptplatz])}
  end

  def handle_event("push_update", _params, socket) do
    {:noreply,
     socket
     |> assign(features_label: "Hauptplatz + Donaupark")
     |> push_vector_features("map", [@tulln_hauptplatz, @donaupark])}
  end

  def handle_event("toggle_wms", _params, socket) do
    overlays = if socket.assigns.wms_active, do: [], else: [@noe_atlas_overlay]

    {:noreply,
     socket
     |> assign(wms_active: !socket.assigns.wms_active)
     |> push_overlays("map", overlays)}
  end

  def handle_event("feature_clicked", params, socket) do
    {:noreply, assign(socket, clicked_feature: params["properties"])}
  end
end
