#!/bin/bash
mkdir -p /root/OSINT_Logs

if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: exif_gps_batch.sh <directory>"
    exit 1
fi

DIR="$1"

if [ ! -d "$DIR" ]; then
    echo "[-] Directory not found: $DIR"
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/exif_gps_batch_${TS}.txt"

echo "EXIF GPS batch for directory: $DIR" | tee "$LOG_FILE"

shopt -s nullglob
for IMG in "$DIR"/*.jpg "$DIR"/*.jpeg "$DIR"/*.JPG "$DIR"/*.JPEG; do
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    echo "File: $IMG" | tee -a "$LOG_FILE"
    /root/CIA_Transforms/exif_gps.sh "$IMG" >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
done
shopt -u nullglob

echo "[+] Batch finished. Log saved to $LOG_FILE"
