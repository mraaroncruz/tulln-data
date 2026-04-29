defmodule TullnData.GaugeServer do
  @moduledoc """
  Polls PEGELONLINE and NÖ forecast APIs at a configured interval,
  holds the latest data in state, and broadcasts updates via PubSub.

  Multiple LiveView widget instances subscribe to the same topic
  and share a single backend poll — no N+1 fetching.
  """
  use GenServer
  require Logger

  @poll_interval_ms :timer.minutes(15)
  @stale_threshold_ms :timer.minutes(5)

  def child_spec(opts) do
    station = Keyword.fetch!(opts, :station)

    %{
      id: {__MODULE__, station},
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  def start_link(opts) do
    station = Keyword.fetch!(opts, :station)
    name = Keyword.get(opts, :name, via(station))
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def via(station), do: {:via, Registry, {TullnData.GaugeRegistry, station}}

  def topic(station), do: "gauge:#{station}"

  def get_state(station) do
    GenServer.call(via(station), :get_state)
  catch
    :exit, _ -> nil
  end

  def subscribe(station) do
    Phoenix.PubSub.subscribe(TullnData.PubSub, topic(station))
  end

  @impl true
  def init(opts) do
    station = Keyword.fetch!(opts, :station)
    interval = Keyword.get(opts, :interval_ms, @poll_interval_ms)

    state = %{
      station: station,
      interval: interval,
      current: nil,
      measurements: [],
      forecast: nil,
      characteristic_values: [],
      last_fetched_at: nil,
      errors: []
    }

    send(self(), :poll)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, snapshot(state), state}
  end

  @impl true
  def handle_info(:poll, state) do
    state = do_poll(state)
    broadcast(state)
    Process.send_after(self(), :poll, state.interval)
    {:noreply, state}
  end

  defp do_poll(state) do
    station = state.station
    errors = []

    {current, errors} =
      case TullnData.Pegelonline.current_water_level(station) do
        {:ok, data} ->
          {data, errors}

        {:error, reason} ->
          Logger.warning(
            "[GaugeServer] #{station} current_water_level failed: #{inspect(reason)}"
          )

          {state.current, [{:current, reason} | errors]}
      end

    {measurements, errors} =
      case TullnData.Pegelonline.measurements(station, "P7D") do
        {:ok, data} ->
          {data, errors}

        {:error, reason} ->
          Logger.warning("[GaugeServer] #{station} measurements failed: #{inspect(reason)}")
          {state.measurements, [{:measurements, reason} | errors]}
      end

    {forecast, errors} =
      case TullnData.NoeForecast.water_level_forecast(station) do
        {:ok, data} ->
          {data, errors}

        {:error, reason} ->
          Logger.warning("[GaugeServer] #{station} forecast failed: #{inspect(reason)}")
          {state.forecast, [{:forecast, reason} | errors]}
      end

    {char_values, errors} =
      case TullnData.Pegelonline.characteristic_values(station) do
        {:ok, data} ->
          {data, errors}

        {:error, reason} ->
          Logger.warning(
            "[GaugeServer] #{station} characteristic_values failed: #{inspect(reason)}"
          )

          {state.characteristic_values, [{:characteristic_values, reason} | errors]}
      end

    %{
      state
      | current: current,
        measurements: measurements,
        forecast: forecast,
        characteristic_values: char_values,
        last_fetched_at: DateTime.utc_now(),
        errors: errors
    }
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(
      TullnData.PubSub,
      topic(state.station),
      {:gauge_update, snapshot(state)}
    )
  end

  defp snapshot(state) do
    %{
      station: state.station,
      current: state.current,
      measurements: state.measurements,
      forecast: state.forecast,
      characteristic_values: state.characteristic_values,
      last_fetched_at: state.last_fetched_at,
      stale?: stale?(state),
      errors: state.errors
    }
  end

  defp stale?(%{last_fetched_at: nil}), do: true

  defp stale?(%{last_fetched_at: fetched_at}) do
    DateTime.diff(DateTime.utc_now(), fetched_at, :millisecond) > @stale_threshold_ms
  end
end
