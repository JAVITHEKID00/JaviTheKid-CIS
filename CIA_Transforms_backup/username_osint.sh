#!/bin/bash
mkdir -p /root/OSINT_Logs

if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: username_osint.sh <username>"
    exit 1
fi

USERN="$1"

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"
TS=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/username_osint_${USERN}_${TS}.txt"

echo "Username OSINT for: $USERN" | tee "$LOG_FILE"

echo -e "\n[+] holehe (only used accounts)" | tee -a "$LOG_FILE"
holehe --only-used --no-color "$USERN" >> "$LOG_FILE" 2>&1

echo -e "\n[+] socialscan" | tee -a "$LOG_FILE"
socialscan "$USERN" --timeout 15 --no-color >> "$LOG_FILE" 2>&1

echo "[+] Done. Log saved to $LOG_FILE"
