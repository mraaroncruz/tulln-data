defmodule TullnData.Repo.Migrations.CreateFloodScenarios do
  use Ecto.Migration

  def change do
    create table(:flood_scenarios) do
      add :source_id, :string, null: false
      add :scenario, :string, null: false
      add :return_period, :integer, null: false
      add :geom, :geometry, null: false, srid: 4326
      add :source_updated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:flood_scenarios, [:source_id, :scenario])
    create index(:flood_scenarios, [:geom], using: :gist)
    create index(:flood_scenarios, [:scenario])
  end
end
