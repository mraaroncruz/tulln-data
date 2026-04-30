defmodule TullnDataWeb.MapDemoLiveTest do
  use TullnDataWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders map demo page with map component", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/map")

    assert html =~ "Map Component Demo"
    assert has_element?(view, "#map[phx-hook=MapComponent]")
  end

  test "renders control buttons", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/map")

    assert has_element?(view, "#load-polygon-btn")
    assert has_element?(view, "#push-update-btn")
    assert has_element?(view, "#toggle-wms-btn")
  end

  test "load_polygon updates features label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/map")

    view |> element("#load-polygon-btn") |> render_click()

    assert render(view) =~ "Hauptplatz"
  end

  test "push_update shows both features", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/map")

    view |> element("#push-update-btn") |> render_click()

    assert render(view) =~ "Hauptplatz + Donaupark"
  end

  test "toggle_wms toggles button label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/map")

    assert render(view) =~ "Show WMS Overlay"

    view |> element("#toggle-wms-btn") |> render_click()

    assert render(view) =~ "Hide WMS"
  end

  test "feature_clicked event updates clicked feature display", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/map")

    render_hook(view, "feature_clicked", %{
      "properties" => %{"name" => "Tulln Hauptplatz"},
      "geometry" => %{"type" => "Point", "coordinates" => [15.88, 48.33]},
      "lng_lat" => [15.88, 48.33]
    })

    assert render(view) =~ "Clicked: Tulln Hauptplatz"
  end
end
