#!/usr/bin/env bash
# Downloads input data: the Novi Sad GTFS, the OSM extract, MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# The feed is generated from JGSP Novi Sad's own timetables by Nedzad Beus's
# gtfs-generators on GitLab — the source Transitous uses for Serbia.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== Novi Sad GTFS (gtfs-generators) =="
  curl -fL --retry 3 --max-time 600 -o data/ns-gtfs.zip \
    "https://gitlab.com/api/v4/projects/vekejsn%2Fgtfs-generators/packages/generic/novi_sad-gtfs/latest/novi_sad_gtfs.zip"
  unzip -o data/ns-gtfs.zip -d data/gtfs
fi

# 2) OSM — from the Geofabrik extract, not Overpass.
#    3 x 3 road tiles out of the Serbian Geofabrik extract — the suburban
#    lines reach Beocin, Sremski Karlovci and Zabalj.
#    pipeline/pbf-tiles.py cuts the tiles out of the .pbf and writes exactly the
#    JSON shape Overpass would have returned (ways with tags, NODE IDS and
#    geometry — buildGraph silently drops ways without el.nodes).
if [ ! -f data/osm/tiles/t9.json ]; then
  need_osmium
  if [ ! -f data/serbia-latest.osm.pbf ]; then
    echo "== Geofabrik serbia-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/serbia-latest.osm.pbf \
      "https://download.geofabrik.de/europe/serbia-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm 2>/dev/null || true
