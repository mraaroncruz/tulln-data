defmodule TullnData.Hora do
  @moduledoc false

  alias TullnData.FloodScenario
  alias TullnData.Repo

  import Ecto.Query

  @base_url "https://inspire.lfrz.gv.at/000801/ds"
  @bezirk_tulln_prefix "321"

  @scenarios %{
    "hq30" => {@base_url <> "/HWRL_UEFF_HQ30.zip", "UEFF_HQ30.gml", 30},
    "hq100" => {@base_url <> "/HWRL_UEFF_HQ100.zip", "UEFF_HQ100.gml", 100},
    "hq300" => {@base_url <> "/HWRL_UEFF_HQ300.zip", "UEFF_HQ300.gml", 300}
  }

  def scenarios, do: Map.keys(@scenarios)

  def ingest(scenario) when scenario in ~w(hq30 hq100 hq300) do
    {zip_url, gml_filename, return_period} = Map.fetch!(@scenarios, scenario)

    with {:ok, zip_path} <- download(zip_url),
         {:ok, gml_path} <- extract(zip_path, gml_filename),
         {:ok, features} <- parse_gml(gml_path, return_period) do
      result = upsert_features(features, scenario, return_period)
      cleanup([zip_path, gml_path])
      result
    end
  end

  def ingest_all do
    Enum.map(scenarios(), fn scenario ->
      {scenario, ingest(scenario)}
    end)
  end

  defp download(url) do
    tmp_dir = System.tmp_dir!()
    filename = url |> URI.parse() |> Map.get(:path) |> Path.basename()
    dest = Path.join(tmp_dir, "hora_#{filename}")

    case Req.get(url, into: File.stream!(dest), receive_timeout: 600_000) do
      {:ok, %{status: 200}} -> {:ok, dest}
      {:ok, resp} -> {:error, "HTTP #{resp.status} downloading #{url}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract(zip_path, gml_filename) do
    dest_dir = Path.join(System.tmp_dir!(), "hora_extract_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dest_dir)

    case :zip.unzip(String.to_charlist(zip_path), [{:cwd, String.to_charlist(dest_dir)}]) do
      {:ok, _files} ->
        gml_path = Path.join(dest_dir, gml_filename)

        if File.exists?(gml_path) do
          {:ok, gml_path}
        else
          {:error, "GML file #{gml_filename} not found in archive"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_gml(gml_path, return_period) do
    handler = TullnData.Hora.GmlHandler
    state = handler.initial_state(@bezirk_tulln_prefix, return_period)

    case :xmerl_sax_parser.file(
           String.to_charlist(gml_path),
           event_fun: &handler.handle_event/3,
           event_state: state
         ) do
      {:ok, final_state, _rest} ->
        {:ok, handler.features(final_state)}

      {:fatal_error, _location, reason, _end_tags, _state} ->
        {:error, {:xml_parse_error, reason}}
    end
  end

  defp upsert_features(features, scenario, return_period) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    results =
      Repo.transaction(fn ->
        Enum.map(features, fn feature ->
          attrs = %{
            source_id: feature.source_id,
            scenario: scenario,
            return_period: return_period,
            geom: feature.geom,
            source_updated_at: feature.source_updated_at,
            updated_at: now,
            inserted_at: now
          }

          Repo.insert!(
            FloodScenario.changeset(%FloodScenario{}, attrs),
            on_conflict: {:replace, [:geom, :source_updated_at, :updated_at]},
            conflict_target: [:source_id, :scenario]
          )
        end)
      end)

    case results do
      {:ok, records} -> {:ok, length(records)}
      error -> error
    end
  end

  defp cleanup(paths) do
    Enum.each(paths, fn path ->
      dir = Path.dirname(path)
      if String.contains?(dir, "hora_extract_"), do: File.rm_rf!(dir)
      File.rm(path)
    end)
  end

  def flood_class(%Geo.Point{} = point) do
    query =
      from(fs in FloodScenario,
        where: fragment("ST_Contains(?, ?)", fs.geom, ^point),
        select: fs.scenario,
        order_by: [asc: fs.return_period],
        limit: 1
      )

    Repo.one(query)
  end
end
