defmodule TullnData.Budgets.LineItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias TullnData.Budgets.FiscalYear

  @sections [
    :vrv97_ordinary_expense,
    :vrv97_ordinary_revenue,
    :vrv97_extraordinary_expense,
    :vrv97_extraordinary_revenue,
    :vrv2015_fhh,
    :vrv2015_ehh,
    :vrv2015_vhh
  ]

  schema "budget_line_items" do
    belongs_to :fiscal_year, FiscalYear

    field :ansatz_code, :string
    field :ansatz_subcode, :string
    field :account_code, :string
    field :account_subcode, :string
    field :ansatz_name, :string
    field :account_name, :string
    field :amount, :decimal
    field :project_code, :string
    field :mvag, :string
    field :section, Ecto.Enum, values: @sections

    timestamps(type: :utc_datetime)
  end

  def sections, do: @sections

  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [
      :fiscal_year_id,
      :ansatz_code,
      :ansatz_subcode,
      :account_code,
      :account_subcode,
      :ansatz_name,
      :account_name,
      :amount,
      :project_code,
      :mvag,
      :section
    ])
    |> validate_required([:fiscal_year_id, :ansatz_code, :amount])
  end
end
