#!/bin/bash
mkdir -p /root/OSINT_Logs

# ======================================================
#  SOCIAL MEDIA INTELLIGENCE V2 – Gallito CIA Platform
# ======================================================

LOG_DIR="/root/OSINT_Logs"
SCRIPT_NAME="social_v2"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$TIMESTAMP.txt"

mkdir -p "$LOG_DIR"

clear
echo "==============================================="
echo "     SOCIAL MEDIA INTELLIGENCE – V2"
echo "==============================================="
echo ""

read -p "Enter username or email: " QUERY

echo "[+] Starting Social Media Recon for: $QUERY"
echo "-----------------------------------------------" | tee -a "$LOG_FILE"
echo "TARGET: $QUERY" | tee -a "$LOG_FILE"
echo "-----------------------------------------------" | tee -a "$LOG_FILE"

# ---------- 1) SocialScan ----------------------------------

echo "" | tee -a "$LOG_FILE"
echo "[SOCIALSCAN RESULTS]" | tee -a "$LOG_FILE"
echo "-----------------------------------------------" | tee -a "$LOG_FILE"

if command -v socialscan &> /dev/null; then
    socialscan "$QUERY" --json | tee -a "$LOG_FILE"
else
    echo "[!] SocialScan not installed" | tee -a "$LOG_FILE"
fi

# ---------- 2) Holehe (email) ------------------------------

echo "" | tee -a "$LOG_FILE"
echo "[HOLEHE RESULTS]" | tee -a "$LOG_FILE"
echo "-----------------------------------------------" | tee -a "$LOG_FILE"

if command -v holehe &> /dev/null; then
    holehe "$QUERY" --no-color 2>/dev/null | tee -a "$LOG_FILE"
else
    echo "[!] Holehe not installed" | tee -a "$LOG_FILE"
fi

# ---------- 3) Basic Profile Pivoting -----------------------

echo "" | tee -a "$LOG_FILE"
echo "[BASIC OSINT PROFILE]" | tee -a "$LOG_FILE"
echo "-----------------------------------------------" | tee -a "$LOG_FILE"

echo "Checking possible profile URLs..." | tee -a "$LOG_FILE"

declare -a SITES=(
"https://facebook.com/$QUERY"
"https://instagram.com/$QUERY"
"https://twitter.com/$QUERY"
"https://x.com/$QUERY"
"https://tiktok.com/@$QUERY"
"https://github.com/$QUERY"
"https://linkedin.com/in/$QUERY"
"https://pinterest.com/$QUERY"
"https://vsco.co/$QUERY"
"https://snapchat.com/add/$QUERY"
)

for URL in "${SITES[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
        echo "[+] Found: $URL" | tee -a "$LOG_FILE"
    else
        echo "[-] Not found: $URL" | tee -a "$LOG_FILE"
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "===============================================" | tee -a "$LOG_FILE"
echo "[+] SOCIAL MEDIA INTELLIGENCE V2 COMPLETED"
echo "[+] Log saved to: $LOG_FILE"
echo "==============================================="
echo ""
