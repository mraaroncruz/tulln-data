defmodule TullnDataWeb.HochwasserTestLiveTest do
  use TullnDataWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag :external

  test "renders gauge widgets", %{conn: conn} do
    {:ok, view, html} = live(conn, "/hochwasser/test")

    assert html =~ "Hochwasser-Dashboard"
    assert html =~ "Kienstock" or render(view) =~ "Kienstock"
  end
end
