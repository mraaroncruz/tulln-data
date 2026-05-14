defmodule TullnData.Budgets.Quicktest do
  @moduledoc """
  Computes the five canonical KDZ Quicktest ratios for a municipality + year:

    1. Öffentliche Sparquote (ÖSQ) — % free savings after mandatory operating costs
    2. Eigenfinanzierungsquote (EFQ) — % of operating costs covered by operating revenue
    3. Verschuldungsdauer (VD) — years to pay off net debt out of savings
    4. Schuldendienstquote (SDQ) — % of revenue locked into debt service
    5. Investitionsquote (IQ) — % of total spending going to capital investment

  Each ratio is graded A–E against thresholds taken from KDZ's published methodology.

  **MVP status:** `compute/2` currently returns calibrated placeholder values per
  Gemeinde — the real math requires mapping VRV2015 MVAG codes to operating
  vs. capital flows and isolating leaf-level line items from group subtotals.
  That's its own piece of work. The card shape, grade colors, sparkline slots
  and thresholds are all correct; only the numeric source is stubbed. Replace
  the per-municipality maps below with a real aggregation once MVAG mapping is in.
  """

  @grade_order [:a, :b, :c, :d, :e]

  @thresholds %{
    oesq: %{direction: :higher_is_better, breaks: [25.0, 15.0, 5.0, 0.0]},
    efq: %{direction: :higher_is_better, breaks: [110.0, 100.0, 90.0, 80.0]},
    vd: %{direction: :lower_is_better, breaks: [3.0, 10.0, 15.0, 25.0]},
    sdq: %{direction: :lower_is_better, breaks: [6.0, 10.0, 15.0, 25.0]},
    iq: %{direction: :higher_is_better, breaks: [30.0, 20.0, 10.0, 0.0]}
  }

  # Placeholder ratio values per municipality, matching the v1 designer mock
  # (Tulln 2023: B / B / B / A / C → averaged-ish to "Gesamt B"). Tweak per
  # slug to make peer comparison meaningful. Replace once real aggregation lands.
  @demo_values %{
    "tulln-der-donau" => %{oesq: 12.5, efq: 105.2, vd: 6.2, sdq: 3.1, iq: 14.2},
    "klosterneuburg" => %{oesq: 18.6, efq: 112.4, vd: 2.8, sdq: 4.7, iq: 22.1},
    "korneuburg" => %{oesq: 6.8, efq: 98.3, vd: 11.4, sdq: 8.9, iq: 9.6},
    "stockerau" => %{oesq: 10.4, efq: 103.5, vd: 7.1, sdq: 5.5, iq: 13.8}
  }

  @demo_default %{oesq: 8.0, efq: 100.0, vd: 8.0, sdq: 6.0, iq: 10.0}

  @doc """
  Returns the five Quicktest ratios for the given municipality slug + year,
  in the order they appear on the result page.

  Each entry is a `%{key, value, grade, label, unit}` map.
  """
  def compute(slug, _year) when is_binary(slug) do
    values = Map.get(@demo_values, slug, @demo_default)

    [
      ratio(:oesq, "Öffentliche Sparquote", "%", values.oesq),
      ratio(:efq, "Eigenfinanzierungsquote", "%", values.efq),
      ratio(:vd, "Verschuldungsdauer", "Jahre", values.vd),
      ratio(:sdq, "Schuldendienstquote", "%", values.sdq),
      ratio(:iq, "Investitionsquote", "%", values.iq)
    ]
  end

  @doc """
  Overall A–E grade for a municipality, used on the landing-page cards.
  Currently the median grade across the five ratios.
  """
  def overall_grade(slug) do
    ratios = compute(slug, nil)
    grades = Enum.map(ratios, & &1.grade)

    grade_indexes = Enum.map(grades, &Enum.find_index(@grade_order, fn g -> g == &1 end))
    median_idx = grade_indexes |> Enum.sort() |> Enum.at(div(length(grade_indexes), 2))
    Enum.at(@grade_order, median_idx)
  end

  @doc """
  Maps a numeric value for a given ratio key to an A–E grade.
  """
  def grade(ratio_key, value) when is_number(value) do
    %{direction: dir, breaks: breaks} = Map.fetch!(@thresholds, ratio_key)
    do_grade(value, breaks, dir)
  end

  def grade_order, do: @grade_order

  def short_label(:oesq), do: "ÖSQ"
  def short_label(:efq), do: "EFQ"
  def short_label(:vd), do: "VD"
  def short_label(:sdq), do: "SDQ"
  def short_label(:iq), do: "IQ"

  def tooltip(:oesq),
    do:
      "Wie viel Spielraum bleibt nach den Pflichtausgaben? Hohe ÖSQ heißt: die Stadt kann sparen oder investieren."

  def tooltip(:efq),
    do:
      "Decken die laufenden Einnahmen die laufenden Ausgaben? Unter 100 % heißt: laufender Betrieb ist defizitär."

  def tooltip(:vd),
    do:
      "Wie viele Jahre dauert es, die Schulden aus eigener Kraft zu tilgen? Unter 3 Jahren ist sehr solide."

  def tooltip(:sdq),
    do:
      "Wie viel der Einnahmen geht in den Schuldendienst (Zinsen + Tilgung)? Niedrig ist gut — bedeutet finanzielle Flexibilität."

  def tooltip(:iq),
    do:
      "Wie viel des Budgets fließt in Investitionen statt in den laufenden Betrieb? Höher heißt: aktive Stadtentwicklung."

  defp do_grade(value, [b1, b2, b3, b4], :higher_is_better) do
    cond do
      value >= b1 -> :a
      value >= b2 -> :b
      value >= b3 -> :c
      value >= b4 -> :d
      true -> :e
    end
  end

  defp do_grade(value, [b1, b2, b3, b4], :lower_is_better) do
    cond do
      value <= b1 -> :a
      value <= b2 -> :b
      value <= b3 -> :c
      value <= b4 -> :d
      true -> :e
    end
  end

  defp ratio(key, label, unit, value) do
    %{
      key: key,
      label: label,
      unit: unit,
      value: value,
      grade: grade(key, value)
    }
  end
end
