defmodule TullnData.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string, null: false
      add :geom, :geometry, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:locations, [:geom], using: :gist)
  end
end
