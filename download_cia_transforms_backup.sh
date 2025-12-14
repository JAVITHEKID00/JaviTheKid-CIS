#!/usr/bin/env bash
set -euo pipefail

# Crea un archivo comprimido de la carpeta CIA_Transforms_backup
# Uso: ./download_cia_transforms_backup.sh [directorio_de_salida]

TARGET_DIR="CIA_Transforms_backup"
OUTPUT_DIR="${1:-$(pwd)}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "[ERROR] No se encontró el directorio ${TARGET_DIR} en $(pwd)." >&2
    exit 1
fi

resolve_path() {
    if command -v realpath >/dev/null 2>&1; then
        realpath "$1"
    else
        readlink -f "$1"
    fi
}

if [[ -n "${1:-}" ]]; then
    OUTPUT_DIR="$(resolve_path "$OUTPUT_DIR")"
fi

mkdir -p "$OUTPUT_DIR"

TS=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="CIA_Transforms_backup_${TS}.tar.gz"
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git archive --format=tar.gz --output="$ARCHIVE_PATH" HEAD "$TARGET_DIR"
else
    tar -czf "$ARCHIVE_PATH" "$TARGET_DIR"
fi

echo "[OK] Archivo creado: $ARCHIVE_PATH"
