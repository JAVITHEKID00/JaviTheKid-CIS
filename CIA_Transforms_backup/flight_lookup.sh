#!/usr/bin/env bash
# JaviTheKid – CIA Transform: Flight Lookup (FlightAware AeroAPI)
# Usage:
#   flight_lookup.sh <AIRPORT_CODE> [TAG]
# Example:
#   flight_lookup.sh KIAH now
set -euo pipefail

CONF_FILE="/root/CIA_Transforms/api_keys.conf"
LOG_DIR="/root/OSINT_Logs"
BASE_URL="https://aeroapi.flightaware.com/aeroapi"

mkdir -p "$LOG_DIR"

# Load keys
if [[ -f "$CONF_FILE" ]]; then
  # shellcheck source=/root/CIA_Transforms/api_keys.conf
  source "$CONF_FILE"
else
  echo "[-] ERROR: No se encontró $CONF_FILE"
  exit 1
fi

if [[ -z "${FLIGHTAWARE_KEY:-}" ]]; then
  echo "[-] ERROR: FLIGHTAWARE_KEY no definido en api_keys.conf"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <AIRPORT_CODE> [TAG]"
  echo "Ejemplo: $0 KIAH now"
  exit 1
fi

AIRPORT="$1"
TAG="${2:-now}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Safe filename (avoid spaces/special chars)
SAFE_AIRPORT="${AIRPORT//[^A-Za-z0-9_-]/_}"
SAFE_TAG="${TAG//[^A-Za-z0-9_-]/_}"
OUT_FILE="${LOG_DIR}/flight_${SAFE_AIRPORT}_${SAFE_TAG}_${TIMESTAMP}.json"

URL="${BASE_URL}/airports/${AIRPORT}/flights"

TMP_BODY="$(mktemp)"
HTTP_CODE="$(/usr/bin/curl -s -o "$TMP_BODY" -w "%{http_code}" \
  -H "x-apikey: ${FLIGHTAWARE_KEY}" \
  "$URL" || true)"

# Ensure body is valid JSON; if not, wrap as string
BODY_JSON="$(python3 -c 'import json,sys;
p=sys.argv[1]
data=open(p,"rb").read()
try:
  json.loads(data.decode("utf-8", errors="strict"))
  print(data.decode("utf-8"))
except Exception:
  print(json.dumps(data.decode("utf-8", errors="replace")))
' "$TMP_BODY" 2>/dev/null || echo "\"\"")"

rm -f "$TMP_BODY"

# Write final JSON
(
  echo "{"
  echo "  \"type\": \"flight_lookup\","
  echo "  \"airport\": \"${AIRPORT}\","
  echo "  \"tag\": \"${TAG}\","
  echo "  \"timestamp\": \"${TIMESTAMP}\","
  echo "  \"http_code\": ${HTTP_CODE},"
  echo "  \"url\": \"${URL}\","
  echo "  \"body\": ${BODY_JSON}"
  echo "}"
) > "$OUT_FILE"

# Friendly status
if [[ "$HTTP_CODE" = "200" ]]; then
  echo "Saved to: $OUT_FILE (OK)"
elif [[ "$HTTP_CODE" = "401" || "$HTTP_CODE" = "403" ]]; then
  echo "Saved to: $OUT_FILE (Auth error HTTP $HTTP_CODE)"
elif [[ "$HTTP_CODE" = "404" ]]; then
  echo "Saved to: $OUT_FILE (Not found)"
elif [[ "$HTTP_CODE" = "429" ]]; then
  echo "Saved to: $OUT_FILE (Rate limited 429)"
else
  echo "Saved to: $OUT_FILE (HTTP $HTTP_CODE)"
fi
