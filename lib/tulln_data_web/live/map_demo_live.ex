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

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, polygon_name: "Hauptplatz")}
  end

  @impl true
  def handle_event("load_polygon", _params, socket) do
    geojson = feature_collection([@tulln_hauptplatz])

    {:noreply,
     socket
     |> assign(polygon_name: "Hauptplatz")
     |> push_event("update_parcels", %{geojson: geojson})}
  end

  def handle_event("push_update", _params, socket) do
    geojson = feature_collection([@tulln_hauptplatz, @donaupark])

    {:noreply,
     socket
     |> assign(polygon_name: "Hauptplatz + Donaupark")
     |> push_event("update_parcels", %{geojson: geojson})}
  end

  def handle_event("viewport_changed", params, socket) do
    IO.inspect(params, label: "viewport")
    {:noreply, socket}
  end

  defp feature_collection(features) do
    %{"type" => "FeatureCollection", "features" => features}
  end
end
