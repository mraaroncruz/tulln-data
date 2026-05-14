defmodule TullnDataWeb.PageController do
  use TullnDataWeb, :controller

  alias TullnData.Budgets
  alias TullnData.Budgets.Quicktest

  def home(conn, _params) do
    municipalities =
      Budgets.list_municipalities()
      |> Enum.map(fn m ->
        Map.put(m, :grade, Quicktest.overall_grade(m.slug))
      end)

    render(conn, :home, municipalities: municipalities)
  end

  def info(conn, _params) do
    render(conn, :info)
  end
end
