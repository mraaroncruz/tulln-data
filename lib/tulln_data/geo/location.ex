defmodule TullnData.Geo.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    field :name, :string
    field :geom, Geo.PostGIS.Geometry

    timestamps(type: :utc_datetime)
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :geom])
    |> validate_required([:name, :geom])
  end
end
