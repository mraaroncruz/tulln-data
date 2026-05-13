defmodule TullnData.Hora do
  @moduledoc """
  Ingest pipeline for HORA HQ30/HQ100/HQ300 flood inundation polygons
  from Austria's INSPIRE node (`inspire.lfrz.gv.at`).

  Heavy lifting (GML parsing, CRS reprojection, attribute filter) is delegated
  to GDAL's `ogr2ogr` for performance and to avoid binary-heap pressure on the
  BEAM. The Elixir code orchestrates download → unzip → ogr2ogr → SQL upsert.

  Requires `ogr2ogr` (from `gdal`) on PATH at runtime.
  """

  alias TullnData.FloodScenario
  alias TullnData.Repo

  import Ecto.Query
  require Logger

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

    with {:ok, zip_path} <- download_cached(zip_url),
         {:ok, gml_path} <- extract_cached(zip_path, gml_filename),
         {:ok, count} <- ogr_to_staging(gml_path, scenario),
         {:ok, count} <- copy_into_canonical(scenario, return_period, count) do
      {:ok, count}
    end
  end

  def ingest_all do
    Enum.map(scenarios(), fn scenario ->
      {scenario, ingest(scenario)}
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

  defp download_cached(url) do
    tmp_dir = System.tmp_dir!()
    filename = url |> URI.parse() |> Map.get(:path) |> Path.basename()
    dest = Path.join(tmp_dir, "hora_#{filename}")

    if File.exists?(dest) do
      Logger.info("HORA: using cached download #{dest}")
      {:ok, dest}
    else
      download(url, dest)
    end
  end

  defp download(url, dest) do
    Logger.info("HORA: downloading #{url}")
    started = System.monotonic_time(:millisecond)
    file = File.open!(dest, [:write, :binary])
    counter = :counters.new(2, [])

    try do
      result =
        Req.get(url,
          receive_timeout: 600_000,
          into: fn {:data, chunk}, {req, resp} ->
            IO.binwrite(file, chunk)
            :counters.add(counter, 1, byte_size(chunk))
            mb = div(:counters.get(counter, 1), 1_048_576)
            last = :counters.get(counter, 2)

            if mb >= last + 100 do
              :counters.put(counter, 2, mb)
              Logger.info("HORA: downloaded #{mb} MB")
            end

            {:cont, {req, resp}}
          end
        )

      total_mb = div(:counters.get(counter, 1), 1_048_576)
      elapsed = elapsed_s(started)

      case result do
        {:ok, %{status: 200}} ->
          Logger.info("HORA: download complete (#{total_mb} MB in #{elapsed}s)")
          {:ok, dest}

        {:ok, resp} ->
          {:error, "HTTP #{resp.status} downloading #{url}"}

        {:error, reason} ->
          {:error, reason}
      end
    after
      File.close(file)
    end
  end

  defp extract_cached(zip_path, gml_filename) do
    pattern = Path.join([System.tmp_dir!(), "hora_extract_*", gml_filename])

    case Path.wildcard(pattern) do
      [path | _] ->
        Logger.info("HORA: using cached extracted GML #{path}")
        {:ok, path}

      [] ->
        extract(zip_path, gml_filename)
    end
  end

  defp extract(zip_path, gml_filename) do
    dest_dir = Path.join(System.tmp_dir!(), "hora_extract_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dest_dir)

    Logger.info("HORA: extracting #{Path.basename(zip_path)}")
    started = System.monotonic_time(:millisecond)

    case :zip.unzip(String.to_charlist(zip_path), [{:cwd, String.to_charlist(dest_dir)}]) do
      {:ok, _files} ->
        gml_path = Path.join(dest_dir, gml_filename)

        if File.exists?(gml_path) do
          size_mb = div(File.stat!(gml_path).size, 1_048_576)
          Logger.info("HORA: extracted #{gml_filename} (#{size_mb} MB in #{elapsed_s(started)}s)")
          {:ok, gml_path}
        else
          {:error, "GML file #{gml_filename} not found in archive"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ogr_to_staging(gml_path, scenario) do
    staging = staging_table(scenario)

    Logger.info(
      "HORA: ogr2ogr → #{staging} (filter localId LIKE '#{@bezirk_tulln_prefix}%', reproject to 4326)"
    )

    started = System.monotonic_time(:millisecond)

    # GDAL's GML driver reads INSPIRE HORA coords as (X=col1, Y=col2), but the
    # source stores them in EPSG:3035 authority order (northing, easting), so
    # X and Y end up swapped. We skip ogr2ogr's reprojection and fix the axis
    # order in SQL via ST_FlipCoordinates + ST_Transform — deterministic, and
    # avoids fighting GDAL's auto axis-mapping heuristics.
    args = [
      "-f",
      "PostgreSQL",
      pg_dsn(),
      gml_path,
      "HazardArea",
      "-nln",
      staging,
      "-where",
      "localId LIKE '#{@bezirk_tulln_prefix}%'",
      "-overwrite",
      "-lco",
      "GEOMETRY_NAME=geom",
      "-lco",
      "FID=fid"
    ]

    case System.cmd("ogr2ogr", args, stderr_to_stdout: true) do
      {output, 0} ->
        case Repo.query("SELECT COUNT(*)::int FROM #{staging}", []) do
          {:ok, %{rows: [[count]]}} ->
            Logger.info("HORA: ogr2ogr complete — #{count} rows staged in #{elapsed_s(started)}s")
            if String.length(output) > 0, do: Logger.debug(output)
            {:ok, count}

          {:error, reason} ->
            {:error, reason}
        end

      {output, status} ->
        {:error, "ogr2ogr exited #{status}: #{String.trim(output)}"}
    end
  end

  defp copy_into_canonical(scenario, return_period, _staged_count) do
    staging = staging_table(scenario)
    Logger.info("HORA: upserting #{staging} → flood_scenarios")
    started = System.monotonic_time(:millisecond)

    sql = """
    INSERT INTO flood_scenarios
      (source_id, scenario, return_period, geom, source_updated_at, inserted_at, updated_at)
    SELECT
      gml_id,
      $1::text,
      $2::int,
      ST_Transform(ST_SetSRID(ST_FlipCoordinates(geom), 3035), 4326),
      beginlifespanversion,
      NOW(),
      NOW()
    FROM #{staging}
    ON CONFLICT (source_id, scenario) DO UPDATE
      SET geom = EXCLUDED.geom,
          source_updated_at = EXCLUDED.source_updated_at,
          updated_at = NOW();
    """

    case Repo.query(sql, [scenario, return_period]) do
      {:ok, %{num_rows: count}} ->
        Repo.query!("DROP TABLE IF EXISTS #{staging}")
        Logger.info("HORA: upsert complete — #{count} rows in #{elapsed_s(started)}s")
        {:ok, count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp staging_table(scenario), do: "hora_staging_#{scenario}"

  defp pg_dsn do
    cfg = Repo.config()

    "PG:host=#{cfg[:hostname]} port=#{cfg[:port]} dbname=#{cfg[:database]} user=#{cfg[:username]} password=#{cfg[:password]}"
  end

  defp elapsed_s(started_ms) do
    Float.round((System.monotonic_time(:millisecond) - started_ms) / 1000, 1)
  end
end
