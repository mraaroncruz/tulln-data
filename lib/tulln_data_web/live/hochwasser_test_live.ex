defmodule TullnDataWeb.HochwasserTestLive do
  use TullnDataWeb, :live_view

  import TullnDataWeb.GaugeComponents

  @stations [:kienstock, :korneuburg]

  @station_labels %{
    kienstock: "Kienstock (Donau km 2015)",
    korneuburg: "Korneuburg (Donau km 1942)"
  }

  @impl true
  def mount(_params, _session, socket) do
    gauges =
      for station <- @stations, into: %{} do
        if connected?(socket) do
          TullnData.GaugeServer.subscribe(station)
        end

        data = TullnData.GaugeServer.get_state(station)
        {station, data}
      end

    {:ok, assign(socket, gauges: gauges, station_labels: @station_labels)}
  end

  @impl true
  def handle_info({:gauge_update, %{station: station} = data}, socket) do
    gauges = Map.put(socket.assigns.gauges, station, data)
    {:noreply, assign(socket, :gauges, gauges)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-6 px-4">
      <h1 class="text-2xl font-bold mb-6">Hochwasser-Dashboard (Test)</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.gauge_widget
          :for={{station, gauge} <- @gauges}
          :if={gauge}
          gauge={gauge}
          station_label={@station_labels[station]}
        />
      </div>

      <div
        :if={Enum.all?(@gauges, fn {_, v} -> is_nil(v) end)}
        class="text-center py-12 text-base-content/50"
      >
        <p>Lade Pegeldaten...</p>
        <span class="loading loading-spinner loading-lg mt-4"></span>
      </div>
    </div>
    """
  end
end
