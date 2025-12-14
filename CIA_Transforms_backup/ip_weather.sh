#!/usr/bin/env bash
# JaviTheKid – CIA Transform: IP Weather Lookup (OpenWeather)
# Usage:
#   ip_weather.sh "Katy,US"
#   ip_weather.sh "29.7858,-95.8244"
set -euo pipefail

BASE_DIR="/root"
CONF_FILE="${BASE_DIR}/CIA_Transforms/api_keys.conf"
OUT_DIR="${BASE_DIR}/OSINT_Logs"

mkdir -p "$OUT_DIR"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <location>"
  echo "Examples:"
  echo "  $0 \"Katy,US\""
  echo "  $0 \"29.7858,-95.8244\""
  exit 1
fi

TARGET="$1"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

if [[ -f "$CONF_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONF_FILE"
else
  echo "Config file not found: $CONF_FILE" >&2
  exit 1
fi

if [[ -z "${OPENWEATHER_KEY:-}" ]]; then
  echo "OPENWEATHER_KEY is not set in ${CONF_FILE}" >&2
  exit 1
fi

SAFE_TARGET="${TARGET//[^A-Za-z0-9._,-]/_}"
OUT_FILE="${OUT_DIR}/ip_weather_${SAFE_TARGET}_${TIMESTAMP}.json"

urlencode() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

QUERY_TYPE=""
URL=""

if [[ "$TARGET" =~ ^-?[0-9]+(\.[0-9]+)?\,-?[0-9]+(\.[0-9]+)?$ ]]; then
  LAT="${TARGET%,*}"
  LON="${TARGET#*,}"
  QUERY_TYPE="coordinates"
  URL="https://api.openweathermap.org/data/2.5/weather?lat=${LAT}&lon=${LON}&appid=${OPENWEATHER_KEY}&units=imperial"
else
  QUERY_TYPE="city"
  CITY_ENC="$(urlencode "$TARGET")"
  URL="https://api.openweathermap.org/data/2.5/weather?q=${CITY_ENC}&appid=${OPENWEATHER_KEY}&units=imperial"
fi

TMP_BODY="$(mktemp)"
HTTP_CODE="$(curl -s -o "$TMP_BODY" -w "%{http_code}" "$URL" || true)"

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

(
  echo "{"
  echo "  \"type\": \"weather\","
  echo "  \"query_type\": \"${QUERY_TYPE}\","
  echo "  \"target\": \"${TARGET}\","
  echo "  \"timestamp\": \"${TIMESTAMP}\","
  echo "  \"http_code\": ${HTTP_CODE},"
  echo "  \"url\": \"${URL}\","
  echo "  \"body\": ${BODY_JSON}"
  echo "}"
) > "$OUT_FILE"

if [[ "$HTTP_CODE" = "200" ]]; then
  echo "Saved to: $OUT_FILE (OK)"
elif [[ "$HTTP_CODE" = "401" ]]; then
  echo "Saved to: $OUT_FILE (Error 401: invalid API key)"
elif [[ "$HTTP_CODE" = "404" ]]; then
  echo "Saved to: $OUT_FILE (Not found)"
elif [[ "$HTTP_CODE" = "429" ]]; then
  echo "Saved to: $OUT_FILE (Rate limited 429)"
else
  echo "Saved to: $OUT_FILE (HTTP $HTTP_CODE)"
fi
