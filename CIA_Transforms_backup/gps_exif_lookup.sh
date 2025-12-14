#!/bin/bash
mkdir -p /root/OSINT_Logs

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "[ERROR] File not found."
    exit 1
fi

echo "== EXIF GPS LOOKUP =="
exiftool -gps* "$FILE"

LAT=$(exiftool -n -gpslatitude "$FILE" | awk -F": " '{print $2}')
LON=$(exiftool -n -gpslongitude "$FILE" | awk -F": " '{print $2}')

if [ -z "$LAT" ] || [ -z "$LON" ]; then
    echo "[!] No GPS data found."
    exit 0
fi

echo ""
echo "[+] Coordinates Found:"
echo "   LAT: $LAT"
echo "   LON: $LON"
echo ""

MAP="https://www.google.com/maps?q=$LAT,$LON"
echo "[+] Google Maps:"
echo "$MAP"

# Save result
TS=$(date +"%Y%m%d_%H%M%S")
OUT="/root/OSINT_Logs/gps_exif_${TS}.txt"

echo "Coordinates: $LAT,$LON" > "$OUT"
echo "Google Maps: $MAP" >> "$OUT"

echo ""
echo "[+] Saved to: $OUT"
