#!/bin/bash
mkdir -p /root/OSINT_Logs

if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: bssid_lookup.sh <BSSID>"
    echo "Example: bssid_lookup.sh 18:35:D1:AA:BB:CC"
    exit 1
fi

BSSID="$1"

# Set your Wigle credentials here
# Create account at https://wigle.net/ then generate API token
WIGLE_USER="YOUR_WIGLE_USERNAME"
WIGLE_TOKEN="YOUR_WIGLE_API_TOKEN"

if [ "$WIGLE_USER" = "YOUR_WIGLE_USERNAME" ]; then
    echo "[-] Edit bssid_lookup.sh and set WIGLE_USER and WIGLE_TOKEN first."
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/bssid_${BSSID}_${TS}.txt"

echo "BSSID lookup for $BSSID ..." | tee "$LOG_FILE"

python3 <<PYEOF >> "$LOG_FILE" 2>&1
import requests, sys

bssid = "$BSSID"
user = "$WIGLE_USER"
token = "$WIGLE_TOKEN"

url = "https://api.wigle.net/api/v2/network/search"
params = {"netid": bssid}

print("[+] Querying Wigle API...")
try:
    r = requests.get(url, params=params, auth=(user, token), timeout=20)
except Exception as e:
    print("[-] Request error:", e)
    sys.exit(1)

print("Status:", r.status_code)
if r.status_code != 200:
    print("[-] HTTP error:")
    print(r.text)
    sys.exit(1)

data = r.json()
results = data.get("results", [])
if not results:
    print("[-] No results for this BSSID.")
    sys.exit(0)

r0 = results[0]
lat = r0.get("trilat")
lon = r0.get("trilong")
ssid = r0.get("ssid", "N/A")
lastupdt = r0.get("lastupdt", "N/A")

print(f"\n[+] SSID      : {ssid}")
print(f"[+] Latitude  : {lat}")
print(f"[+] Longitude : {lon}")
print(f"[+] Last seen : {lastupdt}")

gmap = f"https://www.google.com/maps?q={lat},{lon}"
print("\n[+] Google Maps:", gmap)
PYEOF

echo "[+] Saved to $LOG_FILE"
