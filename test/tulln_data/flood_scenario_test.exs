defmodule TullnData.FloodScenarioTest do
  use TullnData.DataCase

  alias TullnData.FloodScenario

  @valid_attrs %{
    source_id: "32101_0",
    scenario: "hq30",
    return_period: 30,
    geom: %Geo.Polygon{
      coordinates: [
        [{15.88, 48.33}, {15.88, 48.34}, {15.90, 48.34}, {15.90, 48.33}, {15.88, 48.33}]
      ],
      srid: 4326
    }
  }

  test "valid changeset" do
    changeset = FloodScenario.changeset(%FloodScenario{}, @valid_attrs)
    assert changeset.valid?
  end

  test "requires source_id, scenario, return_period, geom" do
    changeset = FloodScenario.changeset(%FloodScenario{}, %{})
    refute changeset.valid?

    assert %{
             source_id: ["can't be blank"],
             scenario: ["can't be blank"],
             return_period: ["can't be blank"],
             geom: ["can't be blank"]
           } = errors_on(changeset)
  end

  test "rejects invalid scenario" do
    changeset = FloodScenario.changeset(%FloodScenario{}, %{@valid_attrs | scenario: "hq50"})
    refute changeset.valid?
    assert %{scenario: ["is invalid"]} = errors_on(changeset)
  end

  test "inserts and queries by point-in-polygon" do
    {:ok, _} =
      %FloodScenario{}
      |> FloodScenario.changeset(@valid_attrs)
      |> Repo.insert()

    inside = %Geo.Point{coordinates: {15.89, 48.335}, srid: 4326}
    outside = %Geo.Point{coordinates: {16.0, 48.5}, srid: 4326}

    assert TullnData.Hora.flood_class(inside) == "hq30"
    assert TullnData.Hora.flood_class(outside) == nil
  end

  test "upsert replaces geometry on conflict" do
    {:ok, original} =
      %FloodScenario{}
      |> FloodScenario.changeset(@valid_attrs)
      |> Repo.insert()

    updated_geom = %Geo.Polygon{
      coordinates: [
        [{15.87, 48.32}, {15.87, 48.35}, {15.91, 48.35}, {15.91, 48.32}, {15.87, 48.32}]
      ],
      srid: 4326
    }

    {:ok, _} =
      %FloodScenario{}
      |> FloodScenario.changeset(%{@valid_attrs | geom: updated_geom})
      |> Repo.insert(
        on_conflict: {:replace, [:geom, :updated_at]},
        conflict_target: [:source_id, :scenario]
      )

    reloaded = Repo.get!(FloodScenario, original.id)
    assert reloaded.geom != original.geom
  end
end
