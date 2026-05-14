defmodule TullnDataWeb.HaushaltLive do
  use TullnDataWeb, :live_view

  alias TullnData.Budgets
  alias TullnData.Budgets.{Quicktest, Treemap}

  @default_fallback_years [2023, 2022, 2021]

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    case Budgets.get_municipality_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Gemeinde »#{slug}« nicht gefunden.")
         |> push_navigate(to: ~p"/")}

      municipality ->
        municipalities = Budgets.list_municipalities()
        years = effective_years(slug)
        year = parse_year(params["year"], years)
        peers = parse_peers(params["vs"], municipalities, municipality)

        {:ok,
         socket
         |> assign(:page_title, "Budget #{year}: #{municipality.name}")
         |> assign(:municipality, municipality)
         |> assign(:municipalities, municipalities)
         |> assign(:years, years)
         |> assign(:year, year)
         |> assign(:view_mode, :per_thousand)
         |> assign(:peers, peers)
         |> assign_breakdown()
         |> assign_quicktest()}
    end
  end

  @impl true
  def handle_params(%{"slug" => slug} = params, _uri, socket) do
    cond do
      slug != socket.assigns.municipality.slug ->
        {:noreply, push_navigate(socket, to: build_url(slug, params))}

      true ->
        years = socket.assigns.years
        year = parse_year(params["year"], years)

        peers =
          parse_peers(params["vs"], socket.assigns.municipalities, socket.assigns.municipality)

        view_mode = parse_view_mode(params["view"])

        {:noreply,
         socket
         |> assign(:year, year)
         |> assign(:peers, peers)
         |> assign(:view_mode, view_mode)
         |> assign_breakdown()
         |> assign_quicktest()}
    end
  end

  @impl true
  def handle_event("switch_gemeinde", %{"slug" => slug}, socket) do
    {:noreply, push_patch(socket, to: build_url(slug, %{"year" => socket.assigns.year}))}
  end

  def handle_event("switch_year", %{"year" => year}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_url(socket.assigns.municipality.slug, %{"year" => year})
     )}
  end

  def handle_event("switch_view", %{"view" => view}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         build_url(socket.assigns.municipality.slug, %{
           "year" => socket.assigns.year,
           "view" => view
         })
     )}
  end

  def handle_event("toggle_peer", %{"slug" => peer_slug}, socket) do
    current = Enum.map(socket.assigns.peers, & &1.slug)
    me = socket.assigns.municipality.slug

    new_peers =
      cond do
        peer_slug == me -> current
        peer_slug in current -> current -- [peer_slug]
        length(current) >= 3 -> current
        true -> current ++ [peer_slug]
      end

    {:noreply,
     push_patch(socket,
       to:
         build_url(me, %{
           "year" => socket.assigns.year,
           "vs" => Enum.join(new_peers, ",")
         })
     )}
  end

  defp assign_breakdown(socket) do
    %{municipality: m, year: year} = socket.assigns
    breakdown = Budgets.top_level_ansatz_breakdown(m.slug, year)
    total = Enum.reduce(breakdown, 0.0, fn row, acc -> acc + decimal_to_float(row.amount) end)

    rects =
      breakdown
      |> Enum.map(&Map.put(&1, :amount, decimal_to_float(&1.amount)))
      |> Treemap.layout(1000, 500)

    peer_breakdowns =
      Enum.map(socket.assigns.peers, fn peer ->
        peer_bd = Budgets.top_level_ansatz_breakdown(peer.slug, year)
        peer_total = Enum.reduce(peer_bd, 0.0, fn r, a -> a + decimal_to_float(r.amount) end)

        %{
          municipality: peer,
          breakdown: peer_bd,
          total: peer_total,
          rects:
            peer_bd
            |> Enum.map(&Map.put(&1, :amount, decimal_to_float(&1.amount)))
            |> Treemap.layout(400, 300)
        }
      end)

    socket
    |> assign(:breakdown, breakdown)
    |> assign(:total, total)
    |> assign(:rects, rects)
    |> assign(:peer_breakdowns, peer_breakdowns)
  end

  defp assign_quicktest(socket) do
    %{municipality: m, year: year} = socket.assigns
    assign(socket, :ratios, Quicktest.compute(m.slug, year))
  end

  defp effective_years(slug) do
    case Budgets.available_years(slug) do
      [] -> @default_fallback_years
      ys -> ys
    end
  end

  defp parse_year(nil, [first | _]), do: first
  defp parse_year(nil, []), do: hd(@default_fallback_years)

  defp parse_year(year_str, years) when is_binary(year_str) do
    case Integer.parse(year_str) do
      {y, ""} -> if y in years, do: y, else: hd(years || @default_fallback_years)
      _ -> hd(years || @default_fallback_years)
    end
  end

  defp parse_view_mode("absolute"), do: :absolute
  defp parse_view_mode("per_einwohner"), do: :per_einwohner
  defp parse_view_mode(_), do: :per_thousand

  defp parse_peers(nil, _municipalities, _self), do: []
  defp parse_peers("", _, _), do: []

  defp parse_peers(csv, municipalities, self) when is_binary(csv) do
    csv
    |> String.split(",", trim: true)
    |> Enum.reject(&(&1 == self.slug))
    |> Enum.uniq()
    |> Enum.take(3)
    |> Enum.map(fn slug -> Enum.find(municipalities, &(&1.slug == slug)) end)
    |> Enum.reject(&is_nil/1)
  end

  defp build_url(slug, params) do
    qs =
      params
      |> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
      |> Map.reject(fn {_, v} -> v in ["", nil] end)

    case map_size(qs) do
      0 -> ~p"/haushalt/#{slug}"
      _ -> ~p"/haushalt/#{slug}?#{qs}"
    end
  end

  defp decimal_to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp decimal_to_float(n) when is_number(n), do: n * 1.0
  defp decimal_to_float(_), do: 0.0

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_nav={:dashboard}>
      <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
        <h1 class="text-3xl font-bold text-ot-on-surface">
          Budget {@year}: {@municipality.name}
        </h1>
        <div class="flex items-center gap-3">
          <form phx-change="switch_gemeinde" class="flex items-center gap-2 text-sm">
            <label for="gemeinde-select" class="text-ot-on-surface-variant">Gemeinde:</label>
            <select
              id="gemeinde-select"
              name="slug"
              class="rounded border border-ot-outline px-3 py-1.5 bg-white text-ot-on-surface focus:outline-none focus:ring-2 focus:ring-ot-primary"
            >
              <option
                :for={m <- @municipalities}
                value={m.slug}
                selected={m.slug == @municipality.slug}
              >
                {m.name}
              </option>
            </select>
          </form>
          <form phx-change="switch_year" class="flex items-center gap-2 text-sm">
            <label for="year-select" class="text-ot-on-surface-variant">Jahr:</label>
            <select
              id="year-select"
              name="year"
              class="rounded border border-ot-outline px-3 py-1.5 bg-white text-ot-on-surface focus:outline-none focus:ring-2 focus:ring-ot-primary"
            >
              <option :for={y <- @years} value={y} selected={y == @year}>{y}</option>
            </select>
          </form>
        </div>
      </div>

      <div class="flex flex-wrap gap-2 mb-4 text-sm">
        <span class="text-ot-on-surface-variant self-center mr-1">Ansicht:</span>
        <.view_toggle current={@view_mode} mode={:per_thousand} label="€ pro 1.000 € Steuergeld" />
        <.view_toggle current={@view_mode} mode={:absolute} label="Absolut" />
        <.view_toggle current={@view_mode} mode={:per_einwohner} label="€ pro Einwohner" />
      </div>

      <%= if @rects == [] do %>
        <div class="bg-white border border-ot-outline rounded-lg p-8 text-center text-ot-on-surface-variant">
          Für {@municipality.name} sind noch keine Ergebnishaushalt-Daten ({@year}) verfügbar.
          Bitte ein anderes Jahr wählen.
        </div>
      <% else %>
        <div class="bg-white border border-ot-outline rounded-lg p-6 mb-8">
          <div class="text-sm text-ot-on-surface-variant mb-1">
            {@municipality.name} › Haushalt
          </div>
          <h2 class="text-xl font-semibold mb-4">
            <%= case @view_mode do %>
              <% :per_thousand -> %>
                1.000 € Steuergeld aus {@municipality.name} gehen an:
              <% :absolute -> %>
                Aufwendungen {@year} (gesamt {format_total(@total)})
              <% :per_einwohner -> %>
                Aufwendungen pro Einwohner ({@municipality.population || "—"})
            <% end %>
          </h2>
          <TullnDataWeb.UI.treemap_svg
            rects={@rects}
            total={@total}
            per_thousand={@view_mode == :per_thousand}
          />
        </div>
      <% end %>

      <section class="mb-8">
        <div class="flex items-baseline justify-between mb-4">
          <h2 class="text-2xl font-semibold">Finanzielle Gesundheit (KDZ Quicktest)</h2>
          <.link
            navigate={~p"/info"}
            class="text-sm text-ot-primary hover:underline"
          >
            Details ansehen →
          </.link>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          <TullnDataWeb.UI.quicktest_card :for={r <- @ratios} ratio={r} />
        </div>
      </section>

      <section class="mb-8">
        <div class="flex items-baseline justify-between mb-4">
          <h2 class="text-2xl font-semibold">Vergleich mit Nachbarstädten</h2>
          <span class="text-sm text-ot-on-surface-variant">Max. 3 Peer-Gemeinden — €/Einwohner</span>
        </div>
        <div class="flex flex-wrap gap-2 mb-4">
          <button
            :for={m <- @municipalities}
            :if={m.slug != @municipality.slug}
            phx-click="toggle_peer"
            phx-value-slug={m.slug}
            class={[
              "px-3 py-1.5 rounded-full text-sm transition-colors border",
              peer_chip_class(m.slug, @peers)
            ]}
          >
            <%= if Enum.any?(@peers, &(&1.slug == m.slug)) do %>
              {m.name} ×
            <% else %>
              + {m.name}
            <% end %>
          </button>
        </div>
        <%= if @peers != [] do %>
          <div class={[
            "grid gap-4",
            "grid-cols-1",
            length(@peers) >= 1 && "md:grid-cols-2",
            length(@peers) >= 2 && "lg:grid-cols-3"
          ]}>
            <div class="bg-white border border-ot-outline rounded-lg p-4">
              <div class="flex items-baseline justify-between mb-2">
                <h3 class="font-semibold">{@municipality.name}</h3>
                <span class="text-xs text-ot-on-surface-variant">
                  {format_per_einwohner(@total, @municipality.population)} €/EW
                </span>
              </div>
              <TullnDataWeb.UI.treemap_svg
                rects={@rects}
                viewport_w={400}
                viewport_h={300}
                total={@total}
                per_thousand={false}
              />
            </div>
            <div :for={p <- @peer_breakdowns} class="bg-white border border-ot-outline rounded-lg p-4">
              <div class="flex items-baseline justify-between mb-2">
                <h3 class="font-semibold">{p.municipality.name}</h3>
                <span class="text-xs text-ot-on-surface-variant">
                  {format_per_einwohner(p.total, p.municipality.population)} €/EW
                </span>
              </div>
              <TullnDataWeb.UI.treemap_svg
                rects={p.rects}
                viewport_w={400}
                viewport_h={300}
                total={p.total}
                per_thousand={false}
              />
            </div>
          </div>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  attr :current, :atom, required: true
  attr :mode, :atom, required: true
  attr :label, :string, required: true

  defp view_toggle(assigns) do
    ~H"""
    <button
      phx-click="switch_view"
      phx-value-view={mode_param(@mode)}
      class={[
        "px-3 py-1.5 rounded border text-sm transition-colors",
        if(@current == @mode,
          do: "bg-ot-primary text-white border-ot-primary",
          else: "bg-white text-ot-on-surface-variant border-ot-outline hover:bg-ot-surface-subtle"
        )
      ]}
    >
      {@label}
    </button>
    """
  end

  defp mode_param(:per_thousand), do: "per_thousand"
  defp mode_param(:absolute), do: "absolute"
  defp mode_param(:per_einwohner), do: "per_einwohner"

  defp peer_chip_class(slug, peers) do
    if Enum.any?(peers, &(&1.slug == slug)) do
      "bg-ot-primary text-white border-ot-primary"
    else
      "bg-white text-ot-on-surface-variant border-ot-outline hover:bg-ot-surface-subtle"
    end
  end

  defp format_total(total) when is_number(total) do
    cond do
      total >= 1_000_000_000 ->
        :erlang.float_to_binary(total / 1_000_000_000, decimals: 1) <> " Mrd €"

      total >= 1_000_000 ->
        :erlang.float_to_binary(total / 1_000_000, decimals: 1) <> " Mio €"

      true ->
        :erlang.float_to_binary(total, decimals: 0) <> " €"
    end
  end

  defp format_total(_), do: "—"

  defp format_per_einwohner(total, pop) when is_number(total) and is_integer(pop) and pop > 0 do
    :erlang.float_to_binary(total / pop, decimals: 0)
  end

  defp format_per_einwohner(_, _), do: "—"
end
