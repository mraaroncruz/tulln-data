defmodule TullnFlood.PegelonlineTest do
  use ExUnit.Case, async: true

  @moduletag :external

  describe "current_water_level/1" do
    test "returns current reading for Kienstock" do
      assert {:ok, reading} = TullnFlood.Pegelonline.current_water_level(:kienstock)
      assert reading.station == "KIENSTOCK"
      assert is_float(reading.value_cm) or is_integer(reading.value_cm)
      assert is_binary(reading.timestamp)
      assert reading.state in ["normal", "low", "high", "unknown"]
    end

    test "returns current reading for Korneuburg" do
      assert {:ok, reading} = TullnFlood.Pegelonline.current_water_level(:korneuburg)
      assert reading.station == "KORNEUBURG"
      assert is_float(reading.value_cm) or is_integer(reading.value_cm)
    end
  end

  describe "measurements/2" do
    test "returns 15-min interval data for last 24h" do
      assert {:ok, measurements} = TullnFlood.Pegelonline.measurements(:kienstock, "P1D")
      assert length(measurements) > 0

      first = hd(measurements)
      assert is_binary(first.timestamp)
      assert is_float(first.value_cm) or is_integer(first.value_cm)
    end
  end

  describe "characteristic_values/1" do
    test "returns RNW and HSW for Kienstock" do
      assert {:ok, values} = TullnFlood.Pegelonline.characteristic_values(:kienstock)
      shortnames = Enum.map(values, & &1.shortname)
      assert "RNW" in shortnames
      assert "HSW" in shortnames
    end
  end
end
