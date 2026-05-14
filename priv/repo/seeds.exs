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

# Municipalities seeded for the OpenTulln budget lens.
# Tulln is the focal Gemeinde; the three peers are size-comparable Danube-corridor
# Bezirksstädte chosen for budget comparison (per Linear ELB-1345).
# Populations from 2024 Statistik Austria figures; refine if a STATcube fetch lands.

municipalities = [
  %{
    slug: "tulln-der-donau",
    name: "Tulln an der Donau",
    gkz: "32135",
    population: 16_556,
    bezirk: "Tulln",
    bundesland: "Niederösterreich"
  },
  %{
    slug: "klosterneuburg",
    name: "Klosterneuburg",
    gkz: "32125",
    population: 27_542,
    bezirk: "Klosterneuburg (Statutarstadt)",
    bundesland: "Niederösterreich"
  },
  %{
    slug: "korneuburg",
    name: "Korneuburg",
    gkz: "31207",
    population: 13_565,
    bezirk: "Korneuburg",
    bundesland: "Niederösterreich"
  },
  %{
    slug: "stockerau",
    name: "Stockerau",
    gkz: "31230",
    population: 16_916,
    bezirk: "Korneuburg",
    bundesland: "Niederösterreich"
  }
]

for attrs <- municipalities do
  TullnData.Budgets.upsert_municipality!(attrs)
end

IO.puts("=== Seeded #{length(municipalities)} Gemeinden ===")

for m <- TullnData.Budgets.list_municipalities() do
  IO.puts("  #{m.name} · GKZ #{m.gkz} · Pop #{m.population}")
end

IO.puts("")
