defmodule TullnDataWeb.UI do
  @moduledoc """
  OpenTulln shared UI primitives — grade chip, treemap thumbnail, Gemeinde card.

  Lift visual choices from `priv/design/` rather than reinventing. Tokens
  defined in `assets/css/app.css` under `@theme`.
  """
  use TullnDataWeb, :html

  alias TullnData.Budgets.Quicktest

  @grade_bg %{
    a: "bg-ot-grade-a text-white",
    b: "bg-ot-grade-b text-white",
    c: "bg-ot-grade-c text-ot-on-surface",
    d: "bg-ot-grade-d text-white",
    e: "bg-ot-grade-e text-white"
  }

  @doc """
  Small letter chip: a colored square with the A–E letter. Used on Gemeinde
  cards (landing) and on each Quicktest card on the result page.
  """
  attr :grade, :atom, required: true, values: [:a, :b, :c, :d, :e]
  attr :size, :string, default: "md", values: ["sm", "md"]
  attr :class, :string, default: ""

  def grade_chip(assigns) do
    assigns =
      assign(assigns,
        bg_class: Map.fetch!(@grade_bg, assigns.grade),
        dim_class:
          case assigns.size do
            "sm" -> "w-6 h-6 text-xs"
            "md" -> "w-8 h-8 text-base"
          end
      )

    ~H"""
    <div class={[
      "inline-flex items-center justify-center rounded font-bold shadow-sm",
      @dim_class,
      @bg_class,
      @class
    ]}>
      {String.upcase(to_string(@grade))}
    </div>
    """
  end

  @doc """
  Tiny static treemap thumbnail for the landing-page Gemeinde cards. Decorative
  — schematic shape rather than data-accurate. Four variants, dispatched by
  the `seed` (typically the Gemeinde index).
  """
  attr :seed, :integer, default: 0

  def treemap_thumb(assigns) do
    assigns = assign(assigns, variant: rem(assigns.seed, 4))

    ~H"""
    <div class="w-full h-32 rounded bg-ot-surface-container flex overflow-hidden border border-ot-outline">
      <%= case @variant do %>
        <% 0 -> %>
          <div class="w-1/2 h-full bg-ot-treemap-1 border-r border-ot-outline"></div>
          <div class="w-1/2 h-full flex flex-col">
            <div class="h-2/3 w-full bg-ot-treemap-3 border-b border-ot-outline"></div>
            <div class="h-1/3 w-full bg-ot-treemap-5 flex">
              <div class="w-2/3 h-full border-r border-ot-outline"></div>
              <div class="w-1/3 h-full bg-ot-treemap-6"></div>
            </div>
          </div>
        <% 1 -> %>
          <div class="w-3/5 h-full bg-ot-treemap-1 border-r border-ot-outline"></div>
          <div class="w-2/5 h-full flex flex-col">
            <div class="h-1/2 w-full bg-ot-treemap-3 border-b border-ot-outline"></div>
            <div class="h-1/2 w-full bg-ot-treemap-5"></div>
          </div>
        <% 2 -> %>
          <div class="w-1/3 h-full bg-ot-treemap-1 border-r border-ot-outline"></div>
          <div class="w-2/3 h-full flex flex-col">
            <div class="h-4/5 w-full bg-ot-treemap-3 border-b border-ot-outline flex">
              <div class="w-1/2 h-full border-r border-ot-outline"></div>
              <div class="w-1/2 h-full bg-ot-treemap-4"></div>
            </div>
            <div class="h-1/5 w-full bg-ot-treemap-5"></div>
          </div>
        <% _ -> %>
          <div class="w-[45%] h-full bg-ot-treemap-1 border-r border-ot-outline"></div>
          <div class="w-[55%] h-full flex flex-col">
            <div class="h-2/5 w-full bg-ot-treemap-3 border-b border-ot-outline"></div>
            <div class="h-3/5 w-full bg-ot-treemap-5"></div>
          </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Landing-page Gemeinde card.
  """
  attr :municipality, :map, required: true
  attr :grade, :atom, default: :b
  attr :seed, :integer, default: 0

  def gemeinde_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/haushalt/#{@municipality.slug}"}
      class={[
        "group block bg-white rounded-lg border border-ot-outline p-6",
        "hover:bg-ot-surface-subtle transition-colors relative overflow-hidden",
        "shadow-[0_1px_2px_rgba(0,0,0,0.04)] focus:outline-none focus:ring-2 focus:ring-ot-primary"
      ]}
    >
      <div class="flex justify-between items-start mb-4">
        <div>
          <h2 class="text-2xl font-semibold text-ot-on-surface group-hover:text-ot-primary transition-colors">
            {@municipality.name}
          </h2>
          <div class="text-sm text-ot-on-surface-variant mt-1 flex items-center gap-1">
            <.icon name="hero-user-group-mini" class="w-4 h-4" />
            Pop: {format_int(@municipality.population)}
          </div>
        </div>
        <.grade_chip grade={@grade} />
      </div>
      <.treemap_thumb seed={@seed} />
    </.link>
    """
  end

  @doc """
  Quicktest card — letter grade chip, ratio label, current value, tiny sparkline,
  and a German-language tooltip explaining what the ratio means.
  """
  attr :ratio, :map, required: true

  def quicktest_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-ot-outline p-4 shadow-[0_1px_2px_rgba(0,0,0,0.04)]">
      <div class="flex items-start justify-between gap-2 mb-2">
        <div class="min-w-0">
          <div class="text-sm text-ot-on-surface-variant truncate" title={@ratio.label}>
            {@ratio.label}
          </div>
        </div>
        <.grade_chip grade={@ratio.grade} size="sm" />
      </div>
      <div class="text-2xl font-semibold tabular-nums text-ot-on-surface">
        {format_value(@ratio.value)}<span class="text-base font-normal text-ot-on-surface-variant ml-1">{@ratio.unit}</span>
      </div>
      <div class="mt-2 flex items-end gap-px h-5">
        <div
          :for={h <- demo_sparkline(@ratio.key)}
          class="flex-1 bg-ot-primary/30 rounded-sm"
          style={"height: #{h}%;"}
        >
        </div>
      </div>
      <p class="mt-2 text-xs text-ot-on-surface-variant leading-snug">
        {Quicktest.tooltip(@ratio.key)}
      </p>
    </div>
    """
  end

  @doc """
  Full-size SVG treemap. Takes pre-computed rectangles from
  `TullnData.Budgets.Treemap.layout/3`. The viewBox is the same coordinate
  space as the layout viewport, so the consumer chooses width/height by
  picking the layout viewport size.
  """
  attr :rects, :list, required: true
  attr :viewport_w, :integer, default: 1000
  attr :viewport_h, :integer, default: 500
  attr :total, :any, required: true, doc: "Total of all amounts, for share calc"
  attr :per_thousand, :boolean, default: true

  def treemap_svg(assigns) do
    ~H"""
    <svg
      viewBox={"0 0 #{@viewport_w} #{@viewport_h}"}
      class="w-full h-auto"
      preserveAspectRatio="none"
      role="img"
      aria-label="Aufschlüsselung des Haushalts"
    >
      <rect
        :for={r <- @rects}
        x={r.x}
        y={r.y}
        width={r.w}
        height={r.h}
        fill={treemap_fill(r.item, @total)}
        stroke="white"
        stroke-width="2"
      />
      <%= for r <- @rects, r.w > 80 and r.h > 40 do %>
        <text
          x={r.x + 12}
          y={r.y + 24}
          fill={text_fill(r.item, @total)}
          class="font-semibold"
          style="font-size: 14px;"
        >
          {treemap_label(r.item)}
        </text>
        <text
          x={r.x + 12}
          y={r.y + 44}
          fill={text_fill(r.item, @total)}
          class="tabular-nums"
          style="font-size: 13px;"
        >
          {format_amount(r.item, @total, @per_thousand)}
        </text>
      <% end %>
    </svg>
    """
  end

  defp treemap_fill(item, total) do
    share = share_of(item, total)

    cond do
      share >= 0.18 -> "#1B4332"
      share >= 0.12 -> "#2D6A4F"
      share >= 0.07 -> "#40916C"
      share >= 0.04 -> "#74C365"
      share >= 0.02 -> "#95D5B2"
      true -> "#B7E4C7"
    end
  end

  defp text_fill(item, total) do
    if share_of(item, total) >= 0.07, do: "#F8FAFC", else: "#0b1c30"
  end

  defp share_of(%{amount: a}, total) when is_number(a) and is_number(total) and total > 0,
    do: a / total

  defp share_of(_, _), do: 0.0

  defp treemap_label(%{name: n}), do: n
  defp treemap_label(%{code: c}), do: c
  defp treemap_label(_), do: ""

  defp format_amount(item, total, per_thousand?) do
    share = share_of(item, total)

    if per_thousand? do
      :erlang.float_to_binary(share * 1000, decimals: 0) <> " €"
    else
      format_short_eur(item)
    end
  end

  defp format_short_eur(%{amount: a}) when is_number(a) do
    cond do
      a >= 1_000_000_000 -> :erlang.float_to_binary(a / 1_000_000_000, decimals: 1) <> " Mrd €"
      a >= 1_000_000 -> :erlang.float_to_binary(a / 1_000_000, decimals: 1) <> " Mio €"
      a >= 1_000 -> :erlang.float_to_binary(a / 1_000, decimals: 0) <> " Tsd €"
      true -> :erlang.float_to_binary(a * 1.0, decimals: 0) <> " €"
    end
  end

  defp format_short_eur(_), do: "—"

  @doc """
  Attribution strip — shown at the foot of every page that uses third-party
  open-data. CC-BY 3.0 AT requires this.
  """
  attr :sources, :list, default: ["offenerhaushalt.at", "KDZ"]

  def attribution_strip(assigns) do
    ~H"""
    <div class="text-sm text-ot-secondary">
      Datenquelle: {Enum.join(@sources, ", ")}. Lizenziert unter CC-BY 3.0 AT.
    </div>
    """
  end

  defp format_int(nil), do: "—"

  defp format_int(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp format_value(v) when is_float(v) do
    rounded = Float.round(v, 1)
    formatted = :erlang.float_to_binary(rounded, decimals: 1)
    String.replace(formatted, ".", ",")
  end

  defp format_value(v), do: to_string(v)

  # Slightly different decorative sparkline shapes per ratio, so the row of
  # 5 cards isn't visually identical. Replace with real 5y history once the
  # FiscalYear table accumulates more years.
  defp demo_sparkline(:oesq), do: [40, 55, 65, 60, 70]
  defp demo_sparkline(:efq), do: [80, 85, 88, 90, 92]
  defp demo_sparkline(:vd), do: [55, 50, 45, 48, 42]
  defp demo_sparkline(:sdq), do: [30, 28, 25, 22, 20]
  defp demo_sparkline(_), do: [50, 48, 60, 55, 65]
end
