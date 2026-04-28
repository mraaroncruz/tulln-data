defmodule TullnData.Geo.LocationTest do
  use TullnData.DataCase

  alias TullnData.Geo.Location
  alias TullnData.Repo

  import Ecto.Query

  @hauptplatz %Geo.Point{coordinates: {15.8827, 48.3478}, srid: 4326}
  @minoritenkirche %Geo.Point{coordinates: {15.8835, 48.3483}, srid: 4326}
  @donaupark %Geo.Point{coordinates: {15.8870, 48.3450}, srid: 4326}

  test "inserts and reads back a PostGIS point" do
    {:ok, location} =
      %Location{}
      |> Location.changeset(%{name: "Hauptplatz", geom: @hauptplatz})
      |> Repo.insert()

    assert %Geo.Point{coordinates: {15.8827, 48.3478}, srid: 4326} = location.geom
  end

  test "ST_Distance returns zero for the same point" do
    Repo.insert!(%Location{name: "Hauptplatz", geom: @hauptplatz})

    [{distance}] =
      from(l in Location,
        select: {fragment("ST_Distance(?, ?)", l.geom, ^@hauptplatz)}
      )
      |> Repo.all()

    assert distance == 0.0
  end

  test "ST_Distance orders locations by proximity" do
    Repo.insert!(%Location{name: "Hauptplatz", geom: @hauptplatz})
    Repo.insert!(%Location{name: "Minoritenkirche", geom: @minoritenkirche})
    Repo.insert!(%Location{name: "Donaupark", geom: @donaupark})

    names =
      from(l in Location,
        select: l.name,
        order_by: fragment("ST_Distance(?, ?)", l.geom, ^@hauptplatz)
      )
      |> Repo.all()

    assert names == ["Hauptplatz", "Minoritenkirche", "Donaupark"]
  end
end
