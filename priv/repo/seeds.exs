alias TullnData.Repo
alias TullnData.Geo.Location
import Ecto.Query

# Tulln an der Donau landmarks (WGS84 / SRID 4326)
hauptplatz = %Geo.Point{coordinates: {15.8827, 48.3478}, srid: 4326}
minoritenkirche = %Geo.Point{coordinates: {15.8835, 48.3483}, srid: 4326}
donaupark = %Geo.Point{coordinates: {15.8870, 48.3450}, srid: 4326}

Repo.insert!(%Location{name: "Hauptplatz", geom: hauptplatz})
Repo.insert!(%Location{name: "Minoritenkirche", geom: minoritenkirche})
Repo.insert!(%Location{name: "Donaupark", geom: donaupark})

# ST_Distance smoke test: distance in degrees between Hauptplatz and each location
query =
  from(l in Location,
    select: {
      l.name,
      fragment("ST_Distance(?, ?)", l.geom, ^hauptplatz)
    },
    order_by: fragment("ST_Distance(?, ?)", l.geom, ^hauptplatz)
  )

IO.puts("\n=== ST_Distance from Hauptplatz ===")

for {name, distance} <- Repo.all(query) do
  IO.puts("  #{name}: #{distance}")
end

IO.puts("=== Seed complete ===\n")
