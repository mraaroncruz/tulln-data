defmodule TullnDataWeb.MapComponents do
  use Phoenix.Component

  @default_base_layer %{
    url: "https://maps.wien.gv.at/basemap/geolandbasemap/normal/google3857/{z}/{y}/{x}.png",
    attribution: "&copy; <a href=\"https://basemap.at\">basemap.at</a>"
  }

  attr :id, :string, required: true
  attr :center, :list, default: [15.882, 48.332]
  attr :zoom, :integer, default: 14
  attr :base_layer, :map, default: nil
  attr :overlays, :list, default: []
  attr :vector_features, :list, default: []
  attr :on_feature_click, :string, default: nil
  attr :class, :string, default: "w-full h-full"

  def map(assigns) do
    assigns =
      assign_new(assigns, :resolved_base_layer, fn ->
        assigns[:base_layer] || @default_base_layer
      end)

    ~H"""
    <div
      id={@id}
      phx-hook="MapComponent"
      phx-update="ignore"
      data-center={Jason.encode!(@center)}
      data-zoom={@zoom}
      data-base-layer={Jason.encode!(@resolved_base_layer)}
      data-overlays={Jason.encode!(@overlays)}
      data-vector-features={Jason.encode!(feature_collection(@vector_features))}
      data-on-feature-click={@on_feature_click}
      class={@class}
    />
    """
  end

  @doc """
  Pushes updated vector features to the map hook on the client.
  Call this from your LiveView's handle_event/handle_info when features change.
  """
  def push_vector_features(socket, map_id, features) do
    Phoenix.LiveView.push_event(socket, "map:#{map_id}:update_features", %{
      geojson: feature_collection(features)
    })
  end

  @doc """
  Pushes updated WMS overlays to the map hook on the client.
  """
  def push_overlays(socket, map_id, overlays) do
    Phoenix.LiveView.push_event(socket, "map:#{map_id}:update_overlays", %{overlays: overlays})
  end

  defp feature_collection(features) do
    %{"type" => "FeatureCollection", "features" => features}
  end
end
