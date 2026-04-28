defmodule TullnDataWeb.PageController do
  use TullnDataWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
