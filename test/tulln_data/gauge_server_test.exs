defmodule TullnData.GaugeServerTest do
  use ExUnit.Case

  alias TullnData.GaugeServer

  @moduletag :external

  describe "get_state/1" do
    test "returns gauge snapshot for kienstock" do
      state = GaugeServer.get_state(:kienstock)

      assert state != nil
      assert state.station == :kienstock
      assert is_list(state.measurements)
      assert is_list(state.characteristic_values)
    end

    test "returns gauge snapshot for korneuburg" do
      state = GaugeServer.get_state(:korneuburg)

      assert state != nil
      assert state.station == :korneuburg
    end
  end

  describe "subscribe/1" do
    test "receives gauge_update after subscribing" do
      GaugeServer.subscribe(:kienstock)

      # The server may have already broadcast; if not, we wait for the next poll.
      # Since this is an integration test, we give it a generous timeout.
      assert_receive {:gauge_update, %{station: :kienstock}}, 30_000
    end
  end
end
