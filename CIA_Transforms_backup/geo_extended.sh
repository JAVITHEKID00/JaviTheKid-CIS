#!/bin/bash
mkdir -p /root/OSINT_Logs
# geo_extended.sh – Rich geocoding (address ➜ full info)

if [ -z "$1" ]; then
    echo "Usage: $0 \"FULL ADDRESS\""
    exit 1
fi

ADDR="$1"

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
SAFE_ADDR="$(echo "$ADDR" | tr ' ' '_' | tr -cd '[:alnum:]_')"

TXT_OUT="${LOG_DIR}/geo_extended_${SAFE_ADDR}_${TS}.txt"
JSON_OUT="${LOG_DIR}/geo_extended_${SAFE_ADDR}_${TS}.json"

echo "Geocoding (extended): $ADDR ..."
echo

GEO_ADDR="$ADDR" GEO_TXT="$TXT_OUT" GEO_JSON="$JSON_OUT" /root/OSINT_ENV/venv/bin/python - << 'EOF'
import os, json, textwrap
import urllib.parse

import requests

address = os.environ.get("GEO_ADDR", "").strip()
txt_path = os.environ.get("GEO_TXT")
json_path = os.environ.get("GEO_JSON")

if not address:
    print("[ERROR] Empty address received.")
    raise SystemExit(1)

# --- Nominatim request (OpenStreetMap) ---
base_url = "https://nominatim.openstreetmap.org/search"
params = {
    "q": address,
    "format": "json",
    "addressdetails": 1,
    "limit": 1
}
headers = {
    "User-Agent": "JaviTheKid-CIA-OSINT/1.0 (training use)"
}

try:
    r = requests.get(base_url, params=params, headers=headers, timeout=15)
    r.raise_for_status()
    data = r.json()
except Exception as e:
    print(f"[ERROR] Request failed: {e}")
    raise SystemExit(1)

if not data:
    print("[ERROR] No results from Nominatim.")
    raise SystemExit(1)

result = data[0]

lat = float(result["lat"])
lon = float(result["lon"])
display_name = result.get("display_name", "")
addr = result.get("address", {})

road = addr.get("road") or addr.get("pedestrian") or addr.get("footway")
house_number = addr.get("house_number")
city = addr.get("city") or addr.get("town") or addr.get("village")
neighbourhood = addr.get("neighbourhood") or addr.get("suburb")
county = addr.get("county")
state = addr.get("state")
postcode = addr.get("postcode")
country = addr.get("country")

# --- Timezone (optional, best-effort) ---
timezone = "Unknown"
try:
    from timezonefinder import TimezoneFinder
    tf = TimezoneFinder()
    timezone = tf.timezone_at(lat=lat, lng=lon) or "Unknown"
except Exception:
    timezone = "Unknown (install 'timezonefinder' in venv)"

# Build structured result
extended = {
    "input_address": address,
    "display_name": display_name,
    "latitude": lat,
    "longitude": lon,
    "road": road,
    "house_number": house_number,
    "city": city,
    "neighbourhood": neighbourhood,
    "county": county,
    "state": state,
    "postcode": postcode,
    "country": country,
    "timezone": timezone,
}

# Map links
extended["links"] = {
    "google_maps": f"https://www.google.com/maps?q={lat},{lon}",
    "openstreetmap": f"https://www.openstreetmap.org/?mlat={lat}&mlon={lon}#map=18/{lat}/{lon}",
    "bing_maps": f"https://www.bing.com/maps?q={lat},{lon}",
}

# --- Pretty TXT output ---
lines = []
lines.append("===============================================")
lines.append("     Geo Decode EXT – Address Intelligence    ")
lines.append("===============================================")
lines.append(f"Input address : {address}")
lines.append("")
lines.append(f"Latitude      : {lat}")
lines.append(f"Longitude     : {lon}")
lines.append("")
lines.append(f"Road          : {road}")
lines.append(f"House number  : {house_number}")
lines.append(f"City/Town     : {city}")
lines.append(f"Neighbourhood : {neighbourhood}")
lines.append(f"County        : {county}")
lines.append(f"State         : {state}")
lines.append(f"Postcode      : {postcode}")
lines.append(f"Country       : {country}")
lines.append(f"Timezone      : {timezone}")
lines.append("")
lines.append("---- Map links ----")
for k, v in extended["links"].items():
    lines.append(f"{k:13}: {v}")
lines.append("")
lines.append(f"Saved TXT : {txt_path}")
lines.append(f"Saved JSON: {json_path}")
lines.append("===============================================")

txt_content = "\n".join(lines)

print(txt_content)

try:
    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(txt_content)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(extended, f, ensure_ascii=False, indent=2)
except Exception as e:
    print(f"[WARN] Could not write log files: {e}")

EOF

STATUS=$?
if [ $STATUS -ne 0 ]; then
    echo
    echo "[ERROR] geo_extended.sh failed."
    exit $STATUS
fi

echo
echo "[+] Extended geocode saved:"
echo "    $TXT_OUT"
echo "    $JSON_OUT"
