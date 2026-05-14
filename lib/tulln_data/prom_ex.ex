defmodule TullnData.PromEx do
  @moduledoc """
  PromEx telemetry collector. Prometheus metrics are exposed at `/metrics`,
  wired via `PromEx.Plug` in `TullnDataWeb.Endpoint`.
  """

  use PromEx, otp_app: :tulln_data

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: TullnDataWeb.Router, endpoint: TullnDataWeb.Endpoint},
      Plugins.Ecto,
      TullnData.PromEx.BudgetPlugin
    ]
  end
end
