defmodule Mix.Tasks.Tulln.Ingest.Budget do
  use Mix.Task

  @shortdoc "Ingest municipal budget CSVs from offenerhaushalt.at"

  @moduledoc """
  Usage:

      mix tulln.ingest.budget <slug> <year>

  - `<slug>`: a Gemeinde slug seeded into `budget_municipalities`
    (e.g. `tulln-der-donau`, `klosterneuburg`, `korneuburg`, `stockerau`).
  - `<year>`: a fiscal year. 2001–2019 routes to the VRV97 endpoint; 2020+
    routes to all three VRV2015 haushalte (fhh, ehh, vhh).

  Re-running the same `slug + year` is idempotent: line items are replaced for
  that fiscal year.
  """

  @impl Mix.Task
  def run([slug, year_str]) do
    Mix.Task.run("app.start")

    year =
      case Integer.parse(year_str) do
        {y, ""} -> y
        _ -> Mix.raise("Invalid year: #{year_str}")
      end

    cond do
      year in 2001..2019 ->
        ingest_vrv97(slug, year)

      year >= 2020 ->
        ingest_vrv2015(slug, year)

      true ->
        Mix.raise("Year #{year} out of supported range (2001+)")
    end
  end

  def run(_) do
    Mix.raise("Usage: mix tulln.ingest.budget <slug> <year>")
  end

  defp ingest_vrv97(slug, year) do
    Mix.shell().info("Ingesting #{slug} vrv97 #{year}…")

    case TullnData.Budgets.Ingest.vrv97(slug, year) do
      {:ok, %{line_items: count}} ->
        Mix.shell().info("  #{slug} vrv97 #{year}: #{count} line items")

      {:error, reason} ->
        Mix.shell().error("  #{slug} vrv97 #{year} failed: #{inspect(reason)}")
    end
  end

  defp ingest_vrv2015(slug, year) do
    for haushalt <- ~w(fhh ehh vhh) do
      Mix.shell().info("Ingesting #{slug} vrv2015 #{year} #{haushalt}…")

      case TullnData.Budgets.Ingest.vrv2015(slug, year, haushalt) do
        {:ok, %{line_items: count}} ->
          Mix.shell().info("  #{slug} vrv2015 #{year} #{haushalt}: #{count} line items")

        {:error, reason} ->
          Mix.shell().error("  #{slug} vrv2015 #{year} #{haushalt} failed: #{inspect(reason)}")
      end
    end
  end
end
