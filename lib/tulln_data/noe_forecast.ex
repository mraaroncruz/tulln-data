defmodule TullnData.NoeForecast do
  @moduledoc """
  Client for the NÖ Wasserstand 48h forecast API.

  Provider: Hydrographischer Dienst Niederösterreich.
  Format: CSV (semicolon-delimited, UTF-8).
  No CORS — must be fetched server-side.
  """

  @base_url "https://www.noe.gv.at/wasserstand"

  @station_numbers %{
    kienstock: "207357",
    korneuburg: "207241"
  }

  def station_numbers, do: @station_numbers

  @doc """
  Fetches the 48h water level forecast for a station.

  Returns `{:ok, forecast}` where forecast is:
    %{
      station_name: "Kienstock",
      station_number: "207357",
      unit: "cm",
      observed_until: ~N[...],
      points: [%{timestamp: ~N[...], value: 186.0, min: 186.0, max: 186.0}, ...]
    }
  """
  def water_level_forecast(station_key) when is_map_key(@station_numbers, station_key) do
    number = @station_numbers[station_key]
    fetch_forecast(number, "WasserstandPrognose")
  end

  @doc """
  Fetches the 48h discharge forecast for a station.
  """
  def discharge_forecast(station_key) when is_map_key(@station_numbers, station_key) do
    number = @station_numbers[station_key]
    fetch_forecast(number, "DurchflussPrognose")
  end

  defp fetch_forecast(station_number, parameter) do
    url = "#{@base_url}/kidata/stationdata/#{station_number}_#{parameter}_48Stunden.csv"

    case Req.get(url, decode_body: false) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        parse_csv(body)

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def parse_csv(body) do
    lines = String.split(body, ~r/\r?\n/, trim: true)

    if length(lines) < 10 do
      {:error, :invalid_csv}
    else
      header = Enum.take(lines, 9)
      data_lines = Enum.drop(lines, 10)

      station_name = header |> Enum.at(1) |> parse_header_value()
      station_number = header |> Enum.at(2) |> parse_header_value()
      unit = header |> Enum.at(7) |> parse_header_value()
      observed_until = header |> Enum.at(6) |> parse_header_value() |> parse_timestamp()

      points =
        data_lines
        |> Enum.map(&parse_data_row/1)
        |> Enum.reject(&is_nil/1)

      {:ok,
       %{
         station_name: station_name,
         station_number: station_number,
         unit: unit,
         observed_until: observed_until,
         points: points
       }}
    end
  end

  defp parse_header_value(line) do
    case String.split(line, ";", parts: 2) do
      [_key, value | _] -> value |> String.trim_trailing(";") |> String.trim()
      _ -> nil
    end
  end

  defp parse_data_row(line) do
    case String.split(line, ";") do
      [timestamp_str, mean_str, min_str, max_str | _] ->
        with ts when not is_nil(ts) <- parse_timestamp(String.trim(timestamp_str)),
             {mean, _} <- Float.parse(String.trim(mean_str)) do
          min_val = parse_float_or_nil(min_str)
          max_val = parse_float_or_nil(max_str)

          %{
            timestamp: ts,
            value: mean,
            min: min_val || mean,
            max: max_val || mean
          }
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_float_or_nil(str) do
    case Float.parse(String.trim(str)) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(str) do
    case NaiveDateTime.from_iso8601(String.replace(str, " ", "T")) do
      {:ok, ndt} -> ndt
      _ -> nil
    end
  end
end
