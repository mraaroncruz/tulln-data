defmodule TullnData.Budgets do
  @moduledoc """
  Context for municipal budget data: Gemeinden, fiscal years, and CSV line items
  parsed from offenerhaushalt.at (VRV97 + VRV2015 formats).
  """

  import Ecto.Query

  alias TullnData.Budgets.{FiscalYear, LineItem, Municipality}
  alias TullnData.Repo

  def list_municipalities do
    Municipality
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def get_municipality_by_slug!(slug) do
    Repo.get_by!(Municipality, slug: slug)
  end

  def get_municipality_by_slug(slug) do
    Repo.get_by(Municipality, slug: slug)
  end

  def upsert_municipality!(attrs) do
    %Municipality{}
    |> Municipality.changeset(attrs)
    |> Repo.insert!(
      on_conflict: {:replace, [:name, :gkz, :population, :bezirk, :bundesland, :updated_at]},
      conflict_target: :slug,
      returning: true
    )
  end

  def upsert_fiscal_year!(attrs) do
    %FiscalYear{}
    |> FiscalYear.changeset(attrs)
    |> Repo.insert!(
      on_conflict: {:replace, [:source_url, :ingested_at, :updated_at]},
      conflict_target: [
        :municipality_id,
        :year,
        :vrv_version,
        :statement_type,
        :budget_component
      ],
      returning: true
    )
  end

  # Postgres caps a single bind at 65535 params. Each LineItem row carries ~13
  # fields once timestamps + FK are added, so 1000 rows per insert is a safe
  # batch size and still fast.
  @insert_chunk_size 1000

  @doc """
  Replaces all line items for a given fiscal_year_id with the supplied list of
  attribute maps. Wrapped in a transaction so a partial failure leaves the prior
  state intact. Inserts are chunked to stay under Postgres' per-query parameter
  cap.
  """
  def replace_line_items!(fiscal_year_id, line_item_attrs) when is_list(line_item_attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows =
      Enum.map(line_item_attrs, fn attrs ->
        attrs
        |> Map.put(:fiscal_year_id, fiscal_year_id)
        |> Map.put_new(:inserted_at, now)
        |> Map.put_new(:updated_at, now)
      end)

    Repo.transaction(fn ->
      Repo.delete_all(from(li in LineItem, where: li.fiscal_year_id == ^fiscal_year_id))

      rows
      |> Enum.chunk_every(@insert_chunk_size)
      |> Enum.reduce(0, fn chunk, acc ->
        {count, _} = Repo.insert_all(LineItem, chunk)
        acc + count
      end)
    end)
  end

  @doc """
  Aggregates a Gemeinde's EHH (Ergebnishaushalt) line items for a given year by
  top-level Ansatz group (the first digit of `ansatz_code` — Austria's
  standardized 0–9 functional bereiche). Returns a list of
  `%{code, name, amount}` ordered by amount desc.

  If no EHH data exists for that (slug, year), returns an empty list.
  """
  def top_level_ansatz_breakdown(slug, year) when is_binary(slug) and is_integer(year) do
    case get_municipality_by_slug(slug) do
      nil ->
        []

      m ->
        from(li in LineItem,
          join: fy in FiscalYear,
          on: fy.id == li.fiscal_year_id,
          where:
            fy.municipality_id == ^m.id and fy.year == ^year and
              fy.budget_component == :ehh and not is_nil(li.ansatz_code),
          group_by: fragment("LEFT(?, 1)", li.ansatz_code),
          select: %{
            code: fragment("LEFT(?, 1)", li.ansatz_code),
            amount: sum(li.amount)
          },
          order_by: [desc: sum(li.amount)]
        )
        |> Repo.all()
        |> Enum.map(fn row ->
          Map.put(row, :name, ansatz_group_name(row.code))
        end)
    end
  end

  @doc """
  Returns the list of years for which we have EHH data for a Gemeinde,
  newest first.
  """
  def available_years(slug) when is_binary(slug) do
    case get_municipality_by_slug(slug) do
      nil ->
        []

      m ->
        from(fy in FiscalYear,
          where: fy.municipality_id == ^m.id and fy.budget_component == :ehh,
          select: fy.year,
          distinct: true,
          order_by: [desc: fy.year]
        )
        |> Repo.all()
    end
  end

  # German labels for the canonical Austrian Ansatz functional groups (Gruppen).
  defp ansatz_group_name("0"), do: "Vertretung & Verwaltung"
  defp ansatz_group_name("1"), do: "Öffentliche Ordnung"
  defp ansatz_group_name("2"), do: "Bildung"
  defp ansatz_group_name("3"), do: "Kunst & Kultur"
  defp ansatz_group_name("4"), do: "Soziale Wohlfahrt"
  defp ansatz_group_name("5"), do: "Gesundheit"
  defp ansatz_group_name("6"), do: "Bau & Verkehr"
  defp ansatz_group_name("7"), do: "Wirtschaftsförderung"
  defp ansatz_group_name("8"), do: "Dienstleistungen"
  defp ansatz_group_name("9"), do: "Finanzwirtschaft"
  defp ansatz_group_name(other), do: "Gruppe #{other}"
end
