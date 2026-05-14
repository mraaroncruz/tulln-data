defmodule TullnData.Budgets.FiscalYear do
  use Ecto.Schema
  import Ecto.Changeset

  alias TullnData.Budgets.{LineItem, Municipality}

  @vrv_versions [:vrv97, :vrv2015]
  @statement_types [:actuals, :budget]
  @budget_components [:none, :fhh, :ehh, :vhh]

  schema "budget_fiscal_years" do
    belongs_to :municipality, Municipality
    field :year, :integer
    field :vrv_version, Ecto.Enum, values: @vrv_versions
    field :statement_type, Ecto.Enum, values: @statement_types
    field :budget_component, Ecto.Enum, values: @budget_components, default: :none
    field :source_url, :string
    field :ingested_at, :utc_datetime

    has_many :line_items, LineItem

    timestamps(type: :utc_datetime)
  end

  def vrv_versions, do: @vrv_versions
  def statement_types, do: @statement_types
  def budget_components, do: @budget_components

  def changeset(fiscal_year, attrs) do
    fiscal_year
    |> cast(attrs, [
      :municipality_id,
      :year,
      :vrv_version,
      :statement_type,
      :budget_component,
      :source_url,
      :ingested_at
    ])
    |> validate_required([:municipality_id, :year, :vrv_version, :statement_type])
    |> unique_constraint(
      [:municipality_id, :year, :vrv_version, :statement_type, :budget_component],
      name: :budget_fiscal_years_uniq
    )
  end
end
