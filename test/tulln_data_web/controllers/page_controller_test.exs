defmodule TullnDataWeb.PageControllerTest do
  use TullnDataWeb.ConnCase

  test "GET / renders the OpenTulln landing", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)
    assert body =~ "OpenTulln"
    assert body =~ "Transparenz für den Bezirk Tulln"
  end

  test "GET /info renders the methodology page", %{conn: conn} do
    conn = get(conn, ~p"/info")
    body = html_response(conn, 200)
    assert body =~ "Über OpenTulln"
    assert body =~ "Glossar der Finanzkennzahlen"
  end
end
