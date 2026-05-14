defmodule TullnData.Budgets.Ingest do
  @moduledoc """
  Wires the existing offenerhaushalt.at HTTP client and CSV parsers into the
  `Budgets.*` schemas: downloads a CSV, parses it, upserts the FiscalYear, and
  replaces the LineItems for that FiscalYear.

  Idempotent: re-running an ingest for the same (municipality, year, vrv_version,
  statement_type, budget_component) tuple replaces only those line items.
  """

  require Logger

  alias TullnData.Budget.{Client, Vrv2015, Vrv97}
  alias TullnData.Budgets

  @vrv97_section %{
    1 => :vrv97_ordinary_expense,
    2 => :vrv97_ordinary_revenue,
    5 => :vrv97_extraordinary_expense,
    6 => :vrv97_extraordinary_revenue
  }

  @vrv2015_component_to_section %{
    :finanzierungshaushalt => :vrv2015_fhh,
    :ergebnishaushalt => :vrv2015_ehh,
    :vermogenshaushalt => :vrv2015_vhh
  }

  @vrv2015_component_atom %{
    "fhh" => :fhh,
    "ehh" => :ehh,
    "vhh" => :vhh
  }

  @doc """
  Ingest one VRV97 finanzdaten CSV for the given municipality slug + year.

  Returns `{:ok, %{fiscal_year_id, line_items}}` or `{:error, reason}`.
  """
  def vrv97(slug, year) when is_binary(slug) and is_integer(year) do
    municipality = Budgets.get_municipality_by_slug!(slug)
    Logger.info("[budget ingest] #{slug} vrv97 #{year}: downloading…")

    with {:ok, body} <- Client.download_vrv97_for(slug, year, "finanzdaten") do
      Logger.info("[budget ingest] #{slug} vrv97 #{year}: parsing #{byte_size(body)} bytes…")
      rows = Vrv97.parse(body)
      Logger.info("[budget ingest] #{slug} vrv97 #{year}: parsed #{length(rows)} rows")

      fy =
        Budgets.upsert_fiscal_year!(%{
          municipality_id: municipality.id,
          year: year,
          vrv_version: :vrv97,
          statement_type: :actuals,
          budget_component: :none,
          source_url: vrv97_url(slug, year),
          ingested_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      line_attrs = Enum.map(rows, &vrv97_line_attrs/1)

      case Budgets.replace_line_items!(fy.id, line_attrs) do
        {:ok, count} ->
          Logger.info("[budget ingest] #{slug} vrv97 #{year}: upserted #{count} line items")
          {:ok, %{fiscal_year_id: fy.id, line_items: count}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Ingest one VRV2015 haushalt CSV (fhh/ehh/vhh) for the given municipality + year.

  Returns `{:ok, %{fiscal_year_id, line_items}}` or `{:error, reason}`.
  """
  def vrv2015(slug, year, haushalt, ra_va \\ "ra")
      when is_binary(slug) and is_integer(year) and haushalt in ["fhh", "ehh", "vhh"] and
             ra_va in ["ra", "va"] do
    municipality = Budgets.get_municipality_by_slug!(slug)

    Logger.info("[budget ingest] #{slug} vrv2015 #{year} #{haushalt}/#{ra_va}: downloading…")

    with {:ok, body} <-
           Client.download_vrv2015_for(slug, municipality.gkz, year, haushalt, ra_va) do
      Logger.info(
        "[budget ingest] #{slug} vrv2015 #{year} #{haushalt}: parsing #{byte_size(body)} bytes…"
      )

      rows = Vrv2015.parse(body)

      Logger.info(
        "[budget ingest] #{slug} vrv2015 #{year} #{haushalt}: parsed #{length(rows)} rows"
      )

      fy =
        Budgets.upsert_fiscal_year!(%{
          municipality_id: municipality.id,
          year: year,
          vrv_version: :vrv2015,
          statement_type: statement_type_atom(ra_va),
          budget_component: Map.fetch!(@vrv2015_component_atom, haushalt),
          source_url: vrv2015_url(year, haushalt, ra_va),
          ingested_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      line_attrs = Enum.map(rows, &vrv2015_line_attrs/1)

      case Budgets.replace_line_items!(fy.id, line_attrs) do
        {:ok, count} ->
          Logger.info(
            "[budget ingest] #{slug} vrv2015 #{year} #{haushalt}: upserted #{count} line items"
          )

          {:ok, %{fiscal_year_id: fy.id, line_items: count}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp vrv97_line_attrs(row) do
    %{
      ansatz_code: row.functional_code,
      ansatz_name: row.functional_name,
      account_code: row.economic_code,
      account_name: row.account_name,
      amount: row.amount,
      section: Map.get(@vrv97_section, row.budget_type)
    }
  end

  defp vrv2015_line_attrs(row) do
    base = %{
      ansatz_code: row.functional_code,
      ansatz_subcode: row.functional_subcode,
      account_code: row.account_group,
      account_subcode: row.account_subgroup,
      ansatz_name: row.functional_name,
      account_name: row.account_name,
      project_code: row.project_code,
      mvag: row.mvag,
      section: Map.get(@vrv2015_component_to_section, row.budget_component)
    }

    # fhh/ehh rows carry `amount`; vhh rows carry `closing_balance` instead.
    amount = Map.get(row, :amount) || Map.get(row, :closing_balance) || Decimal.new("0")
    Map.put(base, :amount, amount)
  end

  defp statement_type_atom("ra"), do: :actuals
  defp statement_type_atom("va"), do: :budget

  defp vrv97_url(slug, year),
    do: "https://vrv97.offenerhaushalt.at/download/finanzdaten/top/#{slug}/#{year}"

  defp vrv2015_url(year, haushalt, ra_va),
    do:
      "https://www.offenerhaushalt.at/downloads/ghdByParams?year=#{year}&haushalt=#{haushalt}&rechnungsabschluss=#{ra_va}"
end
