defmodule TullnData.FloodScenario do
  use Ecto.Schema
  import Ecto.Changeset

  @scenarios ~w(hq30 hq100 hq300)

  schema "flood_scenarios" do
    field :source_id, :string
    field :scenario, :string
    field :return_period, :integer
    field :geom, Geo.PostGIS.Geometry
    field :source_updated_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(flood_scenario, attrs) do
    flood_scenario
    |> cast(attrs, [:source_id, :scenario, :return_period, :geom, :source_updated_at])
    |> validate_required([:source_id, :scenario, :return_period, :geom])
    |> validate_inclusion(:scenario, @scenarios)
    |> unique_constraint([:source_id, :scenario])
  end
end
