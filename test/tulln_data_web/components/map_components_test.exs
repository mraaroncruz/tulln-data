defmodule TullnDataWeb.MapComponentsTest do
  use TullnDataWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import TullnDataWeb.MapComponents

  defp render_and_query(assigns) do
    html = render_component(&map/1, assigns)
    document = LazyHTML.from_fragment(html)
    LazyHTML.query(document, "##{assigns[:id]}")
  end

  describe "map/1" do
    test "renders a div with the MapComponent hook and required data attributes" do
      el = render_and_query(id: "test-map", center: [15.882, 48.332], zoom: 14)

      assert LazyHTML.attribute(el, "phx-hook") == ["MapComponent"]
      assert LazyHTML.attribute(el, "phx-update") == ["ignore"]

      [center_json] = LazyHTML.attribute(el, "data-center")
      assert Jason.decode!(center_json) == [15.882, 48.332]

      assert LazyHTML.attribute(el, "data-zoom") == ["14"]
    end

    test "uses default basemap.at base layer when none provided" do
      el = render_and_query(id: "test-map")

      [base_layer_json] = LazyHTML.attribute(el, "data-base-layer")
      base_layer = Jason.decode!(base_layer_json)

      assert base_layer["url"] =~ "basemap"
      assert base_layer["attribution"] =~ "basemap.at"
    end

    test "accepts a custom base layer" do
      custom = %{url: "https://example.com/tiles/{z}/{x}/{y}.png", attribution: "Test"}
      el = render_and_query(id: "test-map", base_layer: custom)

      [base_layer_json] = LazyHTML.attribute(el, "data-base-layer")
      base_layer = Jason.decode!(base_layer_json)

      assert base_layer["url"] == "https://example.com/tiles/{z}/{x}/{y}.png"
    end

    test "serializes overlays as JSON" do
      overlays = [%{id: "noe-atlas", type: "wms", url: "https://gis.noe.gv.at/wms", layers: "0"}]
      el = render_and_query(id: "test-map", overlays: overlays)

      [overlays_json] = LazyHTML.attribute(el, "data-overlays")
      assert [%{"id" => "noe-atlas", "type" => "wms"}] = Jason.decode!(overlays_json)
    end

    test "serializes vector features as a GeoJSON FeatureCollection" do
      features = [
        %{
          "type" => "Feature",
          "properties" => %{"name" => "Test"},
          "geometry" => %{"type" => "Point", "coordinates" => [15.88, 48.33]}
        }
      ]

      el = render_and_query(id: "test-map", vector_features: features)

      [features_json] = LazyHTML.attribute(el, "data-vector-features")
      parsed = Jason.decode!(features_json)

      assert parsed["type"] == "FeatureCollection"
      assert length(parsed["features"]) == 1
      assert hd(parsed["features"])["properties"]["name"] == "Test"
    end

    test "sets on_feature_click data attribute" do
      el = render_and_query(id: "test-map", on_feature_click: "clicked")
      assert LazyHTML.attribute(el, "data-on-feature-click") == ["clicked"]
    end

    test "defaults vector features to empty collection" do
      el = render_and_query(id: "test-map")

      [features_json] = LazyHTML.attribute(el, "data-vector-features")
      assert Jason.decode!(features_json) == %{"type" => "FeatureCollection", "features" => []}
    end
  end
end
