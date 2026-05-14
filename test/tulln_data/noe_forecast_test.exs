defmodule TullnData.NoeForecastTest do
  use ExUnit.Case, async: true

  alias TullnData.NoeForecast

  @sample_csv """
  Datenqualität;!ungeprüfte Rohdaten!;;
  Stationsname;Kienstock;;
  Stationsnummer;207357;;
  Parameter;WasserstandPrognose;;
  Zeitreihenname;Wahrscheinlichste Prognose;Vertrauensbreich;Vertrauensbreich
  von;2026-04-27 12:00:00;;
  bis;2026-04-27 19:00:00;;
  Einheit;cm;;
  ;;;
  Datum;Mittel;Min;Max
  2026-04-27 12:00:00;186;186;186
  2026-04-27 12:15:00;185;185;185
  2026-04-27 12:30:00;184;183;185
  2026-04-28 12:00:00;175;160;190
  2026-04-29 12:00:00;170;150;190
  """

  describe "parse_csv/1" do
    test "parses valid forecast CSV" do
      assert {:ok, forecast} = NoeForecast.parse_csv(@sample_csv)

      assert forecast.station_name == "Kienstock"
      assert forecast.station_number == "207357"
      assert forecast.unit == "cm"
      assert forecast.observed_until == ~N[2026-04-27 19:00:00]

      assert length(forecast.points) == 5

      [first | _] = forecast.points
      assert first.timestamp == ~N[2026-04-27 12:00:00]
      assert first.value == 186.0
      assert first.min == 186.0
      assert first.max == 186.0

      last = List.last(forecast.points)
      assert last.value == 170.0
      assert last.min == 150.0
      assert last.max == 190.0
    end

    test "returns error for truncated CSV" do
      assert {:error, :invalid_csv} = NoeForecast.parse_csv("too short")
    end

    test "observed_until marks transition from observed to forecast" do
      assert {:ok, forecast} = NoeForecast.parse_csv(@sample_csv)
      assert forecast.observed_until == ~N[2026-04-27 19:00:00]

      observed =
        Enum.filter(forecast.points, fn p ->
          NaiveDateTime.compare(p.timestamp, forecast.observed_until) != :gt
        end)

      forecast_pts =
        Enum.filter(forecast.points, fn p ->
          NaiveDateTime.compare(p.timestamp, forecast.observed_until) == :gt
        end)

      assert length(observed) > 0
      assert length(forecast_pts) > 0
    end
  end
end
