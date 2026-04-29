defmodule Mix.Tasks.Tulln.Ingest.Hora do
  use Mix.Task

  @shortdoc "Ingest HORA flood inundation polygons for Bezirk Tulln"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    scenarios = if args == [], do: TullnData.Hora.scenarios(), else: args

    invalid = Enum.reject(scenarios, &(&1 in TullnData.Hora.scenarios()))

    if invalid != [] do
      Mix.raise(
        "Unknown scenarios: #{Enum.join(invalid, ", ")}. Valid: #{Enum.join(TullnData.Hora.scenarios(), ", ")}"
      )
    end

    for scenario <- scenarios do
      Mix.shell().info("Ingesting #{scenario}...")

      case TullnData.Hora.ingest(scenario) do
        {:ok, count} ->
          Mix.shell().info("  #{scenario}: #{count} polygons upserted")

        {:error, reason} ->
          Mix.shell().error("  #{scenario} failed: #{inspect(reason)}")
      end
    end
  end
end
