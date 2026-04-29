defmodule TullnFlood.Pegelonline do
  @moduledoc """
  Client for the PEGELONLINE REST API v2 (wsv.de).

  Provides real-time water level data for Austrian Danube stations
  operated by viadonau. Data is unvalidated raw values at 15-minute intervals.

  License: DL-DE→Zero-2.0 (no attribution required).
  """

  @base_url "https://www.pegelonline.wsv.de/webservices/rest-api/v2"

  @stations %{
    kienstock: %{
      shortname: "KIENSTOCK",
      hzb: 207_357,
      river_km: 2015.2,
      gauge_zero_m: 194.0
    },
    korneuburg: %{
      shortname: "KORNEUBURG",
      hzb: 207_241,
      river_km: 1941.5,
      gauge_zero_m: 159.87
    }
  }

  def stations, do: @stations

  @doc """
  Fetches current water level for a station.

  Returns `{:ok, map}` with keys: `:timestamp`, `:value_cm`, `:state`.
  """
  def current_water_level(station_key) when station_key in [:kienstock, :korneuburg] do
    station = @stations[station_key]

    url =
      "#{@base_url}/stations/#{station.shortname}.json?includeTimeseries=true&includeCurrentMeasurement=true"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_current(body)

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches water level measurements for the last `duration` (ISO 8601 duration, e.g. "P1D").
  """
  def measurements(station_key, duration \\ "P1D")
      when station_key in [:kienstock, :korneuburg] do
    station = @stations[station_key]
    url = "#{@base_url}/stations/#{station.shortname}/W/measurements.json?start=#{duration}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, Enum.map(body, &parse_measurement/1)}

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches characteristic values (RNW, HSW) for a station.
  """
  def characteristic_values(station_key) when station_key in [:kienstock, :korneuburg] do
    station = @stations[station_key]

    url =
      "#{@base_url}/stations/#{station.shortname}/W.json?includeCharacteristicValues=true"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        values =
          body
          |> Map.get("characteristicValues", [])
          |> Enum.map(fn cv ->
            %{
              shortname: cv["shortname"],
              longname: cv["longname"],
              value_cm: cv["value"],
              valid_from: cv["validFrom"]
            }
          end)

        {:ok, values}

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_current(body) do
    case get_in(body, ["timeseries", Access.at(0), "currentMeasurement"]) do
      nil ->
        {:error, :no_measurement}

      measurement ->
        {:ok,
         %{
           station: body["shortname"],
           timestamp: measurement["timestamp"],
           value_cm: measurement["value"],
           state: measurement["stateNswHsw"]
         }}
    end
  end

  defp parse_measurement(entry) do
    %{
      timestamp: entry["timestamp"],
      value_cm: entry["value"]
    }
  end
end
