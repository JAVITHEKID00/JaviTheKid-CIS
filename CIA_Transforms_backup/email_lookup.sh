#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/root/OSINT_Logs"
VENV_PATH="/root/OSINT_ENV/venv/bin/activate"
CONFIG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/api_keys.conf"

mkdir -p "${LOG_DIR}"

usage() {
    echo "Uso: $0 <email>" >&2
    exit 1
}

load_config() {
    if [[ -z "${CONFIG_LOADED:-}" && -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        CONFIG_LOADED=1
    fi
}

require_var() {
    local var_name="$1"
    load_config
    if [[ -z "${!var_name:-}" ]]; then
        echo "[ERROR] Falta la variable de entorno ${var_name}." >&2
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_curl() {
    local label="$1" url="$2" header="$3" curl_cmd=(curl -fsSL)
    echo "[${label}]"

    curl_cmd+=(-H "User-Agent: email_lookup.sh (curl)")

    if [[ -n "$header" ]]; then
        curl_cmd+=(-H "$header")
    fi

    curl_cmd+=("$url")

    if ! "${curl_cmd[@]}"; then
        echo "[WARN] ${label} falló o la respuesta fue vacía." >&2
    fi
    echo
}

EMAIL="${1:-}" || true
[[ -z "$EMAIL" ]] && usage

if [[ ! -f "$VENV_PATH" ]]; then
    echo "[ERROR] No se encontró el entorno virtual en ${VENV_PATH}." >&2
    exit 1
fi

# Validar API keys antes de usarlas
require_var "HIBP_KEY"
require_var "HUNTER_KEY"
require_var "EMAILREP_KEY"

source "$VENV_PATH"
trap 'deactivate >/dev/null 2>&1 || true' EXIT

# Registrar salida completa a un log
TS=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/email_lookup_${EMAIL}_${TS}.log"
exec > >(tee -a "$LOG_FILE") 2>&1

cat <<INFO
== EMAIL LOOKUP FOR $EMAIL ==
Log: $LOG_FILE
INFO

echo "[HIBP]" && run_curl "HIBP" "https://haveibeenpwned.com/api/v3/breachedaccount/$EMAIL?truncateResponse=false" "hibp-api-key: $HIBP_KEY"
echo "[HUNTER]" && run_curl "HUNTER" "https://api.hunter.io/v2/email-verifier?email=$EMAIL&api_key=$HUNTER_KEY" ""
echo "[EMAILREP]" && run_curl "EMAILREP" "https://emailrep.io/$EMAIL?key=$EMAILREP_KEY" ""

echo "[HOLEHE]"
if command_exists /root/OSINT_ENV/venv/bin/holehe; then
    if ! /root/OSINT_ENV/venv/bin/holehe "$EMAIL"; then
        echo "[WARN] holehe no pudo ejecutarse correctamente." >&2
    fi
else
    echo "[WARN] holehe no está instalado en el entorno virtual." >&2
fi

echo

echo "[SOCIALSCAN]"
if command_exists /root/OSINT_ENV/venv/bin/socialscan; then
    if ! /root/OSINT_ENV/venv/bin/socialscan "$EMAIL"; then
        echo "[WARN] socialscan no pudo ejecutarse correctamente." >&2
    fi
else
    echo "[WARN] socialscan no está instalado en el entorno virtual." >&2
fi
