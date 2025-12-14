#!/bin/bash
mkdir -p /root/OSINT_Logs
# JaviTheKid – CIA Transform: Email Breach Lookup

source /root/CIA_Transforms/api_keys.conf

EMAIL="$1"

if [ -z "$EMAIL" ]; then
    echo "Usage: $0 <email>"
    exit 1
fi

echo "== EMAIL BREACH LOOKUP FOR $EMAIL =="

SAFE_EMAIL="${EMAIL//@/_at_}"
TS="$(date +%Y%m%d_%H%M%S)"
OUTPUT="/root/OSINT_Logs/email_breach_${SAFE_EMAIL}_${TS}.json"

HTTP_CODE=$(curl -s -o "$OUTPUT" -w "%{http_code}" \
  -H "hibp-api-key: $HIBP_KEY" \
  -H "user-agent: JaviTheKid-CIA-OSINT" \
  "https://haveibeenpwned.com/api/v3/breachedaccount/$EMAIL?truncateResponse=false")

if [ "$HTTP_CODE" = "200" ]; then
  echo "Saved to: $OUTPUT (OK)"
elif [ "$HTTP_CODE" = "404" ]; then
  echo '{"status":"no_breaches_found"}' > "$OUTPUT"
  echo "Saved to: $OUTPUT (No breaches found)"
else
  echo "{\"status\":\"error\",\"http_code\":$HTTP_CODE}" > "$OUTPUT"
  echo "Saved to: $OUTPUT (Error HTTP $HTTP_CODE)"
fi
