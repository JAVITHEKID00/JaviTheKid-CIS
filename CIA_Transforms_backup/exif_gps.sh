#!/bin/bash
mkdir -p /root/OSINT_Logs

# JavitheKid - EXIF GPS Extractor
# Uso: /root/CIA_Transforms/exif_gps.sh /ruta/a/imagen.jpg

source /root/OSINT_ENV/venv/bin/activate

IMG_PATH="$1"

if [ -z "$IMG_PATH" ]; then
    echo "[ERROR] Usage: $0 <image_path>"
    deactivate
    exit 1
fi

if [ ! -f "$IMG_PATH" ]; then
    echo "[ERROR] File not found: $IMG_PATH"
    deactivate
    exit 1
fi

export IMG_PATH

python << 'EOF'
import os, sys, json
from datetime import datetime
from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS

img_path = os.environ.get("IMG_PATH")
if not img_path:
    print("[ERROR] No IMG_PATH provided.")
    sys.exit(1)

def dms_to_decimal(dms, ref):
    degrees, minutes, seconds = dms

    def to_float(x):
        if isinstance(x, tuple):
            num, den = x
            return float(num) / float(den) if den else 0.0
        return float(x)

    d = to_float(degrees)
    m = to_float(minutes)
    s = to_float(seconds)
    dec = d + (m / 60.0) + (s / 3600.0)
    if ref in ["S", "W"]:
        dec = -dec
    return dec

print(f"[*] Reading EXIF from: {img_path}")

try:
    img = Image.open(img_path)
    exif = img._getexif()
except Exception as e:
    print(f"[ERROR] Cannot open image or read EXIF: {e}")
    sys.exit(1)

if not exif:
    print("[!] No EXIF data found.")
    sys.exit(0)

gps_info = {}
for tag_id, value in exif.items():
    tag = TAGS.get(tag_id, tag_id)
    if tag == 'GPSInfo':
        for key, val in value.items():
            subtag = GPSTAGS.get(key, key)
            gps_info[subtag] = val

if not gps_info:
    print("[!] No GPSInfo in EXIF.")
    sys.exit(0)

lat = lon = None
if "GPSLatitude" in gps_info and "GPSLatitudeRef" in gps_info:
    lat = dms_to_decimal(gps_info["GPSLatitude"], gps_info["GPSLatitudeRef"])
if "GPSLongitude" in gps_info and "GPSLongitudeRef" in gps_info:
    lon = dms_to_decimal(gps_info["GPSLongitude"], gps_info["GPSLongitudeRef"])

if lat is None or lon is None:
    print("[!] GPS tags found but could not compute coordinates.")
    sys.exit(0)

maps_link = f"https://www.google.com/maps?q={lat},{lon}"

result = {
    "image_path": img_path,
    "latitude": lat,
    "longitude": lon,
    "google_maps_link": maps_link,
    "gps_raw": gps_info,
}

print("----------------------------------------")
print(f" Latitude : {lat}")
print(f" Longitude: {lon}")
print(f" Maps URL : {maps_link}")
print("----------------------------------------")

log_dir = "/root/OSINT_Logs"
os.makedirs(log_dir, exist_ok=True)
ts = datetime.now().strftime("%Y%m%d_%H%M%S")
base = os.path.basename(img_path)
safe_base = base.replace(" ", "_")
log_path = os.path.join(log_dir, f"exif_gps_{safe_base}_{ts}.json")

with open(log_path, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print(f"[+] Saved to: {log_path}")
EOF

deactivate
