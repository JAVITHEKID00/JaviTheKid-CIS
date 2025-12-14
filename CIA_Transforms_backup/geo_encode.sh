#!/usr/bin/env bash
mkdir -p /root/OSINT_Logs
#
# Geo Encode (Address -> GPS)
# Usa Nominatim (OpenStreetMap) vía geopy para convertir direcciones en coordenadas.
# Guarda resultados en /root/OSINT_Logs

ADDR="$1"

if [ -z "$ADDR" ]; then
    echo "[USAGE] $0 \"Full address\""
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Limpia el address para nombre de archivo
SAFE_NAME=$(echo "$ADDR" | tr ' /,' '_' | tr -s '_')

OUT_FILE="$LOG_DIR/geocode_${SAFE_NAME}_${TIMESTAMP}.txt"

python3 - << 'EOF' "$ADDR" "$OUT_FILE"
import sys
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderServiceError

addr = sys.argv[1]
out_file = sys.argv[2]

print(f"Geocoding: {addr} ...")

geolocator = Nominatim(user_agent="JaviTheKid_CIA_Geocode")

# Variantes del address para intentar
candidates = []

# Original
candidates.append(addr)

# Reemplazar abreviaturas típicas
replacements = {
    " LN ": " Lane ",
    " Ln ": " Lane ",
    " ln ": " Lane ",
    " ST ": " Street ",
    " Dr ": " Drive ",
}

norm = addr
for k, v in replacements.items():
    norm = norm.replace(k, v)
if norm != addr:
    candidates.append(norm)

# Sin ZIP (por si el ZIP molesta)
parts = addr.split(',')
if len(parts) >= 2:
    # ejemplo: "29603 Wilkerson LN Katy, TX 77494"
    # nos quedamos con "Katy, TX"
    city_state = ','.join(parts[1:]).strip()
    if city_state and city_state not in candidates:
        candidates.append(city_state)

# Solo ciudad + estado si detectamos "Katy" y "TX"
if "Katy" in addr and "TX" in addr and "Katy, TX" not in candidates:
    candidates.append("Katy, TX")

location = None
last_error = None

for cand in candidates:
    try:
        print(f"  -> Trying: {cand}")
        location = geolocator.geocode(
            cand,
            timeout=10,
            country_codes="us",
            addressdetails=True
        )
        if location:
            break
    except GeocoderServiceError as e:
        last_error = e
        print(f"  [WARN] Geocoder error with '{cand}': {e}")

if not location:
    print("[ERROR] Could not obtain coordinates.")
    if last_error:
        print(f"[DETAIL] Last geocoder error: {last_error}")
    # Guardar log mínimo para saber qué se intentó
    with open(out_file, "w", encoding="utf-8") as f:
        f.write("Geocoding FAILED\n")
        f.write(f"Original address: {addr}\n")
        f.write("Tried candidates:\n")
        for cand in candidates:
            f.write(f"  - {cand}\n")
        if last_error:
            f.write(f"Last error: {last_error}\n")
    sys.exit(1)

lat = location.latitude
lon = location.longitude

print(f"[OK] Coordinates: {lat}, {lon}")

# Guardar detalles en el log
with open(out_file, "w", encoding="utf-8") as f:
    f.write(f"Original address: {addr}\n")
    f.write(f"Used candidate: {location.address}\n")
    f.write(f"Latitude: {lat}\n")
    f.write(f"Longitude: {lon}\n")

print(f"[+] Saved to: {out_file}")
EOF
