# Novi Sad Public Transport — interactive map

Interactive, poster-grade map of the public transport network of **Novi Sad**:
99 city and suburban lines of JGSP Novi Sad, from the city grid out to Beočin
under Fruška Gora, Sremski Karlovci and Žabalj — 989 stops, 3 318 km.

## Live

Local build on port 8173 (`npm run serve`).

The feed is generated from JGSP's own timetables by **Nedžad Beus's
gtfs-generators on GitLab** — the source Transitous uses for Serbia — and
ships shapes.

| mode | route_type | graph |
|---|---|---|
| buses | 3 | OSM roadways |

Novi Sad has neither tram (the last one ran in 1958) nor trolleybus, so this is
the whole network.

The feed publishes ONE ROUTE ROW PER PATTERN — 219 rows for 99 live line
numbers — so the rows merge on the shared key by themselves and the engine
picks a representative pattern per direction, exactly as it does for feeds that
ship one row per line. `direction_id` is 0 on every trip, so directions are
keyed by headsign; this feed fills them everywhere.

## Pipeline

`npm run download` fetches the feed and cuts the OSM extract. **The OSM
data comes from Geofabrik, not Overpass** — the public mirrors were answering
504 to every request on the day this map was built, even for a single small
city box — so `pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`)
clips the tiles out of `serbia-latest.osm.pbf`, writing exactly the JSON shape Overpass would
have returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graph) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view.
`npm run serve` hosts the map at <http://localhost:8173>.

Data: JGSP Novi Sad via gtfs-generators ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
