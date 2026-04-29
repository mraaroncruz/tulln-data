defmodule TullnDataWeb.GaugeComponents do
  use Phoenix.Component
  use Gettext, backend: TullnDataWeb.Gettext

  @doc """
  Renders a gauge widget showing current water level, discharge forecast,
  sparkline chart, and threshold bands.

  ## Assigns

    * `:gauge` — snapshot map from GaugeServer (required)
    * `:station_label` — display name for the station (required)
  """
  attr :gauge, :map, required: true
  attr :station_label, :string, required: true

  def gauge_widget(assigns) do
    assigns =
      assigns
      |> assign(:thresholds, extract_thresholds(assigns.gauge.characteristic_values))
      |> assign(:sparkline_data, build_sparkline_data(assigns.gauge))
      |> assign(:level_class, level_class(assigns.gauge))

    ~H"""
    <div class="card bg-base-100 shadow-lg border border-base-300">
      <div class="card-body p-4">
        <div class="flex items-center justify-between">
          <h2 class="card-title text-lg">{@station_label}</h2>
          <.stale_badge :if={@gauge.stale?} />
        </div>

        <div class="flex items-baseline gap-4 mt-2">
          <.current_reading gauge={@gauge} level_class={@level_class} />
          <.timestamp_display gauge={@gauge} />
        </div>

        <.threshold_bar
          :if={@gauge.current}
          value={@gauge.current.value_cm}
          thresholds={@thresholds}
        />

        <.sparkline_chart
          :if={@sparkline_data.points != []}
          data={@sparkline_data}
          thresholds={@thresholds}
        />

        <.forecast_summary :if={@gauge.forecast} forecast={@gauge.forecast} />
      </div>
    </div>
    """
  end

  defp current_reading(assigns) do
    ~H"""
    <div :if={@gauge.current} class="flex items-baseline gap-2">
      <span class={["text-4xl font-bold tabular-nums", @level_class]}>
        {round(@gauge.current.value_cm)}
      </span>
      <span class="text-base-content/60 text-sm">cm</span>
    </div>
    <div :if={!@gauge.current} class="text-base-content/40 italic">
      Keine Daten verfügbar
    </div>
    """
  end

  defp timestamp_display(assigns) do
    ~H"""
    <div :if={@gauge.current} class="text-xs text-base-content/50">
      {format_timestamp(@gauge.current.timestamp)}
    </div>
    """
  end

  defp stale_badge(assigns) do
    ~H"""
    <div class="badge badge-warning badge-sm gap-1">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
        <path
          fill-rule="evenodd"
          d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
          clip-rule="evenodd"
        />
      </svg>
      Veraltet
    </div>
    """
  end

  attr :value, :float, required: true
  attr :thresholds, :map, required: true

  defp threshold_bar(assigns) do
    rnw = assigns.thresholds.rnw
    hsw = assigns.thresholds.hsw

    pct =
      if rnw && hsw && hsw > rnw do
        range = hsw - rnw
        clamped = min(max(assigns.value - rnw, 0), range)
        Float.round(clamped / range * 100, 1)
      else
        50.0
      end

    assigns = assign(assigns, :pct, pct)

    ~H"""
    <div :if={@thresholds.rnw && @thresholds.hsw} class="mt-2">
      <div class="flex justify-between text-xs text-base-content/50 mb-1">
        <span>RNW {@thresholds.rnw}cm</span>
        <span>HSW {@thresholds.hsw}cm</span>
      </div>
      <div class="w-full h-3 rounded-full bg-gradient-to-r from-info via-success via-60% to-error relative">
        <div
          class="absolute top-0 h-3 w-1 bg-base-content rounded-full"
          style={"left: #{@pct}%"}
        />
      </div>
    </div>
    """
  end

  attr :data, :map, required: true
  attr :thresholds, :map, required: true

  defp sparkline_chart(assigns) do
    %{points: points, forecast_start_idx: forecast_start_idx} = assigns.data

    {svg_width, svg_height} = {600, 120}
    padding = %{top: 10, bottom: 20, left: 0, right: 0}
    chart_w = svg_width - padding.left - padding.right
    chart_h = svg_height - padding.top - padding.bottom

    values = Enum.map(points, & &1.value)
    min_val = Enum.min(values) - 10
    max_val = Enum.max(values) + 10

    scale_x = fn i -> padding.left + i / max(length(points) - 1, 1) * chart_w end
    scale_y = fn v -> padding.top + (1 - (v - min_val) / max(max_val - min_val, 1)) * chart_h end

    observed_points =
      points
      |> Enum.take(forecast_start_idx)
      |> Enum.with_index()
      |> Enum.map(fn {p, i} ->
        "#{Float.round(scale_x.(i), 1)},#{Float.round(scale_y.(p.value), 1)}"
      end)
      |> Enum.join(" ")

    forecast_points =
      points
      |> Enum.drop(max(forecast_start_idx - 1, 0))
      |> Enum.with_index(max(forecast_start_idx - 1, 0))
      |> Enum.map(fn {p, i} ->
        "#{Float.round(scale_x.(i), 1)},#{Float.round(scale_y.(p.value), 1)}"
      end)
      |> Enum.join(" ")

    confidence_band =
      if forecast_start_idx < length(points) do
        forecast_pts = Enum.drop(points, max(forecast_start_idx - 1, 0))
        indices = Enum.to_list(max(forecast_start_idx - 1, 0)..(length(points) - 1))

        upper =
          Enum.zip(forecast_pts, indices)
          |> Enum.map(fn {p, i} ->
            "#{Float.round(scale_x.(i), 1)},#{Float.round(scale_y.(p.max), 1)}"
          end)
          |> Enum.join(" ")

        lower =
          Enum.zip(forecast_pts, indices)
          |> Enum.reverse()
          |> Enum.map(fn {p, i} ->
            "#{Float.round(scale_x.(i), 1)},#{Float.round(scale_y.(p.min), 1)}"
          end)
          |> Enum.join(" ")

        upper <> " " <> lower
      end

    rnw_y = if assigns.thresholds.rnw, do: Float.round(scale_y.(assigns.thresholds.rnw), 1)
    hsw_y = if assigns.thresholds.hsw, do: Float.round(scale_y.(assigns.thresholds.hsw), 1)

    forecast_x =
      if forecast_start_idx > 0 && forecast_start_idx < length(points) do
        Float.round(scale_x.(forecast_start_idx), 1)
      end

    assigns =
      assigns
      |> assign(:svg_width, svg_width)
      |> assign(:svg_height, svg_height)
      |> assign(:observed_points, observed_points)
      |> assign(:forecast_points, forecast_points)
      |> assign(:confidence_band, confidence_band)
      |> assign(:rnw_y, rnw_y)
      |> assign(:hsw_y, hsw_y)
      |> assign(:forecast_x, forecast_x)

    ~H"""
    <div class="mt-3">
      <svg
        viewBox={"0 0 #{@svg_width} #{@svg_height}"}
        class="w-full h-auto"
        preserveAspectRatio="none"
      >
        <line
          :if={@rnw_y}
          x1="0"
          y1={@rnw_y}
          x2={@svg_width}
          y2={@rnw_y}
          stroke="oklch(var(--in))"
          stroke-width="1"
          stroke-dasharray="4,4"
          opacity="0.4"
        />
        <line
          :if={@hsw_y}
          x1="0"
          y1={@hsw_y}
          x2={@svg_width}
          y2={@hsw_y}
          stroke="oklch(var(--er))"
          stroke-width="1"
          stroke-dasharray="4,4"
          opacity="0.4"
        />

        <line
          :if={@forecast_x}
          x1={@forecast_x}
          y1="0"
          x2={@forecast_x}
          y2={@svg_height}
          stroke="oklch(var(--bc))"
          stroke-width="1"
          stroke-dasharray="2,4"
          opacity="0.3"
        />

        <polygon
          :if={@confidence_band}
          points={@confidence_band}
          fill="oklch(var(--wa))"
          opacity="0.2"
        />

        <polyline
          :if={@observed_points != ""}
          points={@observed_points}
          fill="none"
          stroke="oklch(var(--p))"
          stroke-width="2"
          stroke-linejoin="round"
        />

        <polyline
          :if={@forecast_points != ""}
          points={@forecast_points}
          fill="none"
          stroke="oklch(var(--wa))"
          stroke-width="2"
          stroke-dasharray="6,3"
          stroke-linejoin="round"
        />
      </svg>

      <div class="flex justify-between text-xs text-base-content/40 mt-1">
        <span>7 Tage</span>
        <span :if={@forecast_x} class="text-warning">← Prognose →</span>
        <span>+48h</span>
      </div>
    </div>
    """
  end

  defp forecast_summary(assigns) do
    points = assigns.forecast.points
    observed_until = assigns.forecast.observed_until

    {h24, h48} =
      if observed_until do
        h24_ts = NaiveDateTime.add(observed_until, 24 * 3600)
        h48_ts = NaiveDateTime.add(observed_until, 48 * 3600)

        h24_val = find_nearest_point(points, h24_ts)
        h48_val = find_nearest_point(points, h48_ts)
        {h24_val, h48_val}
      else
        {nil, nil}
      end

    assigns = assign(assigns, h24: h24, h48: h48)

    ~H"""
    <div class="flex gap-4 mt-3 text-sm">
      <div :if={@h24} class="flex items-center gap-1">
        <span class="text-base-content/50">+24h:</span>
        <span class="font-semibold tabular-nums">{round(@h24.value)} cm</span>
        <span :if={@h24.min != @h24.max} class="text-xs text-base-content/40">
          ({round(@h24.min)}–{round(@h24.max)})
        </span>
      </div>
      <div :if={@h48} class="flex items-center gap-1">
        <span class="text-base-content/50">+48h:</span>
        <span class="font-semibold tabular-nums">{round(@h48.value)} cm</span>
        <span :if={@h48.min != @h48.max} class="text-xs text-base-content/40">
          ({round(@h48.min)}–{round(@h48.max)})
        </span>
      </div>
    </div>
    """
  end

  defp extract_thresholds(char_values) when is_list(char_values) do
    rnw = Enum.find_value(char_values, fn cv -> cv.shortname == "RNW" && cv.value_cm end)
    hsw = Enum.find_value(char_values, fn cv -> cv.shortname == "HSW" && cv.value_cm end)
    %{rnw: rnw, hsw: hsw}
  end

  defp extract_thresholds(_), do: %{rnw: nil, hsw: nil}

  defp build_sparkline_data(%{measurements: measurements, forecast: forecast})
       when is_list(measurements) do
    observed =
      measurements
      |> downsample(168)
      |> Enum.map(fn m ->
        %{value: m.value_cm, min: m.value_cm, max: m.value_cm, timestamp: m.timestamp}
      end)

    {forecast_points, observed_until} =
      case forecast do
        %{points: pts, observed_until: obs} when is_list(pts) ->
          future =
            pts
            |> Enum.filter(fn p ->
              p.timestamp && obs && NaiveDateTime.compare(p.timestamp, obs) == :gt
            end)
            |> downsample(48)

          {future, obs}

        _ ->
          {[], nil}
      end

    all_points = observed ++ forecast_points
    forecast_start_idx = length(observed)

    %{points: all_points, forecast_start_idx: forecast_start_idx, observed_until: observed_until}
  end

  defp build_sparkline_data(_), do: %{points: [], forecast_start_idx: 0, observed_until: nil}

  defp downsample(list, max_points) when length(list) <= max_points, do: list

  defp downsample(list, max_points) do
    step = length(list) / max_points
    Enum.map(0..(max_points - 1), fn i -> Enum.at(list, round(i * step)) end)
  end

  defp find_nearest_point(points, target_ts) do
    Enum.min_by(
      points,
      fn p ->
        abs(NaiveDateTime.diff(p.timestamp, target_ts))
      end,
      fn -> nil end
    )
  end

  defp level_class(%{current: nil}), do: "text-base-content"

  defp level_class(%{current: %{state: state}}) do
    case state do
      "low" -> "text-info"
      "high" -> "text-error"
      "normal" -> "text-success"
      _ -> "text-base-content"
    end
  end

  defp level_class(_), do: "text-base-content"

  defp format_timestamp(nil), do: ""

  defp format_timestamp(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} ->
        Calendar.strftime(dt, "%d.%m. %H:%M")

      _ ->
        ts
    end
  end

  defp format_timestamp(_), do: ""
end
