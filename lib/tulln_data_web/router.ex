defmodule TullnDataWeb.Router do
  use TullnDataWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TullnDataWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TullnDataWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/info", PageController, :info
    live "/haushalt/:slug", HaushaltLive
    live "/map", MapDemoLive
    live "/hochwasser/test", HochwasserTestLive
  end

  scope "/wms", TullnDataWeb do
    get "/:upstream", WmsProxyController, :proxy
  end

  # Other scopes may use custom stacks.
  # scope "/api", TullnDataWeb do
  #   pipe_through :api
  # end
end
