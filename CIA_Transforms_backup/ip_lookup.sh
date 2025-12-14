#!/usr/bin/env bash
mkdir -p /root/OSINT_Logs
# ip_lookup.sh - Consulta información OSINT básica de una IP
# Usa ip-api.com (sin API key) y guarda log en /root/OSINT_Logs

IP="$1"

if [ -z "$IP" ]; then
    echo "[ERROR] Uso: $0 <IP_ADDRESS>"
    exit 1
fi

LOG_DIR="/root/OSINT_Logs"
mkdir -p "$LOG_DIR"

# Activar entorno virtual de OSINT
source /root/OSINT_ENV/bin/activate 2>/dev/null

python3 - << EOF
import requests
import json
import datetime
import os

ip = "${IP}"
print(f"[*] Buscando información para IP: {ip} ...")

url = f"http://ip-api.com/json/{ip}?fields=status,message,query,continent,country,regionName,city,zip,lat,lon,isp,org,as,timezone,mobile,proxy,hosting"
resp = requests.get(url, timeout=10)
data = resp.json()

if data.get("status") != "success":
    print("[!] Consulta fallida:", data.get("message", "Unknown error"))
    raise SystemExit(1)

# Pretty print en pantalla
print("\\n========== IP INFO ==========")
for k, v in data.items():
    print(f"{k:12}: {v}")
print("================================\\n")

# Guardar en log
log_dir = "${LOG_DIR}"
os.makedirs(log_dir, exist_ok=True)
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
log_path = os.path.join(log_dir, f"ip_lookup_{ip}_{ts}.json")

with open(log_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print(f"[+] Datos guardados en: {log_path}")
EOF

# Desactivar entorno virtual
deactivate 2>/dev/null || true
