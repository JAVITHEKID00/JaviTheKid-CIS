#!/bin/bash
mkdir -p /root/OSINT_Logs

EMAIL="$1"

source /root/OSINT_ENV/venv/bin/activate

echo "== EMAIL LOOKUP FOR $EMAIL =="

echo ""
echo "[HIBP]"
curl -s "https://haveibeenpwned.com/api/v3/breachedaccount/$EMAIL?truncateResponse=false" \
  -H "hibp-api-key: $HIBP_KEY"

echo ""
echo "[HUNTER]"
curl -s "https://api.hunter.io/v2/email-verifier?email=$EMAIL&api_key=$HUNTER_KEY"

echo ""
echo "[EMAILREP]"
curl -s "https://emailrep.io/$EMAIL?key=$EMAILREP_KEY"

echo ""
echo "[HOLEHE]"
/root/OSINT_ENV/venv/bin/holehe $EMAIL

echo ""
echo "[SOCIALSCAN]"
/root/OSINT_ENV/venv/bin/socialscan $EMAIL

