#!/usr/bin/env bash
# JaviTheKid – Central Intelligence Access
# phone_lookup.sh : Detecta si es teléfono o IP y consulta APIs apropiadas
set -euo pipefail

CONF_FILE="/root/CIA_Transforms/api_keys.conf"
LOG_DIR="/root/OSINT_Logs"

mkdir -p "$LOG_DIR"

if [[ -f "$CONF_FILE" ]]; then
  # shellcheck source=/root/CIA_Transforms/api_keys.conf
  source "$CONF_FILE"
else
  echo "[-] No se encontró $CONF_FILE"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <phone|ip>"
  exit 1
fi

TARGET="$1"
timestamp="$(date +%Y%m%d_%H%M%S)"

re_ip4='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
re_digits='^[0-9+]{7,20}$'

#################################
# IP LOOKUP
#################################
if [[ "$TARGET" =~ $re_ip4 || "$TARGET" == *:* ]]; then
  SAFE_TARGET="${TARGET//[^A-Za-z0-9._-]/_}"
  OUT_FILE="${LOG_DIR}/ip_lookup_${SAFE_TARGET}_${timestamp}.json"

  ipinfo_http="0"
  ipinfo_body="\"\""
  shodan_http="0"
  shodan_body="\"\""

  # IPINFO
  if [[ -n "${IPINFO_KEY:-}" ]]; then
    ipinfo_tmp="$(mktemp)"
    ipinfo_http="$(curl -s -o "$ipinfo_tmp" -w "%{http_code}" "https://ipinfo.io/${TARGET}?token=${IPINFO_KEY}" || true)"
    ipinfo_body="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$ipinfo_tmp" 2>/dev/null || echo "\"\"")"
    rm -f "$ipinfo_tmp"
  else
    ipinfo_body="\"IPINFO_KEY not set\""
  fi

  # SHODAN
  if [[ -n "${SHODAN_KEY:-}" ]]; then
    shodan_tmp="$(mktemp)"
    shodan_http="$(curl -s -o "$shodan_tmp" -w "%{http_code}" "https://api.shodan.io/shodan/host/${TARGET}?key=${SHODAN_KEY}" || true)"
    shodan_body="$(python3 -c 'import json,sys; print(json.dumps(open(sys.argv[1]).read()))' "$shodan_tmp" 2>/dev/null || echo "\"\"")"
    rm -f "$shodan_tmp"
  else
    shodan_body="\"SHODAN_KEY not set\""
  fi

  (
    echo "{"
    echo "  \"type\": \"ip\","
    echo "  \"target\": \"${TARGET}\","
    echo "  \"timestamp\": \"${timestamp}\","
    echo "  \"ipinfo\": {"
    echo "    \"http_code\": ${ipinfo_http},"
    echo "    \"body\": ${ipinfo_body}"
    echo "  },"
    echo "  \"shodan\": {"
    echo "    \"http_code\": ${shodan_http},"
    echo "    \"body\": ${shodan_body}"
    echo "  }"
    echo "}"
  ) > "$OUT_FILE"

  echo "Saved to: $OUT_FILE"
  exit 0
fi

#################################
# PHONE LOOKUP
#################################
if [[ "$TARGET" =~ $re_digits ]]; then
  SAFE_TARGET="${TARGET//[^A-Za-z0-9+]/_}"
  OUT_FILE="${LOG_DIR}/phone_lookup_${SAFE_TARGET}_${timestamp}.json"

  if [[ -n "${APILAYER_KEY:-}" ]]; then
    tmp="$(mktemp)"
    http_code="$(curl -s -o "$tmp" -w "%{http_code}" \
      "http://apilayer.net/api/validate?access_key=${APILAYER_KEY}&number=${TARGET}&country_code=US&format=1" || true)"

    if [[ "$http_code" = "200" ]]; then
      mv "$tmp" "$OUT_FILE"
    else
      echo "{\"status\":\"error\",\"http_code\":${http_code}}" > "$OUT_FILE"
      rm -f "$tmp"
    fi
  else
    echo "{\"status\":\"error\",\"reason\":\"APILAYER_KEY not set\"}" > "$OUT_FILE"
  fi

  echo "Saved to: $OUT_FILE"
  exit 0
fi

echo "[-] TARGET no parece ni IP ni teléfono: ${TARGET}"
exit 1
