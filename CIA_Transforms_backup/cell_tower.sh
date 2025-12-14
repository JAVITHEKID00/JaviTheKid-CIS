#!/bin/bash
mkdir -p /root/OSINT_Logs

if [ $# -lt 4 ]; then
    echo "[ERROR] Usage: cell_tower.sh <MCC> <MNC> <LAC/TAC> <CID>"
    echo "Example (USA): cell_tower.sh 310 260 12345 67890123"
    exit 1
fi

MCC="$1"
MNC="$2"
LAC="$3"
CID="$4"

# Get your own key at: https://location.services.mozilla.com/
MLS_API_KEY="test"   # <-- replace with your real key when you have it

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/cell_tower_${MCC}_${MNC}_${LAC}_${CID}_${TS}.txt"

echo "Cell tower lookup MCC=$MCC MNC=$MNC LAC=$LAC CID=$CID ..." | tee "$LOG_FILE"

python3 <<PYEOF >> "$LOG_FILE" 2>&1
import requests, json, sys

mcc = int("$MCC")
mnc = int("$MNC")
lac = int("$LAC")
cid = int("$CID")
api_key = "$MLS_API_KEY"

url = f"https://location.services.mozilla.com/v1/search?key={api_key}"
payload = {
    "cell": [{
        "radio": "lte",
        "mcc": mcc,
        "mnc": mnc,
        "lac": lac,
        "cid": cid
    }]
}

print("\n[+] Requesting Mozilla Location Service...")
try:
    r = requests.post(url, json=payload, timeout=20)
except Exception as e:
    print("[-] Request error:", e)
    sys.exit(1)

print("Status:", r.status_code)
if r.status_code != 200:
    print("[-] No data or HTTP error.")
    print(r.text)
    sys.exit(1)

data = r.json()
if "lat" not in data or "lon" not in data:
    print("[-] No coordinates in response.")
    print(data)
    sys.exit(1)

lat = data["lat"]
lon = data["lon"]
acc = data.get("accuracy", "N/A")

print(f"\n[+] Latitude : {lat}")
print(f"[+] Longitude: {lon}")
print(f"[+] Accuracy : {acc} meters")

gmap = f"https://www.google.com/maps?q={lat},{lon}"
print("\n[+] Google Maps:", gmap)
PYEOF

echo "[+] Saved to $LOG_FILE"
