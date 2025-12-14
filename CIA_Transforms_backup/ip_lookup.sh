#!/usr/bin/env bash
set -euo pipefail
# ip_lookup.sh - Consulta información OSINT básica de una IP
# Usa ip-api.com (sin API key) y guarda log en /root/OSINT_Logs

IP="${1:-}" || true

if [[ -z "$IP" ]]; then
    echo "[ERROR] Uso: $0 <IP_ADDRESS>" >&2
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
VENV_PATH="/root/OSINT_ENV/venv/bin/activate"
mkdir -p "$LOG_DIR"

TS=$(date +"%Y%m%d_%H%M%S")
TEXT_LOG="${LOG_DIR}/ip_lookup_${IP}_${TS}.log"
export IP LOG_DIR TS

exec > >(tee -a "$TEXT_LOG") 2>&1
echo "== IP LOOKUP FOR $IP =="
echo "Log: $TEXT_LOG"

if [[ ! -f "$VENV_PATH" ]]; then
    echo "[ERROR] No se encontró el entorno virtual en ${VENV_PATH}." >&2
    exit 1
fi

# Activar entorno virtual de OSINT
source "$VENV_PATH"
trap 'deactivate >/dev/null 2>&1 || true' EXIT

python3 - <<'PYCODE'
import datetime
import ipaddress
import json
import os
import sys

import requests

ip = os.environ.get("IP") or ""
try:
    ipaddress.ip_address(ip)
except ValueError:
    print(f"[ERROR] IP inválida: {ip}")
    raise SystemExit(1)

print(f"[*] Buscando información para IP: {ip} ...")

url = (
    "http://ip-api.com/json/"
    f"{ip}?fields=status,message,query,continent,country,regionName,city,zip,lat,lon,isp,org,as,timezone,mobile,proxy,hosting"
)
try:
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
except requests.RequestException as exc:
    print(f"[!] Error de red consultando ip-api: {exc}")
    raise SystemExit(1)

data = resp.json()

if data.get("status") != "success":
    print("[!] Consulta fallida:", data.get("message", "Unknown error"))
    raise SystemExit(1)

# Pretty print en pantalla
print("\n========== IP INFO ==========")
for k, v in data.items():
    print(f"{k:12}: {v}")
print("================================\n")

# Guardar en log
log_dir = os.environ.get("LOG_DIR", "${LOG_DIR}")
os.makedirs(log_dir, exist_ok=True)
ts = os.environ.get("TS") or datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
log_path = os.path.join(log_dir, f"ip_lookup_{ip}_{ts}.json")

with open(log_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print(f"[+] Datos guardados en: {log_path}")
PYCODE
