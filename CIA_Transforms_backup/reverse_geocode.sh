#!/bin/bash
mkdir -p /root/OSINT_Logs

# reverse_geocode.sh
# Uso:
#   reverse_geocode.sh <LAT> <LON>

LAT="$1"
LON="$2"

if [ -z "$LAT" ] || [ -z "$LON" ]; then
    echo "[ERROR] Uso: reverse_geocode.sh <LAT> <LON>"
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"

TS=$(date +"%Y%m%d_%H%M%S")
OUT="$LOG_DIR/reverse_geocode_${LAT}_${LON}_${TS}.txt"

echo "Reverse geocoding $LAT , $LON ..."
echo

# Activa el entorno virtual de OSINT
source /root/OSINT_ENV/venv/bin/activate

# Bloque Python incrustado
python3 <<EOF > "$OUT"
from geopy.geocoders import Nominatim

lat = float("$LAT")
lon = float("$LON")

geolocator = Nominatim(user_agent="CIA_PLATFORM")

location = geolocator.reverse((lat, lon), language="en")

print("======================================")
print(f"Coordinates: {lat}, {lon}")
print("--------------------------------------")
if location:
    print("Address:")
    print(location.address)
else:
    print("No address found.")
print("======================================")
EOF

# Cierra el venv
deactivate

echo
echo "[+] Saved to: $OUT"
echo
cat "$OUT"
