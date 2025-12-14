#!/bin/bash
mkdir -p /root/OSINT_Logs

if [ $# -lt 2 ]; then
    echo "[ERROR] Usage: triangulate.sh lat1,lon1 lat2,lon2 [lat3,lon3 ...]"
    echo "Example: triangulate.sh 29.7858,-95.8245 29.7800,-95.8200 29.7900,-95.8300"
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/triangulate_${TS}.txt"

python3 <<PYEOF "$@" | tee "$LOG_FILE"
import sys, math

pairs = []
for arg in sys.argv[1:]:
    try:
        lat_str, lon_str = arg.split(",")
        pairs.append((float(lat_str), float(lon_str)))
    except Exception:
        print(f"Skipping invalid arg: {arg}")

if len(pairs) < 2:
    print("Need at least two valid points.")
    sys.exit(1)

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000.0
    from math import radians, sin, cos, sqrt, atan2
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return R * c

avg_lat = sum(p[0] for p in pairs) / len(pairs)
avg_lon = sum(p[1] for p in pairs) / len(pairs)

radius = max(haversine(avg_lat, avg_lon, lat, lon) for lat, lon in pairs)

print("Input points:")
for lat, lon in pairs:
    print(f" - {lat:.6f}, {lon:.6f}")

print("\nApprox center:")
print(f" Latitude : {avg_lat:.6f}")
print(f" Longitude: {avg_lon:.6f}")
print(f" Max radius ≈ {radius:.1f} meters")

gmap = f"https://www.google.com/maps?q={avg_lat},{avg_lon}"
print("\nGoogle Maps:", gmap)
PYEOF

echo "[+] Saved to $LOG_FILE"
