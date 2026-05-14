defmodule TullnData.Budgets.Municipality do
  use Ecto.Schema
  import Ecto.Changeset

  alias TullnData.Budgets.FiscalYear

  schema "budget_municipalities" do
    field :slug, :string
    field :name, :string
    field :gkz, :string
    field :population, :integer
    field :bezirk, :string
    field :bundesland, :string

    has_many :fiscal_years, FiscalYear

    timestamps(type: :utc_datetime)
  end

  def changeset(municipality, attrs) do
    municipality
    |> cast(attrs, [:slug, :name, :gkz, :population, :bezirk, :bundesland])
    |> validate_required([:slug, :name, :gkz])
    |> unique_constraint(:slug)
    |> unique_constraint(:gkz)
  end
end
