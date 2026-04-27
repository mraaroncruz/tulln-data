defmodule TullnFlood.GaugePoller do
  @moduledoc """
  Polls PEGELONLINE for current Kienstock water level every 15 minutes.
  Logs results to prove the API contract works.
  """
  use GenServer
  require Logger

  @poll_interval_ms :timer.minutes(15)

  def start_link(opts \\ []) do
    station = Keyword.get(opts, :station, :kienstock)
    interval = Keyword.get(opts, :interval_ms, @poll_interval_ms)
    GenServer.start_link(__MODULE__, %{station: station, interval: interval}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send(self(), :poll)
    {:ok, state}
  end

  @impl true
  def handle_info(:poll, %{station: station, interval: interval} = state) do
    case TullnFlood.Pegelonline.current_water_level(station) do
      {:ok, reading} ->
        Logger.info(
          "[GaugePoller] #{reading.station} W=#{reading.value_cm}cm state=#{reading.state} at #{reading.timestamp}"
        )

      {:error, reason} ->
        Logger.warning("[GaugePoller] fetch failed for #{station}: #{inspect(reason)}")
    end

    Process.send_after(self(), :poll, interval)
    {:noreply, state}
  end
end
